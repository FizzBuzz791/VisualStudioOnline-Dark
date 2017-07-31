IF Object_id('dbo.BhpbioBulkApprovalBatch') IS NOT NULL 
     DROP TABLE dbo.BhpbioBulkApprovalBatch
GO 

CREATE TABLE dbo.BhpbioBulkApprovalBatch
(
	[Id]						INT			NOT NULL	IDENTITY,
	Approval				BIT			NOT NULL,				--true = approve process
	[UserId]					INT			NOT NULL, 
	[CreatedTime]				DATETIME	NOT NULL,
	[Status]					VARCHAR(13)	NOT	NULL,

	[EarliestMonth]				DATETIME,
	[LatestMonth]				DATETIME,
	[TopLevelLocationTypeId]	INT,
	[LocationId]				INT,
	[LowestLevelLocationTypeId]	INT,
	IsBulk BIT NOT NULL DEFAULT 0
)
GO