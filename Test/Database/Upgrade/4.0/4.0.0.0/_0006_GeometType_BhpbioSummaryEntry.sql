ALTER TABLE dbo.BhpbioSummaryEntry
	ADD [GeometType] [varchar](15) NOT NULL DEFAULT('NA')
GO

DROP INDEX [UQ_BHPBIOSUMMARYENTRY_01] ON [dbo].[BhpbioSummaryEntry] WITH ( ONLINE = OFF )
GO

UPDATE dbo.BhpbioSummaryEntry
	SET GeometType = 'As-Shipped'
WHERE GeometType = 'NA'
	AND NOT IsNull(ProductSize,'TOTAL') = 'TOTAL'
GO

CREATE UNIQUE CLUSTERED INDEX UQ_BHPBIOSUMMARYENTRY_01 ON dbo.BhpbioSummaryEntry 
(
	SummaryEntryTypeId ASC,
	SummaryId ASC,
	MaterialTypeId ASC,
	LocationId ASC,
	ProductSize ASC,
	[GeometType] ASC
)
GO
