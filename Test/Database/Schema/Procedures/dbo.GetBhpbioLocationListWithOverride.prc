IF OBJECT_ID('dbo.GetBhpbioLocationListWithOverride') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioLocationListWithOverride 
GO 
  
CREATE PROCEDURE dbo.GetBhpbioLocationListWithOverride
(
	@iLocationId INT,
	@iGetChildLocations BIT,
	@iStartDate DATETIME,
	@iEndDate DATETIME
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @lowestLocationTypeDescription varchar(255)
	
	IF (@iGetChildLocations = 1)
	BEGIN
		IF (@iLocationId = 0)
		BEGIN
			SET @iLocationId = -1
		END
	
		SET @lowestLocationTypeDescription =
		(
			SELECT lt2.Description
			FROM Location AS l
				INNER JOIN LocationType AS lt
					ON l.Location_Type_Id = lt.Location_Type_Id
				INNER JOIN LocationTYpe AS lt2
					ON lt.Location_Type_Id = lt2.Parent_Location_Type_Id
			WHERE l.Location_Id = @iLocationId
		)
		
		IF (@lowestLocationTypeDescription IS NULL)
		BEGIN
			SET @lowestLocationTypeDescription = ''
		END
	END
	ELSE
	BEGIN
		IF (@iLocationId = 0)
		BEGIN
			SET @iLocationId = (SELECT Location_Id FROM Location WHERE Parent_Location_Id IS NULL)
		END
		
		SET @lowestLocationTypeDescription =
		(
			SELECT lt.Description
			FROM Location AS l
				INNER JOIN LocationType AS lt
					ON l.Location_Type_Id = lt.Location_Type_Id
			WHERE l.Location_Id = @iLocationId
		)
	END

	SELECT l.Location_Id, l.Name, l.Location_Type_Id, lt.Description AS Location_Type_Description,
		ISNULL(bld.Parent_Location_Id, 0) AS Parent_Location_Id, l.Description,
		ISNULL(lt.Parent_Location_Type_Id, 0) AS Parent_Location_Type_Id
	FROM GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, @iGetChildLocations, @lowestLocationTypeDescription, @iStartDate, @iEndDate) AS bl
		INNER JOIN BhpbioLocationDate AS bld
			ON bl.LocationId = bld.Location_Id
			AND bl.IncludeStart BETWEEN bld.Start_Date AND bld.End_Date
		INNER JOIN Location AS l
			ON bld.Location_Id = l.Location_Id
		INNER JOIN LocationType AS lt
			ON l.Location_Type_Id = lt.Location_Type_Id
	ORDER BY l.Name
END 
GO

GRANT EXECUTE ON dbo.GetBhpbioLocationListWithOverride TO BhpbioGenericManager
GO
GRANT EXECUTE ON dbo.GetBhpbioLocationListWithOverride TO CoreUtilityManager
GO