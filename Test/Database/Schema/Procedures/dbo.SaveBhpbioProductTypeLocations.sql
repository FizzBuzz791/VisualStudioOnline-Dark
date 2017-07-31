IF OBJECT_ID('dbo.SaveBhpbioProductTypeLocations') IS NOT NULL 
     DROP PROCEDURE dbo.SaveBhpbioProductTypeLocations 
GO 
  
CREATE PROCEDURE dbo.SaveBhpbioProductTypeLocations
( 
	@iProductTypeId INT,
	@iCode nvarchar(50) = null ,
	@iDescription nvarchar(150) =null,
	@iProductSize nvarchar(50) =null,
	@oProductTypeId INT OUTPUT  
) 
AS
BEGIN 
    SET NOCOUNT ON 
		IF @iProductTypeId = 0  -- Add New
		BEGIN
			INSERT INTO BhpbioProductType (ProductTypeCode, [Description], ProductSize) VALUES
			(@iCode,@iDescription,@iProductSize)
			
			set @oProductTypeId = Scope_Identity()
			return @oProductTypeId
		END
		ELSE
		BEGIN
			-- Clear all the locations
			DELETE FROM BhpbioProductTypelocation WHERE ProductTypeID = @iProductTypeId
		
			UPDATE 	BhpbioProductType SET 
				ProductTypeCode = @iCode ,
				[Description] = @iDescription,
				ProductSize = @iProductSize 
					WHERE ProductTypeID = @iProductTypeId
		END

		SET @oProductTypeId = @iProductTypeId
END 
GO 
GRANT EXECUTE ON dbo.SaveBhpbioProductTypeLocations TO BhpbioGenericManager