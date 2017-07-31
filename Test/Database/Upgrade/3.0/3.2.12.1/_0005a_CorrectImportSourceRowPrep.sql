
PRINT 'Preparing for Import Source Row correction'

IF OBJECT_ID('[Staging].[TmpBackup_ImportSyncRowLumpPercent]') IS NOT NULL 
     DROP TABLE [Staging].TmpBackup_ImportSyncRowLumpPercent
GO

IF OBJECT_ID('[Staging].[TmpStageImportSyncRowCorrectionLog]') IS NOT NULL 
     DROP TABLE [Staging].TmpStageImportSyncRowCorrectionLog
GO

IF OBJECT_ID('[Staging].[TmpStageImportSyncRowCorrection]') IS NOT NULL 
     DROP TABLE [Staging].TmpStageImportSyncRowCorrection
GO

IF OBJECT_ID('Staging.TmpStageImportSyncRowCorrectionLog') IS NULL
BEGIN
	CREATE TABLE Staging.TmpStageImportSyncRowCorrectionLog
	(
		ImportSyncRowId INTEGER,
		ProcessedDateTime DATETIME
	)
END
GO
