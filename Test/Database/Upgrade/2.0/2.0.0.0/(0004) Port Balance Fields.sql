IF NOT EXISTS
	(select * from sys.columns where Name = N'Product' and Object_ID = Object_ID(N'BhpbioPortBalance'))
	AND NOT EXISTS
	(select * from sys.columns where Name = N'ProductSize' AND Object_ID = Object_ID(N'BhpbioPortBalance'))
begin
	Alter Table dbo.BhpbioPortBalance
	Add Product VARCHAR(30) NULL,
		ProductSize VARCHAR(5) NULL
END

IF OBJECT_ID('dbo.BhpbioPortBalanceGrade') IS NULL
	CREATE TABLE dbo.BhpbioPortBalanceGrade
	(
		BhpbioPortBalanceId INT,
		GradeId SMALLINT NOT NULL,
		GradeValue FLOAT NOT NULL,

		CONSTRAINT PK_BhpbioPortBalanceGrade
			PRIMARY KEY (BhpbioPortBalanceId, GradeId),
			
		CONSTRAINT FK_BhpbioPortBalanceGrade_Balance
			FOREIGN KEY (BhpbioPortBalanceId)
			REFERENCES dbo.BhpbioPortBalance (BhpbioPortBalanceId),
			
		CONSTRAINT FK_BhpbioPortBalanceGrade_Grade
			FOREIGN KEY (GradeId)
			REFERENCES dbo.Grade (Grade_Id)		
	)
GO

ALTER TABLE BhpbioPortBalance DROP CONSTRAINT UQ_BhpbioPortBalance_Candidate
GO

ALTER TABLE BhpbioPortBalance
	ADD CONSTRAINT UQ_BhpbioPortBalance_Candidate UNIQUE (HubLocationId, BalanceDate, Product)
GO
