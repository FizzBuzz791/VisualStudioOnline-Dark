IF OBJECT_ID('dbo.GetBhpbioReportDataHubPostCrusherStockpileDelta') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportDataHubPostCrusherStockpileDelta
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReportDataHubPostCrusherStockpileDelta
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iChildLocations BIT
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
		PRIMARY KEY (LocationId)
	)

	DECLARE @StockpileDelta TABLE
	(
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		StockpileId INT NOT NULL,
		WeightometerSampleId INT NOT NULL,
		Tonnes FLOAT NOT NULL,
		LocationId INT NULL,
		Addition BIT NOT NULL,
		ChildLocationId INT NULL,
		PRIMARY KEY (CalendarDate, StockpileId, WeightometerSampleId, Addition)
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
	SET @SampleSourceField = 'SampleSource'
	DECLARE @SampleTonnesField VARCHAR(31)
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
			(LocationId, ParentLocationId)
		SELECT LocationId, ParentLocationId
		FROM dbo.GetBhpbioReportLocationBreakdown(@iLocationId, @iChildLocations, 'Site')

		SELECT @HubLocationTypeId = Location_Type_Id
		FROM dbo.LocationType WITH (NOLOCK) 
		WHERE Description = 'Hub'
		SELECT @SiteLocationTypeId = Location_Type_Id
		FROM dbo.LocationType WITH (NOLOCK) 
		WHERE Description = 'Site'

		-- Get Removals
		INSERT INTO @StockpileDelta
			(CalendarDate, DateFrom, DateTo, StockpileId, WeightometerSampleId, Addition, Tonnes, LocationId, ChildLocationId)		
		SELECT CalendarDate, DateFrom, DateTo, S.Stockpile_Id, WS.Weightometer_Sample_Id, 0, WS.Tonnes, L.ParentLocationId, L.LocationId
		FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
			INNER JOIN dbo.WeightometerSample AS WS WITH (NOLOCK) 
				ON (WS.Weightometer_Sample_Date BETWEEN B.DateFrom AND B.DateTo)
			INNER JOIN dbo.Stockpile AS S WITH (NOLOCK)
				ON (S.Stockpile_Id = WS.Source_Stockpile_Id)
			INNER JOIN dbo.StockpileGroupStockpile AS SGS WITH (NOLOCK)
				ON (SGS.Stockpile_Id = S.Stockpile_Id)
			INNER JOIN dbo.StockpileLocation AS SL WITH (NOLOCK) 
				ON (SL.Stockpile_Id = S.Stockpile_Id)
			INNER JOIN @Location AS L
				ON (L.LocationId = SL.Location_Id)
			INNER JOIN dbo.Location AS LL WITH (NOLOCK)
				ON (LL.Location_Id = L.LocationId)
			LEFT JOIN dbo.BhpbioLocationStockpileConfiguration AS BSLC WITH (NOLOCK)
				ON (BSLC.LocationId = SL.Location_Id)
			LEFT JOIN dbo.StockpileGroupStockpile AS SGS_D WITH (NOLOCK)
				ON (SGS_D.Stockpile_Id = WS.Destination_Stockpile_Id
					AND SGS_D.Stockpile_Group_Id = @StockpileGroupId)
		WHERE Coalesce(WS.Source_Stockpile_Id, -1) <> Coalesce(WS.Destination_Stockpile_Id, -1)
			AND SGS.Stockpile_Group_Id = @StockpileGroupId
			AND SGS_D.Stockpile_Group_Id IS NULL -- Ensure join to check if destination is Post Crusher isn't true.
			AND (LL.Location_Type_Id = @HubLocationTypeId OR
			(BSLC.PromoteStockpiles = 1 AND LL.Location_Type_Id = @SiteLocationTypeId))

		-- Get Additions
		INSERT INTO @StockpileDelta
			(CalendarDate, DateFrom, DateTo, StockpileId, WeightometerSampleId, Addition, Tonnes, LocationId, ChildLocationId)		
		SELECT CalendarDate, DateFrom, DateTo, S.Stockpile_Id, WS.Weightometer_Sample_ID, 1, WS.Tonnes, L.ParentLocationId, L.LocationId
		FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
			INNER JOIN dbo.WeightometerSample AS WS WITH (NOLOCK)
				ON (WS.Weightometer_Sample_Date BETWEEN B.DateFrom AND B.DateTo)
			INNER JOIN dbo.Stockpile AS S WITH (NOLOCK)
				ON (S.Stockpile_Id = WS.Destination_Stockpile_Id)
			INNER JOIN dbo.StockpileGroupStockpile AS SGS WITH (NOLOCK)
				ON (SGS.Stockpile_Id = S.Stockpile_Id)
			INNER JOIN dbo.StockpileLocation AS SL WITH (NOLOCK)
				ON (SL.Stockpile_Id = S.Stockpile_Id)
			INNER JOIN @Location AS L
				ON (L.LocationId = SL.Location_Id)
			INNER JOIN dbo.Location AS LL WITH (NOLOCK)
				ON (LL.Location_Id = L.LocationId)
			LEFT JOIN dbo.BhpbioLocationStockpileConfiguration AS BSLC WITH (NOLOCK)
				ON (BSLC.LocationId = SL.Location_Id)
			LEFT JOIN dbo.StockpileGroupStockpile AS SGS_S WITH (NOLOCK)
				ON (SGS_S.Stockpile_Id = WS.Source_Stockpile_Id
					AND SGS_S.Stockpile_Group_Id = @StockpileGroupId)
		WHERE Coalesce(WS.Source_Stockpile_Id, -1) <> Coalesce(WS.Destination_Stockpile_Id, -1)
			AND SGS.Stockpile_Group_Id = @StockpileGroupId
			AND SGS_S.Stockpile_Group_Id IS NULL  -- Ensure join to check if source is Post Crusher isn't true.
			AND (LL.Location_Type_Id = @HubLocationTypeId OR 
			(BSLC.PromoteStockpiles = 1 AND LL.Location_Type_Id = @SiteLocationTypeId))
			
		-- Obtain the Delta tonnes
		SELECT SD.CalendarDate, SD.DateFrom, SD.DateTo, NULL AS MaterialTypeId, SD.LocationId AS ParentLocationId,
			Sum(CASE WHEN SD.Addition = 1 THEN SD.Tonnes ELSE -SD.Tonnes END) AS Tonnes
		FROM @StockpileDelta AS SD
		GROUP BY SD.CalendarDate, SD.DateFrom, SD.DateTo, SD.LocationId;
					
		-- calculate grade values by location and time period and select these for use in output query
		-- these grade values should be weighted based on sample tonnes for the location
		WITH RelevantWeightometerSamples AS
		(
			 -- get just the relevant weightometer samples for grade blending
			 -- these are those that match the required filtering and those that have notes with the required sample source
			SELECT WS.Weightometer_Sample_Id, dbo.GetDateMonth(ws.Weightometer_Sample_Date) As WeightometerSampleMonth,
				   L.ParentLocationId, L.LocationId
				FROM dbo.WeightometerSample AS WS WITH (NOLOCK)
					INNER JOIN dbo.WeightometerLocation AS WL WITH (NOLOCK)
						ON (ws.Weightometer_Id = wl.Weightometer_Id)
					INNER JOIN @Location AS L
						ON (L.LocationId = wl.Location_Id)
					INNER JOIN dbo.WeightometerSampleNotes AS WSN WITH (NOLOCK)
						ON (wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
							AND wsn.Weightometer_Sample_Field_Id = @SampleSourceField)
					INNER JOIN dbo.GetBhpbioWeightometerSampleSource(@iLocationId, @iDateFrom, @iDateTo) AS ss
						ON (ss.LocationId = WL.Location_Id
							AND ws.Weightometer_Sample_Date >= ss.MonthPeriod
							AND ws.Weightometer_Sample_Date < DateAdd(month,1,ss.MonthPeriod)
								AND wsn.Notes = ss.SampleSource)
					INNER JOIN dbo.Location AS LL WITH (NOLOCK)
						ON (LL.Location_Id = L.LocationId)
					LEFT JOIN dbo.BhpbioLocationStockpileConfiguration AS BSLC WITH (NOLOCK)
						ON (BSLC.LocationId = L.LocationId)
			WHERE WS.Weightometer_Sample_Date BETWEEN @iDateFrom AND @iDateTo
			AND (LL.Location_Type_Id = @HubLocationTypeId OR 
					(BSLC.PromoteStockpiles = 1 AND LL.Location_Type_Id = @SiteLocationTypeId))
		),
		GradesByLocationAndPeriod AS
		(
			SELECT B.CalendarDate, G.Grade_Name AS GradeName, WS.ParentLocationId, WS.LocationId, 
				sum(WSV.Field_Value * WSG.Grade_Value) / nullif(sum(WSV.Field_Value), 0) As GradeValue				
			FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
				INNER JOIN RelevantWeightometerSamples WS
					ON (WS.WeightometerSampleMonth BETWEEN B.DateFrom AND B.DateTo)
				INNER JOIN dbo.WeightometerSampleValue AS WSV WITH (NOLOCK)
					ON (wsv.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
						AND wsv.Weightometer_Sample_Field_Id = @SampleTonnesField)
				INNER JOIN WeightometerSampleGrade AS WSG WITH (NOLOCK)
					ON (ws.Weightometer_Sample_Id = WSG.Weightometer_Sample_Id)
				INNER JOIN Grade AS G WITH (NOLOCK)
					ON (G.Grade_Id = WSG.Grade_Id)
			GROUP BY B.CalendarDate, G.Grade_Name, WS.ParentLocationId, WS.LocationId
		)
		-- now weight the lower level locations to get values at the parent level
		-- this second round of weighting should be done on tonnes rather than sample tonnes
		-- (ie locations weighted against each other based on tonnes)
		SELECT gblp.CalendarDate, gblp.GradeName, NULL AS MaterialTypeId, gblp.ParentLocationId,
			SUM(gblp.GradeValue * sd.Tonnes) / NULLIF(SUM(sd.Tonnes), 0) AS GradeValue
		FROM GradesByLocationAndPeriod AS gblp
			-- innder join the temporary table summing all tones by location
			INNER JOIN (SELECT sd.CalendarDate, sd.ChildLocationId AS LocationId,
							ABS(SUM(CASE WHEN sd.Addition = 1 THEN sd.Tonnes ELSE -sd.Tonnes END)) AS Tonnes
						FROM @StockpileDelta sd
						GROUP BY sd.CalendarDate, sd.ChildLocationId) AS sd
				ON sd.LocationId = gblp.LocationId
				AND sd.CalendarDate = gblp.CalendarDate
		-- group by time period, grade and parent location level
		GROUP BY gblp.CalendarDate, gblp.GradeName, gblp.ParentLocationId

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

/*
exec dbo.GetBhpbioReportDataHubPostCrusherStockpileDelta 
@iDateFrom='2008-04-01 00:00:00',@iDateTo='2008-Jun-30 00:00:00',@iDateBreakdown=NULL,@iLocationId=1,@iChildLocations=0
*/