--PIT CODE LENGTH CHANGES

ALTER TABLE dbo.BhpbioBlastBlockHolding
	ALTER COLUMN MQ2PitCode VARCHAR(10) COLLATE DATABASE_DEFAULT NULL
GO

ALTER TABLE dbo.BhpbioBlastBlockHolding
	ALTER COLUMN Pit VARCHAR(10) COLLATE DATABASE_DEFAULT NULL
GO

ALTER TABLE dbo.BhpbioImportReconciliationMovementStage
	ALTER COLUMN Pit VARCHAR(10) COLLATE DATABASE_DEFAULT NOT NULL
GO

ALTER TABLE dbo.BhpbioImportReconciliationMovement
	DROP CONSTRAINT PK_BhpbioImportReconciliationMovement
GO

ALTER TABLE dbo.BhpbioImportReconciliationMovement
	ALTER COLUMN Pit VARCHAR(10) COLLATE DATABASE_DEFAULT NOT NULL
GO

ALTER TABLE dbo.BhpbioImportReconciliationMovement
	ADD CONSTRAINT PK_BhpbioImportReconciliationMovement PRIMARY KEY CLUSTERED
	(
		BlockNumber, BlockName, Site, Orebody, Pit, Bench, PatternNumber, DateFrom
	)
GO
