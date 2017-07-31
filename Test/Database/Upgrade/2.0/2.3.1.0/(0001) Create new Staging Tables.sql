--
-- Make sure the staging schema exists
--
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Staging')
BEGIN
    -- Have to use 'exec' or the query fails
    EXEC( 'CREATE SCHEMA Staging' );
END

--
-- Now create the tables and indexes
-- These scripts were exported directly from SSMS, so they should contain everything
--
/****** Object:  Table [Staging].[StageBlockDeletion]    Script Date: 03/18/2015 12:12:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Staging].[StageBlockDeletion]') AND type in (N'U'))
BEGIN
CREATE TABLE [Staging].[StageBlockDeletion](
	[BlockDeletionId] [int] IDENTITY(1,1) NOT NULL,
	[BlockExternalSystemId] [varchar](255) NULL,
	[LastMessageTimestamp] [datetime] NOT NULL,
 CONSTRAINT [PK_[StageBlockDeletion] PRIMARY KEY NONCLUSTERED 
(
	[BlockDeletionId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [Staging].[StageBlock]    Script Date: 03/18/2015 12:12:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Staging].[StageBlock]') AND type in (N'U'))
BEGIN
CREATE TABLE [Staging].[StageBlock](
	[BlockId] [int] IDENTITY(1,1) NOT NULL,
	[BlockExternalSystemId] [varchar](255) NULL,
	[FlitchExternalSystemId] [varchar](255) NULL,
	[PatternExternalSystemId] [varchar](255) NULL,
	[BlockNumber] [varchar](2) NULL,
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
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [Staging].[StageBlockModel]    Script Date: 03/18/2015 12:12:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Staging].[StageBlockModel]') AND type in (N'U'))
BEGIN
CREATE TABLE [Staging].[StageBlockModel](
	[BlockModelId] [int] IDENTITY(1,1) NOT NULL,
	[BlockId] [int] NOT NULL,
	[BlockModelName] [varchar](31) NOT NULL,
	[MaterialTypeName] [varchar](8) NOT NULL,
	[OpeningVolume] [float] NOT NULL,
	[OpeningTonnes] [float] NOT NULL,
	[OpeningDensity] [float] NOT NULL,
	[LastModifiedUser] [varchar](50) NOT NULL,
	[LastModifiedDate] [datetime] NULL,
	[LumpPercent] [decimal](7, 4) NULL,
	[ModelFilename] [varchar](200) NULL,
 CONSTRAINT [PK_StageBlockModel] PRIMARY KEY NONCLUSTERED 
(
	[BlockModelId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY],
 CONSTRAINT [UQ_StageBlockModel] UNIQUE CLUSTERED 
(
	[BlockId] ASC,
	[BlockModelName] ASC,
	[MaterialTypeName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [Staging].[StageBlockPoint]    Script Date: 03/18/2015 12:12:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Staging].[StageBlockPoint]') AND type in (N'U'))
BEGIN
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
END
GO
/****** Object:  Table [Staging].[StageBlockModelGrade]    Script Date: 03/18/2015 12:12:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Staging].[StageBlockModelGrade]') AND type in (N'U'))
BEGIN
CREATE TABLE [Staging].[StageBlockModelGrade](
	[BlockModelId] [int] NOT NULL,
	[GradeName] [varchar](31) NOT NULL,
	[GradeValue] [float] NULL,
	[LumpValue] [float] NULL,
	[FinesValue] [float] NULL,
 CONSTRAINT [PK_StageBlockModelGrade] PRIMARY KEY CLUSTERED 
(
	[BlockModelId] ASC,
	[GradeName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  ForeignKey [FK_StageBlockModel_StageBlock]    Script Date: 03/18/2015 12:12:10 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[Staging].[FK_StageBlockModel_StageBlock]') AND parent_object_id = OBJECT_ID(N'[Staging].[StageBlockModel]'))
ALTER TABLE [Staging].[StageBlockModel]  WITH CHECK ADD  CONSTRAINT [FK_StageBlockModel_StageBlock] FOREIGN KEY([BlockId])
REFERENCES [Staging].[StageBlock] ([BlockId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[Staging].[FK_StageBlockModel_StageBlock]') AND parent_object_id = OBJECT_ID(N'[Staging].[StageBlockModel]'))
ALTER TABLE [Staging].[StageBlockModel] CHECK CONSTRAINT [FK_StageBlockModel_StageBlock]
GO
/****** Object:  ForeignKey [FK_StageBlockModelGrade_StageBlockModel]    Script Date: 03/18/2015 12:12:10 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[Staging].[FK_StageBlockModelGrade_StageBlockModel]') AND parent_object_id = OBJECT_ID(N'[Staging].[StageBlockModelGrade]'))
ALTER TABLE [Staging].[StageBlockModelGrade]  WITH CHECK ADD  CONSTRAINT [FK_StageBlockModelGrade_StageBlockModel] FOREIGN KEY([BlockModelId])
REFERENCES [Staging].[StageBlockModel] ([BlockModelId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[Staging].[FK_StageBlockModelGrade_StageBlockModel]') AND parent_object_id = OBJECT_ID(N'[Staging].[StageBlockModelGrade]'))
ALTER TABLE [Staging].[StageBlockModelGrade] CHECK CONSTRAINT [FK_StageBlockModelGrade_StageBlockModel]
GO
/****** Object:  ForeignKey [FK_StageBlockPoint_StageBlock]    Script Date: 03/18/2015 12:12:10 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[Staging].[FK_StageBlockPoint_StageBlock]') AND parent_object_id = OBJECT_ID(N'[Staging].[StageBlockPoint]'))
ALTER TABLE [Staging].[StageBlockPoint]  WITH CHECK ADD  CONSTRAINT [FK_StageBlockPoint_StageBlock] FOREIGN KEY([BlockId])
REFERENCES [Staging].[StageBlock] ([BlockId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[Staging].[FK_StageBlockPoint_StageBlock]') AND parent_object_id = OBJECT_ID(N'[Staging].[StageBlockPoint]'))
ALTER TABLE [Staging].[StageBlockPoint] CHECK CONSTRAINT [FK_StageBlockPoint_StageBlock]
GO
