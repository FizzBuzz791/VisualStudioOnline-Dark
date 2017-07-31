IF OBJECT_ID('dbo.GetBhpbioLocationGroup') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioLocationGroup
GO 
  
CREATE PROCEDURE dbo.GetBhpbioLocationGroup
(
	@iLocationGroupId	INT
)
AS 
BEGIN 
	SELECT * FROM [dbo].[BhpbioLocationGroup] lg WHERE lg.LocationGroupId=@iLocationGroupId
END 
GO

GRANT EXECUTE ON dbo.GetBhpbioLocationGroup TO BhpbioGenericManager
GO
