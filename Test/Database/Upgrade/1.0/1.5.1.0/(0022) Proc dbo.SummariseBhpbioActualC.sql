IF OBJECT_ID('dbo.SummariseBhpbioActualC') IS NOT NULL
     DROP PROCEDURE dbo.SummariseBhpbioActualC 
GO 
    
CREATE PROCEDURE dbo.SummariseBhpbioActualC
(
	@iSummaryMonth DATETIME,
	@iSummaryLocationId INTEGER
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'SummariseBhpbioActualC',
		@TransactionCount = @@TranCount 

	-- if there are no transactions available then start a new one
	-- if there is already a transaction then only mark a savepoint
	IF @TransactionCount = 0
	BEGIN
		SET TRANSACTION ISOLATION LEVEL REPEATABLE READ 
		BEGIN TRANSACTION
	END
	ELSE
	BEGIN
		SAVE TRANSACTION @TransactionName
	END
  
	BEGIN TRY
		DECLARE @summaryId INT
		DECLARE @startOfMonth DATETIME
		DECLARE @startOfNextMonth DATETIME
		DECLARE @summaryEntryTypeId INTEGER
		DECLARE @sampleTonnesSummaryEntryTypeId INTEGER
		
		-- obtain the Actual Type Id for ActualC storage
		SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
		FROM dbo.BhpbioSummaryEntryType bset
		WHERE bset.Name = 'ActualC'
		
		SELECT @sampleTonnesSummaryEntryTypeId = bset.SummaryEntryTypeId
		FROM dbo.BhpbioSummaryEntryType bset
		WHERE bset.Name = 'ActualCSampleTonnes'
		
		-- the first step is to remove previously summarised data for the same filtering criteria that the current summary is running on
		exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iSummaryMonth,
											@iSummaryLocationId = @iSummaryLocationId,
											@iSummaryEntryTypeId = @summaryEntryTypeId
		
		exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iSummaryMonth,
											@iSummaryLocationId = @iSummaryLocationId,
											@iSummaryEntryTypeId = @sampleTonnesSummaryEntryTypeId
											
		-- get the start of the summary month and the start of the following month
		-- this gives us a window of time to operate within
		SELECT @startOfMonth = dbo.GetDateMonth(@iSummaryMonth)
		SELECT @startOfNextMonth = DATEADD(month,1,@iSummaryMonth)

		-- get a Summary Id for the month (or create a new one if needed)
		EXEC dbo.GetBhpbioSummaryIdForMonth @iSummaryMonth = @startOfMonth,
											@oSummaryId = @summaryId OUTPUT

		-- this DOES NOT and CAN NOT return data below the site level
		-- this is because:
		-- (1) weightometers & crushers are at the SITE level, and
		-- (2) the way Sites aggregate is based on the "Sample" tonnes method,
		--     .. hence these records need to be returned at the Site level
		-- note that data must not be returned at the Hub/Company level either

		-- 'C' - all crusher removals
		-- returns [High Grade] & [Bene Feed] as designation types

		DECLARE @Weightometer TABLE
		(
			WeightometerSampleId INT NOT NULL,
			SiteLocationId INT NULL,
			RealTonnes FLOAT NULL,
			SampleTonnes FLOAT NOT NULL,
			MaterialTypeId INT NOT NULL,
			PRIMARY KEY (WeightometerSampleId)
		)
		
		DECLARE @GradeLocation TABLE
		(
			CalendarMonth DATETIME NOT NULL,
			SiteLocationId INT NOT NULL,
			PRIMARY KEY (SiteLocationId, CalendarMonth)
		)
				
		DECLARE @SiteLocation TABLE
		(
			LocationId INT NOT NULL,
			PRIMARY KEY (LocationId)
		)
		
		DECLARE @HighGradeMaterialTypeId INT
		DECLARE @BeneFeedMaterialTypeId INT
		DECLARE @SampleTonnesField VARCHAR(31)
		DECLARE @SampleSourceField VARCHAR(31)
		DECLARE @SiteLocationTypeId SMALLINT
				
		SET @SampleTonnesField = 'SampleTonnes'
		SET @SampleSourceField = 'SampleSource'
		
		SET @HighGradeMaterialTypeId =
			(
				SELECT Material_Type_Id
				FROM dbo.MaterialType
				WHERE Abbreviation = 'High Grade'
					AND Material_Category_Id = 'Designation'
			)

		SET @BeneFeedMaterialTypeId = 
			(
				SELECT Material_Type_Id
				FROM dbo.MaterialType
				WHERE Abbreviation = 'Bene Feed'
					AND Material_Category_Id = 'Designation'
			)
		
		-- Setup the Locations
		-- collect at site level (this is used to ensure the site's sampled tonnes are collated)
		SET @SiteLocationTypeId =
			(
				SELECT Location_Type_Id
				FROM dbo.LocationType
				WHERE Description = 'Site'
			)
		INSERT INTO @SiteLocation
			(LocationId)
		SELECT LocationId
		FROM dbo.GetLocationSubtreeByLocationType(@iSummaryLocationId, @SiteLocationTypeId, @SiteLocationTypeId)
		
		-- -----------------------------------------------------------------------------------------------------------------------------------
		-- The queries used in this procedure are based on / taken from the original reporting implementation (on non-summarised data)
		-- -----------------------------------------------------------------------------------------------------------------------------------
		
		-- retrieve the list of Weightometer Records to be used in the calculations
		INSERT INTO @Weightometer
			(
				WeightometerSampleId,
				SiteLocationId,
				RealTonnes, 
				SampleTonnes, 
				MaterialTypeId
			)
		SELECT  w.WeightometerSampleId, l.LocationId,
			-- calculate the REAL tonnes
			CASE
				WHEN w.UseAsRealTonnes = 1
					THEN ISNULL(ws.Corrected_Tonnes, ws.Tonnes)
				ELSE NULL
			END AS RealTonnes,
			-- calculate the SAMPLE tonnes
			-- if a sample tonnes hasn't been provided then use the actual tonnes recorded for the transaction
			-- not all flows will have this recorded (in particular CVF corrected plant balanced records)
			CASE BeneFeed
				WHEN 1 THEN ISNULL(ws.Corrected_Tonnes, ws.Tonnes)
				ELSE ISNULL(wsv.Field_Value, 0.0)
			END AS SampleTonnes,
			-- return the Material Type based on whether it is bene feed
			CASE w.BeneFeed
				WHEN 1 THEN @BeneFeedMaterialTypeId
				WHEN 0 THEN @HighGradeMaterialTypeId
			END AS MaterialTypeId
		FROM dbo.WeightometerSample AS ws
			INNER JOIN
				(
					-- collect the weightometer sample id's for all movements from the crusher
					-- these are used to ease lookup and ensure uniqueness of the weightometer_sample_ids returned
					SELECT DISTINCT dttf.Weightometer_Sample_Id AS WeightometerSampleId, 1 AS UseAsRealTonnes,
						CASE
							WHEN m.Mill_Id IS NOT NULL
								THEN 1
							ELSE 0
						END AS BeneFeed, l.LocationId
					FROM dbo.DataTransactionTonnes AS dtt
						INNER JOIN dbo.DataTransactionTonnesFlow AS dttf
							ON (dttf.Data_Transaction_Tonnes_Id = dtt.Data_Transaction_Tonnes_Id)
						INNER JOIN dbo.CrusherLocation AS cl
							ON (dttf.Source_Crusher_Id = cl.Crusher_Id)
						LEFT JOIN dbo.Mill AS m
							ON (dttf.Destination_Stockpile_Id = m.Stockpile_Id)
						INNER JOIN @SiteLocation AS l
							ON (cl.Location_Id = l.LocationId)
						LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('ActualC') xs
							ON xs.StockpileId = dttf.Source_Stockpile_Id
							OR xs.StockpileId = dttf.Destination_Stockpile_Id
					WHERE dtt.Data_Transaction_Tonnes_Date >= @startOfMonth
						AND  dtt.Data_Transaction_Tonnes_Date < @startOfNextMonth
						AND dttf.Destination_Crusher_Id IS NULL  -- ignore crusher to crusher feeds
						AND xs.StockpileId IS NULL -- No movements to or from excluded groups.
					GROUP BY dttf.Weightometer_Sample_Id, m.Mill_Id, l.LocationId
					UNION 
					-- collect weightometer sample id's for all movements to train rakes
					-- (by definition it's always delivers to train rake stockpiles...
					--  the grades (but not the tonnes) from these weightometers samples are important to us)
					SELECT DISTINCT dttf.Weightometer_Sample_Id, 0, 0, l.LocationId
					FROM dbo.DataTransactionTonnes AS dtt
						INNER JOIN dbo.DataTransactionTonnesFlow AS dttf
							ON (dttf.Data_Transaction_Tonnes_Id = dtt.Data_Transaction_Tonnes_Id)
						INNER JOIN dbo.WeightometerSample AS ws
							ON (dttf.Weightometer_Sample_Id = ws.Weightometer_Sample_Id)
						INNER JOIN dbo.StockpileGroupStockpile AS sgs
							ON (sgs.Stockpile_Id = dttf.Destination_Stockpile_Id)
						INNER JOIN dbo.WeightometerLocation AS wl
							ON (ws.Weightometer_Id = wl.Weightometer_Id)
						INNER JOIN @SiteLocation AS l
							ON (wl.Location_Id = l.LocationId)
						LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('ActualC') xs
							ON xs.StockpileId = dttf.Source_Stockpile_Id
							OR xs.StockpileId = dttf.Destination_Stockpile_Id
					WHERE dtt.Data_Transaction_Tonnes_Date >= @startOfMonth
						AND dtt.Data_Transaction_Tonnes_Date < @startOfNextMonth
						AND sgs.Stockpile_Group_Id = 'Port Train Rake'
						AND xs.StockpileId IS NULL -- No movements to or from excluded groups.
					GROUP BY dttf.Weightometer_Sample_Id, l.LocationId
				  ) AS w
				ON (ws.Weightometer_Sample_Id = w.WeightometerSampleId)
				-- ensure the weightometer belongs to the required location
			INNER JOIN dbo.WeightometerLocation AS wl
				ON (wl.Weightometer_Id = ws.Weightometer_Id)
			INNER JOIN @SiteLocation AS l
				ON (l.LocationId = wl.Location_Id)
			LEFT OUTER JOIN dbo.WeightometerSampleValue AS wsv
				ON (ws.Weightometer_Sample_Id = wsv.Weightometer_Sample_Id
					AND wsv.Weightometer_Sample_Field_Id = @SampleTonnesField)
		WHERE ws.Weightometer_Sample_Date >= @startOfMonth
			AND ws.Weightometer_Sample_Date < @startOfNextMonth
		
		-- insert main actual row using a Sum of Tonnes
		INSERT INTO dbo.BhpbioSummaryEntry
		(
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			Tonnes
		)
		SELECT  @summaryId,
				@summaryEntryTypeId,
				w.SiteLocationId,
				w.MaterialTypeId,
				Sum(w.RealTonnes)
		FROM @Weightometer w
		GROUP BY 
			w.SiteLocationId,
			w.MaterialTypeId
		HAVING SUM(w.RealTonnes) IS NOT NULL
		
		-- Get the valid locations to be used for the grades. 
		-- This is so locations with no valid real tonnes are not included in the calc.
		INSERT INTO @GradeLocation	(CalendarMonth, SiteLocationId)
		SELECT DISTINCT dbo.GetDateMonth(ws.Weightometer_Sample_Date), w.SiteLocationId
		FROM @Weightometer w
			INNER JOIN dbo.WeightometerSample ws ON ws.Weightometer_Sample_Id = w.WeightometerSampleId
		WHERE w.RealTonnes IS NOT NULL
		
		-- insert the sample tonnes values related to the selction of haulage we are working with
		INSERT INTO dbo.BhpbioSummaryEntry
		(
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			Tonnes
		)
		SELECT  @summaryId,
				@sampleTonnesSummaryEntryTypeId,
				w.SiteLocationId,
				w.MaterialTypeId,
				Sum(w.SampleTonnes)
		FROM @Weightometer w
			LEFT OUTER JOIN
			(
				SELECT ws.Weightometer_Sample_Id
				FROM dbo.WeightometerSample AS ws
					INNER JOIN dbo.WeightometerLocation AS wl
						ON (ws.Weightometer_Id = wl.Weightometer_Id)
					INNER JOIN dbo.WeightometerSampleNotes AS wsn
						ON (wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
							AND wsn.Weightometer_Sample_Field_Id = @SampleSourceField)
					INNER JOIN dbo.GetBhpbioWeightometerSampleSource(@iSummaryLocationId, @startOfMonth, @startOfNextMonth) AS ss
						ON (dbo.GetDateMonth(ws.Weightometer_Sample_Date) = ss.MonthPeriod
							AND wl.Location_Id = ss.LocationId
							AND wsn.Notes = ss.SampleSource)
			) AS sSource ON (sSource.Weightometer_Sample_Id = w.WeightometerSampleId)
			INNER JOIN dbo.WeightometerSample ws
				ON ws.Weightometer_Sample_Id = w.WeightometerSampleId
			INNER JOIN @GradeLocation AS gl
				ON (gl.CalendarMonth = dbo.GetDateMonth(ws.Weightometer_Sample_Date)
					AND ISNULL(gl.SiteLocationId, -1) = ISNULL(w.SiteLocationId, -1))
		WHERE
			-- only include if:
			-- 1. the Material Type is Bene Feed and there is no Sample Source
			-- 2. the Material Type is High Grade and there is a matching SampleSource
			CASE
				WHEN (w.MaterialTypeId = @BeneFeedMaterialTypeId) AND (sSource.Weightometer_Sample_Id IS NULL) THEN 1
				WHEN (w.MaterialTypeId = @HighGradeMaterialTypeId) AND (sSource.Weightometer_Sample_Id IS NOT NULL) THEN 1
				ELSE 0
			END = 1
			AND EXISTS (SELECT * 
						FROM dbo.WeightometerSampleGrade AS wsg
						WHERE wsg.Weightometer_Sample_Id = w.WeightometerSampleId
							AND wsg.Grade_Value IS NOT NULL
						)
		GROUP BY 
			w.SiteLocationId,
			w.MaterialTypeId
		HAVING SUM(w.SampleTonnes) IS NOT NULL
		
		-- insert the actual grades related to the selection of Haulage we are working with and the actual tonnes rows created above
		INSERT INTO dbo.BhpbioSummaryEntryGrade
		(
			SummaryEntryId,
			GradeId,
			GradeValue
		)
		SELECT	bse.SummaryEntryId,
				wsg.Grade_Id,
				SUM(w.SampleTonnes * wsg.Grade_Value) / SUM(w.SampleTonnes)
		FROM @Weightometer AS w
			INNER JOIN dbo.BhpbioSummaryEntry bse
				ON bse.LocationId = w.SiteLocationId
				AND bse.MaterialTypeId = w.MaterialTypeId
				AND bse.SummaryId = @summaryId
				AND bse.SummaryEntryTypeId = @sampleTonnesSummaryEntryTypeId
			-- check the membership with the Sample Source
			LEFT OUTER JOIN
			(
				SELECT ws.Weightometer_Sample_Id
				FROM dbo.WeightometerSample AS ws
					INNER JOIN dbo.WeightometerLocation AS wl
						ON (ws.Weightometer_Id = wl.Weightometer_Id)
					INNER JOIN dbo.WeightometerSampleNotes AS wsn
						ON (wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
							AND wsn.Weightometer_Sample_Field_Id = @SampleSourceField)
					INNER JOIN dbo.GetBhpbioWeightometerSampleSource(@iSummaryLocationId, @startOfMonth, @startOfNextMonth) AS ss
						ON (dbo.GetDateMonth(ws.Weightometer_Sample_Date) = ss.MonthPeriod
							AND wl.Location_Id = ss.LocationId
							AND wsn.Notes = ss.SampleSource)
			) AS sSource
			ON (sSource.Weightometer_Sample_Id = w.WeightometerSampleId)
			INNER JOIN dbo.WeightometerSample ws
				ON ws.Weightometer_Sample_Id = w.WeightometerSampleId
			INNER JOIN dbo.WeightometerSampleGrade AS wsg
				ON (wsg.Weightometer_Sample_Id = w.WeightometerSampleId)
			INNER JOIN @GradeLocation AS gl
				ON (gl.CalendarMonth = dbo.GetDateMonth(ws.Weightometer_Sample_Date)
					AND ISNULL(gl.SiteLocationId, -1) = ISNULL(w.SiteLocationId, -1))
		WHERE 
				-- only include if:
				-- 1. the Material Type is Bene Feed and there is no Sample Source
				-- 2. the Material Type is High Grade and there is a matching SampleSource
				CASE
					WHEN (w.MaterialTypeId = @BeneFeedMaterialTypeId) AND (sSource.Weightometer_Sample_Id IS NULL) THEN 1
					WHEN (w.MaterialTypeId = @HighGradeMaterialTypeId) AND (sSource.Weightometer_Sample_Id IS NOT NULL) THEN 1
					ELSE 0
				END = 1
		GROUP BY bse.SummaryEntryId, wsg.Grade_Id
		
		-- if we started a new transaction that is still valid then commit the changes
		IF (@TransactionCount = 0) AND (XAct_State() = 1)
		BEGIN
			COMMIT TRANSACTION
		END
	END TRY
	BEGIN CATCH
		-- if we started a transaction then roll it back
		IF (@TransactionCount = 0)
		BEGIN
			ROLLBACK TRANSACTION
		END
		-- if we are part of an existing transaction and 
		ELSE IF (XAct_State() = 1) AND (@TransactionCount > 0)
		BEGIN
			ROLLBACK TRANSACTION @TransactionName
		END

		EXEC dbo.StandardCatchBlock
	END CATCH
END
GO

GRANT EXECUTE ON dbo.SummariseBhpbioActualC TO BhpbioGenericManager
GO

/*
exec dbo.SummariseBhpbioActualC
	@iSummaryMonth = '2009-11-01',
	@iLocationId = 3
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.SummariseBhpbioActualC">
 <Procedure>
	Generates a set of summary ActualC data based on supplied criteria.
			
	Pass: 
			@iSummaryMonth: the month for which summary data is to be generated,
			@iSummaryLocationId: the location (typically a Site) for which data will be summarised
 </Procedure>
</TAG>
*/