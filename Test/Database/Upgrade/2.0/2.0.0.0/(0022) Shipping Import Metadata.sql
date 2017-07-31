BEGIN TRANSACTION

ALTER TABLE ImportSyncRow ADD OriginalId INT NULL
GO

DECLARE @Nomination_ImportSyncTableId Int
DECLARE @NominationParcel_ImportSyncTableId Int
DECLARE @NominationParcelGrade_ImportSyncTableId Int

DECLARE @ImportSync TABLE  (
	-- FROM ISQ
	--[ImportSyncQueueId] [bigint] IDENTITY(1,1) NOT NULL,
	[ImportSyncRowId] [bigint] NOT NULL,
	[ImportSyncTableId] [smallint] NOT NULL,
	[ImportId] [smallint] NOT NULL,
	[IsPending] [bit] NOT NULL,
	[OrderNo] [int] NULL,
	[SyncAction] [char](1) NOT NULL,
	[InitialComparedDateTime] [datetime] NOT NULL,
	[LastProcessedDateTime] [datetime] NULL,
	[InitialCompareImportJobId] [int] NULL,
	[LastProcessImportJobId] [int] NULL,
	-- FROM ISR
	-- [ImportSyncRowId] [bigint] IDENTITY(1,1) NOT NULL,
	-- [ImportId] [smallint] NOT NULL,
	-- [ImportSyncTableId] [smallint] NOT NULL,
	[IsCurrent] [bit] NOT NULL,
	[SourceRow] [xml] NOT NULL,
	[DestinationRow] [xml] NOT NULL,
	[IsUpdated] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[PreviousImportSyncRowId] [bigint] NULL,
	[RootImportSyncRowId] [bigint] NOT NULL,
	
	PRIMARY KEY (ImportSyncRowId)
)

DECLARE @ImportSyncRowIdMap TABLE (
	NewImportSyncRowId bigint,
	ImportSyncRowId bigint,

	PRIMARY KEY (NewImportSyncRowId, ImportSyncRowId)
)

-- Shipping Schema Changes

UPDATE dbo.ImportSyncTable
SET Name = 'Nomination'
WHERE Name = 'TransactionNomination'

UPDATE dbo.ImportSyncTable
SET Name = 'NominationParcelGrade'
WHERE Name = 'TransactionNominationGrade'

IF (NOT EXISTS (SELECT 1 FROM ImportSyncTable WHERE Name = 'NominationParcel'))
BEGIN
	Insert Into ImportSyncTable
	(
		ImportId, [Name]
	)
	Select ImportId, 'NominationParcel' From Import Where ImportName = 'Shipping'
END

SELECT @Nomination_ImportSyncTableId = ImportSyncTableId
FROM ImportSyncTable
WHERE Name = 'Nomination'

SELECT @NominationParcel_ImportSyncTableId = ImportSyncTableId
FROM ImportSyncTable
WHERE Name = 'NominationParcel'

SELECT @NominationParcelGrade_ImportSyncTableId = ImportSyncTableId
FROM ImportSyncTable
WHERE Name = 'NominationParcelGrade'

-- update existing xml structures 

-- NOMINATION SOURCE
-- change table name

UPDATE ISR
SET SourceRow = SourceRow.query('<ShippingSource><Nomination>{ShippingSource/TransactionNomination/*}</Nomination></ShippingSource>')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @Nomination_ImportSyncTableId

-- rename nomination item no field
UPDATE ISR
SET SourceRow.modify('insert <ItemNo>{(/ShippingSource/Nomination/Nomination/text())[1]}</ItemNo> as last into (/ShippingSource/Nomination)[1]')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @Nomination_ImportSyncTableId

UPDATE ISR
SET SourceRow.modify('delete (/ShippingSource/Nomination/Nomination)')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @Nomination_ImportSyncTableId

-- rename Product as ShippedProduct
UPDATE ISR
SET SourceRow.modify('insert <ShippedProduct>{(/ShippingSource/Nomination/Product/text())[1]}</ShippedProduct> as last into (/ShippingSource/Nomination)[1]')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @NominationParcel_ImportSyncTableId

