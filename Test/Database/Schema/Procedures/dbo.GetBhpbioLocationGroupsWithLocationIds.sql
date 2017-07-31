IF OBJECT_ID('dbo.GetBhpbioLocationGroupsWithLocationIds') IS NOT NULL 
     DROP PROCEDURE dbo.GetBhpbioLocationGroupsWithLocationIds 
GO 
  
CREATE PROCEDURE dbo.GetBhpbioLocationGroupsWithLocationIds
AS
BEGIN 
    SET NOCOUNT ON 
    
	select 
		lg.LocationGroupId,
		ParentLocationId,
		LocationGroupTypeName,
		Name,
		CreatedDate,
		LocationId 
	from [dbo].[BhpbioLocationGroup] lg
		inner join [dbo].[BhpbioLocationGroupLocation] lgl
			on lgl.LocationGroupId = lg.LocationGroupId

END 
GO 

GRANT EXECUTE ON dbo.GetBhpbioLocationGroupsWithLocationIds TO BhpbioGenericManager
Go