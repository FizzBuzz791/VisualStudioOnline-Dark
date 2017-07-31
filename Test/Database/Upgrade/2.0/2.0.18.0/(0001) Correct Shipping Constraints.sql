ALTER TABLE BhpbioShippingNominationItemParcel
	DROP CONSTRAINT [IX__BhpbioShippingNominationItemParcel_Hub]
GO
		
ALTER TABLE BhpbioShippingNominationItemParcel
	ADD CONSTRAINT [IX__BhpbioShippingNominationItemParcel_HubProduct]
	UNIQUE (BhpbioShippingNominationItemId ASC, HubProduct ASC)
GO
	
CREATE CLUSTERED INDEX [IX__BhpbioShippingNominationItemParcel_HubLocation]
	ON BhpbioShippingNominationItemParcel ([BhpbioShippingNominationItemId] ASC, HubLocationId ASC)	
GO

DECLARE @NominationParcel_ImportSyncTableId Int

SELECT @NominationParcel_ImportSyncTableId = ImportSyncTableId
FROM ImportSyncTable
WHERE Name = 'NominationParcel'

DECLARE @NominationItem TABLE
(
	ImportSyncQueueId Int Primary Key,
	ImportSyncRowId Int,
	NominationKey varchar(10),
	ItemNo varchar(3),
	Hub varchar(3),
	HubProduct varchar(4),
	BhpbioShippingNominationItemParcelId Int
)

INSERT INTO @NominationItem
SELECT ISQ.ImportSyncQueueId,
	ISR.ImportSyncRowId,
	ISR.SourceRow.value('(/ShippingSource/NominationParcel/NominationKey)[1]', 'nvarchar(10)') As NominationKey,
	ISR.SourceRow.value('(/ShippingSource/NominationParcel/ItemNo)[1]', 'nvarchar(3)') As ItemNo,
	ISR.SourceRow.value('(/ShippingSource/NominationParcel/Hub)[1]', 'nvarchar(3)') As Hub,
	ISR.SourceRow.value('(/ShippingSource/NominationParcel/HubProduct)[1]', 'nvarchar(4)') As HubProduct,
	ISR.DestinationRow.value('(/ShippingDestination/NominationParcel/BhpbioShippingNominationItemParcelId)[1]', 'Int') As BhpbioShippingNominationItemParcelId
FROM ImportSyncRow ISR
INNER JOIN IMPORTSYNCQUEUE ISQ ON ISR.IMPORTSYNCROWID = ISQ.IMPORTSYNCROWID
WHERE ISR.ImportId = 7
AND ISR.ImportSyncTableId = @NominationParcel_ImportSyncTableId
AND ISR.IsCurrent = 1
AND ISQ.IsPending = 0

UPDATE NIP
	SET HubLocationId = L.Location_Id
FROM @NominationItem NI
INNER JOIN BhpbioShippingNominationItemParcel NIP On NI.BhpbioShippingNominationItemParcelId = NIP.BhpbioShippingNominationItemParcelId
INNER JOIN Location L
	On L.NAme = CASE 
		WHEN NI.Hub = 'YND' THEN 'YANDI'
		WHEN NI.Hub = 'MAC' THEN 'AREAC'
		WHEN NI.Hub = 'GWY' THEN 'YARRIE'
		WHEN NI.Hub = 'NHG' THEN 'NJV'
		WHEN NI.Hub = 'JMB' THEN 'JIMBLEBAR'
		WHEN NI.Hub = 'JIM' THEN 'JINGBAO'
	END
	AND L.Location_Type_Id = 2
WHERE NIP.HubLocationId = 0

GO

ALTER TABLE BhpbioShippingNominationItemParcel
	ADD CONSTRAINT FK_BhpbioShippingNominationParcel_HubLocationId_Location
		FOREIGN KEY (HubLocationId)
		REFERENCES dbo.Location (Location_Id)
GO






