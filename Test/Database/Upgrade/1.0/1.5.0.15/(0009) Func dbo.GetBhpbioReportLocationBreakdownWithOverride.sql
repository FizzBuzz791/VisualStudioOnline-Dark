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
	--PRIMARY KEY CLUSTERED (LocationId)
)
AS
BEGIN

	-- effectively returns a Location Subtree
	-- if "GetChildLocations" = 0 then the returned ParentLocationId's are NOT resolved
	-- if         ""          = 1 then the returned ParentLocationId's ARE resolved
	
	DECLARE @LocationId INT
	DECLARE @LowestLevel TINYINT
	DECLARE @BreakDownLocationTypeId TINYINT

	-- resolve the lowest location level we want to achieve
	SET @LowestLevel =
		(
			SELECT	Location_Level
			FROM	dbo.GetLocationTypeHierarchy(0) AS h
				INNER JOIN dbo.LocationType AS lt ON (h.Location_Type_Id = lt.Location_Type_Id)
			WHERE	(@iLowestLocationTypeDescription IS NOT NULL AND lt.Description = @iLowestLocationTypeDescription)
			OR		(@iLowestLocationTypeDescription IS NULL AND h.Bottom_In_Hierarchy = 1)
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
		SELECT @BreakDownLocationTypeId = LT.Location_Type_Id
		FROM dbo.Location AS L
			INNER JOIN dbo.LocationType AS LT
				ON (L.Location_Type_Id = LT.Parent_Location_Type_Id)
		WHERE L.Location_Id = @LocationId
	END
/**/
	;WITH ParentLocation (Location_Id, Location_Type_Id, TopMost_Location_Id, [Start_Date], End_Date, Parent_Location_Id, Is_Override, Child_Parent_Id)--, TopMostName)
	AS
	(     
		  SELECT	L.Location_Id, L.Location_Type_Id, L.Location_Id, L.[Start_Date], L.End_Date, L.Parent_Location_Id
		  ,			Is_Override
		  ,			CASE WHEN L.Parent_Location_Id = @LocationId THEN L.Location_Id ELSE L.Parent_Location_Id END Child_Parent_Id
		  FROM		BhpbioLocationDate L
		  WHERE		L.Location_Id = @LocationId

		  UNION ALL

		  -- Child dates within parent dates
		  SELECT	L.Location_Id, L.Location_Type_Id, PL.TopMost_Location_Id
		  ,			L.[Start_Date]
		  ,			L.End_Date
		  ,			L.Parent_Location_Id
		  ,			CASE WHEN L.Is_Override = 1 THEN L.Is_Override ELSE PL.Is_Override END
		  ,			CASE WHEN L.Parent_Location_Id = @LocationId THEN L.Location_Id ELSE PL.Child_Parent_Id END Child_Parent_Id
		  FROM		BhpbioLocationDate L
		  INNER JOIN ParentLocation PL 
			ON PL.Location_Id = L.Parent_Location_Id
			AND L.Start_Date >= PL.Start_Date
			AND L.End_Date <= PL.End_Date

		  UNION ALL

		  -- Child StartDate outside of Parent and EndDate within Parent range
		  SELECT	L.Location_Id, L.Location_Type_Id, PL.TopMost_Location_Id
		  ,			PL.[Start_Date]
		  ,			L.End_Date 
		  ,			L.Parent_Location_Id
		  ,			CASE WHEN L.Is_Override = 1 THEN L.Is_Override ELSE PL.Is_Override END
		  ,			CASE WHEN L.Parent_Location_Id = @LocationId THEN L.Location_Id ELSE PL.Child_Parent_Id END Child_Parent_Id
		  FROM		BhpbioLocationDate L
		  INNER JOIN ParentLocation PL 
			ON PL.Location_Id = L.Parent_Location_Id
			AND L.Start_Date < PL.Start_Date
			AND L.End_Date BETWEEN PL.Start_Date AND PL.End_Date

		  UNION ALL

		  -- Child StartDate within Parent Range and EndDate outside Parent range
		  SELECT	L.Location_Id, L.Location_Type_Id, PL.TopMost_Location_Id
		  ,			L.[Start_Date]
		  ,			PL.End_Date
		  ,			L.Parent_Location_Id
		  ,			CASE WHEN L.Is_Override = 1 THEN L.Is_Override ELSE PL.Is_Override END
		  ,			CASE WHEN L.Parent_Location_Id = @LocationId THEN L.Location_Id ELSE PL.Child_Parent_Id END Child_Parent_Id
		  FROM		BhpbioLocationDate L
		  INNER JOIN ParentLocation PL 
			ON PL.Location_Id = L.Parent_Location_Id
			AND L.Start_Date BETWEEN PL.Start_Date AND PL.End_Date
			AND L.End_Date > PL.End_Date

		  UNION ALL

		  -- Both Child StartDate and EndDate outside of Parent
		  SELECT	L.Location_Id, L.Location_Type_Id, PL.TopMost_Location_Id
		  ,			PL.[Start_Date]
		  ,			PL.End_Date
		  ,			L.Parent_Location_Id
		  ,			CASE WHEN L.Is_Override = 1 THEN L.Is_Override ELSE PL.Is_Override END
		  ,			CASE WHEN L.Parent_Location_Id = @LocationId THEN L.Location_Id ELSE PL.Child_Parent_Id END Child_Parent_Id
		  FROM		BhpbioLocationDate L
		  INNER JOIN ParentLocation PL 
			ON PL.Location_Id = L.Parent_Location_Id
			AND L.Start_Date < PL.Start_Date 
			AND L.End_Date > PL.End_Date
	) 

	INSERT INTO @Location    
	SELECT	Location_Id,Child_Parent_Id    --Parent_Location_Id
	,		CASE WHEN [Start_Date] < @iDateFrom THEN @iDateFrom ELSE [Start_Date] END [Include_Start]
	,		CASE WHEN End_Date > @iDateTo THEN @iDateTo ELSE End_Date END [Include_End]
	FROM	ParentLocation
	WHERE	([Start_Date] BETWEEN @iDateFrom AND @iDateTo
				OR End_Date BETWEEN @iDateFrom AND @iDateTo
				OR ([Start_Date] < @iDateFrom AND End_Date >@iDateTo))
	AND		Location_Type_Id <= @LowestLevel + 1

	IF @iGetChildLocations = 1
	BEGIN
		DELETE
		FROM @Location
		WHERE LocationId = @LocationId

		DELETE
		FROM @Location
		WHERE ParentLocationId IS NULL
	END
	ELSE
		UPDATE @Location SET ParentLocationId = NULL
	
	RETURN
