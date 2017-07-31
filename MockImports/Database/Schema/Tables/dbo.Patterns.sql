USE [ReconcilorImportMockWS]
GO
/****** Object:  Table [dbo].[Patterns]    Script Date: 07/08/2013 15:44:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Patterns](
	[Id] [int] NOT NULL identity(1,1),
	[Bench] [nvarchar](50) NULL,
	[Number] [nvarchar](50) NULL,
	[Orebody] [nvarchar](50) NULL,
	[Pit] [nvarchar](50) NULL,
	[Site] [nvarchar](50) NULL,
 CONSTRAINT [PK_Patterns] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
