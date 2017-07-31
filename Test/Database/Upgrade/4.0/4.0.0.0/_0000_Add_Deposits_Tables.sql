IF OBJECT_ID('dbo.BhpbioLocationGroup') IS NOT NULL 
     DROP TABLE dbo.BhpbioLocationGroup
GO

CREATE TABLE dbo.BhpbioLocationGroup
( 
  LocationGroupId			INT			NOT NULL IDENTITY,
  ParentLocationId			INT			NOT NULL,
  LocationGroupTypeName		VARCHAR(31)	NOT NULL,
  Name						VARCHAR(31)	NOT NULL,
  CreatedDate				DATETIME	NOT NULL,
  CONSTRAINT PK_BhpioLocationGroup PRIMARY KEY CLUSTERED
  (
	LocationGroupId ASC
  )
)
GO

IF OBJECT_ID('dbo.BhpbioLocationGroupLocation') IS NOT NULL 
     DROP TABLE dbo.BhpbioLocationGroupLocation
GO 

CREATE TABLE dbo.BhpbioLocationGroupLocation
(
  LocationGroupId	INT NOT NULL,
  LocationId		INT NOT NULL UNIQUE,
  PRIMARY KEY(LocationGroupId,LocationId)
)
GO

IF OBJECT_ID('dbo.BhpbioBulkApprovalBatch') IS NOT NULL 
     DROP TABLE dbo.BhpbioBulkApprovalBatch
GO 

CREATE TABLE dbo.BhpbioBulkApprovalBatch
(
	Id							INT			NOT NULL IDENTITY,
	OperationType				BIT			NOT NULL, --true = approve process
	UserId						INT			NOT NULL, 
	CreatedTime					DATETIME	NOT NULL,
	Status						VARCHAR(13)	NOT	NULL,

	EarliestMonth				DATETIME,
	LatestMonth					DATETIME,
	TopLevelLocationTypeId		INT,
	LocationId					INT,
	LowestLevelLocationTypeId	INT
)
GO

IF OBJECT_ID('dbo.BhpbioBulkApprovalBatchProgress') IS NOT NULL
	DROP TABLE dbo.BhpbioBulkApprovalBatchProgress
GO
CREATE TABLE dbo.BhpbioBulkApprovalBatchProgress
(
	BulkApprovalBatchId		INT			NOT NULL,
	TimeStamp				DATETIME	NOT NULL,
	ApprovedMonth			DATETIME	NOT NULL,
	ProcessingLocationId	INT			NOT NULL,
	LastApprovalTagId		VARCHAR(63)	NOT NULL,
	CountApprovalsProcessed	INT			NOT NULL,
	TotalCountApprovals		INT			NOT NULL
)
GO