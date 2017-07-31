﻿IF OBJECT_ID('dbo.BhpbioLocationStockpileConfiguration') IS NOT NULL 
     DROP TABLE dbo.BhpbioLocationStockpileConfiguration
Go 

CREATE TABLE dbo.BhpbioLocationStockpileConfiguration
(
	LocationId INT NOT NULL,
	ImageData VARBINARY(MAX) NULL,
	PromoteStockpiles BIT,
	CONSTRAINT PK_BhpbioLocationStockpileConfiguration
		PRIMARY KEY (LocationId),
	CONSTRAINT FK_BhpbioLocationStockpileConfiguration_Location
		FOREIGN KEY (LocationId)
		REFERENCES dbo.Location (Location_Id)
)
GO
