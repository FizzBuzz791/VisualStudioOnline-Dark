/****** Object:  Table [Staging].[StageBlockModel]    Script Date: 01/13/2015 09:03:31 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [Staging].[StageBlockModel](
	[BlockModelId] [int] IDENTITY(1,1) NOT NULL,
	[BlockId] [int] NOT NULL,
	[BlockModelName] [varchar](31) NOT NULL,
	[MaterialTypeName] [varchar](15) NOT NULL,
	[OpeningVolume] [float] NOT NULL,
	[OpeningTonnes] [float] NOT NULL,
	[OpeningDensity] [float] NOT NULL,
	[LastModifiedUser] [varchar](50) NOT NULL,
	[LastModifiedDate] [datetime] NULL,
	[ModelFilename] [varchar](200) NULL,
	[LumpPercentAsDropped] [decimal](7, 4) NULL,
	[LumpPercentAsShipped] [decimal](7, 4) NULL,
CONSTRAINT [PK_StageBlockModel] PRIMARY KEY NONCLUSTERED 
(
	[BlockModelId] ASC
) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY],
 CONSTRAINT [UQ_StageBlockModel] UNIQUE CLUSTERED 
(
	[BlockId] ASC,
	[BlockModelName] ASC,
	[MaterialTypeName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [Staging].[StageBlockModel]  WITH CHECK ADD  CONSTRAINT [FK_StageBlockModel_StageBlock] FOREIGN KEY([BlockId])
REFERENCES [Staging].[StageBlock] ([BlockId])
GO

ALTER TABLE [Staging].[StageBlockModel] CHECK CONSTRAINT [FK_StageBlockModel_StageBlock]
GO


