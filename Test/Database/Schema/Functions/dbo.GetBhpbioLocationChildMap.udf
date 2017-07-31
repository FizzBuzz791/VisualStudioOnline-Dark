IF OBJECT_ID('dbo.GetBhpbioLocationChildMap') IS NOT NULL 
     DROP FUNCTION dbo.GetBhpbioLocationChildMap
GO 

CREATE FUNCTION dbo.GetBhpbioLocationChildMap
(
	@dateTime DATETIME,
	@iLocationId INT,
	@iLocationTypeId INT
)
RETURNS @LocationMap TABLE
(
	LocationId INT NOT NULL,
	ChildLocationId INT NOT NULL
	PRIMARY KEY (LocationId, ChildLocationId)
)
BEGIN
	-- Find locations at the specified Level OR above this level where they have no children
	DECLARE @locationsAtLevel Table (Location_Id INT)

	INSERT INTO @locationsAtLevel
	SELECT l.Location_Id 
	FROM BhpbioLocationDate l
	WHERE @dateTime BETWEEN l.Start_Date and l.End_Date
		AND (@iLocationId IS NULL OR l.Location_Id = @iLocationId)
		AND
		  (
			l.Location_Type_Id = @iLocationTypeId
			OR (
					l.Location_Type_Id IN (SELECT Location_Type_Id FROM dbo.GetLocationTypeParentLocationTypeList(@iLocationTypeId))
					AND Not Exists (SELECT * FROM BhpbioLocationDate cl 
									WHERE  cl.Parent_Location_Id = l.Location_Id
										AND @dateTime BETWEEN cl.Start_Date and cl.End_Date)
				)
			)
	
	;
	With LocationMap as
	(
		SELECT lal.Location_Id as LocationId, lal.Location_Id as ChildLocationId
		FROM @locationsAtLevel lal
		
		UNION ALL
		
		SELECT l.Parent_Location_Id, l.Location_ID
		FROM BhpbioLocationDate l
			INNER JOIN @locationsAtLevel lal ON lal.Location_Id = l.Location_Id
		WHERE @dateTime BETWEEN l.Start_Date and l.End_Date
		
		UNION ALL
		
		SELECT l2.Parent_Location_Id, lm.ChildLocationId
		FROM BhpbioLocationDate l2
			INNER JOIN LocationMap lm ON lm.LocationId = l2.Location_Id
		WHERE 
			@dateTime BETWEEN l2.Start_Date and l2.End_Date
			AND l2.Parent_Location_Id IS NOT NULL
			AND lm.LocationId <> lm.ChildLocationId
	)
	INSERT INTO @LocationMap
	SELECT m.LocationId, m.ChildLocationId
	FROM LocationMap m
	ORDER BY 1,2
	
	RETURN
END
GO

/*
<TAG Name="Data Dictionary" FunctionName="GetBhpbioLocationChildMap">
 <Function>
	Returns a map of child locations and a row for each of it's parents. Child locations are determined by 
	the lowest location type provided or if the location has no children. Location parameter can filter out 
	locations not to be included.
 </Function>
</TAG>
*/

--
--select Count(1) from dbo.GetBhpbioLocationChildMap(null, null)