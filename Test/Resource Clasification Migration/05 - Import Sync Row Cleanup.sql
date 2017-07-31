IF NOT (OBJECT_ID('Staging.TmpStageImportSyncRowRCCorrectionLog') IS NULL)
BEGIN
	DROP TABLE Staging.TmpStageImportSyncRowRCCorrectionLog
END
GO

IF NOT (OBJECT_ID('Staging.TmpStageImportSyncRowRCCorrection') IS NULL)
BEGIN
	DROP TABLE Staging.TmpStageImportSyncRowRCCorrection
END
GO