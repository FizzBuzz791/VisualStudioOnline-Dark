IF OBJECT_ID('dbo.GetBhpbioReportDataSitePostCrusherStockpileDelta') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportDataSitePostCrusherStockpileDelta 
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReportDataSitePostCrusherStockpileDelta
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iChildLocations BIT,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @OutputTonnes TABLE
	(
		CalendarDate DATETIME,
		DateFrom DATETIME,
		DateTo DATETIME,
		LocationId INTEGER,
		ProductSize VARCHAR(5),
		Tonnes FLOAT
	)
	
	DECLARE @OutputGrades TABLE
	(
		CalendarDate DATETIME,
		LocationId INTEGER,
		GradeId INTEGER,
		GradeValue FLOAT,
		ProductSize VARCHAR(5),
		Tonnes FLOAT
	)
	
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		ParentLocationId INT NULL,
		IncludeStart DATETIME,
		IncludeEnd DATETIME,
		PRIMARY KEY (LocationId, IncludeStart, IncludeEnd)
	)

	DECLARE @StockpileDelta TABLE
	(
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		StockpileId INT NOT NULL,
		WeightometerSampleId INT NOT NULL,
		ProductSize VARCHAR(5) NOT NULL,
		Tonnes FLOAT NOT NULL,
		LocationId INT NULL,
		Addition BIT NOT NULL,
		PRIMARY KEY (CalendarDate, StockpileId, WeightometerSampleId, Addition, ProductSize)
	)
	
	DECLARE @StockpileGroupId VARCHAR(31)
	DECLARE @LastShift CHAR(1)
	DECLARE @HubLocationTypeId INT
	DECLARE @SiteLocationTypeId INT
	DECLARE @ProductSizeField VARCHAR(31)

	SET @ProductSizeField = 'ProductSize'
	SET @StockpileGroupId = 'Post Crusher'
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioReportDataSitePostCrusherStockpileDelta',
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
	
	
		SELECT @HubLocationTypeId = Location_Type_Id
		FROM dbo.LocationType
		WHERE Description = 'Hub'
		SELECT @SiteLocationTypeId = Location_Type_Id
		FROM dbo.LocationType
		WHERE Description = 'Site'
		
		INSERT INTO @Location
			(LocationId, ParentLocationId, IncludeStart, IncludeEnd)
		SELECT LocationId, ParentLocationId, IncludeStart, IncludeEnd
		FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, @iChildLocations, 'PIT', @iDateFrom, @iDateTo)

		IF @iIncludeLiveData = 1
		BEGIN
			-- Get Removals
			INSERT INTO @StockpileDelta
				(CalendarDate, DateFrom, DateTo, StockpileId, WeightometerSampleId, Addition, ProductSize, Tonnes, LocationId)		
			SELECT DISTINCT CalendarDate, DateFrom, DateTo, S.Stockpile_Id, WS.Weightometer_Sample_Id, 0, 
				ISNULL(wsn.Notes, defaultlf.ProductSize), 
				ISNULL(defaultlf.[Percent], 1) * ws.Tonnes,
				L.ParentLocationId
			FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
				INNER JOIN dbo.WeightometerSample AS WS
					ON (WS.Weightometer_Sample_Date BETWEEN B.DateFrom AND B.DateTo)
				INNER JOIN dbo.Stockpile AS S
					ON (S.Stockpile_Id = WS.Source_Stockpile_Id)
				-- source stockpile group is post-crusher
				INNER JOIN dbo.StockpileGroupStockpile AS SGS
					ON (SGS.Stockpile_Id = S.Stockpile_Id
					AND SGS.Stockpile_Group_Id = @StockpileGroupId)
				INNER JOIN dbo.BhpbioStockpileLocationDate AS SL
					ON SL.Stockpile_Id = S.Stockpile_Id
					AND	WS.Weightometer_Sample_Date BETWEEN SL.[Start_Date] AND SL.End_Date
				INNER JOIN @Location AS L
					ON (L.LocationId = SL.Location_Id)
					AND WS.Weightometer_Sample_Date BETWEEN L.IncludeStart AND L.IncludeEnd
				LEFT JOIN dbo.BhpbioLocationStockpileConfiguration AS BSLC
					ON (BSLC.LocationId = SL.Location_Id)
				INNER JOIN dbo.BhpbioLocationDate AS LL
					ON (LL.Location_Id = L.LocationId 
						AND ws.Weightometer_Sample_Date BETWEEN LL.Start_Date and LL.End_Date)
				LEFT JOIN dbo.StockpileGroupStockpile SGS_D
					ON (SGS_D.Stockpile_Id = WS.Destination_Stockpile_Id
						AND SGS_D.Stockpile_Group_Id = @StockpileGroupId)
				LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('PostCrusher') xs
					ON xs.StockpileId = WS.Source_Stockpile_Id
					OR xs.StockpileId = WS.Destination_Stockpile_Id
				LEFT JOIN dbo.WeightometerSampleNotes wsn
					ON (ws.Weightometer_Sample_Id = wsn.Weightometer_Sample_Id
						AND wsn.Weightometer_Sample_Field_Id = @ProductSizeField)
				LEFT JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf
					ON wsn.Notes IS NULL
					AND l.LocationId = defaultlf.LocationId
					AND ws.Weightometer_Sample_Date BETWEEN defaultlf.StartDate AND defaultlf.EndDate					
				LEFT JOIN dbo.BhpbioApprovalData bad
					ON bad.LocationId = LL.Parent_Location_Id
					AND bad.TagId = 'F25PostCrusherStockpileDelta'
					AND bad.ApprovedMonth = dbo.GetDateMonth(WS.Weightometer_Sample_Date)
			WHERE Coalesce(WS.Source_Stockpile_Id, -1) <> Coalesce(WS.Destination_Stockpile_Id, -1)
							AND SGS_D.Stockpile_Group_Id IS NULL -- Ensure join to check if destination is Post Crusher isn't true.
				AND (LL.Location_Type_Id = @SiteLocationTypeId AND
				(BSLC.PromoteStockpiles = 0 OR BSLC.PromoteStockpiles IS NULL))
				AND WS.Weightometer_Id NOT LIKE '%Raw%'
				AND (@iIncludeApprovedData = 0 OR bad.TagId IS NULL)
				AND xs.StockpileId IS NULL -- No movements to or from excluded groups.
				AND	(ISNULL(defaultlf.[Percent], 1) > 0)

			-- Get Additions
			INSERT INTO @StockpileDelta
				(CalendarDate, DateFrom, DateTo, StockpileId, WeightometerSampleId, Addition, ProductSize, Tonnes, LocationId)		
			SELECT DISTINCT CalendarDate, DateFrom, DateTo, S.Stockpile_Id, WS.Weightometer_Sample_ID, 1, 
				ISNULL(wsn.Notes, defaultlf.ProductSize), 
				ISNULL(defaultlf.[Percent], 1) * ws.Tonnes,
				L.ParentLocationId
			FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
				INNER JOIN dbo.WeightometerSample AS WS
					ON (WS.Weightometer_Sample_Date BETWEEN B.DateFrom AND B.DateTo)
				INNER JOIN dbo.Stockpile AS S
					ON (S.Stockpile_Id = WS.Destination_Stockpile_Id)
				INNER JOIN dbo.StockpileGroupStockpile AS SGS
					ON (SGS.Stockpile_Id = S.Stockpile_Id
					AND SGS.Stockpile_Group_Id = @StockpileGroupId)
				INNER JOIN dbo.BhpbioStockpileLocationDate AS SL
					ON SL.Stockpile_Id = S.Stockpile_Id
					AND	WS.Weightometer_Sample_Date BETWEEN SL.[Start_Date] AND SL.End_Date
				INNER JOIN @Location AS L
					ON (L.LocationId = SL.Location_Id)
					AND WS.Weightometer_Sample_Date BETWEEN L.IncludeStart AND L.IncludeEnd
				LEFT JOIN dbo.BhpbioLocationStockpileConfiguration AS BSLC
					ON (BSLC.LocationId = SL.Location_Id)
				INNER JOIN dbo.BhpbioLocationDate AS LL
					ON (LL.Location_Id = L.LocationId
						AND WS.Weightometer_Sample_Date BETWEEN LL.Start_Date and LL.End_Date)
				LEFT JOIN dbo.StockpileGroupStockpile SGS_S
					ON (SGS_S.Stockpile_Id = WS.Source_Stockpile_Id
						AND SGS_S.Stockpile_Group_Id = @StockpileGroupId)
				LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('PostCrusher') xs
					ON xs.StockpileId = WS.Source_Stockpile_Id
					OR xs.StockpileId = WS.Destination_Stockpile_Id
				LEFT JOIN dbo.WeightometerSampleNotes wsn
					ON (ws.Weightometer_Sample_Id = wsn.Weightometer_Sample_Id
						AND wsn.Weightometer_Sample_Field_Id = @ProductSizeField)
				LEFT JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf
					ON wsn.Notes IS NULL
					AND l.LocationId = defaultlf.LocationId
					AND ws.Weightometer_Sample_Date BETWEEN defaultlf.StartDate AND defaultlf.EndDate					
				-- this join is used to test whether there is an approval associated with this data
				LEFT JOIN dbo.BhpbioApprovalData bad
					ON bad.LocationId = LL.Parent_Location_Id
					AND bad.TagId = 'F25PostCrusherStockpileDelta'
					AND bad.ApprovedMonth = dbo.GetDateMonth(WS.Weightometer_Sample_Date)
			WHERE Coalesce(WS.Source_Stockpile_Id, -1) <> Coalesce(WS.Destination_Stockpile_Id, -1)
				AND SGS_S.Stockpile_Group_Id IS NULL  -- Ensure join to check if source is Post Crusher isn't true.
				AND (LL.Location_Type_Id = @SiteLocationTypeId AND
				(BSLC.PromoteStockpiles = 0 OR BSLC.PromoteStockpiles IS NULL))
				AND WS.Weightometer_Id NOT LIKE '%Raw%'
				AND (@iIncludeApprovedData = 0 OR bad.TagId IS NULL)
				AND xs.StockpileId IS NULL -- No movements to or from excluded groups.
				AND	(ISNULL(defaultlf.[Percent], 1) > 0)

			-- Obtain the Delta tonnes
			INSERT INTO @OutputTonnes
			(
				CalendarDate,
				DateFrom,
				DateTo,
				LocationId,
				ProductSize,
				Tonnes
			)
			-- for separate lump and fines
			SELECT SD.CalendarDate, SD.DateFrom, SD.DateTo, SD.LocationId AS ParentLocationId, SD.ProductSize,
				Sum(CASE WHEN SD.Addition = 1 THEN SD.Tonnes ELSE -SD.Tonnes END) AS Tonnes
			FROM @StockpileDelta AS SD
			GROUP BY SD.CalendarDate, SD.DateFrom, SD.DateTo, SD.LocationId, SD.ProductSize
			UNION ALL
			-- for rolled up total
			SELECT SD.CalendarDate, SD.DateFrom, SD.DateTo, SD.LocationId AS ParentLocationId, 'TOTAL',
				Sum(CASE WHEN SD.Addition = 1 THEN SD.Tonnes ELSE -SD.Tonnes END) AS Tonnes
			FROM @StockpileDelta AS SD
			GROUP BY SD.CalendarDate, SD.DateFrom, SD.DateTo, SD.LocationId

			INSERT INTO @OutputGrades
			(
				CalendarDate,
				LocationId,
				GradeId,
				GradeValue,
				ProductSize,
				Tonnes
			)
			-- obtain the Delta Grades for separate lump and fines
			SELECT SD.CalendarDate, SD.LocationId, WSG.Grade_Id,
				Sum(SD.Tonnes * WSG.Grade_Value) / NULLIF(Sum(SD.Tonnes), 0), SD.ProductSize,
				Sum(SD.Tonnes)
			FROM @StockpileDelta AS SD
				INNER JOIN dbo.WeightometerSample AS WS
					ON (WS.Weightometer_Sample_Id = SD.WeightometerSampleId)
				INNER JOIN dbo.WeightometerSampleGrade AS WSG
					ON (WSG.Weightometer_Sample_Id = WS.Weightometer_Sample_Id)
			GROUP BY SD.CalendarDate, WSG.Grade_Id, SD.LocationId, SD.ProductSize
			UNION ALL			
			-- obtain the Delta Grades roll up
			SELECT SD.CalendarDate, SD.LocationId, WSG.Grade_Id,
				Sum(SD.Tonnes * WSG.Grade_Value) / NULLIF(Sum(SD.Tonnes), 0), 'TOTAL',
				Sum(SD.Tonnes)
			FROM @StockpileDelta AS SD
				INNER JOIN dbo.WeightometerSample AS WS
					ON (WS.Weightometer_Sample_Id = SD.WeightometerSampleId)
				INNER JOIN dbo.WeightometerSampleGrade AS WSG
					ON (WSG.Weightometer_Sample_Id = WS.Weightometer_Sample_Id)
			GROUP BY SD.CalendarDate, WSG.Grade_Id, SD.LocationId
			
		END
		
		IF @iIncludeApprovedData = 1
		BEGIN
			DECLARE @summaryEntryType VARCHAR(31)
			SET @summaryEntryType = 'SitePostCrusherStockpileDelta'
			
			DECLARE @summaryEntryGradeType VARCHAR(31)
			SET @summaryEntryGradeType = 'SitePostCrusherSpDeltaGrades'
			
			-- Retrieve Tonnes
			INSERT INTO @OutputTonnes
				(CalendarDate, DateFrom, DateTo, LocationId, ProductSize, Tonnes)
			SELECT s.CalendarDate, s.DateFrom, s.DateTo, l.ParentLocationId, s.ProductSize, s.Tonnes
			FROM dbo.GetBhpbioSummaryTonnesBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryType, 1) s
				INNER JOIN @Location l
					ON l.LocationId = s.LocationId
					AND s.CalendarDate BETWEEN l.IncludeStart AND l.IncludeEnd
					
			-- Retrieve Grades
			INSERT INTO @OutputGrades
			(
				CalendarDate,
				LocationId,
				GradeId,
				GradeValue,
				ProductSize,
				Tonnes
			)
			SELECT s.CalendarDate, l.ParentLocationId, s.GradeId,  s.GradeValue, s.ProductSize, s.Tonnes
			FROM dbo.GetBhpbioSummaryGradeBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryGradeType, 1, 1, 0) s
				INNER JOIN @Location l
					ON l.LocationId = s.LocationId
					AND s.CalendarDate BETWEEN l.IncludeStart AND l.IncludeEnd
		END
		
		-- Output the tonnes
		SELECT o.CalendarDate, o.DateFrom, o.DateTo, NULL AS MaterialTypeId, o.LocationId AS ParentLocationId,
			Sum(o.Tonnes) AS Tonnes, o.ProductSize
		FROM @OutputTonnes o
		GROUP BY o.CalendarDate, o.DateFrom, o.DateTo, o.LocationId, o.ProductSize

		-- Output the grades
		SELECT o.CalendarDate, G.Grade_Name As GradeName, NULL AS MaterialTypeId, o.LocationId AS ParentLocationId,
			Sum(ABS(o.Tonnes) * o.GradeValue) / NULLIF(Sum(ABS(o.Tonnes)), 0) AS GradeValue, o.ProductSize
		FROM @OutputGrades AS o
			INNER JOIN dbo.Grade AS G
				ON (G.Grade_Id = o.GradeId)
		GROUP BY o.CalendarDate, G.Grade_Name, o.LocationId, o.ProductSize
		
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

GRANT EXECUTE ON dbo.GetBhpbioReportDataSitePostCrusherStockpileDelta TO BhpbioGenericManager
GO
