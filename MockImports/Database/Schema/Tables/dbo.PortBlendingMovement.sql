USE [ReconcilorImportMockWS]
GO
/****** Object:  Table [dbo].[PortBlendingMovement]    Script Date: 07/09/2013 13:24:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PortBlending](
	[PortBlendingId] int NOT NULL identity(1,1),
	[SourceHub] varchar(50) NULL,
	[DestinationHub] varchar(50) NULL,
	[StartDate] datetime NULL,
	[EndDate] datetime NULL,
	[LoadSites] varchar(10) NULL,
	[SourceProduct] varchar(50) NULL,
	[DestinationProduct] varchar(50) NULL,
	[SourceProductSize] varchar(50) NULL,
	[DestinationProductSize] varchar(50) NULL,
	[Tonnes] decimal(18,4) NULL,
 CONSTRAINT [PK_PortBlendingMovement] PRIMARY KEY CLUSTERED 
(
	[PortBlendingId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
