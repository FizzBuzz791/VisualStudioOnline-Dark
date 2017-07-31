DECLARE @issueIntroductionDateTime DATETIME
DECLARE @processCorrectionDate DATETIME
-- The time the issue occured
SET @issueIntroductionDateTime  = '2015-8-20 20:00:00'

SELECT @processCorrectionDate = CONVERT(datetime, value) 
FROM Setting s
WHERE Setting_Id = 'BHPBIO_LUMPFINES_IMPORT_CORRECTION_DATE'

INSERT INTO Staging.TmpStageLumpFinesBlockCorrectionBlocks(BlockFullName, MinLastUpdateDateTime, MaxLastUpdateDateTime, FlagDelete)
SELECT kv.TextValue, MIN(cde.ChangeAppliedDateTime), MAX(cde.ChangeAppliedDateTime), 0
FROM Staging.ChangedDataEntry cde
	INNER JOIN Staging.ChangedDataEntryRelatedKeyValue kv ON kv.ChangedDataEntryId = cde.Id
WHERE kv.ChangeKey ='BlockFullName'
 AND cde.ChangeTypeId = 'StageBlockModel'
 AND cde.ChangeAppliedDateTime BETWEEN @issueIntroductionDateTime AND @processCorrectionDate
 AND NOT EXISTS (SELECT * FROM Staging.TmpStageLumpFinesBlockCorrectionBlocks b WHERE b.BlockFullName = kv.TextValue)
GROUP BY kv.TextValue

-- there may have been existing data in TmpStageLumpFinesBlockCorrectionBlocks
-- perform an operation to determine the overall min and max change dates for each block
-- flag all existing rows for delete
UPDATE Staging.TmpStageLumpFinesBlockCorrectionBlocks SET FlagDelete = 1

-- insert new rows representing overall min and max
INSERT INTO Staging.TmpStageLumpFinesBlockCorrectionBlocks(BlockFullName, MinLastUpdateDateTime, MaxLastUpdateDateTime, FlagDelete)
SELECT b.BlockFullName, MIN(b.MinLastUpdateDateTime), MAX(b.MaxLastUpdateDateTime), 0
FROM Staging.TmpStageLumpFinesBlockCorrectionBlocks b
GROUP BY b.BlockFullName

-- Delete duplicates
DELETE FROM Staging.TmpStageLumpFinesBlockCorrectionBlocks WHERE FlagDelete = 1
GO

