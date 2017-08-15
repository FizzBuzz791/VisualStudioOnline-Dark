CREATE TABLE [dbo].[TransactionGrades]
(
	TransactionId int NOT NULL,
	GradeName varchar(31) NULL,
	HeadValue decimal(18,4) null
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TransactionGrades]  WITH CHECK ADD  CONSTRAINT [FK_TransactionGrades_Transactions] FOREIGN KEY([TransactionId])
REFERENCES [dbo].[Transactions] ([Id])
GO
ALTER TABLE [dbo].[TransactionGrades] CHECK CONSTRAINT [FK_TransactionGrades_Transactions]
GO
