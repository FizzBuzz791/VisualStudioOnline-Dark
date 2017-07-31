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
	IsPending bit,
	IsCurrent bit,
	Error VarChar(100),
	Exception VarChar(8000)
)

INSERT INTO @NominationItem
SELECT ISQ.ImportSyncQueueId,
	ISR.ImportSyncRowId,
	ISR.SourceRow.value('(/ShippingSource/Nomination/NominationKey)[1]', 'nvarchar(10)') As NominationKey,
	ISR.SourceRow.value('(/ShippingSource/Nomination/ItemNo)[1]', 'nvarchar(3)') As ItemNo,
	ISQ.IsPending,
	ISR.IsCurrent,
	ISV.UserMessage,
	ISE.UserMessage + ISE.InternalMessage
FROM ImportSyncRow ISR
INNER JOIN IMPORTSYNCQUEUE ISQ ON ISR.IMPORTSYNCROWID = ISQ.IMPORTSYNCROWID
LEFT JOIN importsyncvalidate ISV on isq.importsyncqueueid = isv.importsyncqueueid
LEFT JOIN importsyncException ISE on isq.importsyncqueueid = ISE.importsyncqueueid
WHERE ISR.ImportId = 7
AND ISR.ImportSyncTableId = @Nomination_ImportSyncTableId

UPDATE ISR
SET DestinationRow = ISR2.DestinationRow
FROM @NominationItem NI
INNER JOIN ImportSyncRow ISR
	ON ISR.ImportSyncRowId = NI.ImportSyncRowId
INNER JOIN ImportSyncQueue ISQ
	ON ISQ.ImportSyncQueueId = NI.ImportSyncQueueId
INNER JOIN @NominationItem NI2
	ON NI.NominationKey = NI2.NominationKey
	AND NI.ItemNo = NI2.ItemNo
	AND NI.ImportSyncRowId <> NI2.ImportSyncRowId
INNER JOIN ImportSyncRow ISR2
	ON ISR2.ImportSyncRowId = NI2.ImportSyncRowId
INNER JOIN ImportSyncQueue ISQ2
	ON ISQ2.ImportSyncQueueId = NI2.ImportSyncQueueId
WHERE (ISR.DestinationRow.value('(/ShippingDestination/Nomination/BhpbioShippingNominationItemId)[1]', 'Int') Is Null
  OR ISR.DestinationRow.value('(/ShippingDestination/Nomination/BhpbioShippingNominationItemId)[1]', 'Int') = 0)
AND (ISR2.DestinationRow.value('(/ShippingDestination/Nomination/BhpbioShippingNominationItemId)[1]', 'Int') > 0)
AND (ISQ.IsPending = 0 OR ISR.IsCurrent = 1)
AND (ISR.IsDeleted = 0)
AND ISR.ImportSyncRowId > ISR2.ImportSyncRowId

