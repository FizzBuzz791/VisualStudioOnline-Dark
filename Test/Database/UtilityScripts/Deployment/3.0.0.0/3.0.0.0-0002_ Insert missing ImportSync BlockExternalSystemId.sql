-- CREATE TEMPORARY INDEX SPECIFICALLY FOR THIS SCRIPT.. IT IS DROPPED AT THE END
CREATE NONCLUSTERED  INDEX IX_STAGING_TEMP ON Staging.StageBlock (Site, OreBody,AlternativePitCode,Pit,Bench,PatternNumber,BlockName)
GO



--------------------------------------------------------------------------------------------------------------------------------------------------
-- This script updates Block Import Sync data to include BlockExternalSystemId elements now expected
--
-- This script makes use of cursors.  This is as a result of testing various approaches and the performance implications of each.  The XML processing
-- in this script seems to be a significant aspect of it.
--
--------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @Block_ImportSyncTableId Int

-- Determine the Table Ids
SELECT @Block_ImportSyncTableId = ImportSyncTableId
FROM ImportSyncTable
WHERE Name = 'BlastModelBlockWithPointAndGrade'

DECLARE @minImportSyncRowId INTEGER
DECLARE @maxImportSyncRowId INTEGER
DECLARE @countToProcess INTEGER
DECLARE @intLoopCount INTEGER
DECLARE @intStepSize INTEGER

SET @intStepSize = 50000

DECLARE @lastProcessSyncRowId INTEGER
SET @lastProcessSyncRowId = 0

SELECT @minImportSyncRowId = Min(isq.ImportSyncRowId), 
	@maxImportSyncRowId = Max(isq.ImportSyncRowId),
	@countToProcess = Count(*)
FROM ImportSyncQueue isq
INNER JOIN ImportSyncRow isr ON isr.ImportSyncRowId = isq.ImportSyncRowId
WHERE 
	isq.ImportId = 1
	AND isq.SyncAction IN ('I','U')
	AND isr.ImportSyncTableId = @Block_ImportSyncTableId 
	AND isr.IsCurrent = 1

DECLARE @importSyncRowId BIGINT
DECLARE @count INTEGER

SET NOCOUNT ON

SET @count = 0

/* Part 1 - determine the BlockExternalSystemId values for all current sync records */
DECLARE @BlockModelExternalSystemIds TABLE
(
	ImportSyncRowId BigInt Primary Key,
	[Site] nvarchar(9),
	OreBody nvarchar(2),
	Pit nvarchar(10),
	Bench nvarchar(4),
	PatternNumber nvarchar(4),
	BlockName nvarchar(14),
	RequiresExternalSystemIdInsert Bit,
	BlockExternalSystemId VARCHAR(50)
	UNIQUE (ImportSyncRowId)
)

