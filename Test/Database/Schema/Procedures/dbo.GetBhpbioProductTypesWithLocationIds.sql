IF OBJECT_ID('dbo.GetBhpbioProductTypesWithLocationIds') IS NOT NULL 
     DROP PROCEDURE dbo.GetBhpbioProductTypesWithLocationIds 
GO 
  
CREATE PROCEDURE dbo.GetBhpbioProductTypesWithLocationIds
AS
BEGIN 
    SET NOCOUNT ON 
    
	SELECT
		p.ProductTypeId,
		p.ProductTypeCode,
		p.Description,
		p.ProductSize,
		l.LocationId
	FROM BhpbioProductTypelocation l
		inner join BhpbioProductType p on p.ProductTypeId = l.ProductTypeId

END 
GO 
GRANT EXECUTE ON dbo.GetBhpbioProductTypesWithLocationIds TO BhpbioGenericManager
