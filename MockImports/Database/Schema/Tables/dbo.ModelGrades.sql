USE [ReconcilorImportMockWS]
GO
/****** Object:  Table [dbo].[ModelGrades]    Script Date: 07/09/2013 13:24:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ModelGrades](
	[GradeId] [int] NOT NULL,
	[ModelId] [int] NOT NULL,
 CONSTRAINT [PK_ModelGrades] PRIMARY KEY CLUSTERED 
(
	[GradeId] ASC,
	[ModelId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ModelGrades]  WITH CHECK ADD  CONSTRAINT [FK_ModelGrades_Grades] FOREIGN KEY([GradeId])
REFERENCES [dbo].[Grades] ([Id])
GO
ALTER TABLE [dbo].[ModelGrades] CHECK CONSTRAINT [FK_ModelGrades_Grades]
GO
ALTER TABLE [dbo].[ModelGrades]  WITH CHECK ADD  CONSTRAINT [FK_ModelGrades_Models] FOREIGN KEY([ModelId])
REFERENCES [dbo].[Models] ([Id])
GO
ALTER TABLE [dbo].[ModelGrades] CHECK CONSTRAINT [FK_ModelGrades_Models]
GO
