IF Object_Id('dbo.GetBhpbioReportLocationBreakdownWithOverride') IS NOT NULL 
     DROP FUNCTION dbo.GetBhpbioReportLocationBreakdownWithOverride
GO

CREATE FUNCTION dbo.GetBhpbioReportLocationBreakdownWithOverride
(
	@iLocationId INT,
	@iGetChildLocations BIT,
	@iLowestLocationTypeDescription VARCHAR(31),
	@iDateFrom DATETIME,
	@iDateTo DATETIME
)
RETURNS @Location TABLE
(
	LocationId INT NOT NULL,
	ParentLocationId INT NULL,
	IncludeStart DATETIME,
	IncludeEnd DATETIME
)
AS
BEGIN
	-- effectively returns a Location Subtree
	-- if "GetChildLocations" = 0 then the returned ParentLocationId's are NOT resolved
	-- if         ""          = 1 then the returned ParentLocationId's ARE resolved

	DECLARE @LocationId INT
	DECLARE @CurrentLocationTypeId TINYINT
	DECLARE @NextLocationTypeId TINYINT
	DECLARE @CurrentLevel TINYINT
	DECLARE @LowestLevel TINYINT

	DECLARE @ParentLocation TABLE
	(
		LocationId INT NOT NULL,
		PRIMARY KEY (LocationId)
	)

	-- resolve the lowest location level we want to achieve
	SET @LowestLevel =
		(
			SELECT Location_Level
			FROM dbo.GetLocationTypeHierarchy(0) AS h
				INNER JOIN dbo.LocationType AS lt
					ON (h.Location_Type_Id = lt.Location_Type_Id)
			WHERE (@iLowestLocationTypeDescription IS NOT NULL AND lt.Description = @iLowestLocationTypeDescription)
				OR (@iLowestLocationTypeDescription IS NULL AND h.Bottom_In_Hierarchy = 1)
		)
	
	SET @LocationId = @iLocationId
	IF @LocationId <= 0 OR @LocationId IS NULL
	BEGIN
		SELECT @LocationId = Location_Id
		FROM dbo.Location
		WHERE Parent_Location_Id IS NULL
	END
	
	IF @iGetChildLocations = 1
	BEGIN
		INSERT INTO @ParentLocation
			(LocationId)
		SELECT Location_Id
		FROM dbo.Location AS L
		WHERE L.Parent_Location_Id = @LocationId
	END
	
	-- get initial seed location	
	INSERT INTO @Location
	SELECT	L.Location_Id, NULL, 
	  CASE WHEN L.Start_Date < @iDateFrom THEN @iDateFrom ELSE L.Start_Date END AS Include_Start,
	  CASE WHEN L.End_Date > @iDateTo THEN @iDateTo ELSE L.End_Date END AS Include_End
	FROM		BhpbioLocationDate L
	LEFT JOIN BhpbioLocationDate ParentHub 
	  ON ParentHub.Location_Id = L.Parent_Location_Id 
	  AND ParentHub.Location_type_Id = 2
	WHERE		L.Location_Id = @LocationId
	---------------------------------------------
	-- We may have more than one seed location if it has been overridden for a given time period to belong to a different parent (e.g. JB Site)
	-- Special clause here to ensure that 'sites' (i.e. under hubs) moved from one hub to another are only returned if the query from/to dates 
	-- fall within the override date range, therefore not allowing cross date boundary site reporting  
	AND (ParentHub.Location_Id IS NULL OR (@iDateFrom >= L.[Start_Date] AND @iDateTo <= L.[End_Date]))
	---------------------------------------------
	
	-- determine the initial location type for the loop
	SELECT @CurrentLocationTypeId = lt.Location_Type_Id
	FROM dbo.LocationType AS lt
	INNER JOIN Location AS l
			ON lt.Parent_Location_Type_Id = l.Location_Type_Id
	WHERE l.Location_Id = @LocationId

	-- determine the current location level
	SELECT @CurrentLevel = Location_Level
	FROM dbo.GetLocationTypeHierarchy(0)
	WHERE Location_Type_Id = @CurrentLocationTypeId

	-- at each level, add all child records
	WHILE (@CurrentLocationTypeId IS NOT NULL) AND (@CurrentLevel <= @LowestLevel)
	BEGIN
	    INSERT INTO @Location
	    
		  -- Child location dates within parent dates
		  SELECT	L.Location_Id, 
			CASE	WHEN PL2.LocationId IS NOT NULL THEN PL2.LocationId
					WHEN PL.ParentLocationId IS NOT NULL THEN PL.ParentLocationId
					ELSE NULL
			END,
			L.[Start_Date], L.End_Date
		  FROM		BhpbioLocationDate L
		  INNER JOIN @Location PL 
			  ON PL.LocationId = L.Parent_Location_Id
			  AND L.Start_Date >= PL.IncludeStart
			  AND L.End_Date <= PL.IncludeEnd
		  LEFT JOIN @ParentLocation AS PL2
              ON (PL2.LocationId = L.Location_Id)
		  WHERE L.Location_Type_Id = @CurrentLocationTypeId

		  UNION ALL

		  -- Child StartDate outside of Parent and EndDate within Parent range
		  SELECT	L.Location_Id, 
			CASE	WHEN PL2.LocationId IS NOT NULL THEN PL2.LocationId
					WHEN PL.ParentLocationId IS NOT NULL THEN PL.ParentLocationId
					ELSE NULL
			END,
			PL.IncludeStart, L.End_Date 
		  FROM		BhpbioLocationDate L
		  INNER JOIN @Location PL 
			ON PL.LocationId = L.Parent_Location_Id
			AND L.Start_Date < PL.IncludeStart
			AND L.End_Date BETWEEN PL.IncludeStart AND PL.IncludeEnd
		  LEFT JOIN @ParentLocation AS PL2
              ON (PL2.LocationId = L.Location_Id)
		  WHERE L.Location_Type_Id = @CurrentLocationTypeId

		  UNION ALL

		  -- Child StartDate within Parent Range and EndDate outside Parent range
		  SELECT	L.Location_Id, 
			CASE	WHEN PL2.LocationId IS NOT NULL THEN PL2.LocationId
					WHEN PL.ParentLocationId IS NOT NULL THEN PL.ParentLocationId
					ELSE NULL
			END,
			L.[Start_Date], PL.IncludeEnd
		  FROM		BhpbioLocationDate L
		  INNER JOIN @Location PL 
			  ON PL.LocationId = L.Parent_Location_Id
			  AND L.Start_Date BETWEEN PL.IncludeStart AND PL.IncludeEnd
			  AND L.End_Date > PL.IncludeEnd
		  LEFT JOIN @ParentLocation AS PL2
              ON (PL2.LocationId = L.Location_Id)
		  WHERE L.Location_Type_Id = @CurrentLocationTypeId

		  UNION ALL

		  -- Both Child StartDate and EndDate outside of Parent
		  SELECT	L.Location_Id, 
			CASE	WHEN PL2.LocationId IS NOT NULL THEN PL2.LocationId
					WHEN PL.ParentLocationId IS NOT NULL THEN PL.ParentLocationId
					ELSE NULL
			END,
			PL.IncludeStart, PL.IncludeEnd
		  FROM		BhpbioLocationDate L
		  INNER JOIN @Location PL 
			  ON PL.LocationId = L.Parent_Location_Id
			  AND L.Start_Date < PL.IncludeStart 
			  AND L.End_Date > PL.IncludeEnd
		  LEFT JOIN @ParentLocation AS PL2
              ON (PL2.LocationId = L.Location_Id)
		  WHERE L.Location_Type_Id = @CurrentLocationTypeId

		-- Advance to the next lowest location type id
		SET @NextLocationTypeId = NULL
		
		SELECT @NextLocationTypeId = LT.Location_Type_Id
		FROM dbo.LocationType AS PLT
			INNER JOIN dbo.LocationType AS LT
				ON (PLT.Location_Type_Id = LT.Parent_Location_Type_Id)
		WHERE PLT.Location_Type_Id = @CurrentLocationTypeId

		SET @CurrentLocationTypeId = @NextLocationTypeId
		SET @CurrentLevel = @CurrentLevel + 1
	END

	IF @iGetChildLocations = 1
	BEGIN
		DELETE
		FROM @Location
		WHERE LocationId = @LocationId
	END
	
	RETURN
END
GO

/*
SELECT * FROM dbo.GetBhpbioReportLocationBreakdown(12, 0, NULL)

SELECT * FROM dbo.GetBhpbioReportLocationBreakdown(24749, 0, 'SITE')
SELECT * FROM dbo.GetBhpbioReportLocationBreakdown(12, 0, 'SITE')
SELECT * FROM dbo.GetBhpbioReportLocationBreakdown(8, 0, 'SITE')
SELECT * FROM dbo.GetBhpbioReportLocationBreakdown(1, 0, 'SITE')
SELECT * FROM dbo.GetBhpbioReportLocationBreakdown(NULL, 0, 'SITE')

SELECT * FROM dbo.GetBhpbioReportLocationBreakdown(24749, 1, 'SITE')
SELECT * FROM dbo.GetBhpbioReportLocationBreakdown(12, 1, 'SITE')
SELECT * FROM dbo.GetBhpbioReportLocationBreakdown(8, 1, 'SITE')
SELECT * FROM dbo.GetBhpbioReportLocationBreakdown(1, 1, 'SITE')
SELECT * FROM dbo.GetBhpbioReportLocationBreakdown(NULL, 1, 'SITE')
*/



	

