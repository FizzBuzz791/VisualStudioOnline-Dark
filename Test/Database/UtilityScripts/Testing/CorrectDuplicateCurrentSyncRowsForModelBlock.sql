DECLARE @syncData TABLE
(
	ModelBlockId Int Null,
	ImportSyncRowId Int Null,
	Unique (ModelBlockId, ImportSyncRowId)
)

DECLARE @syncDataMax TABLE
(
	ModelBlockId Int Null,
	MaxImportSyncRowId Int Null,
	Unique (ModelBlockId)
)

Insert Into @syncData(ModelBlockId,ImportSyncRowId)
SELECT	isr.DestinationRow.value('(/BlockModelDestination/BlastModelBlockWithPointAndGrade/ModelBlockId)[1]', 'int'), isr.ImportSyncRowId
FROM ImportSyncRow  isr
WHERE isr.ImportSyncTableId = 1 AND isr.IsCurrent = 1

-- remove  IsCurrent flag if there is no matched ModelBlockId
UPDATE isru
SET isru.IsCurrent = 0
FROM ImportSyncRow isru
INNER JOIN @syncData sd ON sd.ImportSyncRowId = isru.ImportSyncRowId 
WHERE isru.ImportSyncTableId = 1 AND isru.IsCurrent = 1 AND sd.ModelBlockId IS NULL -- can't be current if ModelBlockId is null

Insert Into @syncDataMax(ModelBlockId,MaxImportSyncRowId)
SELECT	sd.ModelBlockId, Max(sd.ImportSyncRowId)
FROM @syncData  sd
GROUP BY sd.ModelBlockId

-- remove  IsCurrent flag if there is a later sync row for the ModelBlockId that is also current
UPDATE isru
SET isru.IsCurrent = 0
FROM ImportSyncRow isru
INNER JOIN @syncData sd ON sd.ImportSyncRowId = isru.ImportSyncRowId 
INNER JOIN @syncDataMax sdm ON sdm.ModelBlockId = sd.ModelBlockId
WHERE isru.ImportSyncTableId = 1 AND isru.IsCurrent = 1 AND sdm.MaxImportSyncRowId > sd.ImportSyncRowId