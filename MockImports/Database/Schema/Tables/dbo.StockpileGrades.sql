CREATE TABLE [dbo].[StockpileGrades](
	[StockpileId] [int] NOT NULL,
	[GradeId] [int] NOT NULL,
 CONSTRAINT [PK_StockpileGrades] PRIMARY KEY CLUSTERED 
(
	[StockpileId] ASC,
	[GradeId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[StockpileGrades]  WITH CHECK ADD  CONSTRAINT [FK_StockpileGrades_Grades] FOREIGN KEY([GradeId])
REFERENCES [dbo].[Grades] ([Id])
GO

ALTER TABLE [dbo].[StockpileGrades] CHECK CONSTRAINT [FK_StockpileGrades_Grades]
GO

ALTER TABLE [dbo].[StockpileGrades]  WITH CHECK ADD  CONSTRAINT [FK_StockpileGrades_Stockpiles] FOREIGN KEY([StockpileId])
REFERENCES [dbo].[Stockpiles] ([Id])
GO

ALTER TABLE [dbo].[StockpileGrades] CHECK CONSTRAINT [FK_StockpileGrades_Stockpiles]
GO

