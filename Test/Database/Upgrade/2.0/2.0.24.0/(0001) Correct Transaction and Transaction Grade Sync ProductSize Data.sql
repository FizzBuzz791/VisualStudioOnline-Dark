/*
* This script is intended to update Transaction and Transaction Grade sync data to include ProductSize information (LUMP, FINES or ROM)
*/

-- Declare Temporary Tables required for preparing information prior to update
DECLARE @Transaction_ImportSyncTableId Int
DECLARE @TransactionGrade_ImportSyncTableId Int

-- Determine the Table Ids
SELECT @Transaction_ImportSyncTableId = ImportSyncTableId
FROM ImportSyncTable
WHERE Name = 'Transaction'

SELECT @TransactionGrade_ImportSyncTableId = ImportSyncTableId
FROM ImportSyncTable
WHERE Name = 'TransactionGrade'

/* Part 1 - determine the ProductSize values for all current transactions */
DECLARE @TransactionProductSize TABLE
(
	ImportSyncRowId Int Primary Key,
	ProductSize nvarchar(5),
	WeightometerSampleId Int,
	RequiresUpdate Bit,
	RequiresInsert Bit,
	UNIQUE (WeightometerSampleId,ImportSyncRowId)
)

-- get the product size where available
INSERT INTO @TransactionProductSize (ImportSyncRowId, ProductSize, WeightometerSampleId)
SELECT 
	   ISR.ImportSyncRowId,
	   ISR.SourceRow.value('(/ProductionSource/Transaction/ProductSize)[1]', 'nvarchar(5)'),
	   ISR.DestinationRow.value('(/ProductionDestination/Transaction/WeightometerSampleId)[1]', 'int')
FROM ImportSyncRow ISR
WHERE ISR.ImportSyncTableId = @Transaction_ImportSyncTableId

-- Any missing values should be considered ROM
-- Any values of 'TOTAL' should be changed to ROM
UPDATE @TransactionProductSize
	SET ProductSize = 'ROM', RequiresInsert = 1 
WHERE ProductSize IS NULL

UPDATE @TransactionProductSize
	SET ProductSize = 'ROM', RequiresUpdate = 1 
WHERE ProductSize = 'TOTAL'

/* Part 2 - determine the ProductSize values needed for all current transactions grades */
DECLARE @TransactionGradeProductSize TABLE
(
	ImportSyncRowId Int Primary Key,
	ProductSize nvarchar(5),
	WeightometerSampleId Int,
	TransactionProductSize nvarchar(5),
	RequiresUpdate Bit,
	RequiresInsert Bit,
	UNIQUE (WeightometerSampleId,ImportSyncRowId)
)

INSERT INTO @TransactionGradeProductSize (ImportSyncRowId, ProductSize, WeightometerSampleId)
SELECT 
	   ISR.ImportSyncRowId,
	   ISR.SourceRow.value('(/ProductionSource/TransactionGrade/ProductSize)[1]', 'nvarchar(5)'),
	   ISR.DestinationRow.value('(/ProductionDestination/TransactionGrade/WeightometerSampleId)[1]', 'int')
FROM ImportSyncRow ISR
WHERE ISR.ImportSyncTableId = @TransactionGrade_ImportSyncTableId

UPDATE tg
	SET TransactionProductSize = t.ProductSize
FROM @TransactionGradeProductSize tg
	INNER JOIN @TransactionProductSize t ON t.WeightometerSampleId = tg.WeightometerSampleId

UPDATE tg
	SET RequiresInsert = 1,
	ProductSize = 'ROM'
FROM @TransactionGradeProductSize tg
WHERE tg.ProductSize IS NULL

UPDATE tg
	SET RequiresUpdate = 1,
	ProductSize = 'ROM'
FROM @TransactionGradeProductSize tg
WHERE tg.ProductSize = 'TOTAL'

UPDATE tg
	SET ProductSize = TransactionProductSize,
	tg.RequiresUpdate = 1
FROM @TransactionGradeProductSize tg
	INNER JOIN @TransactionProductSize t ON t.WeightometerSampleId = tg.WeightometerSampleId
WHERE tg.RequiresInsert = 0  AND Not tg.ProductSize = t.ProductSize

/* Part 3 - Remove Transaction Grade records from temporary store that do NOT require any update */
DELETE @TransactionGradeProductSize 
WHERE RequiresUpdate = 0 AND RequiresInsert = 0

DELETE @TransactionProductSize 
WHERE RequiresUpdate = 0 AND RequiresInsert = 0

/* Part 4 - Perform Updates */
BEGIN TRANSACTION

-- Update the transaction records that are missing a ProductSize to ROM
UPDATE ISR
SET SourceRow.modify('insert <ProductSize>ROM</ProductSize> as last into (/ProductionSource/Transaction)[1]')
FROM @TransactionProductSize t
	INNER JOIN ImportSyncRow isr ON isr.ImportSyncRowId = t.ImportSyncRowId
