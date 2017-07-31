IF OBJECT_ID('dbo.BhpbioPurgeRequestStatus') IS NOT NULL
	DROP TABLE dbo.BhpbioPurgeRequestStatus
GO

CREATE TABLE dbo.BhpbioPurgeRequestStatus
(
	PurgeRequestStatusId SMALLINT NOT NULL,
	Name VARCHAR(50) COLLATE DATABASE_DEFAULT NOT NULL,
	IsReadyForApproval BIT NOT NULL,
	IsReadyForPurging BIT NOT NULL,
	IsFinalStatePositive BIT NOT NULL,
	IsFinalStateNegative BIT NOT NULL,
	CONSTRAINT PK_BhpbioPurgeRequestStatus PRIMARY KEY CLUSTERED 
	(
		PurgeRequestStatusId ASC
	) ON [PRIMARY]
) ON [PRIMARY]

GO

IF OBJECT_ID('dbo.BhpbioPurgeRequest') IS NOT NULL
	DROP TABLE dbo.BhpbioPurgeRequest
GO

CREATE TABLE dbo.BhpbioPurgeRequest
(
	PurgeRequestId INT IDENTITY(1,1) NOT NULL,
	PurgeMonth DATETIME NOT NULL,
	PurgeRequestStatusId SMALLINT NOT NULL,
	RequestingUserId INT NOT NULL,
	ApprovingUserId INT NULL,
	LastStatusChangeDateTime DATETIME NOT NULL,
	CONSTRAINT PK_BhpbioPurgeRequest PRIMARY KEY CLUSTERED 
	(
		PurgeRequestId ASC
	) ON [PRIMARY],
	CONSTRAINT FK_BhpbioPurgeRequest_RequestingUser FOREIGN KEY (RequestingUserId)
		REFERENCES dbo.SecurityUser (UserId),
	CONSTRAINT FK_BhpbioPurgeRequest_ApprovingUser FOREIGN KEY (ApprovingUserId)
		REFERENCES dbo.SecurityUser (UserId),
	CONSTRAINT FK_BhpbioPurgeRequest_PurgeRequestStatus FOREIGN KEY (PurgeRequestStatusId)
		REFERENCES dbo.BhpbioPurgeRequestStatus (PurgeRequestStatusId)
) ON [PRIMARY]

GO

IF OBJECT_ID('dbo.BhpbioSummary') IS NOT NULL
	DROP TABLE dbo.BhpbioSummary
GO

CREATE TABLE dbo.BhpbioSummary
(
	SummaryId INT NOT NULL IDENTITY(1,1),
	SummaryMonth DATETIME NOT NULL,
	
	CONSTRAINT PK_BhpbioSummary
		PRIMARY KEY (SummaryId),
		
	CONSTRAINT UQ_BhpbioSummary_SummaryMonth
		UNIQUE (SummaryMonth),
)
GO
/*
<TAG Name="Data Dictionary" TableName="dbo.BhpbioSummary">
	<Table>
		Represents a set of summary data, and describes the period the summary covers
	</Table>
	<Columns>
		<Column Name="SummaryId">
			Uniquely identifies the summary
		</Column>
		<Column Name="SummaryMonth">
			Describes the month the summary is for.  This is a DateTime field but only the Year and Month are relevant
		</Column>
	</Columns>
</TAG>
*/

IF OBJECT_ID('dbo.BhpbioSummaryEntryType') IS NOT NULL
	DROP TABLE dbo.BhpbioSummaryEntryType
GO
CREATE TABLE dbo.BhpbioSummaryEntryType
(
	SummaryEntryTypeId INT NOT NULL,
	Name VARCHAR (30) NOT NULL,
	AssociatedBlockModelId INTEGER NULL,
	
	CONSTRAINT PK_BhpbioSummaryEntryType
		PRIMARY KEY (SummaryEntryTypeId),
		
	CONSTRAINT UQ_BhpbioSummaryEntryType_Name
		UNIQUE (Name),
		
	CONSTRAINT FK_BhpbioSummaryEntryType_BlockModel
		FOREIGN KEY (AssociatedBlockModelId)
		REFERENCES dbo.BlockModel (Block_Model_Id)
)
GO
/*
<TAG Name="Data Dictionary" TableName="dbo.BhpbioSummaryEntryType">
	<Table>
		This table contains the set of entry types that may be stored in the BhpbioSummaryEntry table
	</Table>
	<Columns>
		<Column Name="BhpbioSummaryEntryType">
			Uniquely identifies the entry type
		</Column>
		<Column Name="Name">
			A name describing the entry type
		</Column>
		<Column Name="AssociatedBlockModelId">
			Identifies the block model associated with this summary entry type
		</Column>
	</Columns>
</TAG>
*/

