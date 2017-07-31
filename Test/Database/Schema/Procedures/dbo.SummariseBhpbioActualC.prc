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
		DECLARE @endOfMonth DATETIME
		DECLARE @startOfNextMonth DATETIME
		DECLARE @summaryEntryTypeId INTEGER
		DECLARE @sampleTonnesSummaryEntryTypeId INTEGER
		
		DECLARE @interimGrade TABLE
		(
			SummaryEntryId INT NOT NULL,
			WeightometerId	VARCHAR(31) NULL,
			GradeId SMALLINT NOT NULL,
			GradeValue REAL NOT NULL,
			RealTonnes FLOAT NULL,
			ShouldWeightBySampleTonnes BIT NOT NULL
		)
			
		-- this proc is only applicable for the Site locations - it will give strange results if run anywhere 
		-- else. The UI should only allow it to be run for the Site level, so this error should never occur
		IF NOT EXISTS (
			SELECT 1 from Location l
			INNER JOIN LocationType lt ON lt.Location_Type_Id = l.Location_Type_Id
			WHERE lt.[Description] = 'Site'
		)
		BEGIN
			RAISERROR('@iSummaryLocationId must be a Site location', 16, 1)
		END

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
		SELECT @endOfMonth = DATEADD(day,-1,@startOfNextMonth)

		-- get a Summary Id for the month (or create a new one if needed)
		EXEC dbo.GetBhpbioSummaryIdForMonth @iSummaryMonth = @startOfMonth,
											@oSummaryId = @summaryId OUTPUT

		-- this DOES NOT and CAN NOT return data below the site level
		-- this is because:
		-- (1) weightometers & crushers are at the SITE level, and
		-- (2) the way *some* Sites aggregate, involves "Sample" tonnes (for back-calculated grades) before weighting on real tonnes,
		--     .. hence these records need to be returned at the Site level
		-- note that data must not be returned at the Hub/Company level either

		-- 'C' - all crusher removals
		-- returns [High Grade] & [Bene Feed] as designation types

		DECLARE @Weightometer TABLE
		(
			WeightometerId	VARCHAR(31) NOT NULL,
			WeightometerSampleId INT NOT NULL,

			SiteLocationId INT NULL,
			RealTonnes FLOAT NULL,
			SampleTonnes FLOAT NOT NULL,
			MaterialTypeId INT NOT NULL,
			ProductSize VARCHAR(5) NOT NULL,
			IncludeInCTonnes BIT DEFAULT(1),
			PRIMARY KEY (WeightometerSampleId, ProductSize)
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
			IncludeStart DateTime NOT NULL,
			IncludeEnd DateTime NOT NULL,
			
			PRIMARY KEY (LocationId, IncludeStart, IncludeEnd)
		)

		DECLARE @HighGradeMaterialTypeId INT
		DECLARE @BeneFeedMaterialTypeId INT
		DECLARE @SampleTonnesField VARCHAR(31)
		DECLARE @SampleSourceField VARCHAR(31)
		DECLARE @ProductSizeFieldId VARCHAR(11)
		DECLARE @SiteLocationTypeId SMALLINT
		
		SET @SampleTonnesField = 'SampleTonnes'
		SET @SampleSourceField = 'SampleSource'
		SET @ProductSizeFieldId = 'ProductSize'

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
			(LocationId, IncludeStart, IncludeEnd)
		SELECT LocationId, IncludeStart, IncludeEnd
		FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iSummaryLocationId, 0, 'Site', @startOfMonth, @endOfMonth)
		
		-- -----------------------------------------------------------------------------------------------------------------------------------
		-- The queries used in this procedure are based on / taken from the original reporting implementation (on non-summarised data)
		-- -----------------------------------------------------------------------------------------------------------------------------------

		-- retrieve the list of Weightometer Records to be used in the calculations
		INSERT INTO @Weightometer
			(
				WeightometerId,
				WeightometerSampleId,
				SiteLocationId,
				RealTonnes, 
				SampleTonnes, 
				ProductSize,
				MaterialTypeId,
				IncludeInCTonnes
			)
		SELECT  ws.Weightometer_Id, w.WeightometerSampleId, l.LocationId,
			-- calculate the REAL tonnes
			ISNULL(ISNULL(defaultlf.[Percent], 1) * ws.Corrected_Tonnes, ISNULL(defaultlf.[Percent], 1) * ws.Tonnes) AS RealTonnes,
			-- calculate the SAMPLE tonnes
			-- if a sample tonnes hasn't been provided then use the actual tonnes recorded for the transaction
			-- not all flows will have this recorded (in particular CVF corrected plant balanced records)
			CASE w.BeneFeed
				WHEN 1 THEN ISNULL(ISNULL(defaultlf.[Percent], 1) * ws.Corrected_Tonnes, ISNULL(defaultlf.[Percent], 1) * ws.Tonnes)
				ELSE ISNULL(ISNULL(defaultlf.[Percent], 1) * wsv.Field_Value, 0.0)
			END AS SampleTonnes,
			ISNULL(wsn.Notes, defaultlf.ProductSize) As ProductSize,
			-- return the Material Type based on whether it is bene feed
			CASE w.BeneFeed
				WHEN 1 THEN @BeneFeedMaterialTypeId
				WHEN 0 THEN @HighGradeMaterialTypeId
			END AS MaterialTypeId,
			w.IncludeInCTonnes
		FROM dbo.WeightometerSample AS ws
			INNER JOIN
				(
					-- collect the weightometer sample id's for all movements from the crusher
					-- these are used to ease lookup and ensure uniqueness of the weightometer_sample_ids returned
					SELECT DISTINCT dttf.Weightometer_Sample_Id AS WeightometerSampleId, 1 AS IncludeInCTonnes,
						CASE
							WHEN m.Mill_Id IS NOT NULL
								THEN 1
							ELSE 0
						END AS BeneFeed, l.LocationId
					FROM dbo.DataTransactionTonnes AS dtt
						INNER JOIN dbo.DataTransactionTonnesFlow AS dttf
							ON (dttf.Data_Transaction_Tonnes_Id = dtt.Data_Transaction_Tonnes_Id)
						INNER JOIN dbo.GetBhpbioCrusherLocationWithOverride(@startOfMonth, @endOfMonth) AS cl
							ON (dttf.Source_Crusher_Id = cl.Crusher_Id)
                            AND (dtt.Data_Transaction_Tonnes_Date BETWEEN cl.IncludeStart AND cl.IncludeEnd)
						LEFT JOIN dbo.Mill AS m
							ON (dttf.Destination_Stockpile_Id = m.Stockpile_Id)
						INNER JOIN @SiteLocation AS l
							ON (cl.Location_Id = l.LocationId)
                            AND (dtt.Data_Transaction_Tonnes_Date BETWEEN l.IncludeStart AND l.IncludeEnd)
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
						INNER JOIN dbo.GetBhpbioWeightometerLocationWithOverride(@startOfMonth, @endOfMonth) AS wl
							ON (ws.Weightometer_Id = wl.Weightometer_Id)
							AND (ws.Weightometer_Sample_Date BETWEEN wl.IncludeStart AND wl.IncludeEnd)
						INNER JOIN @SiteLocation AS l
							ON (wl.Location_Id = l.LocationId)
							AND (ws.Weightometer_Sample_Date BETWEEN l.IncludeStart AND l.IncludeEnd)
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
			INNER JOIN dbo.GetBhpbioWeightometerLocationWithOverride(@startOfMonth, @endOfMonth) AS wl
				ON (ws.Weightometer_Id = wl.Weightometer_Id)
				AND (ws.Weightometer_Sample_Date BETWEEN wl.IncludeStart AND wl.IncludeEnd)
			INNER JOIN @SiteLocation AS l
				ON (l.LocationId = wl.Location_Id)
				AND (ws.Weightometer_Sample_Date BETWEEN l.IncludeStart AND l.IncludeEnd)
			LEFT OUTER JOIN dbo.WeightometerSampleValue AS wsv
				ON (ws.Weightometer_Sample_Id = wsv.Weightometer_Sample_Id
					AND wsv.Weightometer_Sample_Field_Id = @SampleTonnesField)
			LEFT JOIN dbo.WeightometerSampleNotes wsn
				ON (ws.Weightometer_Sample_Id = wsn.Weightometer_Sample_Id
					AND wsn.Weightometer_Sample_Field_Id = @ProductSizeFieldId)
			LEFT JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf
				ON wsn.Notes IS NULL
				AND wl.Location_Id = defaultlf.LocationId
				AND ws.Weightometer_Sample_Date BETWEEN defaultlf.StartDate AND defaultlf.EndDate
		WHERE ws.Weightometer_Sample_Date >= @startOfMonth
			AND ws.Weightometer_Sample_Date < @startOfNextMonth
			AND ISNULL(defaultlf.[Percent], 1) > 0

		-- insert main actual tonnes row for lump and fines
		INSERT INTO dbo.BhpbioSummaryEntry
		(
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			ProductSize,
			Tonnes
		)
		SELECT  @summaryId,
				@summaryEntryTypeId,
				w.SiteLocationId,
				w.MaterialTypeId,
				w.ProductSize,
				Sum(w.RealTonnes)
		FROM @Weightometer w
		WHERE w.IncludeInCTonnes = 1
		GROUP BY 
			w.SiteLocationId,
			w.MaterialTypeId,
			w.ProductSize
		HAVING SUM(w.RealTonnes) IS NOT NULL

		-- Get the valid locations to be used for the grades. 
		-- This is so locations with no valid real tonnes are not included in the calc.
		INSERT INTO @GradeLocation	(CalendarMonth, SiteLocationId)
		SELECT DISTINCT dbo.GetDateMonth(ws.Weightometer_Sample_Date), w.SiteLocationId
		FROM @Weightometer w
			INNER JOIN dbo.WeightometerSample ws ON ws.Weightometer_Sample_Id = w.WeightometerSampleId
		WHERE w.RealTonnes IS NOT NULL

		-- insert the sample tonnes values for lump and fines
		-- NOTE: this SummaryEntryType is now obsolete
		INSERT INTO dbo.BhpbioSummaryEntry
		(
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			ProductSize,
			Tonnes
		)
		SELECT  @summaryId,
				@sampleTonnesSummaryEntryTypeId,
				w.SiteLocationId,
				w.MaterialTypeId,
				w.ProductSize,
				Sum(w.SampleTonnes)
		FROM @Weightometer w
			LEFT OUTER JOIN
			(
				SELECT ws.Weightometer_Sample_Id
				FROM dbo.WeightometerSample AS ws
					INNER JOIN dbo.GetBhpbioWeightometerLocationWithOverride(@startOfMonth, @endOfMonth) AS wl
						ON (ws.Weightometer_Id = wl.Weightometer_Id)
						AND (ws.Weightometer_Sample_Date BETWEEN wl.IncludeStart AND wl.IncludeEnd)
					INNER JOIN dbo.WeightometerSampleNotes AS wsn
						ON (wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
							AND wsn.Weightometer_Sample_Field_Id = @SampleSourceField)
					INNER JOIN dbo.GetBhpbioWeightometerSampleSourceActualC(@iSummaryLocationId, @startOfMonth, @startOfNextMonth, 0) AS ss
						ON (dbo.GetDateMonth(ws.Weightometer_Sample_Date) = ss.MonthPeriod
							AND ws.Weightometer_Id = ss.Weightometer_Id
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
			w.MaterialTypeId,
			w.ProductSize
		HAVING SUM(w.SampleTonnes) IS NOT NULL
		
		-- insert total rows (lump + fines rollup)
		INSERT INTO dbo.BhpbioSummaryEntry
		(
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			ProductSize,
			Tonnes
		)
		SELECT  bse.SummaryId,
				bse.SummaryEntryTypeId,
				bse.LocationId,
				bse.MaterialTypeId,
				'TOTAL' As ProductSize,
				Sum(bse.Tonnes) As Tonnes
		FROM BhpbioSummaryEntry bse
		INNER JOIN @SiteLocation sl
			ON sl.LocationId = bse.LocationId
		WHERE bse.SummaryId = @summaryId
		AND (SummaryEntryTypeId = @summaryEntryTypeId OR SummaryEntryTypeId = @sampleTonnesSummaryEntryTypeId)
		GROUP BY 
			bse.SummaryId,
			bse.SummaryEntryTypeId,
			bse.LocationId,
			bse.MaterialTypeId
			
		-- insert grade values into an interim table... this is to support weighting back-calculated grades together by sample tonnes first... before aggregating with other data using real tonnes
		INSERT INTO @interimGrade
		(
			SummaryEntryId,
			WeightometerId,
			GradeId,
			GradeValue,
			RealTonnes,
			ShouldWeightBySampleTonnes
		)
		SELECT	bse.SummaryEntryId,
				CASE WHEN sSource.ShouldWeightBySampleTonnes = 1 THEN w.WeightometerId ELSE NULL END,
				wsg.Grade_Id,
				CASE WHEN sSource.ShouldWeightBySampleTonnes = 1 THEN
					SUM(w.SampleTonnes * wsg.Grade_Value) / 
					CASE 
						WHEN SUM(w.SampleTonnes) > 0 THEN SUM(w.SampleTonnes)
						ELSE SUM(w.RealTonnes)
					END
				ELSE
					SUM(w.RealTonnes * wsg.Grade_Value) / SUM(w.RealTonnes)
				END,
				 SUM(w.RealTonnes),
				IsNull(sSource.ShouldWeightBySampleTonnes,0)
		FROM @Weightometer AS w
			INNER JOIN dbo.BhpbioSummaryEntry bse
				ON bse.LocationId = w.SiteLocationId
				AND bse.MaterialTypeId = w.MaterialTypeId
				AND (w.ProductSize = bse.ProductSize OR bse.ProductSize = 'TOTAL')
				AND bse.SummaryId = @summaryId
				AND bse.SummaryEntryTypeId = @summaryEntryTypeId
			-- check the membership with the Sample Source
			LEFT OUTER JOIN
			(
				SELECT ws.Weightometer_Sample_Id, ss.ShouldWeightBySampleTonnes
				FROM dbo.WeightometerSample AS ws
					INNER JOIN dbo.GetBhpbioWeightometerLocationWithOverride(@startOfMonth, @endOfMonth) AS wl
						ON (ws.Weightometer_Id = wl.Weightometer_Id)
						AND (ws.Weightometer_Sample_Date BETWEEN wl.IncludeStart AND wl.IncludeEnd)
					INNER JOIN dbo.WeightometerSampleNotes AS wsn
						ON (wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
							AND wsn.Weightometer_Sample_Field_Id = @SampleSourceField)
					INNER JOIN dbo.GetBhpbioWeightometerSampleSourceActualC(@iSummaryLocationId, @startOfMonth, @startOfNextMonth, 0) AS ss
						ON (dbo.GetDateMonth(ws.Weightometer_Sample_Date) = ss.MonthPeriod
							AND wl.Weightometer_Id = ss.Weightometer_Id
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
				wsg.Grade_Value Is Not Null AND ((sSource.ShouldWeightBySampleTonnes = 1 AND w.SampleTonnes > 0 ) OR (IsNull(sSource.ShouldWeightBySampleTonnes,0) = 0 AND w.RealTonnes > 0))
				AND
				-- only include if:
				-- 1. the Material Type is Bene Feed and there is no Sample Source
				-- 2. the Material Type is High Grade and there is a matching SampleSource
				CASE
					WHEN (w.MaterialTypeId = @BeneFeedMaterialTypeId) AND (sSource.Weightometer_Sample_Id IS NULL) THEN 1
					WHEN (w.MaterialTypeId = @HighGradeMaterialTypeId) AND (sSource.Weightometer_Sample_Id IS NOT NULL) THEN 1
					ELSE 0
				END = 1
		GROUP BY bse.SummaryEntryId, CASE WHEN sSource.ShouldWeightBySampleTonnes = 1 THEN w.WeightometerId ELSE NULL END, wsg.Grade_Id, sSource.ShouldWeightBySampleTonnes

		-- insert the actual grades weighted by real tonnes
		INSERT INTO dbo.BhpbioSummaryEntryGrade
		(
			SummaryEntryId,
			GradeId,
			GradeValue
		)
		SELECT SummaryEntryId, GradeId, SUM(GradeValue * RealTonnes)/SUM(RealTonnes)
		FROM @interimGrade
		GROUP BY SummaryEntryId, GradeId
		HAVING SUM(RealTonnes)> 0
				
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
-- Permissions

GRANT EXECUTE ON  [dbo].[SummariseBhpbioActualC] TO [BhpbioGenericManager]
GO

/*
exec dbo.SummariseBhpbioActualC
	@iSummaryMonth = '2013-01-01',
	@iSummaryLocationId = 8
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
