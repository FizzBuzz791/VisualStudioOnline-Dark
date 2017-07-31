IF OBJECT_ID('[Staging].[TmpRCBackup_ModelBlockPartialValue]') IS NOT NULL 
     DROP TABLE [Staging].TmpRCBackup_ModelBlockPartialValue
GO

SELECT * 
INTO [Staging].TmpRCBackup_ModelBlockPartialValue
FROM ModelBlockPartialValue
WHERE Model_Block_Partial_Field_Id like 'Resource%'
GO

IF OBJECT_ID('[Staging].[TmpRCBackup_BhpbioSummaryEntryFieldValue]') IS NOT NULL 
     DROP TABLE [Staging].TmpRCBackup_BhpbioSummaryEntryFieldValue
GO

SELECT fv.*
INTO [Staging].TmpRCBackup_BhpbioSummaryEntryFieldValue
FROM BhpbioSummaryEntryFieldValue fv
	INNER JOIN BhpbioSummaryEntryField f ON f.SummaryEntryFieldId = fv.SummaryEntryFieldId
WHERE f.Name like 'Resource%'
GO

IF OBJECT_ID('[Staging].[TmpRCBackup_ImportSyncRow]') IS NOT NULL 
     DROP TABLE [Staging].TmpRCBackup_ImportSyncRow
GO

SELECT isr.*
INTO [Staging].TmpRCBackup_ImportSyncRow
FROM ImportSyncRow isr
	INNER JOIN ImportSyncQueue isq ON isq.ImportSyncRowId = isr.ImportSyncRowId
WHERE isq.ImportId = 1 AND isr.IsCurrent = 1 AND isq.InitialComparedDateTime >= '2016-05-01'
GO
