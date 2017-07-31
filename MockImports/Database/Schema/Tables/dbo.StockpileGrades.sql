USE [ReconcilorImportMockWS]
GO

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_StockpileGrades_Grades]') AND parent_object_id = OBJECT_ID(N'[dbo].[StockpileGrades]'))
ALTER TABLE [dbo].[StockpileGrades] DROP CONSTRAINT [FK_StockpileGrades_Grades]
GO

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_StockpileGrades_Stockpiles]') AND parent_object_id = OBJECT_ID(N'[dbo].[StockpileGrades]'))
ALTER TABLE [dbo].[StockpileGrades] DROP CONSTRAINT [FK_StockpileGrades_Stockpiles]
GO

USE [ReconcilorImportMockWS]
GO

/****** Object:  Table [dbo].[StockpileGrades]    Script Date: 07/11/2013 14:49:05 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[StockpileGrades]') AND type in (N'U'))
DROP TABLE [dbo].[StockpileGrades]
GO

USE [ReconcilorImportMockWS]
GO

/****** Object:  Table [dbo].[StockpileGrades]    Script Date: 07/11/2013 14:49:05 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

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

