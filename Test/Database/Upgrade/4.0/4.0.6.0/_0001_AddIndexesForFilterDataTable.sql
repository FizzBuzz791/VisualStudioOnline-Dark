CREATE NONCLUSTERED INDEX [IX_ImportSyncRowId]
ON [dbo].[BhpbioImportSyncRowFilterData] ([ImportSyncRowId])

CREATE NONCLUSTERED INDEX [IX_LastProcessImportJobId_ImportSyncQueueId]
ON [dbo].[ImportSyncQueue] ([LastProcessImportJobId])
INCLUDE ([ImportSyncQueueId])

CREATE NONCLUSTERED INDEX [IX_Site_BlockName_Pit_Bench_PatternNumber_DateFrom]
ON [dbo].[BhpbioImportReconciliationMovement] ([Site],[BlockName],[Pit],[Bench],[PatternNumber], [DateFrom])