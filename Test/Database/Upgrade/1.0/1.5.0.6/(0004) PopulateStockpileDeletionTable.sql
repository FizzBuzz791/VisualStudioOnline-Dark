-- Insert records in the BhpbioStockpileDeletion table for all Stockpiles that have a recent import sync Delete operation
INSERT INTO dbo.BhpbioStockpileDeletion(Stockpile_Name)
SELECT  DISTINCT isr.SourceRow.value('(/StockpileSource/Stockpile/StockpileName)[1]', 'VARCHAR(100)') as StockpileName FROM ImportSyncRow isr 
	INNER JOIN ImportSyncQueue isq ON isq.ImportSyncRowId = isr.ImportSyncRowId
WHERE isr.ImportId = 10 AND isq.IsPending = 0 AND isq.SyncAction = 'D'
AND isq.LastProcessedDateTime > '2011-01-01'
GO

-- Having done that, remove deltion rows for any stockpiles that have a current Insert or Delete that has been processed succesfully (not pending)
DELETE sd 
FROM dbo.BhpbioStockpileDeletion sd
WHERE sd.Stockpile_Name 
 IN (
	SELECT  DISTINCT isr.SourceRow.value('(/StockpileSource/Stockpile/StockpileName)[1]', 'VARCHAR(100)') as StockpileName FROM ImportSyncRow isr 
		INNER JOIN ImportSyncQueue isq ON isq.ImportSyncRowId = isr.ImportSyncRowId
	WHERE isr.ImportId = 10 AND isr.IsCurrent = 1 AND isq.IsPending = 0
	AND isq.SyncAction in ('I', 'U')
)
GO
