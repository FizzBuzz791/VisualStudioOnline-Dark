/****** Object:  Table [Staging].[StageBlockPoint]    Script Date: 01/13/2015 09:03:44 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [Staging].[StageBlockPoint](
	[BlockId] [int] NOT NULL,
	[Number] [int] NOT NULL,
	[X] [float] NOT NULL,
	[Y] [float] NOT NULL,
	[Z] [float] NOT NULL,
 CONSTRAINT [PK_StageBlockPoint] PRIMARY KEY CLUSTERED 
(
	[BlockId] ASC,
	[Number] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [Staging].[StageBlockPoint]  WITH CHECK ADD  CONSTRAINT [FK_StageBlockPoint_StageBlock] FOREIGN KEY([BlockId])
REFERENCES [Staging].[StageBlock] ([BlockId])
GO

ALTER TABLE [Staging].[StageBlockPoint] CHECK CONSTRAINT [FK_StageBlockPoint_StageBlock]
GO


