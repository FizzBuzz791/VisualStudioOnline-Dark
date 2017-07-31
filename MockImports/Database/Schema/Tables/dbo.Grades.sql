USE [ReconcilorImportMockWS]
GO

/****** Object:  Table [dbo].[Grades]    Script Date: 07/11/2013 14:50:38 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Grades]') AND type in (N'U'))
DROP TABLE [dbo].[Grades]
GO

USE [ReconcilorImportMockWS]
GO

/****** Object:  Table [dbo].[Grades]    Script Date: 07/11/2013 14:50:38 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Grades](
	[Id] [int] NOT NULL identity(1,1),
	[FinesValue] decimal(12,6) NULL,
	[HeadValue] decimal(12,6) NULL,
	[LumpValue] decimal(12,6) NULL,
	[Name] [nvarchar](50) NULL,
	[SampleValue] decimal(12,6) NULL,
 CONSTRAINT [PK_Grades] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

