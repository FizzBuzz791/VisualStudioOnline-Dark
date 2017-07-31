IF OBJECT_ID('Staging.DeleteBhpbioStageBlock') IS NOT NULL
     DROP PROCEDURE Staging.DeleteBhpbioStageBlock
GO 
  
CREATE PROCEDURE Staging.DeleteBhpbioStageBlock
(
	@iBlockExternalSystemId VARCHAR(255),
	@iTimestamp DateTime
)
WITH ENCRYPTION
AS
BEGIN 
	SET NOCOUNT ON 

	BEGIN TRY
		
		DECLARE @iLatestDeletionTimestamp DATETIME
		DECLARE @iLatestBlockTimestamp DATETIME
		DECLARE @blockId INTEGER
		
		SELECT	@iLatestBlockTimestamp = LastMessageTimestamp,
				@blockId = BlockId
		FROM Staging.StageBlock
		WHERE BlockExternalSystemId = @iBlockExternalSystemId
		
		SELECT @iLatestDeletionTimestamp = MAX(LastMessageTimestamp)
		FROM Staging.StageBlockDeletion
		WHERE BlockExternalSystemId = @iBlockExternalSystemId
		
		IF  (@iLatestBlockTimestamp IS NULL OR @iTimestamp > @iLatestBlockTimestamp)
			AND (@iLatestDeletionTimestamp IS NULL OR @iTimestamp > @iLatestDeletionTimestamp)
		BEGIN
			-- this is the latest message
			
			-- insert the deletion record
			INSERT INTO Staging.StageBlockDeletion(BlockExternalSystemId, LastMessageTimestamp)
			VALUES (@iBlockExternalSystemId, @iTimestamp)
			
			-- and delete the block record (if one exists)
			IF @blockId IS NOT NULL
			BEGIN
				DECLARE @ChangedDataEntryId INTEGER
		
				--Change Logging
				INSERT INTO Staging.ChangedDataEntry
				SELECT GETDATE(), GETDATE(),'StageBlock'

				SET @ChangedDataEntryId = Scope_Identity()

				INSERT INTO Staging.ChangedDataEntryRelatedKeyValue
				SELECT @ChangedDataEntryId, 'BlockFullName', BlockFullName
				FROM Staging.StageBlock
				WHERE BlockId = @blockId
				UNION ALL
				SELECT @ChangedDataEntryId, 'Site', CASE WHEN m.ContextKey IS NULL THEN b.[Site] ELSE m.[To] END
				FROM Staging.StageBlock b
					LEFT JOIN Staging.StageDataMap m ON m.ContextKey = 'Site' AND m.[From] = b.[Site]
				WHERE b.BlockId = @blockId
				UNION ALL
				SELECT @ChangedDataEntryId, 'Pit', [AlternativePitCode]
				FROM Staging.StageBlock
				WHERE BlockId = @blockId
				UNION ALL
				SELECT @ChangedDataEntryId, 'Bench', Bench
				FROM Staging.StageBlock
				WHERE BlockId = @blockId

				-- delete the point
				DELETE p
				FROM Staging.StageBlockPoint p
				WHERE p.BlockId = @blockId 
				
				-- delete the grades
				DELETE g
				FROM Staging.StageBlockModel m
					INNER JOIN Staging.StageBlockModelGrade g 
						ON g.BlockModelId = m.BlockModelId
				WHERE m.BlockId = @blockId
				
				-- delete the RC data
                DELETE rc
                FROM Staging.StageBlockModel m
                    INNER JOIN Staging.StageBlockModelResourceClassification rc
                         ON rc.BlockModelId = m.BlockModelId
                WHERE m.BlockId = @blockId

				-- delete the models
				DELETE m
				FROM Staging.StageBlockModel m
				WHERE m.BlockId = @blockId
				
				-- delete the block
				DELETE b
				FROM Staging.StageBlock b
				WHERE b.BlockId = @blockId
			END
		END
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON Staging.DeleteBhpbioStageBlock TO BhpbioGenericManager
GO