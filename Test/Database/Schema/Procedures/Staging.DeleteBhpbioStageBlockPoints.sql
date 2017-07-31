IF OBJECT_ID('Staging.DeleteBhpbioStageBlockPoints') IS NOT NULL
     DROP PROCEDURE Staging.DeleteBhpbioStageBlockPoints
GO 
  
CREATE PROCEDURE Staging.DeleteBhpbioStageBlockPoints
(
	@iBlockId Integer
)
WITH ENCRYPTION
AS
BEGIN 

	SET NOCOUNT ON 
  
	BEGIN TRY
				
		-- delete the points
		DELETE p
		FROM Staging.StageBlockPoint p
		WHERE p.BlockId = @iBlockId 
		
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON Staging.DeleteBhpbioStageBlockPoints TO BhpbioGenericManager
GO