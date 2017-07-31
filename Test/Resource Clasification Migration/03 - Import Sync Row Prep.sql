-- CREATE TEMPORARY TABLES AND INSERT PRIMARY KEYS TO PROCESS

IF OBJECT_ID('Staging.TmpStageImportSyncRowRCCorrectionLog') IS NULL
BEGIN
	CREATE TABLE Staging.TmpStageImportSyncRowRCCorrectionLog
	(
		ImportSyncRowId INTEGER,
		ProcessedDateTime DATETIME
	)
END
GO

IF OBJECT_ID('Staging.TmpStageImportSyncRowRCCorrection') IS NULL
BEGIN
	CREATE TABLE Staging.TmpStageImportSyncRowRCCorrection
	(
		ImportSyncRowId INTEGER,
		[Site] varchar(50),
		Pit varchar(50),
		Bench varchar(50),
		PatternNumber varchar(50),
		ModelName varchar(50),
		BlockName varchar(50),
		ModelOreType varchar(50),
		ResourceClassification varchar(max)
	)
END
ELSE
BEGIN
	DELETE FROM Staging.TmpStageImportSyncRowRCCorrection
END
GO

-----------------------------------------------------------
-- ImportSyncRow
-- Identify the current sync row for all impacted blocks
INSERT INTO Staging.TmpStageImportSyncRowRCCorrection(ImportSyncRowId, [Site], Pit, Bench, PatternNumber, ModelName, BlockName, ModelOreType, ResourceClassification)
SELECT isq.ImportSyncRowId,
	SourceRow.value('/BlockModelSource[1]/*[1]/Site[1]','varchar(255)') as [Site],
	SourceRow.value('/BlockModelSource[1]/*[1]/Pit[1]','varchar(255)') as Pit,
	SourceRow.value('/BlockModelSource[1]/*[1]/Bench[1]','varchar(255)')  as Bench,
	SourceRow.value('/BlockModelSource[1]/*[1]/PatternNumber[1]','varchar(255)') as PatternNumber,
	SourceRow.value('/BlockModelSource[1]/*[1]/ModelName[1]','varchar(255)')  as ModelName,
	SourceRow.value('/BlockModelSource[1]/*[1]/BlockName[1]','varchar(255)')  as BlockName,
	SourceRow.value('/BlockModelSource[1]/*[1]/ModelOreType[1]','varchar(255)')  as ModelOreType,
	SourceRow.value('(/BlockModelSource/BlastModelBlockWithPointAndGrade/ResourceClassification)[1]', 'nvarchar(MAX)') as ResourceClassification
FROM ImportSyncQueue isq 
INNER JOIN ImportSyncRow isr ON isr.ImportSyncRowId = isq.ImportSyncRowId
WHERE isq.ImportId = 1
	AND isr.IsCurrent = 1
GO