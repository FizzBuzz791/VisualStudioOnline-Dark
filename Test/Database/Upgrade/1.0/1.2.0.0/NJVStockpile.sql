DECLARE @StockpileGroupOrder INT

SET @StockpileGroupOrder = (SELECT MAX(Order_No) + 1
							FROM StockpileGroup)

EXEC dbo.AddStockpileGroup
	@iStockpile_Group_Id = 'HUB Train Rake',
	@iDescription = 'Train Rake Stockpiles that represent material coming from site and going to a hub',
	@iOrder_No = @StockpileGroupOrder

-----
-- TRAIN RAKE LOADING

DECLARE @SystemStartDate DATETIME
DECLARE @StockpileId INT
DECLARE @BuildId INT
DECLARE @ComponentId INT
DECLARE @MaterialTypeId INT

DECLARE @TrainRakeCursor CURSOR
DECLARE @StockpileName VARCHAR(31)
DECLARE @SiteName VARCHAR(31)
DECLARE @StockpileGroup VARCHAR(31)
DECLARE @GradeCursor CURSOR
DECLARE @GradeId INT

DECLARE @TrainRake TABLE
(
	StockpileName VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
	SiteName VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
	StockpileGroup VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL
)

BEGIN TRANSACTION

-- create the train rake list
INSERT INTO @TrainRake
	(StockpileName, SiteName, StockpileGroup)
SELECT 'NJV Train Rake', 'NJV', 'Port Train Rake'
UNION ALL
SELECT 'NJV Hub Feed Train Rake', 'NJV', 'HUB Train Rake'

-- insert the train rakes
SELECT @SystemStartDate = CAST(Value AS DATETIME)
FROM dbo.Setting
WHERE Setting_Id = 'SYSTEM_START_DATE'

SET @MaterialTypeId =
	(
		SELECT mt.Material_Type_Id
		FROM dbo.MaterialType AS mt
			INNER JOIN dbo.MaterialTypeGroup AS mtg
				ON (mt.Material_Type_Group_Id = mtg.Material_Type_Group_Id)
		WHERE mt.Abbreviation = 'Ore'
			AND mtg.Name = 'Default'
	)

SET @TrainRakeCursor = CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
	SELECT StockpileName, SiteName, StockpileGroup
	FROM @TrainRake

SET @GradeCursor = CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
	SELECT Grade_Id
	FROM dbo.Grade

OPEN @TrainRakeCursor
FETCH NEXT FROM @TrainRakeCursor INTO @StockpileName, @SiteName, @StockpileGroup

WHILE @@FETCH_STATUS = 0
BEGIN
	-- add the stockpile
	EXEC dbo.AddStockpile
		@iStockpile_Name = @StockpileName,
		@iDescription = @StockpileName,
		@iStart_Date = @SystemStartDate,
		@iIs_Multi_Build = 0,
		@iIs_Multi_Component = 0,
		@iStockpile_Type_Id = 'Average',
		@iMaterial_Type_Id = @MaterialTypeId,
		@iIs_In_Reports	= 0,
		@iMax_Tonnes = NULL,
		@iIs_Visible = 0,
		@iHaulage_Raw_Resolve_All = 0,
		@iReclaim_Start_Date = NULL,
		@iReclaim_Start_Shift = NULL,
		@iEnd_Date = NULL,
		@iEnd_Shift = NULL,
		@iCompletion_Description = NULL,
		@iStockpile_State_Id = 'Normal',
		@iNotes = NULL,
		@iOpening_Tonnes = 0.0,
		@oStockpile_Id = @StockpileId OUTPUT,
		@oBuild_Id = @BuildId OUTPUT,
		@oComponent_Id = @ComponentId OUTPUT

	-- add the grades
	OPEN @GradeCursor
	FETCH NEXT FROM @GradeCursor INTO @GradeId
	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC dbo.AddOrUpdateStockpileBuildComponentGrade
			@iStockpile_Id = @StockpileId,
			@iBuild_Id = @BuildId,
			@iComponent_Id = @ComponentId,
			@iGrade_Id = @GradeId,
			@iGrade_Value = 0
			
		FETCH NEXT FROM @GradeCursor INTO @GradeId
	END
	CLOSE @GradeCursor

	-- add the stockpile location
	INSERT INTO dbo.StockpileLocation
	(
		Stockpile_Id, Location_Id, Location_Type_Id
	)
	SELECT @StockpileId, l.Location_Id, l.Location_Type_Id
	FROM dbo.Location AS l
		INNER JOIN dbo.LocationType AS lt
			ON (l.Location_Type_Id = lt.Location_Type_Id)
	WHERE l.Name = @SiteName
		AND lt.Description = 'Hub'

	-- add to the relevant group
	INSERT INTO dbo.StockpileGroupStockpile
	(
		Stockpile_Group_Id, Stockpile_Id
	)
	SELECT @StockpileGroup, @StockpileId
	
	FETCH NEXT FROM @TrainRakeCursor INTO @StockpileName, @SiteName, @StockpileGroup
END

CLOSE @TrainRakeCursor

COMMIT TRANSACTION
GO