IF OBJECT_ID('dbo.BhpbioSummaryEntry') IS NOT NULL
	DROP TABLE dbo.BhpbioSummaryEntry
GO

CREATE TABLE dbo.BhpbioSummaryEntry
(
	SummaryEntryId INT NOT NULL IDENTITY(1,1),
	SummaryId INT NOT NULL,
	SummaryEntryTypeId INT NOT NULL,
	LocationId INT NOT NULL,
	MaterialTypeId INT NULL,
	Tonnes FLOAT NOT NULL,
	
	CONSTRAINT PK_BhpbioSummaryEntry
		PRIMARY KEY (SummaryEntryId),
		
	CONSTRAINT FK_BhpbioSummaryEntry_BhpbioSummary
		FOREIGN KEY (SummaryId)
		REFERENCES dbo.BhpbioSummary (SummaryId)
		ON DELETE CASCADE,
		
	CONSTRAINT FK_BhpbioSummaryEntry_BhpbioSummaryEntryType
		FOREIGN KEY (SummaryEntryTypeId)
		REFERENCES dbo.BhpbioSummaryEntryType (SummaryEntryTypeId)
		ON DELETE CASCADE,
		
	CONSTRAINT FK_BhpbioSummaryEntry_MaterialType
		FOREIGN KEY (MaterialTypeId)
		REFERENCES dbo.MaterialType (Material_Type_Id)
		ON DELETE CASCADE
)
GO
CREATE UNIQUE INDEX UQ_BHPBIOSUMMARYENTRY_01 ON dbo.BhpbioSummaryEntry (SummaryId, SummaryEntryTypeId, LocationId, MaterialTypeId)
GO
/*
<TAG Name="Data Dictionary" TableName="dbo.BhpbioSummaryEntry">
	<Table>
		A summary entry which may represent a movement, a balance or a delta dependant on the type of the summary entry
	</Table>
	<Columns>
		<Column Name="SummaryEntryId">
			Uniquely identifies the row
		</Column>
		<Column Name="SummaryId">
			Identifies the summary set this entry is a part of
		</Column>
		<Column Name="SummaryEntryTypeId">
			Specifies the type of entry represented
		</Column>
		<Column Name="LocationId">
			Identifies the Location associated with the entry.
		</Column>
		<Column Name="MaterialTypeId">
			Identifies the type of material the entry relates to
		</Column>
		<Column Name="Tonnes">
			The amount of material in tonnes
		</Column>
	</Columns>
</TAG>
*/

IF OBJECT_ID('dbo.BhpbioSummaryEntryGrade') IS NOT NULL
	DROP TABLE dbo.BhpbioSummaryEntryGrade
GO

CREATE TABLE dbo.BhpbioSummaryEntryGrade
(
	SummaryEntryGradeId INT NOT NULL IDENTITY(1,1),
	SummaryEntryId INT NOT NULL,
	GradeId SMALLINT NOT NULL,
	GradeValue REAL NOT NULL,
	
	CONSTRAINT PK_BhpbioSummaryEntryGrade
		PRIMARY KEY (SummaryEntryGradeId),
		
	CONSTRAINT FK_BhpbioSummaryEntryGrade_BhpbioSummaryEntry
		FOREIGN KEY (SummaryEntryId)
		REFERENCES dbo.BhpbioSummaryEntry (SummaryEntryId)
		ON DELETE CASCADE,
		
	CONSTRAINT FK_BhpbioSummaryEntryGrade_Grade
		FOREIGN KEY (GradeId)
		REFERENCES dbo.Grade (Grade_Id)
		ON DELETE CASCADE
)
GO
CREATE UNIQUE INDEX UQ_BHPBIOSUMMARYENTRYGRADE_01 ON dbo.BhpbioSummaryEntryGrade (SummaryEntryId, GradeId)
GO
/*
<TAG Name="Data Dictionary" TableName="dbo.BhpbioSummaryEntryGrade">
	<Table>
		This table associates a grade value with a summary entry
	</Table>
	<Columns>
		<Column Name="SummaryEntryGradeId">
			Uniquely identifies the summary entry grade row
		</Column>
		<Column Name="SummaryEntryId">
			Identifies the summary entrythis grade value relates to
		</Column>
		<Column Name="GradeId">
			Identifies the grade this entry relates to
		</Column>
		<Column Name="GradeValue">
			The value of the grade associated with the entry
		</Column>
	</Columns>
</TAG>
*/
