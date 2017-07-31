IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BhpbioBulkApprovalBatchProgress]'))
	DROP TABLE dbo.BhpbioBulkApprovalBatchProgress
GO
CREATE TABLE dbo.BhpbioBulkApprovalBatchProgress
(
	[BulkApprovalBatchId]		INT			NOT NULL,
	[TimeStamp]					DATETIME	NOT NULL,
	[ApprovedMonth]				DATETIME	NOT NULL,
	[ProcessingLocationId]		INT			NOT NULL,
	[LastApprovalTagId]			VARCHAR(63)	NOT NULL,
	[CountApprovalsProcessed]	INT			NOT NULL,
	[TotalCountApprovals]		INT			NOT NULL
)
GO