sp_rename 'BhpbioBulkApprovalBatch.OperationType', 'Approval', 'COLUMN'
GO

ALTER TABLE BhpbioBulkApprovalBatch ADD IsBulk BIT NOT NULL DEFAULT 0
GO