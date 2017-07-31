USE [ReconcilorImportMockWS]
GO

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Points_Polygons]') AND parent_object_id = OBJECT_ID(N'[dbo].[Points]'))
ALTER TABLE [dbo].[Points] DROP CONSTRAINT [FK_Points_Polygons]
GO

/****** Object:  Table [dbo].[Points]    Script Date: 07/10/2013 15:37:36 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Points]') AND type in (N'U'))
DROP TABLE [dbo].[Points]
GO

/****** Object:  Table [dbo].[Points]    Script Date: 07/09/2013 13:24:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Points](
	[Id] [int] NOT NULL identity(1,1),
	[Number] varchar(20) NULL,
	[PolygonId] [int] NULL,
	[Easting] real NULL,
	[Northing] real NULL,
	[RL] real NULL,
 CONSTRAINT [PK_Points] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Points]  WITH CHECK ADD  CONSTRAINT [FK_Points_Polygons] FOREIGN KEY([PolygonId])
REFERENCES [dbo].[Polygons] ([Id])
GO
ALTER TABLE [dbo].[Points] CHECK CONSTRAINT [FK_Points_Polygons]
GO
