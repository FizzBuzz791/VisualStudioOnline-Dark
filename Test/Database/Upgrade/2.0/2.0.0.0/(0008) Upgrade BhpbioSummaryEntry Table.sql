Alter Table dbo.BhpbioSummaryEntry
Add ProductSize Varchar(5) Not Null Default('TOTAL')
Go

Drop Index UQ_BHPBIOSUMMARYENTRY_01 On dbo.BhpbioSummaryEntry
Go

Create Unique Clustered Index UQ_BHPBIOSUMMARYENTRY_01 On dbo.BhpbioSummaryEntry
(
	LocationId Asc,
	SummaryId Asc,
	SummaryEntryTypeId Asc,
	MaterialTypeId Asc,
	ProductSize Asc
)
Go
