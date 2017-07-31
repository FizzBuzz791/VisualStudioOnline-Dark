IF OBJECT_ID('dbo.GetBhpbioLocationNameWithOverride') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioLocationNameWithOverride
GO 
  
CREATE PROCEDURE dbo.GetBhpbioLocationNameWithOverride
(
	@iLocationId INT,
	@iDateStart DATETIME,
	@iDateEnd DATETIME
)
AS
BEGIN
	SELECT	DISTINCT LO.LocationId AS Location_Id, L.Name, LT.[Description] AS Location_Type_Description 
	FROM	dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId,0,
			(	SELECT	lt.[Description] 
				FROM	locationtype lt 
				INNER JOIN location l ON lt.location_type_id = l.location_type_id
				WHERE	l.location_id=@iLocationId)
			, @iDateStart, @iDateEnd) LO
	INNER JOIN location L ON LO.LocationId = L.Location_Id
	INNER JOIN locationType LT ON L.Location_Type_Id = LT.Location_Type_Id
END
GO

GRANT EXECUTE ON dbo.GetBhpbioLocationNameWithOverride TO BhpbioGenericManager
GO
GRANT EXECUTE ON dbo.GetBhpbioLocationNameWithOverride TO CoreUtilityManager
GO
/*
declare @location int
set @location=12
exec getlocationlist null,null,@location
exec GetBhpbioLocationNameWithOverride @location,'01-JAN-1900','31-DEC-2012'
exec GetBhpbioLocationRoot @location
*/		