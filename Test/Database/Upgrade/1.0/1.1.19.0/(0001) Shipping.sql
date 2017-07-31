ALTER TABLE dbo.BhpbioShippingTransactionNomination
	ALTER COLUMN CustomerNo INT NULL
GO
	
ALTER TABLE dbo.BhpbioShippingTransactionNomination
	ALTER COLUMN CustomerName VARCHAR(63) COLLATE DATABASE_DEFAULT NULL
GO
