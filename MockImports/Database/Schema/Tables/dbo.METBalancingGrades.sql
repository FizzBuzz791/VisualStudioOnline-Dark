USE [ReconcilorImportMockWS]
GO
/****** Object:  Table [dbo].[MetBalancingGrade]    Script Date: 07/09/2013 13:24:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MetBalancingGrade](
	[MetBalancingId] [int] NOT NULL,
	[GradeName] varchar(31) NULL,
	[HeadValue] decimal(18,4) NULL
)
GO
ALTER TABLE [dbo].[MetBalancingGrade]  WITH CHECK ADD  CONSTRAINT [FK_MetBalancingGrade_MetBalancing] FOREIGN KEY([MetBalancingId])
REFERENCES [dbo].[MetBalancing] ([MetBalancingId])
GO
