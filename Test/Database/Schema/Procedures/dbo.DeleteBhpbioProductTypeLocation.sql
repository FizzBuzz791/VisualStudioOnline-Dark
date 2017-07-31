

IF OBJECT_ID('dbo.DeleteBhpbioProductTypeLocation') IS NOT NULL 
     DROP PROCEDURE dbo.DeleteBhpbioProductTypeLocation 
GO 
  
CREATE PROCEDURE dbo.DeleteBhpbioProductTypeLocation
( 
	@iProductTypeId int,
	@iLocationId int = null
) 
AS
BEGIN 
    SET NOCOUNT ON 
		IF @iLocationId is null -- Comes from the DefaultProductTypeDelete (DataGrid) Screen 
		BEGIN
			DELETE FROM [dbo].[BhpbioProductTypeLocation] WHERE
			ProductTypeId = @iProductTypeId 

			DELETE FROM [dbo].[BhpbioProductType] WHERE
			ProductTypeId = @iProductTypeId 
		END
	
END 
GO 
GRANT EXECUTE ON dbo.DeleteBhpbioProductTypeLocation TO BhpbioGenericManager
 
GO












		