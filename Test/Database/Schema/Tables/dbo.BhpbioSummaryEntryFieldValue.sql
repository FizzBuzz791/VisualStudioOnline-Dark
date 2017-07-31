SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[BhpbioSummaryEntryFieldValue](
	[SummaryEntryFieldValueId] [int] IDENTITY(1,1) NOT NULL,
	[SummaryEntryFieldId] [int] NOT NULL,
	[SummaryEntryId] [int] NOT NULL,
	[Value] [float] NULL,
 CONSTRAINT [PK_BhpbioSummaryEntryFieldValue] PRIMARY KEY CLUSTERED 
(
	[SummaryEntryFieldValueId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[BhpbioSummaryEntryFieldValue]  WITH CHECK ADD  CONSTRAINT [FK_BhpbioSummaryEntryFieldValue_BhpbioSummaryEntry] FOREIGN KEY([SummaryEntryId])
REFERENCES [dbo].[BhpbioSummaryEntry] ([SummaryEntryId])
GO

ALTER TABLE [dbo].[BhpbioSummaryEntryFieldValue] CHECK CONSTRAINT [FK_BhpbioSummaryEntryFieldValue_BhpbioSummaryEntry]
GO

ALTER TABLE [dbo].[BhpbioSummaryEntryFieldValue]  WITH CHECK ADD  CONSTRAINT [FK_BhpbioSummaryEntryFieldValue_BhpbioSummaryEntryField] FOREIGN KEY([SummaryEntryFieldId])
REFERENCES [dbo].[BhpbioSummaryEntryField] ([SummaryEntryFieldId])
GO

ALTER TABLE [dbo].[BhpbioSummaryEntryFieldValue] CHECK CONSTRAINT [FK_BhpbioSummaryEntryFieldValue_BhpbioSummaryEntryField]
GO

ALTER TABLE [dbo].[BhpbioSummaryEntryFieldValue] ADD CONSTRAINT [unique_BhpbioSummaryEntryField_Value] UNIQUE ([SummaryEntryFieldId],[SummaryEntryId])
GO