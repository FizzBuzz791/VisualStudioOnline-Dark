IF OBJECT_ID('dbo.GetBhpbioSiblingLocations') IS NOT NULL 
     DROP PROCEDURE dbo.GetBhpbioSiblingLocations 
GO 

CREATE PROCEDURE dbo.GetBhpbioSiblingLocations
	@iLocationId	INT,
	@iLocationDate	DATE
AS
	BEGIN
		DECLARE	@locationType	INT
		DECLARE @parentLocation INT
	
		SELECT @parentLocation = Parent_Location_Id
		FROM Location
		WHERE Location_Id = @iLocationId

		IF @parentLocation IS NULL
			-- This is for the WAIO edge case
			SELECT L.Location_Id, L.Name, L.Location_Type_Id, LT.Description AS Location_Type_Description, L.Parent_Location_Id, NULL AS Description, NULL AS Parent_Location_Type_Id
			FROM Location L
			INNER JOIN LocationType LT ON LT.Location_Type_Id = L.Location_Type_Id
			WHERE L.Location_Id = @iLocationId
		ELSE
			EXEC GetBhpbioLocationListWithOverride @parentLocation, 1, @iLocationDate, @iLocationDate
	END
GO

GRANT EXECUTE ON dbo.GetBhpbioSiblingLocations TO BhpbioGenericManager
GO