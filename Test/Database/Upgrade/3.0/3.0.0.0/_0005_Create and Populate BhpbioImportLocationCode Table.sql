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

INSERT INTO dbo.BhpbioImportLocationCode
VALUES (1, 3, 'YD'),
 (12, 3, 'YD'),
 (17, 3, 'YD'),
 (30, 3, 'YD'),
 (39, 3, 'YD'),
 (1, 5, 'YR'),
 (12, 5, 'YR'),
 (17, 5, 'YR'),
 (30, 5, 'YR'),
 (39, 5, 'YR'),
 (1, 7, 'AC'),
 (12, 7, 'AC'),
 (17, 7, 'AC'),
 (30, 7, 'AC'),
 (39, 7, 'AC'),
 (1, 11, 'ER'),
 (12, 11, 'ER'),
 (17, 11, 'ER'),
 (30, 11, 'ER'),
 (39, 11, 'ER'),
 (1, 9, 'WB'),
 (12, 9, 'WB'),
 (17, 9, 'WB'),
 (30, 9, 'WB'),
 (39, 9, 'WB'),
 (1, 10, '18'),
 (12, 10, '18'),
 (17, 10, '18'),
 (30, 10, '18'),
 (39, 10, '18'),
 (1, 12, 'JB'),
 (12, 12, 'JB'),
 (17, 12, 'JB'),
 (30, 12, 'JB'),
 (39, 12, 'JB')
GO