-- add blast/block lump percentage
IF NOT EXISTS
	(select * from sys.columns where Name = N'LumpPercent' and Object_ID = Object_ID(N'BhpbioBlastBlockModelHolding'))
begin
	Alter Table dbo.BhpbioBlastBlockModelHolding
	Add LumpPercent DECIMAL(7,4) NULL
END


-- add lump & fines percentage
IF NOT EXISTS
	(select * from sys.columns where Name = N'LumpValue' and Object_ID = Object_ID(N'BhpbioBlastBlockModelGradeHolding'))
	AND NOT EXISTS
	(select * from sys.columns where Name = N'FinesValue' AND Object_ID = Object_ID(N'BhpbioBlastBlockModelGradeHolding'))
begin
	Alter Table dbo.BhpbioBlastBlockModelGradeHolding
	Add LumpValue Float NULL,
		FinesValue Float NULL
END