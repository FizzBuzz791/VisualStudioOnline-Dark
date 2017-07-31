USE [ReconcilorImportMockWS]
GO
/****** Object:  Table [dbo].[MetBalancing]    Script Date: 07/09/2013 13:24:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MetBalancing](
	[MetBalancingId] int NOT NULL identity(1,1),
	[Site] varchar(50) NULL,
	[StartDate] datetime NULL,
	[EndDate] datetime NULL,
	[PlantName] varchar(50) NULL,
	[StreamName] varchar(50) NULL,
	[Weightometer] varchar(50) NULL,
	[ProductSize] varchar(50) NULL,
	[DryTonnes] decimal(18,4) NULL,
	[WetTonnes] decimal(18,4) NULL,
	[SplitCycle] decimal(18,4) NULL,
	[SplitPlant] decimal(18,4) NULL,
 CONSTRAINT [PK_MetBalancing] PRIMARY KEY CLUSTERED 
(
	[MetBalancingId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
