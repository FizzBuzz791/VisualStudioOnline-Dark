USE [ReconcilorImportMockWS]
GO

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Stockpiles_Locations]') AND parent_object_id = OBJECT_ID(N'[dbo].[Stockpiles]'))
ALTER TABLE [dbo].[Stockpiles] DROP CONSTRAINT [FK_Stockpiles_Locations]
GO

USE [ReconcilorImportMockWS]
GO

/****** Object:  Table [dbo].[Stockpiles]    Script Date: 07/11/2013 14:51:01 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Stockpiles]') AND type in (N'U'))
DROP TABLE [dbo].[Stockpiles]
GO

USE [ReconcilorImportMockWS]
GO

/****** Object:  Table [dbo].[Stockpiles]    Script Date: 07/11/2013 14:51:01 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Stockpiles](
	[Id] [int] NOT NULL identity(1,1),
	[LocationId] [int] NULL,
	[Name] [nvarchar](50) NULL,
	[BusinessId] [nvarchar](50) NULL,
	[StockpileType] [nvarchar](50) NULL,
	[Description] [nvarchar](50) NULL,
	[OreType] [nvarchar](50) NULL,
	[Type] [nvarchar](50) NULL,
	[Active] [bit] NULL,
	[StartDate] [datetime] NULL,
	[ProductSize] [nvarchar](50) NULL,
	[BalanceDate] [datetime] NULL,
	[Hub] [nvarchar](50) NULL,
	[Product] [nvarchar](50) NULL,
	[Tonnes] [decimal] NULL,
 CONSTRAINT [PK_Stockpiles] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[Stockpiles]  WITH CHECK ADD  CONSTRAINT [FK_Stockpiles_Locations] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO

ALTER TABLE [dbo].[Stockpiles] CHECK CONSTRAINT [FK_Stockpiles_Locations]
GO

