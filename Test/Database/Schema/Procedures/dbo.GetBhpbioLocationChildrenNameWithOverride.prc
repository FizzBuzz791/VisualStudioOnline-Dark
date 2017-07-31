IF OBJECT_ID('dbo.GetBhpbioLocationChildrenNameWithOverride') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioLocationChildrenNameWithOverride
GO 
  
CREATE PROCEDURE dbo.GetBhpbioLocationChildrenNameWithOverride
(
	@iLocationId INT,
	@iDateStart DATETIME,
	@iDateEnd DATETIME
)
AS
BEGIN
	SELECT	DISTINCT LO.LocationId AS Location_Id, L.Name, LT.[Description] AS Location_Type_Description 
	FROM	dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId,1,
			(	SELECT	lt.[Description] 
				FROM	locationtype lt 
				INNER JOIN location l ON lt.location_type_id = l.location_type_id + 1
				WHERE	l.location_id=@iLocationId)
			, @iDateStart, @iDateEnd) LO
	INNER JOIN location L ON LO.LocationId = L.Location_Id
	INNER JOIN locationType LT ON L.Location_Type_Id = LT.Location_Type_Id
	ORDER BY L.Name
END
GO

GRANT EXECUTE ON dbo.GetBhpbioLocationChildrenNameWithOverride TO BhpbioGenericManager
GO
GRANT EXECUTE ON dbo.GetBhpbioLocationChildrenNameWithOverride TO CoreUtilityManager
GO
/*
declare @location int
set @location=1
exec getlocationlist null,@location,null,null,1
exec GetBhpbioLocationRoot @location
exec GetBhpbioLocationChildrenNameWithOverride @location,'01-JAN-1900','31-DEC-2012'
*/		
