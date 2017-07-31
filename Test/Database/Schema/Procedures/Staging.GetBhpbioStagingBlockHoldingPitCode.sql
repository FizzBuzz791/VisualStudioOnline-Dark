IF OBJECT_ID('Staging.GetBhpbioStagingBlockHoldingPitCode') IS NOT NULL
	DROP PROCEDURE Staging.GetBhpbioStagingBlockHoldingPitCode
GO

CREATE PROCEDURE Staging.GetBhpbioStagingBlockHoldingPitCode
(
	@iBlockName VARCHAR(14),
	@iSite VARCHAR(9),
	@iOreBody VARCHAR(2),
	@iPit VARCHAR(10),
	@iBench VARCHAR(4),
	@iPatternNumber VARCHAR(4)
)
WITH ENCRYPTION
AS
BEGIN
	
	SET NOCOUNT ON 

	BEGIN TRY
		SELECT MQ2PitCode
		FROM Staging.BhpbioStageBlock
		WHERE BlockName = @iBlockName
			AND Site = @iSite
			AND Orebody = @iOrebody
			AND Pit = @iPit
			AND Bench = @iBench
			AND PatternNumber = @iPatternNumber
		
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON Staging.GetBhpbioStagingBlockHoldingPitCode TO BhpbioGenericManager
GO
