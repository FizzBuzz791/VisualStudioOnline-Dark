IF OBJECT_ID('dbo.BhpbioSelectEnqueuedBulkApproval') IS NOT NULL
     DROP PROCEDURE dbo.BhpbioSelectEnqueuedBulkApproval
GO 

CREATE PROCEDURE [dbo].[BhpbioSelectEnqueuedBulkApproval]
AS
BEGIN
	SELECT TOP(1) * FROM [dbo].[BhpbioBulkApprovalBatch] job WHERE job.[Status]='QUEUING' OR job.[Status]='PENDING'
END
Go

GRANT EXECUTE ON dbo.BhpbioSelectEnqueuedBulkApproval TO BhpbioGenericManager
GO