UPDATE ISR
SET SourceRow.modify('delete (/ShippingSource/Nomination/Product)')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @NominationParcel_ImportSyncTableId

-- NOMINATION DESTINATION
UPDATE ISR
SET DestinationRow = DestinationRow.query('<ShippingDestination><Nomination>{ShippingDestination/TransactionNomination/*}</Nomination></ShippingDestination>')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @Nomination_ImportSyncTableId

-- rename destination table key field
UPDATE ISR
SET DestinationRow.modify('insert <BhpbioShippingNominationItemId>{(/ShippingDestination/Nomination/BhpbioShippingTransactionNominationId/text())[1]}</BhpbioShippingNominationItemId> as first into (/ShippingDestination/Nomination)[1]')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @Nomination_ImportSyncTableId

UPDATE ISR
SET DestinationRow.modify('delete (/ShippingDestination/Nomination/BhpbioShippingTransactionNominationId)')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @Nomination_ImportSyncTableId

-- NOMINATION PARCEL CREATE RECORDS

INSERT INTO @ImportSync
SELECT isr.ImportSyncRowId,
	@NominationParcel_ImportSyncTableId,
	isr.ImportId,
	0 As IsPending,
	1 As OrderNo,
	'I' As SyncAction,
	isq.InitialComparedDateTime,
	isq.LastProcessedDateTime,
	isq.InitialCompareImportJobId,
	isq.LastProcessImportJobId,
	1 As IsCurrent,
	isr.SourceRow,
	isr.DestinationRow,
	0 As IsUpdated,
	0 As IsDeleted,
	NULL As PreviousImportSyncRowId,
	isr.ImportSyncRowId As RootImportSyncRowId
FROM ImportSyncRow isr
INNER JOIN ImportSyncQueue isq ON ISR.ImportSyncRowId = ISQ.ImportSyncRowId
WHERE isq.ImportSyncTableId = @Nomination_ImportSyncTableId
AND IsCurrent = 1

INSERT INTO ImportSyncRow (
	ImportId,
	ImportSyncTableId,
	IsCurrent,
	SourceRow,
	DestinationRow,
	IsUpdated,
	IsDeleted,
	PreviousImportSyncRowId,
	RootImportSyncRowId,
	OriginalId)
SELECT ImportId,
	ImportSyncTableId,
	IsCurrent,
	SourceRow,
	DestinationRow,
	IsUpdated,
	IsDeleted,
	PreviousImportSyncRowId, 
	RootImportSyncRowId,
	ImportSyncRowId
FROM @ImportSync 

INSERT INTO ImportSyncQueue (
	ImportSyncRowId,
	ImportSyncTableId,
	ImportId,
	IsPending,
	OrderNo,
	SyncAction,
	InitialComparedDateTime,
	LastProcessedDateTime,
	InitialCompareImportJobId,
	LastProcessImportJobId)
SELECT isr.ImportSyncRowId,
	ims.ImportSyncTableId,
	ims.ImportId,
	IsPending,
	OrderNo,
	SyncAction,
	InitialComparedDateTime,
	LastProcessedDateTime,
	InitialCompareImportJobId,
	LastProcessImportJobId
FROM @ImportSync ims
INNER JOIN ImportSyncRow isr ON ims.ImportSyncRowId = isr.OriginalId

-- NOMINATION PARCEL SOURCE

-- change table name
UPDATE ISR
SET SourceRow = SourceRow.query('<ShippingSource><NominationParcel>{ShippingSource/Nomination/*}</NominationParcel></ShippingSource>')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @NominationParcel_ImportSyncTableId

-- rename Product as HubProduct
UPDATE ISR
SET SourceRow.modify('insert <HubProduct>{(/ShippingSource/NominationParcel/Product/text())[1]}</HubProduct> as last into (/ShippingSource/NominationParcel)[1]')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @NominationParcel_ImportSyncTableId

UPDATE ISR
SET SourceRow.modify('delete (/ShippingSource/NominationParcel/Product[1])')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @NominationParcel_ImportSyncTableId



-- NOMINATION PARCEL DESTINATION
-- rename destination table
UPDATE ISR
SET DestinationRow = DestinationRow.query('<ShippingDestination><NominationParcel>{ShippingDestination/Nomination/*}</NominationParcel></ShippingDestination>')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @NominationParcel_ImportSyncTableId

