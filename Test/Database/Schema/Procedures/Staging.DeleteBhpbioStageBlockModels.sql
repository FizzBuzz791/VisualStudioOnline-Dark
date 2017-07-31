IF OBJECT_ID('Staging.DeleteBhpbioStageBlockModels') IS NOT NULL
     DROP PROCEDURE Staging.DeleteBhpbioStageBlockModels
GO 
  
CREATE PROCEDURE Staging.DeleteBhpbioStageBlockModels
(
	@iBlockId Integer,
	@iModelName VARCHAR(31)
)
WITH ENCRYPTION
AS
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	BEGIN TRY
		
		-- delete the RC data
		DELETE rc
		FROM Staging.StageBlockModel m
			INNER JOIN Staging.StageBlockModelResourceClassification rc
				ON rc.BlockModelId = m.BlockModelId
		WHERE m.BlockId = @iBlockId 
			AND m.BlockModelName = @iModelName

		-- delete the grades
		DELETE g
		FROM Staging.StageBlockModel m
			INNER JOIN Staging.StageBlockModelGrade g 
				ON g.BlockModelId = m.BlockModelId
		WHERE m.BlockId = @iBlockId 
			AND m.BlockModelName = @iModelName
				
		-- delete the models
		DELETE m
		FROM Staging.StageBlockModel m
		WHERE m.BlockId = @iBlockId 
			AND m.BlockModelName = @iModelName
		
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON Staging.DeleteBhpbioStageBlockModels TO BhpbioGenericManager
GO