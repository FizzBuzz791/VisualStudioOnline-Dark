  IF OBJECT_ID('Staging.AddBhpbioStageBlockPoint') IS NOT NULL
     DROP PROCEDURE Staging.AddBhpbioStageBlockPoint
GO 
  
CREATE PROCEDURE Staging.AddBhpbioStageBlockPoint
(
	@iBlockId INTEGER,
	@iX FLOAT,
	@iY FLOAT,
	@iZ FLOAT,
	@iPointNumber INTEGER

)
WITH ENCRYPTION
AS
BEGIN 
	SET NOCOUNT ON 

	BEGIN TRY
		-- add the Block Point
		INSERT INTO Staging.StageBlockPoint
			(BlockId, Number, X, Y, Z)
		VALUES(@iBlockId, @iPointNumber, @iX, @iY, @iZ)
		
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON Staging.AddBhpbioStageBlockPoint TO BhpbioGenericManager
GO