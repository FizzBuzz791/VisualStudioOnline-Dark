IF Object_Id('dbo.GetBhpbioImportErrorCount') IS NOT NULL
	DROP PROCEDURE dbo.GetBhpbioImportErrorCount
GO

CREATE PROCEDURE dbo.GetBhpbioImportErrorCount
(
	@iValidationFromDate DateTime = null
)

WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	Select 
		Count(ISV.ImportSyncValidateId) + ISNULL(Sum(ImportMessageCounts.MessageCount), 0) As ValidateCount,
		Count(ISC.ImportSyncConflictId) As ConflictCount,
		Count(ISE.ImportSyncExceptionId) As CriticalErrorCount
	From dbo.Import As I
		Inner Join dbo.ImportType As IT
			On (I.ImportTypeID = IT.ImportTypeID)
		Inner Join dbo.ImportGroup As IG
			On (IG.ImportGroupID = I.ImportGroupID)
		Left Join dbo.ImportSyncQueue As ISQ
			ON (ISQ.ImportId = I.ImportId
				And ISQ.IsPending = 1)

		Left Join dbo.ImportSyncRow ISR
			ON ISR.ImportSyncRowId = ISQ.ImportSyncRowId
		Left Join dbo.ImportSyncQueue ROOT_ISQ
			ON ROOT_ISQ.ImportSyncRowId = ISR.RootImportSyncRowId
				And ROOT_ISQ.SyncAction = 'I'

		Left Join dbo.ImportSyncValidate As ISV
			On ISV.ImportSyncQueueId = ISQ.ImportSyncQueueId
				And ROOT_ISQ.InitialComparedDateTime > @iValidationFromDate
		Left Join dbo.ImportSyncConflict As ISC
			ON ISC.ImportSyncQueueId = ISQ.ImportSyncQueueId
				And ROOT_ISQ.InitialComparedDateTime > @iValidationFromDate
		Left Join dbo.ImportSyncException As ISE
			ON ISE.ImportSyncQueueId = ISQ.ImportSyncQueueId
				And ROOT_ISQ.InitialComparedDateTime > @iValidationFromDate
		Left Join (
			Select ILR.ImportId, Count(*) As MessageCount 
			From ImportLoadRow ILR 
				Inner Join ImportLoadRowMessages ILRM 
					ON ILRM.ImportLoadRowId = ILR.ImportLoadRowId
			Group By ILR.ImportId
		) ImportMessageCounts ON ImportMessageCounts.ImportId = I.ImportId
	Order By 1		
	

END
GO

GRANT EXECUTE ON dbo.GetBhpbioImportErrorCount TO CommonImportManager
GO
