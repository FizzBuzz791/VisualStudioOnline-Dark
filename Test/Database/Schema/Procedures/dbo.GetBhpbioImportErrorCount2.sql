IF Object_Id('dbo.GetBhpbioImportErrorCount2') IS NOT NULL
	DROP PROCEDURE dbo.GetBhpbioImportErrorCount2
GO

CREATE PROCEDURE dbo.GetBhpbioImportErrorCount2
(
	@iValidationFromDate DateTime = null,
	@iLocationId INT
)

--WITH ENCRYPTION
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

		Left Join dbo.[BhpbioImportRowLocationParents] ISR
			ON ISR.ImportSyncRowId = ISQ.ImportSyncRowId
		Left Join dbo.ImportSyncQueue ROOT_ISQ
			ON ROOT_ISQ.ImportSyncRowId = ISR.RootImportSyncRowId
				And ROOT_ISQ.SyncAction = 'I'

		Left Join dbo.ImportSyncValidate As ISV
			On ISV.ImportSyncQueueId = ISQ.ImportSyncQueueId
				And dbo.SAMEMONTH(ROOT_ISQ.InitialComparedDateTime,@iValidationFromDate)=1
		Left Join dbo.ImportSyncConflict As ISC
			ON ISC.ImportSyncQueueId = ISQ.ImportSyncQueueId
				And dbo.SAMEMONTH(ROOT_ISQ.InitialComparedDateTime,@iValidationFromDate)=1
		Left Join dbo.ImportSyncException As ISE
			ON ISE.ImportSyncQueueId = ISQ.ImportSyncQueueId
				And dbo.SAMEMONTH(ROOT_ISQ.InitialComparedDateTime, @iValidationFromDate)=1
		Left Join (
			Select ILR.ImportId, Count(*) As MessageCount 
			From ImportLoadRow ILR 
				Inner Join ImportLoadRowMessages ILRM 
					ON ILRM.ImportLoadRowId = ILR.ImportLoadRowId
			Group By ILR.ImportId
		) ImportMessageCounts ON ImportMessageCounts.ImportId = I.ImportId
		where
		    --where ISR.Location_Id=@iLocationId OR dbo.IsChildOf(ISR.Location_Id,@iLocationId)=1
		    --where ISR is related to the current location
			ISR.PitLocationId = @iLocationId OR 
			ISR.SiteLocationId = @iLocationId OR 
			ISR.HubLocationId = @iLocationId OR
			ISR.CompanyLocationId = @iLocationId 
	Order By 1		
	

END
GO


GRANT EXECUTE ON dbo.GetBhpbioImportErrorCount2 TO BhpbioGenericManager --
GO
