IF OBJECT_ID('dbo.DeleteBhpbioAnalysisVariance') IS NOT NULL
     DROP PROCEDURE dbo.DeleteBhpbioAnalysisVariance
GO 

CREATE PROCEDURE dbo.DeleteBhpbioAnalysisVariance
(
	@iLocationId INT,
	@iVarianceType CHAR(1) = NULL
)
WITH ENCRYPTION
AS 
BEGIN 
	SET NOCOUNT ON 

	BEGIN TRY
	
		-- Error if it does not exist.
		IF NOT EXISTS (
						SELECT 1 
						FROM dbo.BhpbioAnalysisVariance 
						WHERE LocationId = @iLocationId
							AND (VarianceType = @iVarianceType OR @iVarianceType IS NULL)
					   )
		BEGIN
			RAISERROR('This variance does not exist.', 16, 1)
		END
		
		-- Delete the variance records associated with the location (and type).
		DELETE
		FROM dbo.BhpbioAnalysisVariance 
		WHERE LocationId = @iLocationId
			AND (VarianceType = @iVarianceType OR @iVarianceType IS NULL)
	
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO
	
GRANT EXECUTE ON dbo.DeleteBhpbioAnalysisVariance TO BhpbioGenericManager
