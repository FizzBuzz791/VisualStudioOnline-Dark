IF OBJECT_ID('dbo.BhpbioImportLocationCode') IS NOT NULL 
     DROP TABLE dbo.BhpbioImportLocationCode
Go 

CREATE TABLE dbo.BhpbioImportLocationCode
(
	ImportParameterId INT NOT NULL,
	LocationId INT NOT NULL,
	LocationCode VARCHAR(2) COLLATE DATABASE_DEFAULT NOT NULL,
	
	CONSTRAINT PK_BhpbioImportLocationCode PRIMARY KEY CLUSTERED
	(
		ImportParameterId, LocationId
	),
	CONSTRAINT FK_BhpbioImportLocationCode_ImportParameter
		FOREIGN KEY (ImportParameterId)
		REFERENCES dbo.ImportParameter (ImportParameterId),
	CONSTRAINT FK_BhpbioImportLocationCode_Location
		FOREIGN KEY (LocationId)
		REFERENCES dbo.Location (Location_Id)
)
GO