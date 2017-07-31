USE [ReconcilorImportMockWS]
GO
/****** Object:  Table [dbo].[StockpileAdjustmentGrade]    Script Date: 07/09/2013 13:24:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StockpileAdjustmentGrade](
	StockpileAdjustmentId int NOT NULL,
	GradeName varchar(31) null,
	HeadValue decimal(18,4) null
)
GO
ALTER TABLE [dbo].[StockpileAdjustmentGrade]  WITH CHECK ADD  CONSTRAINT [FK_StockpileAdjustmentGrade_StockpileAdjustment] FOREIGN KEY([StockpileAdjustmentId])
REFERENCES [dbo].[StockpileAdjustment] ([StockpileAdjustmentId])
GO
