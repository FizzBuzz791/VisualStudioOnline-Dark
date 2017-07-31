IF OBJECT_ID('dbo.DeleteBhpbioReconciliationMovementStage') IS NOT NULL
     DROP PROCEDURE dbo.DeleteBhpbioReconciliationMovementStage  
GO 
  
CREATE PROCEDURE dbo.DeleteBhpbioReconciliationMovementStage
AS 
BEGIN 
	SET NOCOUNT ON 

	BEGIN TRY
		DELETE
		FROM dbo.BhpbioImportReconciliationMovementStage
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON dbo.DeleteBhpbioReconciliationMovementStage TO BhpbioGenericManager
GO
