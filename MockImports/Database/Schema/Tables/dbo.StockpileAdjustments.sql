CREATE TABLE [dbo].[StockpileAdjustment](
	[StockpileAdjustmentId] int NOT NULL identity(1,1),
	[LocationId] int NULL,
	[StockpileName] varchar(31) NULL,
	[AdjustmentType] varchar(5) NULL,
	[AdjustmentDate] datetime NULL,
	[Tonnes] decimal(18,4) NULL,
	[FinesPercent] decimal(18,4) NULL,
	[LumpPercent] decimal(18,4) NULL,
	[BCM] decimal(18,4) NULL,
	[LastModifiedTime] datetime NULL,
 CONSTRAINT [PK_StockpileAdjustment] PRIMARY KEY CLUSTERED 
(
	[StockpileAdjustmentId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[StockpileAdjustment]  WITH CHECK ADD  CONSTRAINT [FK_StockpileAdjustment_Locations] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
