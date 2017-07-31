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
		WeightometerSampleId INT NOT NULL,
		Tonnes FLOAT NOT NULL,
		LocationId INT NULL,
		Addition BIT NOT NULL,
		PRIMARY KEY (WeightometerSampleId, Addition)
	)
	
	DECLARE @SampleSourceField VARCHAR(31)
	SET @SampleSourceField = 'SampleSource'
	
	DECLARE @SampleTonnesField VARCHAR(31)
	SET @SampleTonnesField = 'SampleTonnes'
	
	DECLARE @StockpileGroupId VARCHAR(31)
	SET @StockpileGroupId = 'Post Crusher'
	DECLARE @LastShift CHAR(1)

	DECLARE @HubLocationTypeId INT
	DECLARE @SiteLocationTypeId INT
	
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
		DECLARE @summaryId INT
		DECLARE @startOfMonth DATETIME
		DECLARE @endOfMonth DATETIME
		DECLARE @startOfNextMonth DATETIME
		DECLARE @summaryEntryTypeId INTEGER
		DECLARE @summaryGradesEntryTypeId INTEGER
		
		DECLARE @isSiteCrusher BIT
		DECLARE @isHubCrusher BIT
		
		SELECT @isSiteCrusher = CASE WHEN @iPostCrusherLevel = 'Site' THEN 1 ELSE 0 END
		SELECT @isHubCrusher = CASE WHEN @iPostCrusherLevel = 'Hub' THEN 1 ELSE 0 END
		
		-- obtain the Actual Type Id for ActualY storage
		SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
		FROM dbo.BhpbioSummaryEntryType bset
		WHERE bset.Name = @iPostCrusherLevel + 'PostCrusherStockpileDelta'
		
		SELECT @summaryGradesEntryTypeId = bset.SummaryEntryTypeId
		FROM dbo.BhpbioSummaryEntryType bset
		WHERE bset.Name = @iPostCrusherLevel + 'PostCrusherSpDeltaGrades'
		
		-- the first step is to remove previously summarised data for the same filtering criteria that the current summary is running on
		exec dbo.DeleteBhpbioSummaryEntry @iSummaryMonth = @iSummaryMonth,
											@iSummaryLocationId = @iSummaryLocationId,
											@iSummaryEntryTypeId = @summaryEntryTypeId
											
		-- the first step is to remove previously summarised data for the same filtering criteria that the current summary is running on
		exec dbo.DeleteBhpbioSummaryEntry @iSummaryMonth = @iSummaryMonth,
											@iSummaryLocationId = @iSummaryLocationId,
											@iSummaryEntryTypeId = @summaryGradesEntryTypeId
		
		-- get the start of the summary month and the start of the following month
		-- this gives us a window of time to operate within
		SELECT @startOfMonth = dbo.GetDateMonth(@iSummaryMonth)
		SELECT @startOfNextMonth = DATEADD(month,1,@iSummaryMonth)
		SELECT @endOfMonth = DATEADD(day,-1,@startOfNextMonth)

		-- get a Summary Id for the month (or create a new one if needed)
		EXEC dbo.GetBhpbioSummaryIdForMonth @iSummaryMonth = @startOfMonth,
											@oSummaryId = @summaryId OUTPUT
		
		SELECT @HubLocationTypeId = Location_Type_Id
		FROM dbo.LocationType
		WHERE Description = 'Hub'
		
		SELECT @SiteLocationTypeId = Location_Type_Id
		FROM dbo.LocationType
		WHERE Description = 'Site'
		
		INSERT  INTO @Location (LocationId, ParentLocationId,IncludeStart,IncludeEnd)
		SELECT  LocationId, ParentLocationId,IncludeStart,IncludeEnd
		FROM	dbo.GetBhpbioReportLocationBreakdownWithOverride(@iSummaryLocationId, 1, 'SITE',@startOfMonth,@endOfMonth)
		UNION
		SELECT  Location_Id, Parent_Location_Id,@startOfMonth,@endOfMonth
		FROM	BhpbioLocationDate l
		WHERE	l.Location_Id = @iSummaryLocationId
		AND     @iSummaryMonth BETWEEN L.Start_Date AND L.End_Date
		
		-- -----------------------------------------------------------------------------------------------------------------------------------
		-- The queries used in this procedure are based on / taken from the original reporting implementation (on non-summarised data)
		-- -----------------------------------------------------------------------------------------------------------------------------------
		
		-- Get Removals
		INSERT INTO @StockpileDelta
			(StockpileId, WeightometerSampleId, Addition, Tonnes, LocationId)		
		SELECT DISTINCT S.Stockpile_Id, WS.Weightometer_Sample_Id, 0, WS.Tonnes, 
			CASE WHEN @isSiteCrusher = 1 THEN L.ParentLocationId ELSE L.LocationId END
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
        ON xs.StockpileId = WS.Source_Stockpile_Id
        OR xs.StockpileId = WS.Destination_Stockpile_Id
		WHERE Coalesce(WS.Source_Stockpile_Id, -1) <> Coalesce(WS.Destination_Stockpile_Id, -1)
			AND SGS.Stockpile_Group_Id = @StockpileGroupId
			AND SGS_D.Stockpile_Group_Id IS NULL -- Ensure join to check if destination is Post Crusher isn't true.
			AND WS.Weightometer_Id NOT LIKE '%Raw%'
			AND	WS.Weightometer_Sample_Date BETWEEN @startOfMonth AND @endOfMonth
			AND xs.StockpileId IS NULL -- No movements to or from excluded groups.
			AND 
			(
				(
					@isSiteCrusher = 1
					AND (LL.Location_Type_Id = @SiteLocationTypeId AND (BSLC.PromoteStockpiles = 0 OR BSLC.PromoteStockpiles IS NULL))
				)
				OR 
				(
					@isHubCrusher = 1
					AND (
							LL.Location_Type_Id = @HubLocationTypeId 
						OR (BSLC.PromoteStockpiles = 1 AND LL.Location_Type_Id = @SiteLocationTypeId)
						)
				)
			)
			
		-- Get Additions
		INSERT INTO @StockpileDelta
			(StockpileId, WeightometerSampleId, Addition, Tonnes, LocationId)		
		SELECT DISTINCT S.Stockpile_Id, WS.Weightometer_Sample_ID, 1, WS.Tonnes, 
			CASE WHEN @isSiteCrusher = 1 THEN L.ParentLocationId ELSE L.LocationId END
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
	        ON xs.StockpileId = WS.Source_Stockpile_Id
	        OR xs.StockpileId = WS.Destination_Stockpile_Id
		WHERE Coalesce(WS.Source_Stockpile_Id, -1) <> Coalesce(WS.Destination_Stockpile_Id, -1)
			AND SGS.Stockpile_Group_Id = @StockpileGroupId
			AND SGS_S.Stockpile_Group_Id IS NULL  -- Ensure join to check if source is Post Crusher isn't true.
			AND WS.Weightometer_Id NOT LIKE '%Raw%'
			AND	WS.Weightometer_Sample_Date BETWEEN @startOfMonth AND @endOfMonth
			AND xs.StockpileId IS NULL -- No movements to or from excluded groups.
			AND 
			(
				(
					@isSiteCrusher = 1
					AND (LL.Location_Type_Id = @SiteLocationTypeId AND (BSLC.PromoteStockpiles = 0 OR BSLC.PromoteStockpiles IS NULL))
				)
				OR 
				(
					@isHubCrusher = 1
					AND (
							LL.Location_Type_Id = @HubLocationTypeId 
						OR (BSLC.PromoteStockpiles = 1 AND LL.Location_Type_Id = @SiteLocationTypeId)
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
			Tonnes
		)
		SELECT  @summaryId,
				@summaryEntryTypeId,
				d.LocationId,
				null,
				Sum(CASE WHEN d.Addition = 1 THEN d.Tonnes ELSE -d.Tonnes END) AS Tonnes
		FROM @StockpileDelta d
		GROUP BY d.LocationId;
		
		IF @isSiteCrusher = 1
		BEGIN
			-- insert the grade tonnes (the tonnes used for grade blending are NOT the same as the tonnes reported for stockpile delta)
			INSERT INTO dbo.BhpbioSummaryEntry
			(
				SummaryId,
				SummaryEntryTypeId,
				LocationId,
				MaterialTypeId,
				Tonnes
			)
			SELECT 
				@summaryId,
				@summaryGradesEntryTypeId,
				SD.LocationId,
				null,
				Sum(WS.Tonnes)
			FROM @StockpileDelta AS SD
				INNER JOIN dbo.WeightometerSample AS WS
					ON (WS.Weightometer_Sample_Id = SD.WeightometerSampleId)
			WHERE EXISTS	(	SELECT * 
								FROM dbo.WeightometerSampleGrade AS WSG
								WHERE WSG.Weightometer_Sample_Id = WS.Weightometer_Sample_Id
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
				Sum(WS.Tonnes * WSG.Grade_Value)/ NULLIF(Sum(WS.Tonnes), 0) AS GradeValue
			FROM dbo.BhpbioSummaryEntry bse
				INNER JOIN dbo.Location l 
					ON l.Location_Id = bse.LocationId
				INNER JOIN @StockpileDelta AS SD
					ON (SD.LocationId = l.Location_Id)
				INNER JOIN dbo.WeightometerSample AS WS
					ON (WS.Weightometer_Sample_Id = SD.WeightometerSampleId)
				INNER JOIN dbo.WeightometerSampleGrade AS WSG
					ON (WSG.Weightometer_Sample_Id = WS.Weightometer_Sample_Id)
			WHERE	bse.SummaryId = @summaryId
					AND bse.SummaryEntryTypeId = @summaryGradesEntryTypeId
			GROUP BY bse.SummaryEntryId, WSG.Grade_Id
		END
		
		IF @isHubCrusher = 1
		BEGIN
		
			DECLARE @gradesAndTonnes TABLE
			(
				LocationId INT NOT NULL,
				GradeId INT NOT NULL,
				GradeValue FLOAT NULL,
				GradeTonnes FLOAT NULL
			);
			
			WITH GradesByLocationAndPeriod AS
			(
				SELECT WSG.Grade_Id, L.ParentLocationId, L.LocationId,
					SUM(WSV.Field_Value * WSG.Grade_Value) / NULLIF(SUM(WSV.Field_Value), 0) As GradeValue,
					NULLIF(SUM(WSV.Field_Value),0) AS SampleTonnes
				FROM dbo.WeightometerSample AS WS WITH (NOLOCK)
					INNER JOIN WeightometerSampleGrade AS WSG WITH (NOLOCK)
						ON (ws.Weightometer_Sample_Id = WSG.Weightometer_Sample_Id)
					INNER JOIN dbo.GetBhpbioWeightometerLocationWithOverride(@startOfMonth, @endOfMonth) AS wl
						ON (ws.Weightometer_Id = wl.Weightometer_Id)
						AND (ws.Weightometer_Sample_Date BETWEEN wl.IncludeStart AND wl.IncludeEnd)
					INNER JOIN @Location AS L
						ON (L.LocationId = wl.Location_Id)
						AND	(WS.Weightometer_Sample_Date BETWEEN L.[IncludeStart] AND L.IncludeEnd)
					INNER JOIN dbo.WeightometerSampleNotes AS WSN WITH (NOLOCK)
						ON (wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
							AND wsn.Weightometer_Sample_Field_Id = @SampleSourceField)
					INNER JOIN dbo.WeightometerSampleValue AS WSV WITH (NOLOCK)
						ON (wsv.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
							AND wsv.Weightometer_Sample_Field_Id = @SampleTonnesField)
					INNER JOIN dbo.GetBhpbioWeightometerSampleSource(@iSummaryLocationId, @startOfMonth, @endOfMonth) AS ss
						ON (dbo.GetDateMonth(ws.Weightometer_Sample_Date) = ss.MonthPeriod
						AND L.LocationId = ss.LocationId
							AND wsn.Notes = ss.SampleSource)
					INNER JOIN dbo.Location AS LL WITH (NOLOCK)
						ON (LL.Location_Id = L.LocationId)
					LEFT JOIN dbo.BhpbioLocationStockpileConfiguration AS BSLC WITH (NOLOCK)
						ON (BSLC.LocationId = L.LocationId)
					LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('PostCrusher') xs
						ON xs.StockpileId = WS.Source_Stockpile_Id
						OR xs.StockpileId = WS.Destination_Stockpile_Id
				WHERE (LL.Location_Type_Id = @HubLocationTypeId OR 
						(BSLC.PromoteStockpiles = 1 AND LL.Location_Type_Id = @SiteLocationTypeId))
					AND WS.Weightometer_Sample_Date BETWEEN @startOfMonth AND @endOfMonth
					AND xs.StockpileId IS NULL -- No movements to or from excluded groups.
				GROUP BY WSG.Grade_Id, L.ParentLocationId, L.LocationId
			)
			-- now weight the lower level locations to get values at the parent level
			-- this second round of weighting should be done on tonnes rather than sample tonnes
			-- (ie locations weighted against each other based on tonnes)
			INSERT INTO @gradesAndTonnes
			(
				LocationId,
				GradeId,
				GradeValue,
				GradeTonnes
			)
			SELECT 
				gblp.LocationId,
				gblp.Grade_Id,
				SUM(ABS(sd.Tonnes) * gblp.GradeValue) /	SUM(ABS(sd.Tonnes)) AS GradeValue,
				SUM(gblp.SampleTonnes)
			FROM GradesByLocationAndPeriod AS gblp
				INNER JOIN (SELECT LocationId,
								SUM(CASE WHEN Addition = 1 THEN Tonnes ELSE -Tonnes END) AS Tonnes
							FROM @StockpileDelta
							GROUP BY LocationId) AS sd
					ON sd.LocationId = gblp.LocationId
			WHERE ABS(sd.Tonnes) > 0
			GROUP BY gblp.LocationId, gblp.Grade_Id
			
			INSERT INTO dbo.BhpbioSummaryEntry
			(
				SummaryId,
				SummaryEntryTypeId,
				LocationId,
				MaterialTypeId,
				Tonnes
			)
			SELECT	DISTINCT -- there is one entry per grade Id, each with the same tonnes value.. in this case we just need the tonnes value
					@summaryId,
					@summaryGradesEntryTypeId,
					gt.LocationId,
					null,
					gt.GradeTonnes
			FROM @gradesAndTonnes gt
			
			INSERT INTO dbo.BhpbioSummaryEntryGrade
			(
				SummaryEntryId,
				GradeId,
				GradeValue
			)
			SELECT bse.SummaryEntryId,
				   gt.GradeId,
				   gt.GradeValue
			FROM @gradesAndTonnes gt
				INNER JOIN dbo.BhpbioSummaryEntry bse
					ON bse.SummaryId = @summaryId
					AND bse.SummaryEntryTypeId = @summaryGradesEntryTypeId
					AND bse.LocationId = gt.LocationId
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
exec dbo.SummariseBhpbioPostCrusherStockpileDelta
	@iSummaryMonth = '2009-11-01',
	@iLocationId = 3,
	'Hub'
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