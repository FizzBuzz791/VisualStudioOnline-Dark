
-- reinstate partial values from backup
INSERT INTO ModelBlockPartialValue(Model_Block_Id, Sequence_No, Model_Block_Partial_Field_Id, Field_Value)
SELECT b.Model_Block_Id, b.Sequence_No, b.Model_Block_Partial_Field_id, b.Field_Value
FROM Staging.TmpRCBackup_ModelBlockPartialValue b
LEFT JOIN ModelBlockPartialValue m ON m.Model_Block_Id = b.Model_Block_Id AND m.Sequence_No = b.Sequence_No and m.Model_Block_Partial_Field_Id = b.Model_Block_Partial_Field_Id
WHERE m.Model_Block_Id IS NULL
GO
-- reinstate summary data from backup
INSERT INTO BhpbioSummaryEntryFieldValue(SummaryEntryFieldId, SummaryEntryId, Value)
SELECT b.SummaryEntryFieldId, b.SummaryEntryId, b.Value
FROM Staging.TmpRCBackup_BhpbioSummaryEntryFieldValue b
LEFT JOIN BhpbioSummaryEntryFieldValue m ON m.SummaryEntryFieldId = b.SummaryEntryFieldId AND m.SummaryEntryId = b.SummaryEntryId
WHERE m.SummaryEntryFieldId IS NULL
GO

-- reinstate import sync row values
UPDATE isr
SET isr.SourceRow = b.SourceRow
FROM Staging.TmpRCBackup_ImportSyncRow b 
	INNER JOIN ImportSyncRow isr ON isr.ImportSyncRowId = b.ImportSyncRowId
GO
