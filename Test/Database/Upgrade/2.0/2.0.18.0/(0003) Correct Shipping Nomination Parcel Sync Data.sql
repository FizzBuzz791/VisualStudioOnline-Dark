DECLARE @Nomination_ImportSyncTableId Int
DECLARE @NominationParcel_ImportSyncTableId Int
DECLARE @NominationParcelGrade_ImportSyncTableId Int

SELECT @Nomination_ImportSyncTableId = ImportSyncTableId
FROM ImportSyncTable
WHERE Name = 'Nomination'

SELECT @NominationParcel_ImportSyncTableId = ImportSyncTableId
FROM ImportSyncTable
WHERE Name = 'NominationParcel'

SELECT @NominationParcelGrade_ImportSyncTableId = ImportSyncTableId
FROM ImportSyncTable
WHERE Name = 'NominationParcelGrade'

DECLARE @NominationItem TABLE
(
	ImportSyncQueueId Int Primary Key,
	ImportSyncRowId Int,
	NominationKey varchar(10),
	ItemNo varchar(3),
	HubProduct varchar(4),
	IsPending bit,
	IsCurrent bit,
	Error VarChar(100),
	Exception VarChar(8000)
)

INSERT INTO @NominationItem
SELECT ISQ.ImportSyncQueueId,
	ISR.ImportSyncRowId,
	ISR.SourceRow.value('(/ShippingSource/NominationParcel/NominationKey)[1]', 'nvarchar(10)') As NominationKey,
	ISR.SourceRow.value('(/ShippingSource/NominationParcel/ItemNo)[1]', 'nvarchar(3)') As ItemNo,
	ISR.SourceRow.value('(/ShippingSource/NominationParcel/HubProduct)[1]', 'nvarchar(4)') As HubProduct,
	ISQ.IsPending,
	ISR.IsCurrent,
	ISV.UserMessage,
	ISE.UserMessage + ISE.InternalMessage
FROM ImportSyncRow ISR
INNER JOIN IMPORTSYNCQUEUE ISQ ON ISR.IMPORTSYNCROWID = ISQ.IMPORTSYNCROWID
LEFT JOIN importsyncvalidate ISV on isq.importsyncqueueid = isv.importsyncqueueid
LEFT JOIN importsyncException ISE on isq.importsyncqueueid = ISE.importsyncqueueid
WHERE ISR.ImportId = 7
AND ISR.ImportSyncTableId = @NominationParcel_ImportSyncTableId

update isq
set ispending = 0
from importsyncqueue isq
inner join importsyncrow isr on isr.importsyncrowid = isq.importsyncrowid
inner join importsyncrow isrnext on isrnext.previousimportsyncrowid = isr.importsyncrowid
left JOIN importsyncException ISE on isq.importsyncqueueid = ISE.importsyncqueueid
where isq.importid = 7
and isq.ispending = 1
and isr.isupdated = 1

update isq
set ispending = 0
from importsyncqueue isq
inner join importsyncrow isr on isr.importsyncrowid = isq.importsyncrowid
left join importsyncException ISE on isq.importsyncqueueid = ISE.importsyncqueueid
where isq.importid = 7
and isq.ispending = 1
and isr.ImportSyncTableId = 27
and isr.DestinationRow.value('(/ShippingDestination/NominationParcel/BhpbioShippingNominationItemParcelId)[1]', 'Int') is not null

update isq
set ispending = 0
from importsyncqueue isq
inner join importsyncrow isr on isr.importsyncrowid = isq.importsyncrowid
left join importsyncException ISE on isq.importsyncqueueid = ISE.importsyncqueueid
where isq.importid = 7
and isq.ispending = 1
and isr.ImportSyncTableId = 8
and isr.DestinationRow.value('(/ShippingDestination/Nomination/BhpbioShippingNominationItemId)[1]', 'Int') is not null

UPDATE ISR
SET IsDeleted = 1, IsCurrent = 0
FROM @NominationItem NI
INNER JOIN ImportSyncRow ISR
	ON ISR.ImportSyncRowId = NI.ImportSyncRowId
INNER JOIN ImportSyncQueue ISQ
	ON ISQ.ImportSyncQueueId = NI.ImportSyncQueueId
INNER JOIN @NominationItem NI2
	ON NI.NominationKey = NI2.NominationKey
	AND NI.ItemNo = NI2.ItemNo
	AND NI.HubProduct = NI2.HubProduct
	AND NI.ImportSyncRowId <> NI2.ImportSyncRowId
INNER JOIN ImportSyncRow ISR2
	ON ISR2.ImportSyncRowId = NI2.ImportSyncRowId
INNER JOIN ImportSyncQueue ISQ2
	ON ISQ2.ImportSyncQueueId = NI2.ImportSyncQueueId
WHERE NI.Exception Is Not Null
AND ISR2.IsCurrent = 1

UPDATE ISQ
SET IsPending = 0
FROM @NominationItem NI
INNER JOIN ImportSyncRow ISR
	ON ISR.ImportSyncRowId = NI.ImportSyncRowId
INNER JOIN ImportSyncQueue ISQ
	ON ISQ.ImportSyncQueueId = NI.ImportSyncQueueId
INNER JOIN @NominationItem NI2
	ON NI.NominationKey = NI2.NominationKey
	AND NI.ItemNo = NI2.ItemNo
	AND NI.HubProduct = NI2.HubProduct
	AND NI.ImportSyncRowId <> NI2.ImportSyncRowId
INNER JOIN ImportSyncRow ISR2
	ON ISR2.ImportSyncRowId = NI2.ImportSyncRowId
INNER JOIN ImportSyncQueue ISQ2
	ON ISQ2.ImportSyncQueueId = NI2.ImportSyncQueueId
WHERE NI.Exception Is Not Null
AND ISR2.IsCurrent = 1

UPDATE ISRCHI
SET IsDeleted = 1
FROM @NominationItem NI
INNER JOIN ImportSyncRow ISR
	ON ISR.ImportSyncRowId = NI.ImportSyncRowId
INNER JOIN ImportSyncQueue ISQ
	ON ISQ.ImportSyncQueueId = NI.ImportSyncQueueId
inner join importsyncrelationship isrel on isrel.parentimportsyncrowid = isr.importsyncrowid
inner join importsyncrow isrchi on isrel.importsyncrowid = isrchi.importsyncrowid
inner join importsyncqueue isqchi on isqchi.importsyncrowid = isrchi.importsyncrowid
WHERE NI.Hub = 'NBL'
aND isqchi.IsPending = 1
AND ISR.IsDeleted = 1

UPDATE ISQCHI
SET IsPending = 0
FROM @NominationItem NI
INNER JOIN ImportSyncRow ISR
	ON ISR.ImportSyncRowId = NI.ImportSyncRowId
INNER JOIN ImportSyncQueue ISQ
	ON ISQ.ImportSyncQueueId = NI.ImportSyncQueueId
inner join importsyncrelationship isrel on isrel.parentimportsyncrowid = isr.importsyncrowid
inner join importsyncrow isrchi on isrel.importsyncrowid = isrchi.importsyncrowid
inner join importsyncqueue isqchi on isqchi.importsyncrowid = isrchi.importsyncrowid
WHERE NI.Hub = 'NBL'
AND isqchi.IsPending = 1
AND ISR.IsDeleted = 1