WHERE t.RequiresInsert = 1 AND t.ProductSize = 'ROM'

UPDATE ISR
SET SourceRow.modify('insert <ProductSize>FINES</ProductSize> as last into (/ProductionSource/Transaction)[1]')
FROM @TransactionProductSize t
	INNER JOIN ImportSyncRow isr ON isr.ImportSyncRowId = t.ImportSyncRowId
WHERE t.RequiresInsert = 1 AND t.ProductSize = 'FINES'

UPDATE ISR
SET SourceRow.modify('insert <ProductSize>LUMP</ProductSize> as last into (/ProductionSource/Transaction)[1]')
FROM @TransactionProductSize t
	INNER JOIN ImportSyncRow isr ON isr.ImportSyncRowId = t.ImportSyncRowId
WHERE t.RequiresInsert = 1 AND t.ProductSize = 'LUMP'

-- Update the transaction records that have a ProductSize but require an update to ROM
UPDATE ISR
SET SourceRow.modify('replace value of (/ProductionSource/Transaction/ProductSize/text())[1] with "ROM"')
FROM @TransactionProductSize t
	INNER JOIN ImportSyncRow isr ON isr.ImportSyncRowId = t.ImportSyncRowId
WHERE t.RequiresUpdate = 1 AND t.ProductSize = 'ROM'

-- Update the transaction records that have a ProductSize but require an update to LUMP
UPDATE ISR
SET SourceRow.modify('replace value of (/ProductionSource/Transaction/ProductSize/text())[1] with "LUMP"')
FROM @TransactionProductSize t
	INNER JOIN ImportSyncRow isr ON isr.ImportSyncRowId = t.ImportSyncRowId
WHERE t.RequiresUpdate = 1 AND t.ProductSize = 'LUMP'

-- Update the transaction records that have a ProductSize but require an update to LUMP
UPDATE ISR
SET SourceRow.modify('replace value of (/ProductionSource/Transaction/ProductSize/text())[1] with "FINES"')
FROM @TransactionProductSize t
	INNER JOIN ImportSyncRow isr ON isr.ImportSyncRowId = t.ImportSyncRowId
WHERE t.RequiresUpdate = 1 AND t.ProductSize = 'FINES'

-- Update the transaction grade records that are missing a ProductSize that should be ROM
UPDATE ISR
SET SourceRow.modify('insert <ProductSize>ROM</ProductSize> as last into (/ProductionSource/TransactionGrade)[1]')
FROM @TransactionGradeProductSize tg
	INNER JOIN ImportSyncRow isr ON isr.ImportSyncRowId = tg.ImportSyncRowId
WHERE tg.RequiresInsert = 1 AND tg.ProductSize = 'ROM'

UPDATE ISR
SET SourceRow.modify('insert <ProductSize>LUMP</ProductSize> as last into (/ProductionSource/TransactionGrade)[1]')
FROM @TransactionGradeProductSize tg
	INNER JOIN ImportSyncRow isr ON isr.ImportSyncRowId = tg.ImportSyncRowId
WHERE tg.RequiresInsert = 1 AND tg.ProductSize = 'LUMP'

UPDATE ISR
SET SourceRow.modify('insert <ProductSize>FINES</ProductSize> as last into (/ProductionSource/TransactionGrade)[1]')
FROM @TransactionGradeProductSize tg
	INNER JOIN ImportSyncRow isr ON isr.ImportSyncRowId = tg.ImportSyncRowId
WHERE tg.RequiresInsert = 1 AND tg.ProductSize = 'FINES'

UPDATE ISR
SET SourceRow.modify('replace value of (/ProductionSource/TransactionGrade/ProductSize/text())[1] with "ROM"')
FROM @TransactionGradeProductSize tg
	INNER JOIN ImportSyncRow isr ON isr.ImportSyncRowId = tg.ImportSyncRowId
WHERE tg.RequiresUpdate = 1 AND tg.ProductSize = 'ROM'

UPDATE ISR
SET SourceRow.modify('replace value of (/ProductionSource/TransactionGrade/ProductSize/text())[1] with "LUMP"')
FROM @TransactionGradeProductSize tg
	INNER JOIN ImportSyncRow isr ON isr.ImportSyncRowId = tg.ImportSyncRowId
WHERE tg.RequiresUpdate = 1 AND tg.ProductSize = 'LUMP'

UPDATE ISR
SET SourceRow.modify('replace value of (/ProductionSource/TransactionGrade/ProductSize/text())[1] with "FINES"')
FROM @TransactionGradeProductSize tg
	INNER JOIN ImportSyncRow isr ON isr.ImportSyncRowId = tg.ImportSyncRowId
WHERE tg.RequiresUpdate = 1 AND tg.ProductSize = 'FINES'

COMMIT TRANSACTION

/* Finish */