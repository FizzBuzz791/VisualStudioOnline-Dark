SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [Staging].[StageBlockDeletion](
	[BlockDeletionId] [int] IDENTITY(1,1) NOT NULL,
	[BlockExternalSystemId] [varchar](255) NULL,
	[LastMessageTimestamp] [datetime] NOT NULL

 CONSTRAINT [PK_[StageBlockDeletion] PRIMARY KEY NONCLUSTERED 
(
	[BlockDeletionId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
)
GO

CREATE UNIQUE CLUSTERED INDEX UQ_StageBlockDeletion_01 ON Staging.StageBlockDeletion 
(
	BlockExternalSystemId ASC,
	LastMessageTimestamp ASC
)
GO

SET ANSI_PADDING OFF
GO
