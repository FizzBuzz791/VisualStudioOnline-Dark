--Add Filename
Alter Table BhpbioBlastBlockModelHolding
Add ModelFilename VARCHAR(200) COLLATE Database_Default NULL

--DROP CONSTRAINTS
Alter Table BhpbioBlastBlockModelGradeHolding
Drop CONSTRAINT PK_BhpbioBlastBlockModelGradeHolding

Alter Table BhpbioBlastBlockModelGradeHolding
Drop CONSTRAINT FK_BhpbioBlastBlockModelGradeHolding_BhpbioBlastBlockModelHolding

Alter Table BhpbioBlastBlockModelHolding
Drop CONSTRAINT PK_BhpbioBlastBlockModelHolding

GO

--Alter column
Alter Table BhpbioBlastBlockModelGradeHolding
Alter column ModelName VARCHAR(31) COLLATE Database_Default NOT NULL

Alter Table BhpbioBlastBlockModelHolding
Alter column ModelName VARCHAR(31) COLLATE Database_Default NOT NULL

Go

--Add constraints
Alter Table BhpbioBlastBlockModelGradeHolding
	Add CONSTRAINT PK_BhpbioBlastBlockModelGradeHolding PRIMARY KEY CLUSTERED
	(
		BlockId, ModelName, ModelOreType, GradeName
	)
	
Alter Table BhpbioBlastBlockModelHolding
	Add CONSTRAINT PK_BhpbioBlastBlockModelHolding PRIMARY KEY CLUSTERED
	(
		BlockId, ModelName, ModelOreType
	)

Alter Table BhpbioBlastBlockModelGradeHolding
	Add CONSTRAINT FK_BhpbioBlastBlockModelGradeHolding_BhpbioBlastBlockModelHolding FOREIGN KEY
	(
		BlockId, ModelName, ModelOreType
	)
	REFERENCES dbo.BhpbioBlastBlockModelHolding
	(
		BlockId, ModelName, ModelOreType
	)

