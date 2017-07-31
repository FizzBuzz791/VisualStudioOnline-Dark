
Insert Into dbo.ImportSyncTable
(
	ImportId, [Name]
)
Select ImportId, 'TransactionGrade' From dbo.Import Where ImportName = 'Production'
Go

Insert Into dbo.ImportSyncTable
(
	ImportId, [Name]
)
Select ImportId, 'PortBalanceGrade' From dbo.Import Where ImportName = 'PortBalance'
Go

Insert Into dbo.ImportSyncTable
(
	ImportId, [Name]
)
Select ImportId, 'MetBalancingGrade' From dbo.Import Where ImportName = 'Met Balancing'
Go

-- WARNING: the following data fixes must be executed once only!!!!!!! Otherwise it will create duplicate elements in dbo.ImportSyncRow table!

--!!!!!!!!!!!!!!!!MET BALANCING IMPORT!!!!!!!!!!!!!!!!!!!
Update dbo.ImportSyncRow
Set SourceRow.modify('insert <ProductSize>TOTAL</ProductSize> as last into (/MetBalancingSource/MetBalancing)[1]')
Where ImportId = 6
	And IsCurrent = 1
	And ImportSyncTableId = 7 -- MetBalancing
Go

--!!!!!!!!!!!!!!!!PORT BALANCE IMPORT!!!!!!!!!!!!!!!!!!!
Update dbo.ImportSyncRow
Set SourceRow.modify('insert <Product>Unknown</Product> as last into (/PortBalanceSource/PortBalance)[1]')
Where ImportId = 11
	And IsCurrent = 1
	And ImportSyncTableId = 21 -- PortBalance
Go	
Update dbo.ImportSyncRow
Set SourceRow.modify('insert <ProductSize>TOTAL</ProductSize> as last into (/PortBalanceSource/PortBalance)[1]')
Where ImportId = 11
	And IsCurrent = 1
	And ImportSyncTableId = 21 -- PortBalance
Go
-- !!!!!!!!!!!!!!!!!PORT BLENDING IMPORT!!!!!!!!!!!!!!!!!!!
-- PortBlending data fix:
-- replicate RakeHub values into new element SourceHub
Update dbo.ImportSyncRow
Set SourceRow.modify('insert <SourceHub>{/PortBlendingSource/PortBlending/RakeHub[1]/text()}</SourceHub> as first into (/PortBlendingSource/PortBlending)[1]')
Where ImportId = 12
	And IsCurrent = 1
	And ImportSyncTableId = 22 -- PortBlending
Go
-- delete RakeHub element
Update dbo.ImportSyncRow
Set SourceRow.modify('delete (/PortBlendingSource/PortBlending/RakeHub)[1]')
Where ImportId = 12
	And IsCurrent = 1
	And ImportSyncTableId = 22
Go
-- delete MoveHub element
Update dbo.ImportSyncRow
Set SourceRow.modify('delete (/PortBlendingSource/PortBlending/MoveHub)[1]')
Where ImportId = 12
	And IsCurrent = 1
	And ImportSyncTableId = 22
Go
-- insert 2 new fields (DestinationProduct & SourceProduct) that are part of modified primary (composite) key:
Update dbo.ImportSyncRow
Set SourceRow.modify('insert <DestinationProduct>Unknown</DestinationProduct> as first into (/PortBlendingSource/PortBlending)[1]')
Where ImportId = 12
	And IsCurrent = 1
	And ImportSyncTableId = 22
Go
Update dbo.ImportSyncRow
Set SourceRow.modify('insert <SourceProduct>Unknown</SourceProduct> as first into (/PortBlendingSource/PortBlending)[1]')
Where ImportId = 12
	And IsCurrent = 1
	And ImportSyncTableId = 22
Go
-- PortBlendingGrade data fix:
-- replicate RakeHub values into new element SourceHub
Update dbo.ImportSyncRow
Set SourceRow.modify('insert <SourceHub>{/PortBlendingSource/PortBlendingGrade/RakeHub[1]/text()}</SourceHub> as first into (/PortBlendingSource/PortBlendingGrade)[1]')
Where ImportId = 12
	And IsCurrent = 1
	And ImportSyncTableId = 23 -- PortBlendingGrade
Go
-- delete RakeHub element
Update dbo.ImportSyncRow
Set SourceRow.modify('delete (/PortBlendingSource/PortBlendingGrade/RakeHub)[1]')
Where ImportId = 12
	And IsCurrent = 1
	And ImportSyncTableId = 23
Go
-- delete MoveHub element
Update dbo.ImportSyncRow
Set SourceRow.modify('delete (/PortBlendingSource/PortBlendingGrade/MoveHub)[1]')
Where ImportId = 12
	And IsCurrent = 1
	And ImportSyncTableId = 23
Go
-- insert 2 new fields (DestinationProduct & SourceProduct) that are part of modified primary (composite) key:
Update dbo.ImportSyncRow
Set SourceRow.modify('insert <DestinationProduct>Unknown</DestinationProduct> as first into (/PortBlendingSource/PortBlendingGrade)[1]')
Where ImportId = 12
	And IsCurrent = 1
	And ImportSyncTableId = 23
Go
Update dbo.ImportSyncRow
Set SourceRow.modify('insert <SourceProduct>Unknown</SourceProduct> as first into (/PortBlendingSource/PortBlendingGrade)[1]')
Where ImportId = 12
	And IsCurrent = 1
	And ImportSyncTableId = 23
Go
-- rename <Name> to <GradeName> and <Value> to <HeadValue>
Update dbo.ImportSyncRow
Set SourceRow.modify('insert <GradeName>{/PortBlendingSource/PortBlendingGrade/Name[1]/text()}</GradeName> as last into (/PortBlendingSource/PortBlendingGrade)[1]')
Where ImportId = 12
	And IsCurrent = 1
	And ImportSyncTableId = 23
Go
Update dbo.ImportSyncRow
Set SourceRow.modify('insert <HeadValue>{/PortBlendingSource/PortBlendingGrade/Value[1]/text()}</HeadValue> as last into (/PortBlendingSource/PortBlendingGrade)[1]')
Where ImportId = 12
	And IsCurrent = 1
	And ImportSyncTableId = 23
Go
Update dbo.ImportSyncRow
Set SourceRow.modify('delete (/PortBlendingSource/PortBlendingGrade/Name)[1]')
Where ImportId = 12
	And IsCurrent = 1
	And ImportSyncTableId = 23
Go
Update dbo.ImportSyncRow
Set SourceRow.modify('delete (/PortBlendingSource/PortBlendingGrade/Value)[1]')
Where ImportId = 12
	And IsCurrent = 1
	And ImportSyncTableId = 23
Go

-- remove any duplicates that have been deleted from the BhpbioPortBlending table
update ISR
set IsCurrent = 0
from ImportSyncRow ISR
left join BhpbioPortBlending BPB
	on DestinationRow.value('(PortBlendingDestination/PortBlending/BhpbioPortBlendingId)[1]', 'Int') = BPB.BhpbioPortBlendingId
where importsynctableid = 22
and iscurrent = 1
and BPB.BhpbioPortBlendingId IS NULL

update ISR
set IsCurrent = 0
from ImportSyncRow ISR
left join BhpbioPortBlending BPB
	on DestinationRow.value('(PortBlendingDestination/PortBlendingGrade/BhpbioPortBlendingId)[1]', 'Int') = BPB.BhpbioPortBlendingId
where importsynctableid = 23
and iscurrent = 1
and BPB.BhpbioPortBlendingId IS NULL