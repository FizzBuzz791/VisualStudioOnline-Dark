IF OBJECT_ID('Staging.AddOrUpdateBhpbioStageBlockIfLatest') IS NOT NULL
     DROP PROCEDURE Staging.AddOrUpdateBhpbioStageBlockIfLatest
GO 
  
CREATE PROCEDURE Staging.AddOrUpdateBhpbioStageBlockIfLatest
(
	@iBlockExternalSystemId VARCHAR(255),
	@iTimestamp DATETIME,
	@iLithologyType VARCHAR(9),
	@iFlitchExternalSystemId VARCHAR(255),
	@iPatternExternalSystemId VARCHAR(255),
	@iSite VARCHAR(16),
	@iOrebody VARCHAR(16),
	@iPit VARCHAR(16),
	@iAlternativePitCode VARCHAR(10),
	@iBench VARCHAR(16),
	@iPatternNumber VARCHAR(16),
	@iBlockName VARCHAR(14),
	@iBlockNumber VARCHAR(16),
	@iDateBlocked DATETIME,
	@iCentroidX FLOAT,
	@iCentroidY FLOAT,
	@iCentroidZ FLOAT,
	@oBlockId INTEGER OUT,
	@oIsLatest BIT OUT
)
WITH ENCRYPTION
AS
BEGIN 

	SET NOCOUNT ON 

		SET @oIsLatest = 0
		
		DECLARE @iLatestDeletionTimestamp DATETIME
		DECLARE @iLatestBlockTimestamp DATETIME
		DECLARE @blockId INTEGER
		DECLARE @patternExternalSystemId VARCHAR(38)
		DECLARE @flitchExternalSystemId VARCHAR(38)
		
		SELECT	@iLatestBlockTimestamp = LastMessageTimestamp,
				@blockId = BlockId,
				@patternExternalSystemId = PatternExternalSystemId,
				@flitchExternalSystemId = FlitchExternalSystemId
		FROM Staging.StageBlock
		WHERE BlockExternalSystemId = @iBlockExternalSystemId
		
		SELECT @iLatestDeletionTimestamp = MAX(LastMessageTimestamp)
		FROM Staging.StageBlockDeletion
		WHERE BlockExternalSystemId = @iBlockExternalSystemId
		
		IF  (@iLatestBlockTimestamp IS NULL OR @iTimestamp > @iLatestBlockTimestamp)
			AND (@iLatestDeletionTimestamp IS NULL OR @iTimestamp > @iLatestDeletionTimestamp)
		BEGIN
			SET @oIsLatest = 1

			DECLARE @BlockFullName VARCHAR(50)
			SET @BlockFullName = IsNull(@iAlternativePitCode, @iPit) + '-' + right('0000' + @iBench, 4) + '-' + right('0000' + @iPatternNumber, 4) + '-' + @iBlockName
			
			IF @blockId IS NULL
			BEGIN
				-- add the Block
				INSERT INTO Staging.StageBlock
					(BlockExternalSystemId, FlitchExternalSystemId, PatternExternalSystemId, BlockNumber, BlockName, BlockFullName, LithologyTypeName, BlockedDate, BlastedDate, Site, OreBody, Pit, Bench, PatternNumber, AlternativePitCode, CentroidX, CentroidY, CentroidZ, LastMessageTimestamp)
				VALUES(@iBlockExternalSystemId, @iFlitchExternalSystemId, @iPatternExternalSystemId, @iBlockNumber, @iBlockName, @BlockFullName, @iLithologyType, @iDateBlocked, null, @iSite, @iOrebody, @iPit, @iBench, @iPatternNumber, @iAlternativePitCode, @iCentroidX, @iCentroidY, @iCentroidZ, @iTimestamp)
			
				SET @oBlockId = Scope_Identity()
			END
			ELSE
			BEGIN
				DECLARE @guidsConsistent BIT
				SET @guidsConsistent = 1

				-- vaidate the pattern guid and the flitch guid have not changed (otherwise something really strange is going on with the messages)
				IF (@patternExternalSystemId IS NOT NULL) AND (NOT (@patternExternalSystemId like @iPatternExternalSystemId))
				BEGIN
					SET @guidsConsistent = 0
					-- raise error..  PatternGUID is different for the same Block
					RAISERROR (N'Unable to update staging data as the Pattern GUID for the Block GUID has changed.  Staging: %s Message: %s', -- Message text.
						   16, -- Severity,
						   1, -- State,
						   @patternExternalSystemId, -- First argument.
						   @iPatternExternalSystemId); -- Second argument.
				END

				IF (@flitchExternalSystemId IS NOT NULL) AND (NOT (@flitchExternalSystemId like @iFlitchExternalSystemId))
				BEGIN
					SET @guidsConsistent = 0
					-- raise error..  FlitchGUID is different for the same Block
					RAISERROR (N'Unable to update staging data as the Flitch GUID for the Block GUID has changed.  Staging: %s Message: %s', -- Message text.
						   16, -- Severity,
						   1, -- State,
						   @flitchExternalSystemId, -- First argument.
						   @iFlitchExternalSystemId); -- Second argument.
				END

				IF @guidsConsistent = 1
				BEGIN
					-- update the Block
					Update Staging.StageBlock
						SET BlockExternalSystemId = @iBlockExternalSystemId, 
							FlitchExternalSystemId = @iFlitchExternalSystemId, 
							PatternExternalSystemId = @iPatternExternalSystemId, 
							BlockNumber = @iBlockNumber, 
							BlockName = @iBlockName,  
							BlockFullName = @BlockFullName, 
							LithologyTypeName = @iLithologyType, 
							BlockedDate = @iDateBlocked, 
							BlastedDate = null,  
							[Site] = @iSite, 
							OreBody = @iOrebody, 
							Pit = @iPit, 
							Bench = @iBench, 
							PatternNumber = @iPatternNumber, 
							AlternativePitCode = @iAlternativePitCode, 
							CentroidX = @iCentroidX, 
							CentroidY = @iCentroidY, 
							CentroidZ = @iCentroidZ, 
							LastMessageTimestamp = @iTimestamp
					WHERE BlockId = @blockId
					
					SET @oBlockId = @blockId
				END
			END

			IF @oBlockId IS NOT NULL
			BEGIN
				DECLARE @ChangedDataEntryId INTEGER
				
				--Change Logging
				INSERT INTO Staging.ChangedDataEntry
				SELECT GETDATE(), GETDATE(),'StageBlock'

				SET @ChangedDataEntryId = Scope_Identity()

				INSERT INTO Staging.ChangedDataEntryRelatedKeyValue
				SELECT @ChangedDataEntryId, 'BlockFullName', BlockFullName
				FROM Staging.StageBlock
				WHERE BlockId = @oBlockId
				UNION ALL
				SELECT @ChangedDataEntryId, 'Site', CASE WHEN m.ContextKey IS NULL THEN b.[Site] ELSE m.[To] END
				FROM Staging.StageBlock b
					LEFT JOIN Staging.StageDataMap m ON m.ContextKey = 'Site' AND m.[From] = b.[Site]
				WHERE b.BlockId = @oBlockId
				UNION ALL
				SELECT @ChangedDataEntryId, 'Pit', IsNull([AlternativePitCode], [Pit])
				FROM Staging.StageBlock
				WHERE BlockId = @oBlockId
				UNION ALL
				SELECT @ChangedDataEntryId, 'Bench', Bench
				FROM Staging.StageBlock
				WHERE BlockId = @oBlockId
			END
		END
END 
GO

GRANT EXECUTE ON Staging.AddOrUpdateBhpbioStageBlockIfLatest TO BhpbioGenericManager
GO

