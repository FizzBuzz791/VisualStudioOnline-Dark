
/****** Object:  Table [Staging].[StageBlockModelGrade]    Script Date: 01/13/2015 09:03:17 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [Staging].[StageBlockModelGrade](
	[BlockModelId] [int] NOT NULL,
	[GradeName] [varchar](31) NOT NULL,
	[GradeValue] [float] NULL,
	[LumpValue] [float] NULL,
	[FinesValue] [float] NULL,
	[GeometType] [varchar](15) NOT NULL DEFAULT('NA'),
 CONSTRAINT [PK_StageBlockModelGrade] PRIMARY KEY CLUSTERED 
(
	[BlockModelId] ASC,
	[GradeName] ASC,
	[GeometType] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [Staging].[StageBlockModelGrade]  WITH CHECK ADD  CONSTRAINT [FK_StageBlockModelGrade_StageBlockModel] FOREIGN KEY([BlockModelId])
REFERENCES [Staging].[StageBlockModel] ([BlockModelId])
GO

ALTER TABLE [Staging].[StageBlockModelGrade] CHECK CONSTRAINT [FK_StageBlockModelGrade_StageBlockModel]
GO


