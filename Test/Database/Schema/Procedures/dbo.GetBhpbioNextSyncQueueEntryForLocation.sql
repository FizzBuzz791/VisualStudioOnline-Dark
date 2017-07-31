 If Object_Id('dbo.GetBhpbioNextSyncQueueEntryForLocation') Is Not Null
	Drop Procedure dbo.GetBhpbioNextSyncQueueEntryForLocation
Go

Create Procedure dbo.GetBhpbioNextSyncQueueEntryForLocation
(
	@iOrderNo BigInt = Null,
	@iImportId SmallInt,
	@iSite Varchar(31),
	@iPit VarChar(31),
	@iBench VarChar(31)
)
With Encryption 
As
Begin


Select Top 1 ISQ.ImportSyncQueueId,
	ISQ.ImportSyncRowId,
	ISQ.IsPending,
	ISQ.OrderNo,
	ISQ.SyncAction,
	ISQ.InitialComparedDateTime,
	ISQ.LastProcessedDateTime,
	ISQ.InitialCompareImportJobId,
	ISQ.LastProcessImportJobId,
	IST.Name As TableName,
	ISQ.ImportId,
	ISQ.ImportSyncTableId
From dbo.ImportSyncQueue As ISQ
	Inner Join dbo.ImportSyncTable As IST
		On IST.ImportSyncTableId = ISQ.ImportSyncTableId
	Inner Join dbo.ImportSyncRow R
		on ISQ.ImportSyncRowId = R.ImportSyncRowId
Where ISQ.IsPending = 1
	And ISQ.OrderNo > Coalesce(@iOrderNo,-1)
	And ISQ.ImportId = @iImportId
	and (@iSite is null or @iSite = '' or  SourceRow.value('/BlockModelSource[1]/*[1]/Site[1]','varchar(255)') = Upper(@iSite))
	and (@iPit is null or @iPit = '' or SourceRow.value('/BlockModelSource[1]/*[1]/Pit[1]','varchar(255)') = Upper(@iPit))
	and (@iBench is null or @iBench = '' or SourceRow.value('/BlockModelSource[1]/*[1]/Bench[1]','varchar(255)') = Upper(@iBench))
Order By OrderNo Asc


End
Go
GRANT EXECUTE ON dbo.GetBhpbioNextSyncQueueEntryForLocation TO CommonImportManager
Go
