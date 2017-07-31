IF OBJECT_ID('Staging.AddBhpbioStageBlockModelGrade') IS NOT NULL
     DROP PROCEDURE Staging.AddBhpbioStageBlockModelGrade
GO 
  
CREATE PROCEDURE Staging.AddBhpbioStageBlockModelGrade
(
	@iBlockModelId INTEGER,
	@iGeometType [varchar](15),
	@iGradeName VARCHAR(31),
	@iHeadValue FLOAT,
	@iLumpValue FLOAT,
	@iFinesValue FLOAT
)
WITH ENCRYPTION
AS
BEGIN 
	SET NOCOUNT ON 

	BEGIN TRY
		-- add the Block Point
		INSERT INTO Staging.StageBlockModelGrade
			(BlockModelId, GeometType, GradeName, GradeValue, LumpValue, FinesValue)
		VALUES(@iBlockModelId, @iGeometType, @iGradeName, @iHeadValue, @iLumpValue, @iFinesValue)
		
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON Staging.AddBhpbioStageBlockModelGrade TO BhpbioGenericManager
GO