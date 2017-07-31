ALTER TABLE dbo.BhpbioBlastBlockLumpFinesGrade
	ADD [GeometType] [varchar](15) NOT NULL DEFAULT('NA')
GO

ALTER TABLE dbo.BhpbioBlastBlockLumpFinesGrade
	DROP CONSTRAINT PK_BhpbioBlastBlockLumpFinesGrade
GO

UPDATE dbo.BhpbioBlastBlockLumpFinesGrade
	SET GeometType = 'As-Dropped'
WHERE GradeId = (SELECT g.GRADE_ID FROM Grade g WHERE g.Grade_Name = 'H2O-As-Dropped')
GO

UPDATE dbo.BhpbioBlastBlockLumpFinesGrade
	SET GeometType = 'As-Shipped'
WHERE GeometType = 'NA'
GO

ALTER TABLE dbo.BhpbioBlastBlockLumpFinesGrade
	ADD CONSTRAINT	   PK_BhpbioBlastBlockLumpFinesGrade
			PRIMARY KEY CLUSTERED ([ModelBlockId] ASC, [SequenceNo] ASC, [GradeId] ASC, GeometType)
GO
