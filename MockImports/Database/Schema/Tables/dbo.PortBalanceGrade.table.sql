CREATE TABLE [dbo].[PortBalanceGrade]
(
	PortBalanceId int NOT NULL, 
	GradeName varchar(31) NULL,
	HeadValue decimal(18,4) null
)
GO
ALTER TABLE [dbo].[PortBalanceGrade]  WITH CHECK ADD  CONSTRAINT [FK_PortBalanceGrade_PortBalance] FOREIGN KEY([PortBalanceId])
REFERENCES [dbo].[PortBalance] ([PortBalanceId])
GO
