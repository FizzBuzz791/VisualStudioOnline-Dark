IF OBJECT_ID('Staging.DeleteBlockModelResourceClassification') IS NOT NULL
     DROP PROCEDURE Staging.DeleteBlockModelResourceClassification
GO 
  
CREATE PROCEDURE Staging.DeleteBlockModelResourceClassification
(
	@iBlockModelId Int,
	@iResourceClassification Varchar(32)
)
WITH ENCRYPTION
AS
BEGIN 

	SET NOCOUNT ON 
  
	BEGIN TRY
		
		DELETE p
		FROM Staging.StageBlockModelResourceClassification p
		WHERE p.BlockModelId = @iBlockModelId 
			AND p.ResourceClassification = @iResourceClassification
		
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON Staging.DeleteBlockModelResourceClassification TO BhpbioGenericManager
GO