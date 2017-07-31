IF OBJECT_ID('dbo.GetBhpbioLocationParentHeirarchyWithOverride') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioLocationParentHeirarchyWithOverride 
GO 
  
CREATE PROCEDURE dbo.GetBhpbioLocationParentHeirarchyWithOverride
(
 	@iLocationId INT,
	@iStartDate DATETIME,
	@iEndDate DATETIME
)
WITH ENCRYPTION
AS 
BEGIN
	DECLARE @topLocationId INT
	
	SET @topLocationId =
	(
		SELECT Location_Id
		FROM dbo.BhpbioLocationDate
		WHERE @iStartDate BETWEEN Start_Date AND End_Date
			AND Location_Type_Id = 1
	)

	DECLARE @locations TABLE
	(
		LocationId INT NOT NULL,
		LocationTypeId TINYINT NOT NULL,
		Name VARCHAR(31) NOT NULL,
		LocationTypeDescription VARCHAR(255) NOT NULL,
		ParentLocationId INT NOT NULL,
		Description VARCHAR(255) NOT NULL,
		ParentLocationTypeId TINYINT NOT NULL
	)

	INSERT INTO @locations
	SELECT l.Location_Id, l.Location_Type_Id, l.Name, lt.Description AS Location_Type_Description,
		ISNULL(bld.Parent_Location_Id, 0) AS Parent_Location_Id, l.Description,
		ISNULL(lt.Parent_Location_Type_Id, 0) AS Parent_Location_Type_Id
	FROM GetBhpbioReportLocationBreakdownWithOverride(@topLocationId, 0, 'PIT', @iStartDate, @iEndDate) AS bl
		INNER JOIN BhpbioLocationDate AS bld
			ON bl.LocationId = bld.Location_Id
			AND bl.IncludeStart BETWEEN bld.Start_Date AND bld.End_Date
		INNER JOIN Location AS l
			ON bld.Location_Id = l.Location_Id
		INNER JOIN LocationType AS lt
			ON l.Location_Type_Id = lt.Location_Type_Id

	DECLARE @heirarchy TABLE
	(
		LocationId INT,
		LocationTypeId TINYINT,
		Name VARCHAR(255),
		Order_No INT Identity(1, 1)
	)

	DECLARE @LocationId INT
	
	 --This query is inclusive but make sure it exists
	SELECT @LocationId = @iLocationId
	FROM @locations
	WHERE LocationId = @iLocationId

	WHILE @LocationId != 0
	BEGIN
		-- Insert this parent location
		INSERT INTO @heirarchy
		(
			LocationId, LocationTypeId, Name
		)
		SELECT LocationId, LocationTypeId, Name
		FROM @locations
		WHERE LocationId = @LocationId	

		SELECT @LocationId = ParentLocationId
		FROM @locations
		WHERE LocationId = @LocationId
	End

	SELECT h.LocationId AS Location_Id, h.LocationTypeId AS Location_Type_Id, h.Name, lt.Description AS Location_Type_Description
	, h.Order_No
	FROM @heirarchy AS h
		INNER JOIN dbo.LocationType AS lt
			ON h.LocationTypeId = lt.Location_Type_Id
	ORDER BY Order_No DESC
END 
GO

GRANT EXECUTE ON dbo.GetBhpbioLocationParentHeirarchyWithOverride TO BhpbioGenericManager
GO
GRANT EXECUTE ON dbo.GetBhpbioLocationParentHeirarchyWithOverride TO CoreUtilityManager
GO