SET @intLoopCount = 1
WHILE @lastProcessSyncRowId < @maxImportSyncRowId
BEGIN
	DELETE FROM @BlockModelExternalSystemIds
	
	PRINT convert(varchar,GetDate(),108) + ': Current Position: ' + convert(varchar, @lastProcessSyncRowId) + '... Max: ' + convert(varchar, @maxImportSyncRowId) + '... Processed: ' + convert(varchar, @count) + '...Remaining: ' + convert(varchar, @countToProcess - @count) + '...Total To Process: ' + convert(varchar, @countToProcess)

	DECLARE @sourceRow XML
	DECLARE @destinationRow XML

	DECLARE curSyncRowFirst Cursor STATIC for SELECT isr.ImportSyncRowId, isr.SourceRow
																	FROM ImportSyncQueue isq
																	INNER JOIN ImportSyncRow isr ON isr.ImportSyncRowId = isq.ImportSyncRowId
																	WHERE 
																		isr.ImportSyncRowId BETWEEN @lastProcessSyncRowId + 1 AND @lastProcessSyncRowId + @intStepSize
																		AND isq.ImportId = 1
																		AND isq.SyncAction IN ('I','U')
																		AND isr.ImportSyncTableId = @Block_ImportSyncTableId 
																		AND isr.IsCurrent = 1
																		ORDER BY isq.ImportSyncRowId
	OPEN curSyncRowFirst

	FETCH NEXT FROM curSyncRowFirst INTO @importSyncRowId, @sourceRow

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @count = @count + 1
		
		-- get the Block data for all sync rows
		INSERT INTO @BlockModelExternalSystemIds (ImportSyncRowId, [Site], OreBody, Pit, Bench, PatternNumber, BlockName, BlockExternalSystemId)
		SELECT
			   @importSyncRowId,
			   @sourceRow.value('(/BlockModelSource/BlastModelBlockWithPointAndGrade/Site)[1]', 'nvarchar(9)') as [Site],
			   @sourceRow.value('(/BlockModelSource/BlastModelBlockWithPointAndGrade/Orebody)[1]', 'nvarchar(2)') as Orebody,
			   @sourceRow.value('(/BlockModelSource/BlastModelBlockWithPointAndGrade/Pit)[1]', 'nvarchar(10)') as Pit,
			   @sourceRow.value('(/BlockModelSource/BlastModelBlockWithPointAndGrade/Bench)[1]', 'nvarchar(4)') as Bench,
			   @sourceRow.value('(/BlockModelSource/BlastModelBlockWithPointAndGrade/PatternNumber)[1]', 'nvarchar(4)') as PatternNumber,
			   @sourceRow.value('(/BlockModelSource/BlastModelBlockWithPointAndGrade/BlockName)[1]', 'nvarchar(14)') as BlockName,
			   @sourceRow.value('(/BlockModelSource/BlastModelBlockWithPointAndGrade/BlockExternalSystemId)[1]', 'nvarchar(50)') as BlockExternalSystemId

		FETCH NEXT FROM curSyncRowFirst INTO @importSyncRowId, @sourceRow
	
	END
	
	SET @lastProcessSyncRowId  = @lastProcessSyncRowId + @intStepSize
	
	-- skip ahead  to jump past the rows of other imports
	DECLARE @nextBlockRow INTEGER
	SELECT TOP 1 @nextBlockRow = ImportSyncRowId FROM ImportSyncRow WHERE ImportSyncRowId > @lastProcessSyncRowId AND ImportSyncTableId = @Block_ImportSyncTableId ORDER BY ImportSyncRowId
	IF @nextBlockRow IS NOT NULL
	BEGIN
		SET @lastProcessSyncRowId = @nextBlockRow - 1
	END

	UPDATE ids
		SET RequiresExternalSystemIdInsert = 1
	FROM @BlockModelExternalSystemIds ids
	WHERE  ids.BlockExternalSystemId IS NULL

	UPDATE ids
		SET BlockExternalSystemId = sb.BlockExternalSystemId
	FROM @BlockModelExternalSystemIds ids
		INNER JOIN Staging.StageBlock sb 
			ON sb.BlockName = ids.BlockName 
				AND sb.[Site] = ids.[Site] 
				AND sb.OreBody = ids.OreBody 
				AND COALESCE(sb.AlternativePitCode, sb.Pit) = ids.Pit 
				AND sb.Bench = ids.Bench 
				AND sb.PatternNumber = ids.PatternNumber 
	WHERE ids.RequiresExternalSystemIdInsert = 1 AND sb.BlockExternalSystemId Is NOT NULL

	CLOSE curSyncRowFirst
	DEALLOCATE curSyncRowFirst
	
	BEGIN TRANSACTION

	DECLARE curSyncRow Cursor FORWARD_ONLY READ_ONLY for (SELECT ImportSyncRowId, BlockExternalSystemId FROM @BlockModelExternalSystemIds WHERE BlockExternalSystemId IS NOT NULL AND RequiresExternalSystemIdInsert = 1)
	OPEN curSyncRow

	DECLARE @blockExternalSystemId VARCHAR(50)
	
	FETCH NEXT FROM curSyncRow INTO @importSyncRowId, @blockExternalSystemId

	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Insert the BlockExternalSystemId field where it is otherwise missing
		UPDATE ISR
		SET SourceRow.modify('insert <BlockExternalSystemId>{sql:variable("@blockExternalSystemId")}</BlockExternalSystemId> after (/BlockModelSource/BlastModelBlockWithPointAndGrade/ModelOreType)[1]')
		FROM ImportSyncRow isr 
		WHERE isr.ImportSyncRowId = @importSyncRowId

		FETCH NEXT FROM curSyncRow INTO @importSyncRowId, @blockExternalSystemId
	END

	CLOSE curSyncRow
	DEALLOCATE curSyncRow

	COMMIT TRANSACTION

	SET @intLoopCount = @intLoopCount + 1
END
GO
-- DROP THE Index created specifically for this work
DROP INDEX IX_STAGING_TEMP ON Staging.StageBlock
GO