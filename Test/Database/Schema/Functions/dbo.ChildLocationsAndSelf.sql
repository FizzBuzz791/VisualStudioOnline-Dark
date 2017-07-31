IF OBJECT_ID('dbo.ChildLocationsAndSelf') IS NOT NULL
     DROP FUNCTION dbo.ChildLocationsAndSelf
GO 

--Get current and sub locations 
CREATE FUNCTION dbo.ChildLocationsAndSelf
(
	@iParentId INT,
	@iLowestLocationType INT
) 
RETURNS TABLE
AS
	RETURN
	WITH LOCATOR AS
	(
		SELECT Name, Location_Id, Location_Type_Id FROM Location 
			WHERE Location_Id=@iParentId

		UNION ALL

		SELECT L.Name, L.Location_Id, L.Location_Type_Id FROM Location L
			INNER JOIN LOCATOR LOC ON LOC.Location_Id=L.Parent_Location_Id
			WHERE L.Location_Type_Id<=@iLowestLocationType
	)
	SELECT * FROM LOCATOR
GO



--Execute example
--DECLARE @iLocationId INT;
--SET @iLocationId=1;
--SELECT * FROM  dbo.MyKids(@iLocationId,4)  ORDER BY Location_Type_Id
