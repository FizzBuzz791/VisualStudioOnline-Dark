-- Drop current indexes
ALTER TABLE dbo.BhpbioSummary
	DROP CONSTRAINT UQ_BhpbioSummary_SummaryMonth
GO
DROP INDEX  UQ_BHPBIOSUMMARYENTRY_01 ON dbo.BhpbioSummaryEntry
GO
DROP INDEX UQ_BHPBIOSUMMARYENTRYGRADE_01 ON dbo.BhpbioSummaryEntryGrade
GO
-- Drop current foreign key constraints
ALTER TABLE dbo.BhpbioSummaryEntry
	DROP CONSTRAINT FK_BhpbioSummaryEntry_BhpbioSummary
GO	

ALTER TABLE dbo.BhpbioSummaryEntryGrade
	DROP CONSTRAINT FK_BhpbioSummaryEntryGrade_BhpbioSummaryEntry
GO

-- Drop current primary key constraints
ALTER TABLE dbo.BhpbioSummary
	DROP CONSTRAINT PK_BhpbioSummary
GO

ALTER TABLE dbo.BhpbioSummaryEntry
	DROP CONSTRAINT PK_BhpbioSummaryEntry
GO

ALTER TABLE dbo.BhpbioSummaryEntryGrade
	DROP CONSTRAINT PK_BhpbioSummaryEntryGrade
GO
	
-- Add new primary key constraints
ALTER TABLE dbo.BhpbioSummary
	ADD CONSTRAINT PK_BhpbioSummary
		PRIMARY KEY NONCLUSTERED (SummaryId)
GO

ALTER TABLE dbo.BhpbioSummaryEntry
	ADD CONSTRAINT PK_BhpbioSummaryEntry
		PRIMARY KEY NONCLUSTERED (SummaryEntryId)
GO

ALTER TABLE dbo.BhpbioSummaryEntryGrade
	ADD CONSTRAINT PK_BhpbioSummaryEntryGrade
		PRIMARY KEY NONCLUSTERED (SummaryEntryGradeId)
GO

-- Add new foreign key constraints
ALTER TABLE dbo.BhpbioSummaryEntry
	ADD CONSTRAINT FK_BhpbioSummaryEntry_BhpbioSummary
		FOREIGN KEY (SummaryId)
		REFERENCES dbo.BhpbioSummary (SummaryId)
		ON DELETE CASCADE
GO

ALTER TABLE dbo.BhpbioSummaryEntryGrade
	ADD CONSTRAINT FK_BhpbioSummaryEntryGrade_BhpbioSummaryEntry
		FOREIGN KEY (SummaryEntryId)
		REFERENCES dbo.BhpbioSummaryEntry (SummaryEntryId)
		ON DELETE CASCADE
GO

-- Add new indexes
CREATE UNIQUE CLUSTERED INDEX UQ_BHPBIOSUMMARY_01 ON dbo.BhpbioSummary 
(
	SummaryMonth ASC,
	SummaryId ASC
)
GO
CREATE UNIQUE CLUSTERED INDEX UQ_BHPBIOSUMMARYENTRY_01 ON dbo.BhpbioSummaryEntry 
(
	SummaryEntryTypeId ASC,
	SummaryId ASC,
	MaterialTypeId ASC,
	LocationId ASC
)
GO
CREATE NONCLUSTERED INDEX IX_BHPBIOSUMMARYENTRY_02 ON dbo.BhpbioSummaryEntry 
(
	SummaryId ASC,
	LocationId ASC,
	SummaryEntryTypeId ASC,
	SummaryEntryId ASC
)
GO
CREATE UNIQUE CLUSTERED INDEX UQ_BHPBIOSUMMARYENTRYGRADE_01 ON dbo.BhpbioSummaryEntryGrade 
(
	SummaryEntryId ASC, 
	GradeId ASC
)
GO