-- delete and replace destination table key field
UPDATE ISR
SET DestinationRow.modify('delete (/ShippingDestination/NominationParcel/BhpbioShippingNominationItemId[1])')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @NominationParcel_ImportSyncTableId

UPDATE ISR
SET DestinationRow.modify('insert <BhpbioShippingNominationItemParcelId>{sql:column("NIP.BhpbioShippingNominationItemParcelId")}</BhpbioShippingNominationItemParcelId> as first into (/ShippingDestination/NominationParcel)[1]')
FROM ImportSyncRow ISR
INNER JOIN BhpbioShippingNominationItem NI
	ON ISR.SourceRow.value('(/ShippingSource/NominationParcel/NominationKey)[1]', 'nvarchar(10)') = NI.NominationKey
	AND ISR.SourceRow.value('(/ShippingSource/NominationParcel/ItemNo)[1]', 'nvarchar(3)') = NI.ItemNo
INNER JOIN BhpbioShippingNominationItemParcel NIP
	ON NI.BhpbioShippingNominationItemId = NIP.BhpbioShippingNominationItemId
WHERE ImportId = 7
AND ImportSyncTableId = @NominationParcel_ImportSyncTableId

-- NOMINATION PARCEL GRADE SOURCE
-- table name change
UPDATE ISR
SET SourceRow = SourceRow.query('<ShippingSource><NominationParcelGrade>{ShippingSource/TransactionNominationGrade/*}</NominationParcelGrade></ShippingSource>')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @NominationParcelGrade_ImportSyncTableId

---- delete official finish time
UPDATE ISR
SET SourceRow.modify('delete (/ShippingSource/NominationParcelGrade/OfficialFinishTime)[1]')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @NominationParcelGrade_ImportSyncTableId

---- rename nomination item no field
UPDATE ISR
SET SourceRow.modify('insert <ItemNo>{(/ShippingSource/NominationParcelGrade/Nomination/text())[1]}</ItemNo> as first into (/ShippingSource/NominationParcelGrade)[1]')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @NominationParcelGrade_ImportSyncTableId

UPDATE ISR
SET SourceRow.modify('delete (/ShippingSource/NominationParcelGrade/Nomination)')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @NominationParcelGrade_ImportSyncTableId

-- add hub product
;WITH NominationItemHub AS
(
	SELECT 
		ISR.SourceRow.value('(/ShippingSource/NominationParcel/NominationKey)[1]', 'nvarchar(10)') AS NominationKey,
		ISR.SourceRow.value('(/ShippingSource/NominationParcel/ItemNo)[1]', 'nvarchar(3)') AS ItemNo,
		ISR.SourceRow.value('(/ShippingSource/NominationParcel/HubProduct)[1]', 'nvarchar(10)') AS HubProduct
	FROM ImportSyncRow ISR
	WHERE ISR.ImportId = 7
	AND ISR.ImportSyncTableId = @NominationParcel_ImportSyncTableId
	AND ISR.IsCurrent = 1
)	
UPDATE ISR
SET SourceRow.modify('insert <HubProduct>{sql:column("NIH.HubProduct")}</HubProduct> as first into (/ShippingSource/NominationParcelGrade)[1]')
FROM ImportSyncRow ISR
INNER JOIN NominationItemHub NIH 
	ON ISR.SourceRow.value('(/ShippingSource/NominationParcelGrade/NominationKey)[1]', 'nvarchar(10)') = NIH.NominationKey
	AND ISR.SourceRow.value('(/ShippingSource/NominationParcelGrade/ItemNo)[1]', 'nvarchar(3)') = NIH.ItemNo
WHERE ISR.ImportId = 7
AND ISR.ImportSyncTableId = @NominationParcelGrade_ImportSyncTableId
AND ISR.IsCurrent = 1
AND (ISR.SourceRow.exist('(/ShippingSource/NominationParcelGrade/HubProduct)[1]') = 0)

