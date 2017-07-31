IF OBJECT_ID('Staging.GetBhpbioStagingBlockId') IS NOT NULL
	DROP PROCEDURE Staging.GetBhpbioStagingBlockId
GO

CREATE PROCEDURE Staging.GetBhpbioStagingBlockId
(
	@iBlockNumber VARCHAR(16),
	@iBlockName VARCHAR(14),
	@iSite VARCHAR(9),
	@iOrebody VARCHAR(2),
	@iPit VARCHAR(10),
	@iBench VARCHAR(4),
	@iPatternNumber VARCHAR(4),
	@oBlockId INT OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON
	
	BEGIN TRY
	

		SELECT @oBlockId = BlockId
		FROM Staging.StageBlock AS bbh
		WHERE BlockNumber = @iBlockNumber
			AND BlockName = @iBlockName
			AND [Site] = @iSite
			AND OreBody = @iOreBody
			AND Pit = @iPit
			AND Bench = @iBench
			AND PatternNumber = @iPatternNumber
			
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END
GO

GRANT EXECUTE ON Staging.GetBhpbioStagingBlockId TO BhpbioGenericManager
GO
