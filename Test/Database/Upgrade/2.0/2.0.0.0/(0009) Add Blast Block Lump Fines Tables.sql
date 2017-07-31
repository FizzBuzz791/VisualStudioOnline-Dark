IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BhpbioBlastBlockLumpPercent]') AND type in (N'U'))
BEGIN
	CREATE TABLE [dbo].[BhpbioBlastBlockLumpPercent]
	(
		[ModelBlockId] [int] NOT NULL,
		[LumpPercent] [decimal](5,4) NOT NULL,
		
		CONSTRAINT [PK_BhpbioBlastBlockLumpPercent]
			PRIMARY KEY CLUSTERED ([ModelBlockId] ASC),

		CONSTRAINT FK__BhpbioBlastBlockLumpPercent__MODEL_BLOCK FOREIGN KEY (ModelBlockId)
			REFERENCES dbo.ModelBlock (Model_Block_Id)
	)
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BhpbioBlastBlockLumpFinesGrade]') AND type in (N'U'))
BEGIN
	CREATE TABLE [dbo].[BhpbioBlastBlockLumpFinesGrade]
	(
		[ModelBlockId] [int] NOT NULL,
		[SequenceNo] [int] NOT NULL,
		[GradeId] [smallint] NOT NULL,
		[LumpValue] [real] NOT NULL,
		[FinesValue] [real] NOT NULL,

		CONSTRAINT [PK_BhpbioBlastBlockLumpFinesGrade]
			PRIMARY KEY CLUSTERED ([ModelBlockId] ASC, [SequenceNo] ASC, [GradeId] ASC),

		CONSTRAINT FK__BhpbioBlastBlockLumpFinesGrade__MODEL_BLOCK FOREIGN KEY (ModelBlockId)
			REFERENCES dbo.ModelBlock (Model_Block_Id),

		CONSTRAINT FK__BhpbioBlastBlockLumpFinesGrade__GRADE FOREIGN KEY (GradeId)
			REFERENCES dbo.Grade (Grade_Id)
	)
END
GO