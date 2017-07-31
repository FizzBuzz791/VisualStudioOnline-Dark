﻿IF OBJECT_ID('dbo.GetBhpbioReportDataHubPostCrusherStockpileDelta') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportDataHubPostCrusherStockpileDelta
GO

CREATE PROCEDURE dbo.GetBhpbioReportDataHubPostCrusherStockpileDelta
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
		ProductSize VARCHAR(5) NULL,
		Tonnes FLOAT
	)
	
	DECLARE @OutputGrades TABLE
	(
		CalendarDate DATETIME,
		LocationId INTEGER,
		GradeId INTEGER,
		GradeValue FLOAT,
		ProductSize VARCHAR(5) NULL,
		Tonnes FLOAT
	)
	
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		ParentLocationId INT NULL,
		IncludeStart DATETIME, 
		IncludeEnd DATETIME,
		PRIMARY KEY (LocationId, Includestart, IncludeEnd)
	)

	DECLARE @StockpileDelta TABLE
	(
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		StockpileId INT NOT NULL,
		WeightometerId VARCHAR(31),
		WeightometerSampleId INT NOT NULL,
		WeightometerSampleDate DateTime NOT NULL,
		ProductSize VARCHAR(5) NOT NULL,
		ProductPercent DECIMAL(5,4) NOT NULL,
		Tonnes FLOAT NOT NULL,
		LocationId INT NULL,
		Addition BIT NOT NULL,
		ChildLocationId INT NULL,
		PRIMARY KEY (CalendarDate, StockpileId, WeightometerSampleId, Addition, ProductSize)
	)
	
	DECLARE @InterimGradesByLocationAndProductSize TABLE
	(
		CalendarDate DATETIME,
		GradeId INTEGER,
		WeightometerId VARCHAR(31),
		LocationId INTEGER,
		ChildLocationId FLOAT,
		ProductSize VARCHAR(5) NULL,
		GradeValue FLOAT,
		ShouldWeightBySampleTonnes BIT
	)
	
	DECLARE @GradeLocation TABLE
	(
		CalendarDate DATETIME NOT NULL,
		ActualLocationId INT NULL
	)
	
	DECLARE @StockpileGroupId VARCHAR(31)
	SET @StockpileGroupId = 'Post Crusher'
	DECLARE @LastShift CHAR(1)
	DECLARE @HubLocationTypeId INT
	DECLARE @SiteLocationTypeId INT
	DECLARE @SampleSourceField VARCHAR(31)
	DECLARE @SampleTonnesField VARCHAR(31)
	DECLARE @ProductSizeField VARCHAR(31)

	SET @ProductSizeField = 'ProductSize'
	SET @SampleSourceField = 'SampleSource'
	SET @SampleTonnesField = 'SampleTonnes'
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioReportDataHubPostCrusherStockpileDelta',
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
		INSERT INTO @Location
			(LocationId, ParentLocationId, IncludeStart, IncludeEnd)
		SELECT LocationId, ParentLocationId, IncludeStart, IncludeEnd
		FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, @iChildLocations, 'Site', @iDateFrom, @iDateTo)

		IF @iIncludeLiveData = 1
		BEGIN

			SELECT @HubLocationTypeId = Location_Type_Id
			FROM dbo.LocationType WITH (NOLOCK) 
			WHERE Description = 'Hub'
			SELECT @SiteLocationTypeId = Location_Type_Id
			FROM dbo.LocationType WITH (NOLOCK) 
			WHERE Description = 'Site'

			-- Get Removals
			INSERT INTO @StockpileDelta
				(CalendarDate, DateFrom, DateTo, WeightometerId,StockpileId, WeightometerSampleId, WeightometerSampleDate, 
				Addition, ProductSize, ProductPercent, Tonnes, LocationId, ChildLocationId)		
			SELECT DISTINCT CalendarDate, DateFrom, DateTo, WS.Weightometer_Id, S.Stockpile_Id, WS.Weightometer_Sample_Id, 
				WS.Weightometer_Sample_Date, 0,
				ISNULL(wsn.Notes, defaultlf.ProductSize), 
				ISNULL(defaultlf.[Percent], 1),
				ISNULL(defaultlf.[Percent], 1) * ws.Tonnes,
				L.ParentLocationId, L.LocationId
			FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
				INNER JOIN dbo.WeightometerSample AS WS WITH (NOLOCK) 
					ON (WS.Weightometer_Sample_Date BETWEEN B.DateFrom AND B.DateTo)
				INNER JOIN dbo.Stockpile AS S WITH (NOLOCK)
					ON (S.Stockpile_Id = WS.Source_Stockpile_Id)
				INNER JOIN dbo.StockpileGroupStockpile AS SGS WITH (NOLOCK)
					ON (SGS.Stockpile_Id = S.Stockpile_Id)
				INNER JOIN dbo.BhpbioStockpileLocationDate AS SL WITH (NOLOCK) 
					ON (SL.Stockpile_Id = S.Stockpile_Id)
					AND	(sl.[Start_Date] BETWEEN @iDateFrom AND @iDateTo
						OR sl.End_Date BETWEEN @iDateFrom AND @iDateTo
						OR (sl.[Start_Date] < @iDateFrom AND sl.End_Date >@iDateTo))
				INNER JOIN @Location AS L
					ON (L.LocationId = SL.Location_Id
						AND WS.Weightometer_Sample_Date BETWEEN L.IncludeStart AND L.IncludeEnd)
				INNER JOIN dbo.BhpbioLocationDate AS LL WITH (NOLOCK)
					ON (LL.Location_Id = L.LocationId
						AND WS.Weightometer_Sample_Date BETWEEN LL.Start_Date AND LL.End_Date)
				LEFT JOIN dbo.BhpbioLocationStockpileConfiguration AS BSLC WITH (NOLOCK)
					ON (BSLC.LocationId = SL.Location_Id)
				LEFT JOIN dbo.StockpileGroupStockpile AS SGS_D WITH (NOLOCK)
					ON (SGS_D.Stockpile_Id = WS.Destination_Stockpile_Id
						AND SGS_D.Stockpile_Group_Id = @StockpileGroupId)
				LEFT JOIN dbo.WeightometerSampleNotes wsn
					ON (ws.Weightometer_Sample_Id = wsn.Weightometer_Sample_Id
						AND wsn.Weightometer_Sample_Field_Id = @ProductSizeField)
				LEFT JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf
					ON wsn.Notes IS NULL
					AND l.LocationId = defaultlf.LocationId
					AND ws.Weightometer_Sample_Date BETWEEN defaultlf.StartDate AND defaultlf.EndDate					
				LEFT JOIN dbo.BhpbioApprovalData bad
					ON bad.LocationId = CASE WHEN LL.Location_Type_Id = @HubLocationTypeId THEN LL.Location_Id ELSE LL.Parent_Location_Id END
					AND bad.TagId = 'F25PostCrusherStockpileDelta'
					AND bad.ApprovedMonth = dbo.GetDateMonth(WS.Weightometer_Sample_Date)
				LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('PostCrusher') xs
					ON xs.StockpileId = WS.Source_Stockpile_Id
					OR xs.StockpileId = WS.Destination_Stockpile_Id
			WHERE Coalesce(WS.Source_Stockpile_Id, -1) <> Coalesce(WS.Destination_Stockpile_Id, -1)
				AND SGS.Stockpile_Group_Id = @StockpileGroupId
				AND SGS_D.Stockpile_Group_Id IS NULL -- Ensure join to check if destination is Post Crusher isn't true.
				AND WS.Weightometer_Id NOT LIKE '%Raw%'
				AND (LL.Location_Type_Id = @HubLocationTypeId OR
					(BSLC.PromoteStockpiles = 1 AND LL.Location_Type_Id = @SiteLocationTypeId AND 
					(BSLC.PromoteStockpilesFromDate IS NULL OR @iDateFrom >= BSLC.PromoteStockpilesFromDate)))
				AND (@iIncludeApprovedData = 0 OR bad.TagId IS NULL)
				AND xs.StockpileId IS NULL -- No movements to or from excluded groups.
				AND	(ISNULL(defaultlf.[Percent], 1) > 0)
				
			-- Get Additions
			INSERT INTO @StockpileDelta
				(CalendarDate, DateFrom, DateTo, WeightometerId, StockpileId, WeightometerSampleId, WeightometerSampleDate, 
				Addition, ProductSize, ProductPercent, Tonnes, LocationId, ChildLocationId)		
			SELECT DISTINCT CalendarDate, DateFrom, DateTo, WS.Weightometer_Id, S.Stockpile_Id, WS.Weightometer_Sample_ID, 
				WS.Weightometer_Sample_Date, 1, 
				ISNULL(wsn.Notes, defaultlf.ProductSize), 
				ISNULL(defaultlf.[Percent], 1),
				ISNULL(defaultlf.[Percent], 1) * ws.Tonnes,
				L.ParentLocationId, L.LocationId
			FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
				INNER JOIN dbo.WeightometerSample AS WS WITH (NOLOCK)
					ON (WS.Weightometer_Sample_Date BETWEEN B.DateFrom AND B.DateTo)
				INNER JOIN dbo.Stockpile AS S WITH (NOLOCK)
					ON (S.Stockpile_Id = WS.Destination_Stockpile_Id)
				INNER JOIN dbo.StockpileGroupStockpile AS SGS WITH (NOLOCK)
					ON (SGS.Stockpile_Id = S.Stockpile_Id)
				INNER JOIN dbo.BhpbioStockpileLocationDate AS SL WITH (NOLOCK)
					ON (SL.Stockpile_Id = S.Stockpile_Id)
					AND	(sl.[Start_Date] BETWEEN @iDateFrom AND @iDateTo
						OR sl.End_Date BETWEEN @iDateFrom AND @iDateTo
						OR (sl.[Start_Date] < @iDateFrom AND sl.End_Date >@iDateTo))
				INNER JOIN @Location AS L
					ON (L.LocationId = SL.Location_Id
						AND WS.Weightometer_Sample_Date BETWEEN L.IncludeStart AND L.IncludeEnd)
				INNER JOIN dbo.BhpbioLocationDate AS LL WITH (NOLOCK)
					ON (LL.Location_Id = L.LocationId
						AND WS.Weightometer_Sample_Date BETWEEN LL.Start_Date AND LL.End_Date)
				LEFT JOIN dbo.BhpbioLocationStockpileConfiguration AS BSLC WITH (NOLOCK)
					ON (BSLC.LocationId = SL.Location_Id)
				LEFT JOIN dbo.StockpileGroupStockpile AS SGS_S WITH (NOLOCK)
					ON (SGS_S.Stockpile_Id = WS.Source_Stockpile_Id
						AND SGS_S.Stockpile_Group_Id = @StockpileGroupId)
				LEFT JOIN dbo.WeightometerSampleNotes wsn
					ON (ws.Weightometer_Sample_Id = wsn.Weightometer_Sample_Id
						AND wsn.Weightometer_Sample_Field_Id = @ProductSizeField)
				LEFT JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf
					ON wsn.Notes IS NULL
					AND l.LocationId = defaultlf.LocationId
					AND ws.Weightometer_Sample_Date BETWEEN defaultlf.StartDate AND defaultlf.EndDate					
				LEFT JOIN dbo.BhpbioApprovalData bad
					ON bad.LocationId = CASE WHEN LL.Location_Type_Id = @HubLocationTypeId THEN LL.Location_Id ELSE LL.Parent_Location_Id END
					AND bad.TagId = 'F25PostCrusherStockpileDelta'
					AND bad.ApprovedMonth = dbo.GetDateMonth(WS.Weightometer_Sample_Date)
				LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('PostCrusher') xs
					ON xs.StockpileId = WS.Source_Stockpile_Id
					OR xs.StockpileId = WS.Destination_Stockpile_Id
			WHERE Coalesce(WS.Source_Stockpile_Id, -1) <> Coalesce(WS.Destination_Stockpile_Id, -1)
				AND SGS.Stockpile_Group_Id = @StockpileGroupId
				AND SGS_S.Stockpile_Group_Id IS NULL  -- Ensure join to check if source is Post Crusher isn't true.
				AND WS.Weightometer_Id NOT LIKE '%Raw%'
				AND (LL.Location_Type_Id = @HubLocationTypeId OR
					(BSLC.PromoteStockpiles = 1 AND LL.Location_Type_Id = @SiteLocationTypeId AND 
						(BSLC.PromoteStockpilesFromDate IS NULL OR @iDateFrom >= BSLC.PromoteStockpilesFromDate)))
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
				
			-- calculate grade values by location and time period and select these for use in output query
			-- some of these grade values should be weighted based on sample tonnes (for back-calculated grades) before being weighted on real tonnes
			-- get an interim set of grade values by child location and product size
			INSERT INTO @InterimGradesByLocationAndProductSize
			SELECT WS.CalendarDate, G.Grade_Id AS GradeId, null, WS.LocationId, WS.ChildLocationId, WS.ProductSize, 
							SUM(CASE WHEN ss.ShouldWeightBySampleTonnes = 1 THEN WS.ProductPercent * WSV.Field_Value ELSE WS.Tonnes END  * WSG.Grade_Value) 
									/ 
							NULLIF(SUM(CASE WHEN ss.ShouldWeightBySampleTonnes =  1 THEN WS.ProductPercent * WSV.Field_Value ELSE ws.Tonnes END), 0)
					As GradeValue,
					0
			FROM @StockpileDelta WS
				INNER JOIN WeightometerSampleGrade AS WSG WITH (NOLOCK)
					ON (ws.WeightometerSampleId = WSG.Weightometer_Sample_Id)
				INNER JOIN dbo.WeightometerSampleNotes AS WSN WITH (NOLOCK)
					ON (wsn.Weightometer_Sample_Id = ws.WeightometerSampleId
						AND wsn.Weightometer_Sample_Field_Id = @SampleSourceField)
				INNER JOIN dbo.WeightometerSampleValue AS WSV WITH (NOLOCK)
					ON (wsv.Weightometer_Sample_Id = ws.WeightometerSampleId
						AND wsv.Weightometer_Sample_Field_Id = @SampleTonnesField)
				INNER JOIN dbo.GetBhpbioWeightometerSampleSource(@iLocationId, @iDateFrom, @iDateTo, 0) AS ss
					ON (dbo.GetDateMonth(ws.WeightometerSampleDate) = ss.MonthPeriod
						AND WS.ChildLocationId = ss.LocationId
							AND wsn.Notes = ss.SampleSource)
				INNER JOIN Grade AS G WITH (NOLOCK)
					ON (G.Grade_Id = WSG.Grade_Id)
			GROUP BY WS.CalendarDate, G.Grade_Id, WS.LocationId, WS.ChildLocationId, WS.ProductSize
			
			INSERT INTO @OutputGrades
			(
				CalendarDate,
				LocationId,
				GradeId,
				GradeValue,
				ProductSize,
				Tonnes
			)
			-- this second round of weighting should be done on tonnes rather than sample tonnes
			-- (ie locations weighted against each other based on tonnes)
			SELECT gblp.CalendarDate, gblp.LocationId, gblp.GradeId,
				SUM(gblp.GradeValue * sd.Tonnes) / NULLIF(SUM(sd.Tonnes), 0) AS GradeValue, 
				gblp.ProductSize,
				SUM(sd.Tonnes)
			FROM @InterimGradesByLocationAndProductSize AS gblp
				-- inner join the temporary table summing all tonnes by location
				INNER JOIN (SELECT sd.CalendarDate, sd.ChildLocationId AS LocationId, sd.ProductSize,
								ABS(SUM(CASE WHEN sd.Addition = 1 THEN sd.Tonnes ELSE -sd.Tonnes END)) AS Tonnes
							FROM @StockpileDelta sd
							GROUP BY sd.CalendarDate, sd.ChildLocationId, sd.ProductSize) AS sd
					ON sd.LocationId = gblp.ChildLocationId
					AND sd.ProductSize = gblp.ProductSize
					AND sd.CalendarDate = gblp.CalendarDate
			-- group by time period, grade and parent location level
			GROUP BY gblp.CalendarDate, gblp.GradeId, gblp.LocationId, gblp.ProductSize
			
			-- roll up lump and fines into total at each child location...then roll up to total
			INSERT INTO @OutputGrades
			(
				CalendarDate,
				LocationId,
				GradeId,
				GradeValue,
				ProductSize,
				Tonnes
			)
			SELECT TotalGradesByChildLocation.CalendarDate, TotalGradesByChildLocation.LocationId, TotalGradesByChildLocation.GradeId,
				SUM(TotalGradesByChildLocation.GradeValue * sdlocation.Tonnes) / NULLIF(SUM(sdLocation.Tonnes), 0),
				'TOTAL',
				SUM(sdLocation.Tonnes)
			FROM
				(
					SELECT gblp.CalendarDate, gblp.LocationId, gblp.ChildLocationId, gblp.GradeId,
					SUM(gblp.GradeValue * sdproduct.Tonnes) / NULLIF(SUM(sdproduct.Tonnes), 0) AS GradeValue
					FROM @InterimGradesByLocationAndProductSize AS gblp
						-- inner join the temporary table summing all tonnes by product and location
						INNER JOIN (SELECT sd.CalendarDate, sd.ChildLocationId AS LocationId, sd.ProductSize,
								ABS(SUM(CASE WHEN sd.Addition = 1 THEN sd.Tonnes ELSE -sd.Tonnes END)) AS Tonnes
							FROM @StockpileDelta sd
							GROUP BY sd.CalendarDate, sd.ChildLocationId, sd.ProductSize) AS sdproduct
						ON sdproduct.LocationId = gblp.ChildLocationId
						AND sdproduct.ProductSize = gblp.ProductSize
						AND sdproduct.CalendarDate = gblp.CalendarDate
					GROUP BY gblp.CalendarDate, gblp.LocationId, gblp.ChildLocationId, gblp.GradeId
				) As TotalGradesByChildLocation
				-- inner join the temporary table summing tonnes by location only
				INNER JOIN (SELECT sd.CalendarDate, sd.ChildLocationId AS LocationId,
								ABS(SUM(CASE WHEN sd.Addition = 1 THEN sd.Tonnes ELSE -sd.Tonnes END)) AS Tonnes
							FROM @StockpileDelta sd
							GROUP BY sd.CalendarDate, sd.ChildLocationId) AS sdlocation
					ON sdlocation.LocationId = TotalGradesByChildLocation.ChildLocationId
						AND sdlocation.CalendarDate = TotalGradesByChildLocation.CalendarDate
			GROUP BY TotalGradesByChildLocation.CalendarDate, TotalGradesByChildLocation.LocationId, TotalGradesByChildLocation.GradeId
		END
		
		IF @iIncludeApprovedData = 1
		BEGIN
			DECLARE @summaryEntryType VARCHAR(31)
			SET @summaryEntryType = 'HubPostCrusherStockpileDelta'
			
			DECLARE @summaryEntryTypeId INT
			SELECT @summaryEntryTypeId = st.SummaryEntryTypeId
			FROM dbo.BhpbioSummaryEntryType st
			WHERE st.Name = @summaryEntryType
			
			DECLARE @summaryGradesEntryType VARCHAR(31)
			SET @summaryGradesEntryType = 'HubPostCrusherSpDeltaGrades'
			
			DECLARE @summaryGradesEntryTypeId INT
			SELECT @summaryGradesEntryTypeId = st.SummaryEntryTypeId
			FROM dbo.BhpbioSummaryEntryType st
			WHERE st.Name = @summaryGradesEntryType
			
			-- Retrieve Tonnes
			INSERT INTO @OutputTonnes
				(CalendarDate, DateFrom, DateTo, LocationId, ProductSize, Tonnes)
			SELECT s.CalendarDate, s.DateFrom, s.DateTo, l.ParentLocationId, s.ProductSize, s.Tonnes
			FROM dbo.GetBhpbioSummaryTonnesBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryType, 1) s
				INNER JOIN @Location l
					ON l.LocationId = s.LocationId
					AND s.CalendarDate BETWEEN L.IncludeStart AND L.IncludeEnd;
			
			-- weight the grades by location by sample tonnes
			WITH GradesWeightedByTonnes AS
			(
				SELECT	B.CalendarDate AS CalendarDate, 
						B.DateFrom, 
						B.DateTo,
						bse.LocationId,
						ll.Parent_Location_Id,
						bse.ProductSize,
						bseg.GradeId,
						SUM(bseg.GradeValue * bset.Tonnes)/ SUM(bset.Tonnes) AS GradeValue
				FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
					INNER JOIN dbo.BhpbioSummary s WITH (NOLOCK)
						ON s.SummaryMonth >= B.DateFrom AND s.SummaryMonth < B.DateTo
					INNER JOIN dbo.BhpbioSummaryEntry AS bse WITH (NOLOCK)
						ON bse.SummaryId = s.SummaryId
						AND bse.SummaryEntryTypeId = @summaryGradesEntryTypeId
					INNER JOIN dbo.BhpbioSummaryEntry AS bset WITH (NOLOCK)
						ON bset.SummaryId = s.SummaryId
						AND bset.SummaryEntryTypeId = @summaryEntryTypeId
						AND bset.LocationId = bse.LocationId
						AND bset.ProductSize = bse.ProductSize
					INNER JOIN dbo.BhpbioSummaryEntryGrade AS bseg WITH (NOLOCK)
						ON bseg.SummaryEntryId = bse.SummaryEntryId
					INNER JOIN @Location l
						ON l.LocationId = bse.LocationId
						AND s.SummaryMonth BETWEEN L.IncludeStart AND L.IncludeEnd
					INNER JOIN dbo.BhpbioLocationDate ll
						ON ll.Location_Id = l.LocationId
						AND l.IncludeStart BETWEEN ll.[Start_Date] and ll.End_Date
				GROUP BY B.CalendarDate, B.DateFrom, B.DateTo, bse.LocationId, ll.Parent_Location_Id, bseg.GradeId, bse.ProductSize
				HAVING SUM(ABS(bset.Tonnes)) > 0
			), TonnesByLocation AS
			(
				SELECT B.CalendarDate, bse.LocationId, SUM(bse.Tonnes) AS Tonnes, bse.ProductSize
				FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
					INNER JOIN dbo.BhpbioSummary s WITH (NOLOCK)
							ON s.SummaryMonth >= B.DateFrom AND s.SummaryMonth < B.DateTo
					INNER JOIN dbo.BhpbioSummaryEntry AS bse WITH (NOLOCK)
						ON bse.SummaryId = s.SummaryId
						AND bse.SummaryEntryTypeId = @summaryEntryTypeId
					INNER JOIN @Location l
						ON l.LocationId = bse.LocationId
						AND s.SummaryMonth BETWEEN L.IncludeStart AND L.IncludeEnd
				GROUP BY B.CalendarDate, bse.LocationId, bse.ProductSize
			)
			-- then weight across locations by normal tonnes
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
			SELECT B.CalendarDate, l.ParentLocationId, gwbt.GradeId,  
				SUM(gwbt.GradeValue * ABS(tbl.Tonnes))/SUM(ABS(tbl.Tonnes)), gwbt.ProductSize,
				SUM(tbl.Tonnes)
			FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
				INNER JOIN TonnesByLocation tbl ON tbl.CalendarDate = B.CalendarDate
				INNER JOIN GradesWeightedByTonnes gwbt
					ON gwbt.CalendarDate = B.CalendarDate
					AND gwbt.LocationId = tbl.LocationId
					AND gwbt.ProductSize = tbl.ProductSize
				INNER JOIN @Location l
					ON l.LocationId = gwbt.LocationId
						AND b.CalendarDate BETWEEN L.IncludeStart AND L.IncludeEnd
			GROUP BY B.CalendarDate, l.ParentLocationId, gwbt.GradeId, gwbt.ProductSize
		END

		-- Output the tonnes
		SELECT o.CalendarDate, o.DateFrom, o.DateTo, NULL AS MaterialTypeId, o.LocationId AS ParentLocationId, o.ProductSize,
			Sum(o.Tonnes) AS Tonnes
		FROM @OutputTonnes o
		GROUP BY o.CalendarDate, o.DateFrom, o.DateTo, o.LocationId, o.ProductSize

		-- Output the grades
		SELECT o.CalendarDate, G.Grade_Name As GradeName, NULL AS MaterialTypeId, o.LocationId AS ParentLocationId, o.ProductSize,
			Sum(ABS(o.Tonnes) * o.GradeValue) / NULLIF(Sum(ABS(o.Tonnes)), 0) AS GradeValue
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

GRANT EXECUTE ON dbo.GetBhpbioReportDataHubPostCrusherStockpileDelta TO BhpbioGenericManager
GO
