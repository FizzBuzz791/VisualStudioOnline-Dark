CREATE TABLE [dbo].[PortBlendingGrade]
(
	[PortBlendingId] int NOT NULL,
	[GradeName] varchar(31) NULL,
	[HeadValue] decimal(18,4) NULL
)
GO
ALTER TABLE [dbo].[PortBlendingGrade]  WITH CHECK ADD  CONSTRAINT [FK_PortBlendingGrade_PortBlending] FOREIGN KEY([PortBlendingId])
REFERENCES [dbo].[PortBlending] ([PortBlendingId])
GO
