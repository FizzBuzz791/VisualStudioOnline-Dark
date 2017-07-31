
PRINT 'Dropping temporary tables'

IF Object_Id('Staging.TmpLumpPercentCorrection') IS NOT NULL
	DROP TABLE Staging.TmpLumpPercentCorrection
GO

IF Object_Id('dbo.BhpbioBlastBlockLumpPercent_Old') IS NOT NULL
	DROP TABLE dbo.BhpbioBlastBlockLumpPercent_Old 
GO

IF Object_Id('dbo.TmpBhpbioSummaryEntrySplitCorrection') IS NOT NULL
BEGIN
	DROP TABLE [dbo].[TmpBhpbioSummaryEntrySplitCorrection]
END
GO

IF OBJECT_ID('[Staging].[TmpBackup_ImportSyncRowLumpPercent]') IS NOT NULL 
     DROP TABLE [Staging].TmpBackup_ImportSyncRowLumpPercent
GO

IF OBJECT_ID('[Staging].[TmpStageImportSyncRowCorrectionLog]') IS NOT NULL 
     DROP TABLE [Staging].TmpStageImportSyncRowCorrectionLog
GO

IF OBJECT_ID('[Staging].[TmpStageImportSyncRowCorrection]') IS NOT NULL 
     DROP TABLE [Staging].TmpStageImportSyncRowCorrection
GO

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

IF OBJECT_ID('[Staging].[TmpRCBackup_ModelBlockPartialValue]') IS NOT NULL 
     DROP TABLE [Staging].TmpRCBackup_ModelBlockPartialValue
GO

IF OBJECT_ID('[Staging].[TmpRCBackup_BhpbioSummaryEntryFieldValue]') IS NOT NULL 
     DROP TABLE [Staging].TmpRCBackup_BhpbioSummaryEntryFieldValue
GO

IF OBJECT_ID('[Staging].[TmpRCBackup_ImportSyncRow]') IS NOT NULL 
     DROP TABLE [Staging].TmpRCBackup_ImportSyncRow
GO

PRINT 'Dropping temporary tables - Complete'
GO