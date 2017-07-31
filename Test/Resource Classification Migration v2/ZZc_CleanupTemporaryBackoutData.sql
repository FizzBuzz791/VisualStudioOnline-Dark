IF OBJECT_ID('[Staging].[TmpRCBackup_ModelBlockPartialValue]') IS NOT NULL 
     DROP TABLE [Staging].TmpRCBackup_ModelBlockPartialValue
GO

IF OBJECT_ID('[Staging].[TmpRCBackup_BhpbioSummaryEntryFieldValue]') IS NOT NULL 
     DROP TABLE [Staging].TmpRCBackup_BhpbioSummaryEntryFieldValue
GO

IF OBJECT_ID('[Staging].[TmpRCBackup_ImportSyncRow]') IS NOT NULL 
     DROP TABLE [Staging].TmpRCBackup_ImportSyncRow
GO