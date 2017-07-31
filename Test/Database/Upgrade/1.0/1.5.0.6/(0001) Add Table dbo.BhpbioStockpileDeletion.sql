IF object_id('dbo.BhpbioStockpileDeletion') IS NOT NULL 
     DROP TABLE dbo.BhpbioStockpileDeletion  
GO 

CREATE TABLE dbo.BhpbioStockpileDeletion  
(	
	Stockpile_Deletion_Id int IDENTITY(1, 1) NOT NULL,
	Stockpile_Name varchar(31),
	
	CONSTRAINT PK_BhpbioStockpileDeletion
		PRIMARY KEY (Stockpile_Deletion_Id),
		
	CONSTRAINT UQ_BhpbioStockpileDeletion_Stockpile_Name
		UNIQUE (Stockpile_Name),
)
GO

