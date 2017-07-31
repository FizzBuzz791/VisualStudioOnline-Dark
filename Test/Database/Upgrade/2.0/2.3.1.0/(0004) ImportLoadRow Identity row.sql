--update to included identity 
DROP TABLE dbo.ImportLoadRow  
Go

CREATE TABLE dbo.ImportLoadRow  
(
	ImportLoadRowId BigInt IDENTITY(1,1) NOT NULL,
	ImportId SmallInt,
	ImportSource Varchar(255) Collate Database_Default,
	SyncAction Varchar(1) Collate Database_Default,
	ImportRow Xml	
	
	CONSTRAINT PK_ImportLoadRow PRIMARY KEY CLUSTERED
		(ImportLoadRowId)
)
GO
