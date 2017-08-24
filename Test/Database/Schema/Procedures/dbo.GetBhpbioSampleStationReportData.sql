IF OBJECT_ID('dbo.GetBhpbioSampleStationReportData') IS NOT NULL
	DROP PROCEDURE dbo.GetBhpbioSampleStationReportData
GO
 
CREATE PROCEDURE dbo.GetBhpbioSampleStationReportData
(
	@iLocationId INT,
	@iStartDate DATETIME,
	@iEndDate DATETIME,
	@iDateBreakdown VARCHAR(30)
)
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioSampleStationReportData',
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
		DECLARE @StockpileGroupId VARCHAR(31)
		DECLARE @HighGradeMaterialTypeId INT
		DECLARE @BeneFeedMaterialTypeId INT
		DECLARE @SampleTonnesField VARCHAR(31)
		DECLARE @SampleSourceField VARCHAR(31)
		DECLARE @ProductSizeField VARCHAR(31)
		DECLARE @SampleCountField VARCHAR(31)

		SET @SampleTonnesField = 'SampleTonnes'
		SET @SampleSourceField = 'SampleSource'
		SET @ProductSizeField = 'ProductSize'
		SET @SampleCountField = 'SampleCount'

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

		DECLARE @Weightometer TABLE
		(
			CalendarDate DATETIME NOT NULL,
			WeightometerSampleId INT NOT NULL,
			DateFrom DATETIME NOT NULL,
			DateTo DATETIME NOT NULL,
			ParentLocationId INT NULL,
			RealTonnes FLOAT NOT NULL,
			SampleTonnes FLOAT NOT NULL,
			DesignationMaterialTypeId INT NOT NULL,
			ProductSize VARCHAR(5) NOT NULL,
			DefaultProductSize BIT NOT NULL,
			SampleCount INT NULL,
			PRIMARY KEY (WeightometerSampleId, ProductSize)
		)

		-- retrieve the list of Weightometer Records to be used in the calculations
		INSERT INTO @Weightometer
			(CalendarDate, DateFrom, DateTo, WeightometerSampleId, ParentLocationId, ProductSize, DefaultProductSize, RealTonnes, SampleTonnes, DesignationMaterialTypeId, SampleCount)
		SELECT b.CalendarDate, b.DateFrom, b.DateTo, w.WeightometerSampleId, l.LocationId, ISNULL(wsn.Notes, defaultlf.ProductSize) As ProductSize,
			CASE WHEN wsn.Notes IS NULL THEN 1 ELSE 0 END As DefaultProductSize,
			-- calculate the REAL tonnes
			CASE
				WHEN w.UseAsRealTonnes = 1 
					THEN ISNULL(ISNULL(defaultlf.[Percent], 1) * ws.Corrected_Tonnes, ISNULL(defaultlf.[Percent], 1) * ws.Tonnes)
				ELSE 0.0
			END AS RealTonnes,
			-- calculate the SAMPLE tonnes
			-- if a sample tonnes hasn't been provided then use the actual tonnes recorded for the transaction
			-- not all flows will have this recorded (in particular CVF corrected plant balanced records)
			CASE w.BeneFeed
				WHEN 1 THEN ISNULL(ISNULL(defaultlf.[Percent], 1) * ws.Corrected_Tonnes, ISNULL(defaultlf.[Percent], 1) * ws.Tonnes)
				ELSE ISNULL(ISNULL(defaultlf.[Percent], 1) * wsv.Field_Value, 0.0)
			END AS SampleTonnes,
			-- return the Material Type based on whether it is bene feed
			CASE w.BeneFeed
				WHEN 1 THEN @BeneFeedMaterialTypeId
				WHEN 0 THEN @HighGradeMaterialTypeId
			END AS MaterialTypeId,
			wsv2.Field_Value
		FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iStartDate, @iEndDate, 1) AS b
		INNER JOIN dbo.WeightometerSample AS ws
			ON (ws.Weightometer_Sample_Date BETWEEN b.DateFrom AND b.DateTo)
		INNER JOIN
			(
				-- collect the weightometer sample id's for all movements from the crusher
				-- these are used to ease lookup and ensure uniqueness of the weightometer_sample_ids returned
				SELECT DISTINCT dttf.Weightometer_Sample_Id AS WeightometerSampleId, 1 AS UseAsRealTonnes,
					CASE
						WHEN m.Mill_Id IS NOT NULL
							THEN 1
						ELSE 0
					END AS BeneFeed
				FROM dbo.DataTransactionTonnes AS dtt
					INNER JOIN dbo.DataTransactionTonnesFlow AS dttf
						ON (dttf.Data_Transaction_Tonnes_Id = dtt.Data_Transaction_Tonnes_Id)
					INNER JOIN dbo.GetBhpbioCrusherLocationWithOverride(@iStartDate, @iEndDate) AS cl
						ON (dttf.Source_Crusher_Id = cl.Crusher_Id)
						AND (dtt.Data_Transaction_Tonnes_Date BETWEEN cl.IncludeStart AND cl.IncludeEnd)
					LEFT JOIN dbo.Mill AS m
						ON (dttf.Destination_Stockpile_Id = m.Stockpile_Id)
					INNER JOIN dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 0, 'SITE', @iStartDate, @iEndDate) AS l
						ON (cl.Location_Id = l.LocationId
						AND dtt.Data_Transaction_Tonnes_Date BETWEEN l.IncludeStart AND l.IncludeEnd)
					LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('ActualC') xs
						ON xs.StockpileId = dttf.Source_Stockpile_Id
						OR xs.StockpileId = dttf.Destination_Stockpile_Id
				WHERE dtt.Data_Transaction_Tonnes_Date BETWEEN @iStartDate AND @iEndDate
					AND dttf.Destination_Crusher_Id IS NULL  -- ignore crusher to crusher feeds
					AND xs.StockpileId IS NULL -- No movements to or from excluded groups.
				GROUP BY dttf.Weightometer_Sample_Id, m.Mill_Id
				UNION 
				-- collect weightometer sample id's for all movements to train rakes
				-- (by definition it's always delivers to train rake stockpiles...
				--  the grades (but not the tonnes) from these weightometers samples are important to us)
				SELECT DISTINCT dttf.Weightometer_Sample_Id, 0, 0
				FROM dbo.DataTransactionTonnes AS dtt
					INNER JOIN dbo.DataTransactionTonnesFlow AS dttf
						ON (dttf.Data_Transaction_Tonnes_Id = dtt.Data_Transaction_Tonnes_Id)
					INNER JOIN dbo.WeightometerSample AS ws
						ON (dttf.Weightometer_Sample_Id = ws.Weightometer_Sample_Id)
					INNER JOIN dbo.StockpileGroupStockpile AS sgs
						ON (sgs.Stockpile_Id = dttf.Destination_Stockpile_Id)
					INNER JOIN dbo.GetBhpbioWeightometerLocationWithOverride(@iStartDate, @iEndDate) AS wl
						ON (ws.Weightometer_Id = wl.Weightometer_Id)
									AND (ws.Weightometer_Sample_Date BETWEEN wl.IncludeStart and wl.IncludeEnd)
					INNER JOIN dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 0, 'SITE', @iStartDate, @iEndDate) AS l
						ON (wl.Location_Id = l.LocationId
						AND dtt.Data_Transaction_Tonnes_Date BETWEEN l.IncludeStart AND l.IncludeEnd)
					LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('ActualC') xs
						ON xs.StockpileId = dttf.Source_Stockpile_Id
						OR xs.StockpileId = dttf.Destination_Stockpile_Id
				WHERE dtt.Data_Transaction_Tonnes_Date BETWEEN @iStartDate AND @iEndDate
					AND sgs.Stockpile_Group_Id = 'Port Train Rake'
					AND xs.StockpileId IS NULL -- No movements to or from excluded groups.
				GROUP BY dttf.Weightometer_Sample_Id
			  ) AS w
			ON (ws.Weightometer_Sample_Id = w.WeightometerSampleId)
			-- ensure the weightometer belongs to the required location
		INNER JOIN dbo.GetBhpbioWeightometerLocationWithOverride(@iStartDate, @iEndDate) AS wl
			ON (ws.Weightometer_Id = wl.Weightometer_Id)
						AND (ws.Weightometer_Sample_Date BETWEEN wl.IncludeStart AND wl.IncludeEnd)
		INNER JOIN dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 0, 'SITE', @iStartDate, @iEndDate) AS l
			ON (l.LocationId = wl.Location_Id
			AND ws.Weightometer_Sample_Date BETWEEN l.IncludeStart AND l.IncludeEnd)
		LEFT OUTER JOIN dbo.WeightometerSampleValue AS wsv
			ON (ws.Weightometer_Sample_Id = wsv.Weightometer_Sample_Id
			AND wsv.Weightometer_Sample_Field_Id = @SampleTonnesField)
		LEFT JOIN dbo.WeightometerSampleNotes wsn
			ON (ws.Weightometer_Sample_Id = wsn.Weightometer_Sample_Id
			AND wsn.Weightometer_Sample_Field_Id = @ProductSizeField)
		LEFT JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf
			ON wsn.Notes IS NULL
			AND wl.Location_Id = defaultlf.LocationId
			AND ws.Weightometer_Sample_Date BETWEEN defaultlf.StartDate AND defaultlf.EndDate
		LEFT JOIN dbo.WeightometerSampleValue wsv2
			ON ws.Weightometer_Sample_Id = wsv2.Weightometer_Sample_Id
			AND wsv2.Weightometer_Sample_Field_Id = @SampleCountField

		SELECT W.DateFrom, W.DateTo, W.ParentLocationId AS LocationId, COALESCE(SS.Name, WS.Weightometer_Id) AS SampleStation, 
			ROUND(SUM(W.SampleTonnes),2,0) AS Assayed, ABS(ROUND(SUM(W.RealTonnes - W.SampleTonnes),2,0)) AS [Unassayed], 
			0 AS Grade_Id, 'Tonnes' As Grade_Name, 100 As Grade_Value, SUM(NULLIF(W.SampleCount, 0)) AS Sample_Count
		FROM @Weightometer W
		INNER JOIN WeightometerSample WS
			ON WS.Weightometer_Sample_Id = W.WeightometerSampleId
		INNER JOIN BhpbioSampleStation SS -- Inner join because we only want Sample Station results.
			ON SS.Weightometer_Id = WS.Weightometer_Id AND SS.ProductSize = W.ProductSize
		GROUP BY W.DateFrom, W.DateTo, W.ParentLocationId, SS.Name, WS.Weightometer_Id

		UNION

		SELECT W.DateFrom, W.DateTo, W.ParentLocationId AS LocationId, COALESCE(SS.Name, WS.Weightometer_Id) AS SampleStation, 
			ROUND(SUM(W.SampleTonnes),2,0) AS Assayed, ROUND(SUM(W.RealTonnes - W.SampleTonnes),2,0) AS [Unassayed], 
			WSG.Grade_Id, G.Grade_Name, SUM(W.SampleTonnes * WSG.Grade_Value) / NULLIF(SUM(W.SampleTonnes), 1.0) As Grade_Value, 
			SUM(NULLIF(W.SampleCount, 0)) AS Sample_Count
		FROM @Weightometer W
		INNER JOIN WeightometerSample WS
			ON WS.Weightometer_Sample_Id = W.WeightometerSampleId
		INNER JOIN BhpbioSampleStation SS -- Inner join because we only want Sample Station results.
			ON SS.Weightometer_Id = WS.Weightometer_Id AND SS.ProductSize = W.ProductSize
		INNER JOIN WeightometerSampleGrade WSG
			ON WSG.Weightometer_Sample_Id = WS.Weightometer_Sample_Id
		INNER JOIN Grade G
			ON G.Grade_Id = WSG.Grade_Id
		GROUP BY W.DateFrom, W.DateTo, W.ParentLocationId, SS.Name, WS.Weightometer_Id, G.Grade_Name, WSG.Grade_Id

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

GRANT EXECUTE ON dbo.GetBhpbioSampleStationReportData TO CoreReporting
GRANT EXECUTE ON dbo.GetBhpbioSampleStationReportData TO BhpbioGenericManager
GO