-- add hub location
;WITH NominationItemHub AS
(
	SELECT 
		ISR.SourceRow.value('(/ShippingSource/NominationParcel/NominationKey)[1]', 'nvarchar(10)') AS NominationKey,
		ISR.SourceRow.value('(/ShippingSource/NominationParcel/ItemNo)[1]', 'nvarchar(3)') AS ItemNo,
		ISR.SourceRow.value('(/ShippingSource/NominationParcel/Hub)[1]', 'nvarchar(10)') AS Hub
	FROM ImportSyncRow ISR
	WHERE ISR.ImportId = 7
	AND ISR.ImportSyncTableId = @NominationParcel_ImportSyncTableId
	AND ISR.IsCurrent = 1
)	
UPDATE ISR
SET SourceRow.modify('insert <Hub>{sql:column("NIH.Hub")}</Hub> as first into (/ShippingSource/NominationParcelGrade)[1]')
FROM ImportSyncRow ISR
INNER JOIN NominationItemHub NIH 
	ON ISR.SourceRow.value('(/ShippingSource/NominationParcelGrade/NominationKey)[1]', 'nvarchar(10)') = NIH.NominationKey
	AND ISR.SourceRow.value('(/ShippingSource/NominationParcelGrade/ItemNo)[1]', 'nvarchar(3)') = NIH.ItemNo
WHERE ISR.ImportId = 7
AND ISR.ImportSyncTableId = @NominationParcelGrade_ImportSyncTableId
AND ISR.IsCurrent = 1
AND (ISR.SourceRow.exist('(/ShippingSource/NominationParcelGrade/Hub)[1]') = 0)

-- add official finish time 
;WITH NominationItemHub AS
(
	SELECT 
		ISR.SourceRow.value('(/ShippingSource/Nomination/NominationKey)[1]', 'nvarchar(10)') AS NominationKey,
		ISR.SourceRow.value('(/ShippingSource/Nomination/ItemNo)[1]', 'nvarchar(3)') AS ItemNo,
		ISR.SourceRow.value('(/ShippingSource/Nomination/OfficialFinishTime)[1]', 'varchar(30)') AS OfficialFinishTime
	FROM ImportSyncRow ISR
	WHERE ISR.ImportId = 7
	AND ISR.ImportSyncTableId = @Nomination_ImportSyncTableId
	AND ISR.IsCurrent = 1
)	
UPDATE ISR
SET SourceRow.modify('insert <OfficialFinishTime>{sql:column("NIH.OfficialFinishTime")}</OfficialFinishTime> as first into (/ShippingSource/NominationParcelGrade)[1]')
FROM ImportSyncRow ISR
INNER JOIN NominationItemHub NIH 
	ON ISR.SourceRow.value('(/ShippingSource/NominationParcelGrade/NominationKey)[1]', 'nvarchar(10)') = NIH.NominationKey
	AND ISR.SourceRow.value('(/ShippingSource/NominationParcelGrade/ItemNo)[1]', 'nvarchar(3)') = NIH.ItemNo
WHERE ISR.ImportId = 7
AND ISR.ImportSyncTableId = @NominationParcelGrade_ImportSyncTableId
AND ISR.IsCurrent = 1
AND (ISR.SourceRow.exist('(/ShippingSource/NominationParcelGrade/OfficialFinishTime)[1]') = 0)

---- rename grade name field
UPDATE ISR
SET SourceRow.modify('insert <GradeName>{(/ShippingSource/NominationParcelGrade/Name/text())[1]}</GradeName> as last into (/ShippingSource/NominationParcelGrade)[1]')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @NominationParcelGrade_ImportSyncTableId

UPDATE ISR
SET SourceRow.modify('delete (/ShippingSource/NominationParcelGrade/Name)')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @NominationParcelGrade_ImportSyncTableId

-- rename grade value field
UPDATE ISR
SET SourceRow.modify('insert <HeadValue>{(/ShippingSource/NominationParcelGrade/Value/text())[1]}</HeadValue> as last into (/ShippingSource/NominationParcelGrade)[1]')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @NominationParcelGrade_ImportSyncTableId

UPDATE ISR
SET SourceRow.modify('delete (/ShippingSource/NominationParcelGrade/Value)')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @NominationParcelGrade_ImportSyncTableId


