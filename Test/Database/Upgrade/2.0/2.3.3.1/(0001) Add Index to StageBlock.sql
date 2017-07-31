If Not Exists(
	Select * From sys.indexes 
	Where name = 'IX_StageBlock_BlockExternalSystemId' And object_id = OBJECT_ID('Staging.StageBlock')
) 
Begin
	Print 'Creating index IX_StageBlock_BlockExternalSystemId'
	CREATE NONCLUSTERED INDEX IX_StageBlock_BlockExternalSystemId ON Staging.StageBlock 
	(
		BlockExternalSystemId ASC
	)
End
