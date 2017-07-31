ALTER TABLE dbo.BhpbioBlastBlockLumpPercent
	ADD [GeometType] [varchar](15) NOT NULL DEFAULT('NA')
GO

ALTER TABLE dbo.BhpbioBlastBlockLumpPercent
	DROP CONSTRAINT PK_BhpbioBlastBlockLumpPercent
GO

UPDATE dbo.BhpbioBlastBlockLumpPercent
	SET GeometType = 'As-Shipped'
WHERE GeometType = 'NA'
GO

ALTER TABLE dbo.BhpbioBlastBlockLumpPercent
	ADD CONSTRAINT [PK_BhpbioBlastBlockLumpPercent]
			PRIMARY KEY CLUSTERED ([ModelBlockId] ASC, [SequenceNo] ASC, GeometType)
GO