-- NOMINATION GRADE DESTINATION
-- rename destination table
UPDATE ISR
SET DestinationRow = DestinationRow.query('<ShippingDestination><NominationParcelGrade>{ShippingDestination/TransactionNominationGrade/*}</NominationParcelGrade></ShippingDestination>')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @NominationParcelGrade_ImportSyncTableId

-- rename destination table key field
UPDATE ISR
SET DestinationRow.modify('insert <BhpbioShippingNominationItemParcelId>{(/ShippingDestination/NominationParcelGrade/BhpbioShippingTransactionNominationId/text())[1]}</BhpbioShippingNominationItemParcelId> as first into (/ShippingDestination/NominationParcelGrade)[1]')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @NominationParcelGrade_ImportSyncTableId

UPDATE ISR
SET DestinationRow.modify('delete (/ShippingDestination/NominationParcelGrade/BhpbioShippingTransactionNominationId)')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @NominationParcelGrade_ImportSyncTableId


-- delete elements not required - NOMINATION
UPDATE ISR
SET SourceRow.modify('delete (/ShippingSource/Nomination/Hub)')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @Nomination_ImportSyncTableId

UPDATE ISR
SET SourceRow.modify('delete (/ShippingSource/Nomination/Product)')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @Nomination_ImportSyncTableId

UPDATE ISR
SET SourceRow.modify('delete (/ShippingSource/Nomination/Tonnes)')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @Nomination_ImportSyncTableId

-- delete elements not required - NOMINATION PARCEL
UPDATE ISR
SET SourceRow.modify('delete (/ShippingSource/NominationParcel/LastAuthorisedDate[1])')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @NominationParcel_ImportSyncTableId

UPDATE ISR
SET SourceRow.modify('delete (/ShippingSource/NominationParcel/VesselName[1])')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @NominationParcel_ImportSyncTableId

UPDATE ISR
SET SourceRow.modify('delete (/ShippingSource/NominationParcel/CustomerNo[1])')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @NominationParcel_ImportSyncTableId

UPDATE ISR
SET SourceRow.modify('delete (/ShippingSource/NominationParcel/CustomerName[1])')
FROM ImportSyncRow ISR
WHERE ImportId = 7
AND ImportSyncTableId = @NominationParcel_ImportSyncTableId

-- update import sync row relationships
-- parcel grade redirect to parcel parent
UPDATE ISREL
	SET ParentImportSyncRowId = ISR.ImportSyncRowId
FROM ImportSyncRelationship ISREL
INNER JOIN ImportSyncRow ISR 
	ON ISREL.ParentImportSyncRowId = ISR.OriginalId
WHERE ISR.ImportSyncTableId = @NominationParcel_ImportSyncTableId
AND ISR.OriginalId IS NOT NULL

-- parcel to nomination item
INSERT INTO ImportSyncRelationship (ImportSyncRowId, ParentImportSyncRowId, IsCurrent)
SELECT DISTINCT ISR.ImportSyncRowId, ISR.OriginalId, ISR.IsCurrent
FROM ImportSyncRow ISR 
WHERE ISR.ImportSyncTableId = @NominationParcel_ImportSyncTableId
AND ISR.OriginalId IS NOT NULL


ALTER TABLE ImportSyncRow DROP COLUMN OriginalId
GO

UPDATE ISQPAR
SET ISPENDING = 1
FROM IMPORTSYNCQUEUE ISQ
INNER JOIN IMPORTSYNCROW ISR ON ISR.IMPORTSYNCROWID = ISQ.IMPORTSYNCROWID
INNER JOIN IMPORTSYNCRELATIONSHIP ISREL ON ISREL.IMPORTSYNCROWID = ISQ.IMPORTSYNCROWID
INNER JOIN IMPORTSYNCROW ISRPAR ON ISREL.PARENTIMPORTSYNCROWID = ISRPAR.IMPORTSYNCROWID
INNER JOIN IMPORTSYNCQUEUE ISQPAR ON ISQPAR.IMPORTSYNCROWID = ISRPAR.IMPORTSYNCROWID
WHERE ISQ.IMPORTID = 7
AND ISQ.ISPENDING = 1
AND ISQPAR.ISPENDING = 0

COMMIT TRANSACTION


