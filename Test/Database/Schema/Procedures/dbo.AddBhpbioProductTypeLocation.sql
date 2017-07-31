IF OBJECT_ID('dbo.AddBhpbioProductTypeLocation') IS NOT NULL 
     DROP PROCEDURE dbo.AddBhpbioProductTypeLocation 
GO 
  
CREATE PROCEDURE dbo.AddBhpbioProductTypeLocation
( 
	@iProductTypeId int,
	@iLocationId int
) 
AS
BEGIN 
    SET NOCOUNT ON 
	
		INSERT INTO [dbo].[BhpbioProductTypeLocation]
			   (ProductTypeId
			   ,LocationId)
		 VALUES (
		 @iProductTypeId , @iLocationId)
	
END 
GO 
GRANT EXECUTE ON dbo.AddBhpbioProductTypeLocation TO BhpbioGenericManager
 
GO