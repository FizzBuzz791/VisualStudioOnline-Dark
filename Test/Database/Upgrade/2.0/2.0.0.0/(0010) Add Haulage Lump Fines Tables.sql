IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BhpbioHaulageLumpFinesGrade]') AND type in (N'U'))
BEGIN
	CREATE TABLE [dbo].[BhpbioHaulageLumpFinesGrade]
	(
		[HaulageRawId] [int] NOT NULL,
		[GradeId] [smallint] NOT NULL,
		[LumpValue] [real] NOT NULL,
		[FinesValue] [real] NOT NULL,

		CONSTRAINT [PK_BhpbioHaulageLumpFinesGrade]
			PRIMARY KEY CLUSTERED ([HaulageRawId] ASC, [GradeId] ASC),
			
		CONSTRAINT FK__BhpbioHaulageLumpFinesGrade__HAULAGE FOREIGN KEY (HaulageRawId)
			REFERENCES dbo.HaulageRaw (Haulage_Raw_Id),
			
		CONSTRAINT FK__BhpbioHaulageLumpFinesGrade__GRADE FOREIGN KEY (GradeId)
			REFERENCES dbo.Grade (Grade_Id)
	)
END
GO