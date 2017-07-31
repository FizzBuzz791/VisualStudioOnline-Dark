IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BhpbioFactorExclusionFilter]') AND type in (N'U'))
	DROP TABLE dbo.BhpbioFactorExclusionFilter
GO

CREATE TABLE dbo.BhpbioFactorExclusionFilter
(
  BhpbioFactorExclusionFilterId Int Identity,
	[StockpileGroupId] VARCHAR(31) NULL,
	HubLocationId Int NULL,
	ExclusionType VARCHAR(31) NULL,
	
	CONSTRAINT PK_BhpbioFactorExclusionFilter PRIMARY KEY CLUSTERED
		(BhpbioFactorExclusionFilterId),
		
	CONSTRAINT FK_BhpbioFactorExclusionFilter_StockpileGroup
		FOREIGN KEY (StockpileGroupId)
		REFERENCES dbo.StockpileGroup (Stockpile_Group_Id),
		
	CONSTRAINT FK_BhpbioFactorExclusionFilter_HubLocation
		FOREIGN KEY (HubLocationId)
		REFERENCES dbo.Location (Location_Id)
		
)
GO

CREATE NONCLUSTERED INDEX [IX_BhpbioFactorExclusionFilter_StockpileGroup] ON BhpbioFactorExclusionFilter 
(
	ExclusionType ASC,
	[StockpileGroupId] ASC
) 
GO

CREATE NONCLUSTERED INDEX [IX_BhpbioFactorExclusionFilter_HubLocation] ON BhpbioFactorExclusionFilter 
(
	ExclusionType ASC,
	HubLocationId ASC
) 
GO
