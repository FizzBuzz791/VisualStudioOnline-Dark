/****** Object:  Table [Staging].[StageBlock]    Script Date: 01/13/2015 09:01:42 ******/
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Staging')
BEGIN
    -- Have to use 'exec' or the query fails
    EXEC( 'CREATE SCHEMA Staging' );
END
Go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [Staging].[StageBlock](
	[BlockId] [int] IDENTITY(1,1) NOT NULL,
	[BlockExternalSystemId] [varchar](255) NULL,
	[FlitchExternalSystemId] [varchar](255) NULL,
	[PatternExternalSystemId] [varchar](255) NULL,
	[BlockNumber] [varchar](4) NULL,
	[BlockName] [varchar](14) NULL,
	[BlockFullName] [varchar](50) NULL,
	[LithologyTypeName] [varchar](9) NULL,
	[BlockedDate] [datetime] NOT NULL,
	[BlastedDate] [datetime] NULL,
	[Site] [varchar](16) NULL,
	[OreBody] [varchar](16) NULL,
	[Pit] [varchar](16) NULL,
	[Bench] [varchar](16) NULL,
	[PatternNumber] [varchar](16) NULL,
	[AlternativePitCode] [varchar](10) NULL,
	[CentroidX] [float] NULL,
	[CentroidY] [float] NULL,
	[CentroidZ] [float] NULL,
	[LastMessageTimestamp] [datetime] NULL,

 CONSTRAINT [PK_StageBlock] PRIMARY KEY NONCLUSTERED 
(
	[BlockId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY],
 CONSTRAINT [UQ_StageBlock] UNIQUE CLUSTERED 
(
	[BlockNumber] ASC,
	[BlockName] ASC,
	[Site] ASC,
	[OreBody] ASC,
	[Pit] ASC,
	[Bench] ASC,
	[PatternNumber] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX IX_StageBlock_BlockExternalSystemId ON Staging.StageBlock 
(
	BlockExternalSystemId ASC
)
GO

SET ANSI_PADDING OFF
GO



