-- make sure the temporary table for storage of blocks needing correction exists
IF NOT OBJECT_ID('Staging.TmpStageLumpFinesBlockCorrectionBlocks') IS NULL
BEGIN
	DROP TABLE Staging.TmpStageLumpFinesBlockCorrectionBlocks
END
GO 

IF NOT OBJECT_ID('Staging.TmpLumpFinesStageBlockModelGradeCorrection') IS NULL
BEGIN
	DROP TABLE Staging.TmpStageLumpFinesBlockCorrectionBlocks
END
GO 

IF NOT OBJECT_ID('Staging.[TmpLumpFinesBhpbioBlastBlockLumpFinesGradeCorrection]') IS NULL
BEGIN
	DROP TABLE Staging.[TmpLumpFinesBhpbioBlastBlockLumpFinesGradeCorrection]
END
GO 

IF NOT OBJECT_ID('Staging.TmpBhpbioSummaryEntryGradeCorrection') IS NULL
BEGIN
	DROP TABLE Staging.TmpBhpbioSummaryEntryGradeCorrection
END
GO 

IF NOT OBJECT_ID('Staging.TmpStageImportSyncRowCorrection') IS NULL
BEGIN
	DROP TABLE Staging.TmpStageImportSyncRowCorrection
END
GO 

IF NOT OBJECT_ID('Staging.TmpStageImportSyncRowCorrectionLog') IS NULL
BEGIN
	DROP TABLE Staging.TmpStageImportSyncRowCorrectionLog
END
GO

IF NOT OBJECT_ID('Staging.TmpStageImportSyncBlockChangesLog') IS NULL
BEGIN
	DROP TABLE Staging.TmpStageImportSyncBlockChangesLog
END
