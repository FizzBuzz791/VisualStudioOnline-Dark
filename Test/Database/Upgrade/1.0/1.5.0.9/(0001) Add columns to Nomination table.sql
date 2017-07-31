-- Add new columns for the import shipping enhancement
ALTER TABLE dbo.BhpbioShippingTransactionNomination
ADD
	COA DATETIME NULL,	
	H2O FLOAT NULL,
	Undersize FLOAT NULL,
	Oversize FLOAT NULL
	
GO