CREATE TABLE [dbo].[StockpileAdjustmentGrade](
	StockpileAdjustmentId int NOT NULL,
	GradeName varchar(31) null,
	HeadValue decimal(18,4) null
)
GO
ALTER TABLE [dbo].[StockpileAdjustmentGrade]  WITH CHECK ADD  CONSTRAINT [FK_StockpileAdjustmentGrade_StockpileAdjustment] FOREIGN KEY([StockpileAdjustmentId])
REFERENCES [dbo].[StockpileAdjustment] ([StockpileAdjustmentId])
GO
