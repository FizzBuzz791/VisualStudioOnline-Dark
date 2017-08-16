CREATE TABLE [dbo].[Blocks](
	[Id] [int] NOT NULL identity(1,1),
	[BlastedDate] [datetime] NULL,
	[BlockedDate] [datetime] NULL,
	[GeoType] [nvarchar](50) NULL,
	[LastModifiedDate] [datetime] NULL,
	[LastModifiedUser] [nvarchar](50) NULL,
	[MQ2PitCode] [nvarchar](50) NULL,
	[Name] [nvarchar](50) NULL,
	[Number] [nvarchar](50) NULL,
	[PatternId] [int] NULL,
	[PolygonId] [int] NULL,
	IsDelete bit default(0)
 CONSTRAINT [PK_ReconciliationMovements] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Blocks]  WITH CHECK ADD  CONSTRAINT [FK_Blocks_Patterns] FOREIGN KEY([PatternId])
REFERENCES [dbo].[Patterns] ([Id])
GO
ALTER TABLE [dbo].[Blocks] CHECK CONSTRAINT [FK_Blocks_Patterns]
GO
ALTER TABLE [dbo].[Blocks]  WITH CHECK ADD  CONSTRAINT [FK_Blocks_Polygons] FOREIGN KEY([PolygonId])
REFERENCES [dbo].[Polygons] ([Id])
GO
ALTER TABLE [dbo].[Blocks] CHECK CONSTRAINT [FK_Blocks_Polygons]
GO
