IF OBJECT_ID('dbo.SummariseBhpbioPostCrusherStockpileDelta') IS NOT NULL
     DROP PROCEDURE dbo.SummariseBhpbioPostCrusherStockpileDelta
GO 
    
CREATE PROCEDURE dbo.SummariseBhpbioPostCrusherStockpileDelta
(
	@iSummaryMonth DATETIME,
	@iSummaryLocationId INTEGER,
	@iPostCrusherLevel VARCHAR(24)
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		ParentLocationId INT NULL,
		IncludeStart DATETIME,
		IncludeEnd DATETIME
		PRIMARY KEY (LocationId,IncludeStart,IncludeEnd)
	)
	
	DECLARE @StockpileDelta TABLE
	(
		StockpileId INT NOT NULL,
		WeightometerId VARCHAR(31) NOT NULL,
		WeightometerSampleId INT NOT NULL,
		WeightometerSampleDate DATETIME NOT NULL,
		Tonnes FLOAT NOT NULL,
		LocationId INT NULL,
		ProductSize VARCHAR(5) NOT NULL,
		ProductPercent DECIMAL(5,4) NOT NULL,
		Addition BIT NOT NULL,
		PRIMARY KEY (WeightometerSampleId, Addition, ProductSize)
	)
	
	DECLARE @SampleSourceField VARCHAR(31)
	SET @SampleSourceField = 'SampleSource'
	
	DECLARE @SampleTonnesField VARCHAR(31)
	SET @SampleTonnesField = 'SampleTonnes'
	
	DECLARE @ProductSizeField VARCHAR(31)
	SET @ProductSizeField = 'ProductSize'
	
	DECLARE @StockpileGroupId VARCHAR(31)
	SET @StockpileGroupId = 'Post Crusher'
	DECLARE @LastShift CHAR(1)

	DECLARE @HubLocationTypeId INT
	DECLARE @SiteLocationTypeId INT
	
	DECLARE @SummaryId INT
	DECLARE @StartOfMonth DATETIME
    DECLARE @EndOfMonth DATETIME
	DECLARE @StartOfNextMonth DATETIME
	DECLARE @PostCrusherStockpileDeltaSummaryEntryTypeId INTEGER
	DECLARE @SummaryGradesEntryTypeId INTEGER
	
	DECLARE @IsSiteCrusher BIT
	DECLARE @IsHubCrusher BIT
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'SummariseBhpbioPostCrusherStockpileDelta',
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
		SELECT @IsSiteCrusher = CASE WHEN @iPostCrusherLevel = 'Site' THEN 1 ELSE 0 END
		SELECT @IsHubCrusher = CASE WHEN @iPostCrusherLevel = 'Hub' THEN 1 ELSE 0 END
		
		-- obtain the Actual Type Id for ActualY storage
		SELECT @PostCrusherStockpileDeltaSummaryEntryTypeId = bset.SummaryEntryTypeId
		FROM dbo.BhpbioSummaryEntryType bset
		WHERE bset.Name = @iPostCrusherLevel + 'PostCrusherStockpileDelta'
		
		SELECT @SummaryGradesEntryTypeId = bset.SummaryEntryTypeId
		FROM dbo.BhpbioSummaryEntryType bset
		WHERE bset.Name = @iPostCrusherLevel + 'PostCrusherSpDeltaGrades'
		
		-- the first step is to remove previously summarised data for the same filtering criteria that the current summary is running on
		EXEC dbo.DeleteBhpbioSummaryEntry @iSummaryMonth = @iSummaryMonth,
											@iSummaryLocationId = @iSummaryLocationId,
											@iSummaryEntryTypeId = @PostCrusherStockpileDeltaSummaryEntryTypeId
											
		-- the first step is to remove previously summarised data for the same filtering criteria that the current summary is running on
		EXEC dbo.DeleteBhpbioSummaryEntry @iSummaryMonth = @iSummaryMonth,
											@iSummaryLocationId = @iSummaryLocationId,
											@iSummaryEntryTypeId = @SummaryGradesEntryTypeId
		
		-- get the start of the summary month and the start of the following month
		-- this gives us a window of time to operate within
		SELECT @StartOfMonth = dbo.GetDateMonth(@iSummaryMonth)
		SELECT @StartOfNextMonth = DATEADD(month,1,@iSummaryMonth)
        SELECT @EndOfMonth = DATEADD(day,-1,@StartOfNextMonth)

		-- get a Summary Id for the month (or create a new one if needed)
		EXEC dbo.GetBhpbioSummaryIdForMonth @iSummaryMonth = @StartOfMonth,
											@oSummaryId = @SummaryId OUTPUT
		
		SELECT @HubLocationTypeId = Location_Type_Id
		FROM dbo.LocationType
		WHERE Description = 'Hub'
		
		SELECT @SiteLocationTypeId = Location_Type_Id
		FROM dbo.LocationType
		WHERE Description = 'Site'
		
		INSERT INTO @Location
		(
			LocationId, ParentLocationId, IncludeStart, IncludeEnd
		)
		SELECT  LocationId, ParentLocationId,IncludeStart,IncludeEnd
		FROM	dbo.GetBhpbioReportLocationBreakdownWithOverride(@iSummaryLocationId, 1, 'SITE',@StartOfMonth,@StartOfNextMonth)
		UNION
		SELECT  Location_Id, Parent_Location_Id,@StartOfMonth,@StartOfNextMonth
		FROM	BhpbioLocationDate l
		WHERE	l.Location_Id = @iSummaryLocationId
		AND     @iSummaryMonth BETWEEN L.Start_Date AND L.End_Date
		
		-- -----------------------------------------------------------------------------------------------------------------------------------
		-- The queries used in this procedure are based on / taken from the original reporting implementation (on non-summarised data)
		-- -----------------------------------------------------------------------------------------------------------------------------------
		
		-- Get Removals
		INSERT INTO @StockpileDelta
		(
			StockpileId, WeightometerId, WeightometerSampleId, WeightometerSampleDate, Addition, ProductSize, ProductPercent, Tonnes, LocationId
		)
		SELECT DISTINCT S.Stockpile_Id, WS.Weightometer_Id, WS.Weightometer_Sample_Id, WS.Weightometer_Sample_Date, 0, 
			ISNULL(wsn.Notes, defaultlf.ProductSize), 
			ISNULL(defaultlf.[Percent], 1),
			ISNULL(defaultlf.[Percent], 1) * ws.Tonnes,
			CASE WHEN @IsSiteCrusher = 1
				THEN L.ParentLocationId
				ELSE L.LocationId
			END
		FROM dbo.WeightometerSample AS WS
			INNER JOIN dbo.Stockpile AS S
				ON (S.Stockpile_Id = WS.Source_Stockpile_Id)
			INNER JOIN dbo.StockpileGroupStockpile AS SGS
				ON (SGS.Stockpile_Id = S.Stockpile_Id)
			INNER JOIN dbo.BhpbioStockpileLocationDate AS SL
				ON (SL.Stockpile_Id = S.Stockpile_Id)
				AND	(WS.Weightometer_Sample_Date BETWEEN SL.[Start_Date] AND SL.End_Date)
			INNER JOIN @Location AS L
				ON (L.LocationId = SL.Location_Id)				
				AND	(WS.Weightometer_Sample_Date BETWEEN L.[IncludeStart] AND L.IncludeEnd)
			INNER JOIN dbo.Location AS LL
				ON (LL.Location_Id = L.LocationId)
			LEFT JOIN dbo.BhpbioLocationStockpileConfiguration AS BSLC
				ON (BSLC.LocationId = SL.Location_Id)
			LEFT JOIN dbo.StockpileGroupStockpile SGS_D
				ON (SGS_D.Stockpile_Id = WS.Destination_Stockpile_Id
					AND SGS_D.Stockpile_Group_Id = @StockpileGroupId)
			LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('PostCrusher') xs
				ON (xs.StockpileId = WS.Source_Stockpile_Id
					OR xs.StockpileId = WS.Destination_Stockpile_Id)
			LEFT JOIN dbo.WeightometerSampleNotes wsn
				ON (ws.Weightometer_Sample_Id = wsn.Weightometer_Sample_Id
					AND wsn.Weightometer_Sample_Field_Id = @ProductSizeField)
			LEFT JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf
				ON wsn.Notes IS NULL
				AND l.LocationId = defaultlf.LocationId
				AND ws.Weightometer_Sample_Date BETWEEN defaultlf.StartDate AND defaultlf.EndDate					
		WHERE Coalesce(WS.Source_Stockpile_Id, -1) <> Coalesce(WS.Destination_Stockpile_Id, -1)
			AND SGS.Stockpile_Group_Id = @StockpileGroupId
			AND SGS_D.Stockpile_Group_Id IS NULL -- Ensure join to check if destination is Post Crusher isn't true.
			AND WS.Weightometer_Id NOT LIKE '%Raw%'
			AND	WS.Weightometer_Sample_Date >= @StartOfMonth
			AND WS.Weightometer_Sample_Date < @StartOfNextMonth
			AND xs.StockpileId IS NULL -- No movements to or from excluded groups.
			AND	(ISNULL(defaultlf.[Percent], 1) > 0)
			AND 
			(
				(
					@IsSiteCrusher = 1
					AND
					(
						LL.Location_Type_Id = @SiteLocationTypeId AND (BSLC.PromoteStockpiles = 0 OR BSLC.PromoteStockpiles IS NULL
					)
				)
			)
			OR 
				(
					@IsHubCrusher = 1
					AND
					(
						LL.Location_Type_Id = @HubLocationTypeId 
						OR (BSLC.PromoteStockpiles = 1 AND LL.Location_Type_Id = @SiteLocationTypeId AND 
							(BSLC.PromoteStockpilesFromDate IS NULL OR @iSummaryMonth >= BSLC.PromoteStockpilesFromDate))
					)
				)
			)
			
		-- Get Additions
		INSERT INTO @StockpileDelta
		(
			StockpileId, WeightometerId, WeightometerSampleId, WeightometerSampleDate, Addition, ProductSize, ProductPercent, Tonnes, LocationId
		)
		SELECT DISTINCT S.Stockpile_Id, WS.Weightometer_Id, WS.Weightometer_Sample_Id, WS.Weightometer_Sample_Date, 1, 
			ISNULL(wsn.Notes, defaultlf.ProductSize), 
			ISNULL(defaultlf.[Percent], 1),
			ISNULL(defaultlf.[Percent], 1) * ws.Tonnes,
			CASE WHEN @IsSiteCrusher = 1
				THEN L.ParentLocationId
				ELSE L.LocationId
			END
		FROM dbo.WeightometerSample AS WS
			INNER JOIN dbo.Stockpile AS S
				ON (S.Stockpile_Id = WS.Destination_Stockpile_Id)
			INNER JOIN dbo.StockpileGroupStockpile AS SGS
				ON (SGS.Stockpile_Id = S.Stockpile_Id)
			INNER JOIN dbo.BhpbioStockpileLocationDate AS SL
				ON (SL.Stockpile_Id = S.Stockpile_Id)
				AND	(WS.Weightometer_Sample_Date BETWEEN SL.[Start_Date] AND SL.End_Date)
			INNER JOIN @Location AS L
				ON (L.LocationId = SL.Location_Id)
				AND	(WS.Weightometer_Sample_Date BETWEEN L.[IncludeStart] AND L.IncludeEnd)
			LEFT JOIN dbo.BhpbioLocationStockpileConfiguration AS BSLC
				ON (BSLC.LocationId = SL.Location_Id)
			INNER JOIN dbo.Location AS LL
				ON (LL.Location_Id = L.LocationId)
			LEFT JOIN dbo.StockpileGroupStockpile SGS_S
				ON (SGS_S.Stockpile_Id = WS.Source_Stockpile_Id
					AND SGS_S.Stockpile_Group_Id = @StockpileGroupId)
			LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('PostCrusher') xs
				ON (xs.StockpileId = WS.Source_Stockpile_Id
					OR xs.StockpileId = WS.Destination_Stockpile_Id)
			LEFT JOIN dbo.WeightometerSampleNotes wsn
				ON (ws.Weightometer_Sample_Id = wsn.Weightometer_Sample_Id
					AND wsn.Weightometer_Sample_Field_Id = @ProductSizeField)
			LEFT JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf
				ON wsn.Notes IS NULL
				AND l.LocationId = defaultlf.LocationId
				AND ws.Weightometer_Sample_Date BETWEEN defaultlf.StartDate AND defaultlf.EndDate					
		WHERE Coalesce(WS.Source_Stockpile_Id, -1) <> Coalesce(WS.Destination_Stockpile_Id, -1)
			AND SGS.Stockpile_Group_Id = @StockpileGroupId
			AND SGS_S.Stockpile_Group_Id IS NULL  -- Ensure join to check if source is Post Crusher isn't true.
			AND WS.Weightometer_Id NOT LIKE '%Raw%'
			AND	WS.Weightometer_Sample_Date >= @StartOfMonth
			AND WS.Weightometer_Sample_Date < @StartOfNextMonth
			AND xs.StockpileId IS NULL -- No movements to or from excluded groups.
			AND	(ISNULL(defaultlf.[Percent], 1) > 0)
			AND 
			(
				(
					@IsSiteCrusher = 1
					AND (LL.Location_Type_Id = @SiteLocationTypeId AND (BSLC.PromoteStockpiles = 0 OR BSLC.PromoteStockpiles IS NULL))
				)
				OR 
				(
					@IsHubCrusher = 1
					AND (
							LL.Location_Type_Id = @HubLocationTypeId 
							OR (BSLC.PromoteStockpiles = 1 AND LL.Location_Type_Id = @SiteLocationTypeId AND 
								(BSLC.PromoteStockpilesFromDate IS NULL OR @iSummaryMonth >= BSLC.PromoteStockpilesFromDate))
						)
				)
			)
			
		---- Insert the actual tonnes
		INSERT INTO dbo.BhpbioSummaryEntry
		(
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			ProductSize,
			Tonnes
		)
		-- for separate lump and fines
		SELECT  @SummaryId,
				@PostCrusherStockpileDeltaSummaryEntryTypeId,
				LocationId, NULL, ProductSize,
				Sum(CASE WHEN Addition = 1 THEN Tonnes ELSE -Tonnes END) AS Tonnes
		FROM @StockpileDelta
		GROUP BY LocationId, ProductSize
		UNION ALL
		-- for rolled up total
		SELECT  @SummaryId,
				@PostCrusherStockpileDeltaSummaryEntryTypeId,
				LocationId, NULL, 'TOTAL',
				Sum(CASE WHEN Addition = 1 THEN Tonnes ELSE -Tonnes END) AS Tonnes
		FROM @StockpileDelta 
		GROUP BY LocationId				
		
		IF @IsSiteCrusher = 1
		BEGIN
			-- insert the grade tonnes (the tonnes used for grade blending are NOT always the same as the tonnes reported for stockpile delta)
			INSERT INTO dbo.BhpbioSummaryEntry
			(
				SummaryId,
				SummaryEntryTypeId,
				LocationId,
				MaterialTypeId,
				ProductSize,
				Tonnes
			)
			-- obtain the Delta Grades for separate lump and fines
			SELECT
				@SummaryId,
				@SummaryGradesEntryTypeId,
				SD.LocationId, 
				NULL, 
				SD.ProductSize,
				SUM(Abs(SD.Tonnes))
			FROM @StockpileDelta AS SD
				INNER JOIN dbo.WeightometerSample AS WS
					ON (WS.Weightometer_Sample_Id = SD.WeightometerSampleId)
			WHERE EXISTS
			(
				SELECT 1
				FROM dbo.WeightometerSampleGrade AS WSG
				WHERE WSG.Weightometer_Sample_Id = SD.WeightometerSampleId  
			)
			GROUP BY SD.LocationId, SD.ProductSize
			UNION ALL			
			-- obtain the Delta Grades roll up
			SELECT
				@SummaryId,
				@SummaryGradesEntryTypeId,
				SD.LocationId, 
				NULL, 
				'TOTAL',
				SUM(Abs(SD.Tonnes))
			FROM @StockpileDelta AS SD
				INNER JOIN dbo.WeightometerSample AS WS
					ON (WS.Weightometer_Sample_Id = SD.WeightometerSampleId)
			WHERE EXISTS
			(
				SELECT 1
				FROM dbo.WeightometerSampleGrade AS WSG
				WHERE WSG.Weightometer_Sample_Id = SD.WeightometerSampleId  
			)
			GROUP BY SD.LocationId
			
			-- insert grade values
			INSERT INTO dbo.BhpbioSummaryEntryGrade
			(
				SummaryEntryId,
				GradeId,
				GradeValue
			)
			SELECT 
				bse.SummaryEntryId,
				WSG.Grade_Id,
				SUM(Abs(SD.Tonnes) * WSG.Grade_Value) / NULLIF(SUM(Abs(SD.Tonnes)), 0) AS GradeValue
			FROM @StockpileDelta AS SD
				INNER JOIN dbo.Location l 
					ON l.Location_Id = SD.LocationId
				INNER JOIN dbo.BhpbioSummaryEntry bse
					ON bse.LocationId = l.Location_Id
						AND bse.SummaryId = @SummaryId
						AND bse.SummaryEntryTypeId = @SummaryGradesEntryTypeId
						AND (SD.ProductSize = bse.ProductSize OR bse.ProductSize = 'TOTAL')
				INNER JOIN dbo.WeightometerSample AS WS
					ON (WS.Weightometer_Sample_Id = SD.WeightometerSampleId)
				INNER JOIN dbo.WeightometerSampleGrade AS WSG
					ON (WSG.Weightometer_Sample_Id = WS.Weightometer_Sample_Id)
			WHERE WS.Tonnes Is Not Null AND WS.Tonnes <> 0
			GROUP BY bse.SummaryEntryId, WSG.Grade_Id
		END
		
		IF @IsHubCrusher = 1
		BEGIN
		
			DECLARE @GradesAndTonnes TABLE
			(
				LocationId INT NOT NULL,
				ProductSize VARCHAR(5) NOT NULL,
				GradeId INT NOT NULL,
				GradeValue FLOAT NULL,
				GradeTonnes FLOAT NULL,
				SampleTonnes FLOAT NULL
			);
			
			WITH GradesByLocationAndPeriod AS
			(
				SELECT WSG.Grade_Id, WS.LocationId,
				    
						SUM(
							CASE WHEN ss.ShouldWeightBySampleTonnes = 1 THEN
								WS.ProductPercent * WSV.Field_Value * WSG.Grade_Value
							ELSE	
								WS.Tonnes* WSG.Grade_Value
							END
						)
						/ 
						NULLIF(SUM(
								CASE WHEN ss.ShouldWeightBySampleTonnes = 1 THEN
									WS.ProductPercent * WSV.Field_Value
								ELSE	
									WS.Tonnes
								END
							), 0) As GradeValue,
						WS.ProductSize, 
						NULLIF(SUM(WS.ProductPercent * WSV.Field_Value),0) AS SampleTonnes
				FROM @StockpileDelta AS WS 
					INNER JOIN WeightometerSampleGrade AS WSG WITH (NOLOCK)
						ON (ws.WeightometerSampleId = WSG.Weightometer_Sample_Id)
					INNER JOIN dbo.WeightometerSampleNotes AS WSN WITH (NOLOCK)
						ON (wsn.Weightometer_Sample_Id = ws.WeightometerSampleId
							AND wsn.Weightometer_Sample_Field_Id = @SampleSourceField)
					INNER JOIN dbo.WeightometerSampleValue AS WSV WITH (NOLOCK)
						ON (wsv.Weightometer_Sample_Id = ws.WeightometerSampleId
							AND wsv.Weightometer_Sample_Field_Id = @SampleTonnesField)
					INNER JOIN dbo.GetBhpbioWeightometerSampleSource(@iSummaryLocationId, @StartOfMonth, @StartOfNextMonth, 0) AS ss
						ON (dbo.GetDateMonth(ws.WeightometerSampleDate) = ss.MonthPeriod
							AND WS.LocationId = ss.LocationId
							AND wsn.Notes = ss.SampleSource)
					INNER JOIN Grade AS G WITH (NOLOCK)
						ON (G.Grade_Id =  WSG.Grade_Id)
				GROUP BY WSG.Grade_Id, WS.LocationId, WS.ProductSize
			)
			-- now weight the lower level locations to get values at the parent level
			-- this second round of weighting should be done on tonnes rather than sample tonnes
			-- (ie locations weighted against each other based on tonnes)
			INSERT INTO @GradesAndTonnes
			(
				LocationId,
				ProductSize,
				GradeId,
				GradeValue,
				GradeTonnes
			)
			SELECT
				gblp.LocationId,
				gblp.ProductSize,
				gblp.Grade_Id,
				SUM(ABS(sd.Tonnes) * gblp.GradeValue) /	SUM(ABS(sd.Tonnes)) AS GradeValue,
				SUM(sd.Tonnes)
			FROM GradesByLocationAndPeriod AS gblp
				INNER JOIN
				(
					SELECT LocationId, ProductSize,
						SUM(CASE WHEN Addition = 1 THEN Tonnes ELSE -Tonnes END) AS Tonnes
					FROM @StockpileDelta
					GROUP BY LocationId, ProductSize
				) AS sd
					ON sd.LocationId = gblp.LocationId 
					AND sd.ProductSize = gblp.ProductSize
			WHERE ABS(sd.Tonnes) > 0
			GROUP BY gblp.LocationId, gblp.Grade_Id, gblp.ProductSize
			
			INSERT INTO dbo.BhpbioSummaryEntry
			(
				SummaryId,
				SummaryEntryTypeId,
				LocationId,
				MaterialTypeId,
				ProductSize,
				Tonnes
			)
			-- grade tonnes for lump and fines
			SELECT	@SummaryId,
					@SummaryGradesEntryTypeId,
					LocationId,
					null,
					ProductSize,
					SUM(Abs(GradeTonnes))
			FROM @GradesAndTonnes
			WHERE GradeId = 1  -- avoid multiplying the tonnes by the number of grades by picking a single grade
			GROUP BY LocationId, ProductSize
			UNION ALL			
			-- grade tonnes rolled up
			SELECT	@SummaryId,
					@SummaryGradesEntryTypeId,
					LocationId,
					null,
					'TOTAL',
					SUM(Abs(GradeTonnes))	
			FROM @GradesAndTonnes
			WHERE GradeId = 1 -- avoid multiplying the tonnes by the number of grades by picking a single grade
			GROUP BY LocationId
			
			-- insert grade values
			INSERT INTO dbo.BhpbioSummaryEntryGrade
			(
				SummaryEntryId,
				GradeId,
				GradeValue
			)
			SELECT bse.SummaryEntryId,
				   gt.GradeId,
				   SUM(Abs(gt.GradeTonnes) * gt.GradeValue) / NULLIF(SUM(Abs(gt.GradeTonnes)), 0)
			FROM @GradesAndTonnes gt
				INNER JOIN dbo.BhpbioSummaryEntry bse
					ON bse.SummaryId = @SummaryId
						AND bse.SummaryEntryTypeId = @SummaryGradesEntryTypeId
						AND bse.LocationId = gt.LocationId
						AND (gt.ProductSize = bse.ProductSize OR bse.ProductSize = 'TOTAL')
			GROUP BY bse.SummaryEntryId, gt.GradeId
		END
		
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

GRANT EXECUTE ON dbo.SummariseBhpbioPostCrusherStockpileDelta TO BhpbioGenericManager
GO

/*
EXEC dbo.SummariseBhpbioPostCrusherStockpileDelta
	@iSummaryMonth = '2013-01-01',
	@iSummaryLocationId = 3,
	@iPostCrusherLevel='Hub'
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.SummariseBhpbioSitePostCrusherStockpileDelta">
 <Procedure>
	Generates a set of summary PostCrusherStockpile Delta data based on supplied criteria.
	This may be for a site or a hub
	
	Delta refers to the difference between additions and reclaims
			
	Pass: 
			@iSummaryMonth: the month for which summary data is to be generated,
			@iSummaryLocationId: the location (a Site or Hub) for which data will be summarised
			@iPostCrusherLevel: 'Site' or 'Hub'
 </Procedure>
</TAG>
*/
