CREATE TABLE [dbo].[HaulageGrade]
(
	HaulageId int NOT NULL, 
	GradeName varchar(31) NULL,
	HeadValue decimal(18,4) null,
	FinesValue decimal(18,4) null,
	LumpValue decimal(18,4) null
)
GO
ALTER TABLE [dbo].[HaulageGrade]  WITH CHECK ADD  CONSTRAINT [FK_HaulageGrade_Haulage] FOREIGN KEY([HaulageId])
REFERENCES [dbo].[Haulage] ([HaulageId])
GO
