SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [Staging].[StageBlockModelResourceClassification](
	[BlockModelResourceClassificationId] [int] NOT NULL IDENTITY,
	[BlockModelId] [int] NOT NULL,
	[ResourceClassification] [varchar](32) NOT NULL,
	[Percentage] [float] NOT NULL,
 CONSTRAINT [PK_StageBlockModelResourceClassification] PRIMARY KEY CLUSTERED 
(
	[BlockModelResourceClassificationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING ON
GO

ALTER TABLE [Staging].[StageBlockModelResourceClassification]  WITH CHECK ADD  CONSTRAINT [FK_StageBlockModelResourceClassification_StageBlockModel] FOREIGN KEY([BlockModelId])
REFERENCES [Staging].[StageBlockModel] (BlockModelId)
GO

ALTER TABLE [Staging].[StageBlockModelResourceClassification] CHECK CONSTRAINT [FK_StageBlockModelResourceClassification_StageBlockModel]
GO
