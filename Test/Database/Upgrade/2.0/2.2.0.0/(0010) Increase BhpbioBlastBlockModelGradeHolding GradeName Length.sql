﻿/* 
NOTE: This script increases the GradeName column length of the BhpbioBlastBlockModelGradeHolding table to 31 characters

HOWEVER, because this column is an existing column and is part of the primary key for this table, it must be dropped and recreated
The script below has been generated by the SQL Server designer and performs the neccessary data copying and reinstating after the change
*/
BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
BEGIN TRANSACTION
GO
CREATE TABLE dbo.Tmp_BhpbioBlastBlockModelGradeHolding
	(
	BlockId int NOT NULL,
	ModelName varchar(31) NOT NULL,
	ModelOreType varchar(8) NOT NULL,
	GradeName varchar(31) NOT NULL,
	GradeValue float(53) NOT NULL,
	LumpValue float(53) NULL,
	FinesValue float(53) NULL
	)  ON [PRIMARY]
GO
IF EXISTS(SELECT * FROM dbo.BhpbioBlastBlockModelGradeHolding)
	 EXEC('INSERT INTO dbo.Tmp_BhpbioBlastBlockModelGradeHolding (BlockId, ModelName, ModelOreType, GradeName, GradeValue, LumpValue, FinesValue)
		SELECT BlockId, ModelName, ModelOreType, GradeName, GradeValue, LumpValue, FinesValue FROM dbo.BhpbioBlastBlockModelGradeHolding WITH (HOLDLOCK TABLOCKX)')
GO
DROP TABLE dbo.BhpbioBlastBlockModelGradeHolding
GO
EXECUTE sp_rename N'dbo.Tmp_BhpbioBlastBlockModelGradeHolding', N'BhpbioBlastBlockModelGradeHolding', 'OBJECT' 
GO
ALTER TABLE dbo.BhpbioBlastBlockModelGradeHolding ADD CONSTRAINT
	PK_BhpbioBlastBlockModelGradeHolding PRIMARY KEY CLUSTERED 
	(
	BlockId,
	ModelName,
	ModelOreType,
	GradeName
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
COMMIT