END
GO

/*
select * from bhpbiolocationdate where period_order !=0 order by 1,2

select * from bhpbiolocationoverride
select * from bhpbiolocationdate where location_id = 77244
select * from location where parent_location_id=12
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
select * from 

SELECT * FROM dbo.GetBhpbioReportLocationBreakdown(12, 0, 'PIT')
SELECT * FROM dbo.GetBhpbioReportLocationBreakdown(12, 1, 'BLOCK')
SELECT * FROM dbo.GetBhpbioReportLocationBreakdown(1, 1, 'PIT')

SELECT * FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(12, 0, 'PIT','2012-08-01')

SELECT * FROM dbo.GetBhpbioReportLocationBreakdown(1, 1, 'PIT')
SELECT * FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(1, 01, 'PIT','2013-08-01')

SELECT * FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(1, 01, 'PIT','2012-08-01','2012-08-31')
SELECT * FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(1, 01, NULL,'2012-08-01','2012-08-31')

exec dbo.GetBhpbioReportLocationBreakdownWithOverride 12, 0, 'PIT','2012-08-01','2012-08-31'
select * from dbo.GetLocationSubtree(12) --gives me children + self
select * from dbo.GetLocationChildLocationList(12) -- gives me children

select * from dbo.GetBhpbioReportLocation(12) -- gives me children + self
exec GetBhpbioReportLocationBreakdownWithOverride 12,0,null,'2012-08-01','2012-09-01'
select * from digblocklocation
*/

