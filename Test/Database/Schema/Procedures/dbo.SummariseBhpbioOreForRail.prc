IF OBJECT_ID('dbo.SummariseBhpbioOreForRail') IS NOT NULL
     DROP PROCEDURE dbo.SummariseBhpbioOreForRail
GO 
    
CREATE PROCEDURE dbo.SummariseBhpbioOreForRail
(
	@iSummaryMonth DATETIME,
	@iSummaryLocationId INTEGER
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
	
	DECLARE @OreForRail TABLE
	(
		StockpileId INT NOT NULL,
		WeightometerSampleId INT NOT NULL,
		WeightometerSampleDate DATETIME NOT NULL,
		Tonnes FLOAT NOT NULL,
		LocationId INT NULL,
		ProductSize VARCHAR(5) NOT NULL,
		ProductPercent DECIMAL(5,4) NOT NULL,
		PRIMARY KEY (WeightometerSampleId, ProductSize)
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
	DECLARE @StartOfNextMonth DATETIME
	DECLARE @OreForRailSummaryEntryTypeId INTEGER
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
		-- obtain the Actual Type Id for Ore For Rail storage
		SELECT @OreForRailSummaryEntryTypeId = bset.SummaryEntryTypeId
		FROM dbo.BhpbioSummaryEntryType bset
		WHERE bset.Name = 'OreForRail'
		
		SELECT @SummaryGradesEntryTypeId = bset.SummaryEntryTypeId
		FROM dbo.BhpbioSummaryEntryType bset
		WHERE bset.Name = 'OreForRailGrades'
		
		-- the first step is to remove previously summarised data for the same filtering criteria that the current summary is running on
		EXEC dbo.DeleteBhpbioSummaryEntry @iSummaryMonth = @iSummaryMonth,
											@iSummaryLocationId = @iSummaryLocationId,
											@iSummaryEntryTypeId = @OreForRailSummaryEntryTypeId
											
		-- the first step is to remove previously summarised data for the same filtering criteria that the current summary is running on
		EXEC dbo.DeleteBhpbioSummaryEntry @iSummaryMonth = @iSummaryMonth,
											@iSummaryLocationId = @iSummaryLocationId,
											@iSummaryEntryTypeId = @SummaryGradesEntryTypeId
		
		-- get the start of the summary month and the start of the following month
		-- this gives us a window of time to operate within
		SELECT @StartOfMonth = dbo.GetDateMonth(@iSummaryMonth)
		SELECT @StartOfNextMonth = DATEADD(month,1,@iSummaryMonth)

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
		FROM	dbo.GetBhpbioReportLocationBreakdownWithOverride(@iSummaryLocationId, 1, 'SITE', @StartOfMonth,@StartOfNextMonth)
		UNION
		SELECT  Location_Id, Parent_Location_Id,@StartOfMonth,@StartOfNextMonth
		FROM	BhpbioLocationDate l
		WHERE	l.Location_Id = @iSummaryLocationId
		AND     @iSummaryMonth BETWEEN L.Start_Date AND L.End_Date
		
		-- -----------------------------------------------------------------------------------------------------------------------------------
		-- The queries used in this procedure are based on / taken from the original reporting implementation (on non-summarised data)
		-- -----------------------------------------------------------------------------------------------------------------------------------
		
		-- Get Removals
		INSERT INTO @OreForRail
		(
			StockpileId, WeightometerSampleId, WeightometerSampleDate, ProductSize, ProductPercent, Tonnes, LocationId
		)
		SELECT DISTINCT S.Stockpile_Id, WS.Weightometer_Sample_Id, WS.Weightometer_Sample_Date,
			ISNULL(wsn.Notes, defaultlf.ProductSize), 
			ISNULL(defaultlf.[Percent], 1),
			ISNULL(defaultlf.[Percent], 1) * ws.Tonnes,
			L.LocationId
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
			LEFT JOIN BhpbioWeightometerGroupWeightometer ei ON ei.Weightometer_Group_Id = 'ExplicitlyIncludeInOreForRail' AND ei.Weightometer_Id =	ws.Weightometer_Id
					AND ei.[Start_Date] <= ws.Weightometer_Sample_Date AND ((ei.End_Date IS NULL) OR ei.End_Date >= ws.Weightometer_Sample_Date)	
		WHERE (
				(	
					Coalesce(WS.Source_Stockpile_Id, -1) <> Coalesce(WS.Destination_Stockpile_Id, -1)
					AND SGS.Stockpile_Group_Id = @StockpileGroupId
					AND SGS_D.Stockpile_Group_Id IS NULL -- Ensure join to check if destination is Post Crusher isn't true.
					AND (LL.Location_Type_Id = @HubLocationTypeId OR
					(BSLC.PromoteStockpiles = 1 AND LL.Location_Type_Id = @SiteLocationTypeId AND 
					(BSLC.PromoteStockpilesFromDate IS NULL OR @iSummaryMonth >= BSLC.PromoteStockpilesFromDate))
					)
				) OR (
					NOT ei.Weightometer_Id IS NULL -- in the explicitly include group
				)
			  )
			AND WS.Weightometer_Id NOT LIKE '%Raw%'
			AND	WS.Weightometer_Sample_Date >= @StartOfMonth
			AND WS.Weightometer_Sample_Date < @StartOfNextMonth
			AND xs.StockpileId IS NULL -- No movements to or from excluded groups.
			
			AND	(ISNULL(defaultlf.[Percent], 1) > 0)
			
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
				@OreForRailSummaryEntryTypeId,
				LocationId, NULL, ProductSize,
				Sum(Tonnes) AS Tonnes
		FROM @OreForRail
		GROUP BY LocationId, ProductSize
		UNION ALL
		-- for rolled up total
		SELECT  @SummaryId,
				@OreForRailSummaryEntryTypeId,
				LocationId, NULL, 'TOTAL',
				Sum(Tonnes) AS Tonnes
		FROM @OreForRail 
		GROUP BY LocationId				
		
	
		DECLARE @GradesAndTonnes TABLE
		(
			LocationId INT NOT NULL,
			ProductSize VARCHAR(5) NOT NULL,
			GradeId INT NOT NULL,
			GradeValue FLOAT NULL,
			GradeTonnes FLOAT NULL
		);
		
		WITH GradesByLocationAndPeriod AS
		(
			SELECT WSG.Grade_Id, WS.LocationId,
				SUM(
					CASE WHEN ss.ShouldWeightBySampleTonnes = 1 THEN
						WS.ProductPercent * WSV.Field_Value * WSG.Grade_Value
					ELSE
						WS.Tonnes * WSG.Grade_Value
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
			FROM @OreForRail WS
				INNER JOIN WeightometerSampleGrade AS WSG WITH (NOLOCK)
					ON (ws.WeightometerSampleId = WSG.Weightometer_Sample_Id)
				INNER JOIN dbo.WeightometerSampleNotes AS WSN WITH (NOLOCK)
					ON (wsn.Weightometer_Sample_Id = ws.WeightometerSampleId
						AND wsn.Weightometer_Sample_Field_Id = @SampleSourceField)
				INNER JOIN dbo.WeightometerSampleValue AS WSV WITH (NOLOCK)
					ON (wsv.Weightometer_Sample_Id = ws.WeightometerSampleId
						AND wsv.Weightometer_Sample_Field_Id = @SampleTonnesField)
				INNER JOIN dbo.GetBhpbioWeightometerSampleSource(@iSummaryLocationId, @StartOfMonth, @StartOfNextMonth, 1) AS ss
					ON (dbo.GetDateMonth(ws.WeightometerSampleDate) = ss.MonthPeriod
						AND WS.LocationId = ss.LocationId
						AND wsn.Notes = ss.SampleSource)
				INNER JOIN Grade AS G WITH (NOLOCK)
					ON (G.Grade_Id = WSG.Grade_Id)
				GROUP BY WSG.Grade_Id, WS.LocationId, WS.ProductSize
		)

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
					SUM(Tonnes) AS Tonnes
				FROM @OreForRail
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
				SUM(GradeTonnes)
		FROM @GradesAndTonnes
		WHERE GradeId <= 6
		GROUP BY LocationId, ProductSize
		UNION ALL			
		-- grade tonnes rolled up
		SELECT	@SummaryId,
				@SummaryGradesEntryTypeId,
				LocationId,
				null,
				'TOTAL',
				SUM(GradeTonnes)
		FROM @GradesAndTonnes
		WHERE GradeId <= 6
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
			   SUM(gt.GradeTonnes * gt.GradeValue) / NULLIF(SUM(gt.GradeTonnes), 0)
		FROM @GradesAndTonnes gt
			INNER JOIN dbo.BhpbioSummaryEntry bse
				ON bse.SummaryId = @SummaryId
					AND bse.SummaryEntryTypeId = @SummaryGradesEntryTypeId
					AND bse.LocationId = gt.LocationId
					AND (gt.ProductSize = bse.ProductSize OR bse.ProductSize = 'TOTAL')
		GROUP BY bse.SummaryEntryId, gt.GradeId
		
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

GRANT EXECUTE ON dbo.SummariseBhpbioOreForRail TO BhpbioGenericManager
GO

/*
EXEC dbo.SummariseBhpbioOreForRail
	@iSummaryMonth = '2009-11-01',
	@iLocationId = 3,
	'Hub'
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.SummariseBhpbioOreForRail">
 <Procedure>
	Generates a set of summary SummariseBhpbioOreForRail Delta data based on supplied criteria.
	This may be for a hub
	
	Delta refers to the difference between additions and reclaims
			
	Pass: 
			@iSummaryMonth: the month for which summary data is to be generated,
			@iSummaryLocationId: the location (a Site or Hub) for which data will be summarised
			@iPostCrusherLevel: 'Site' or 'Hub'
 </Procedure>
</TAG>
*/