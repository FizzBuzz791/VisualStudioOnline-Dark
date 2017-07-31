IF OBJECT_ID('dbo.BhpbioGetApprovalProgress') IS NOT NULL
	DROP PROCEDURE dbo.BhpbioGetApprovalProgress
GO

CREATE PROCEDURE dbo.BhpbioGetApprovalProgress
	@iApprovalId INT
AS
BEGIN
	DECLARE @startTime DATETIME
	
	SELECT TOP(1) @startTime = TimeStamp
	FROM BhpbioBulkApprovalBatchProgress WITH (NOLOCK)
	RIGHT OUTER JOIN BhpbioBulkApprovalBatch WITH (NOLOCK)
		ON Id = BulkApprovalBatchId
	WHERE Id = @iApprovalId
	ORDER BY TimeStamp ASC
	
	SELECT BBAB.Id AS ApprovalId, 
		BBAB.Approval, 
		BBAB.Status AS BatchStatus, 
		BBABP.ApprovedMonth AS ProcessingMonth, 
		LT.Description AS ProcessingLocationType, 
		L.Name AS ProcessingLocation,
		L.Location_Id AS LocationId, 
		BBABP.LastApprovalTagId AS LastApprovalProcessed, 
		CONVERT(VARCHAR(MAX), (CASE BBAB.Status WHEN 'PENDING' THEN CURRENT_TIMESTAMP ELSE BBABP.TimeStamp END) - @startTime, 108) AS ElapsedTime,
		COALESCE(BBABP.CountApprovalsProcessed, 0) AS Progress, 
		COALESCE(BBABP.TotalCountApprovals, 0) AS TotalProgress
	FROM BhpbioBulkApprovalBatchProgress BBABP WITH (NOLOCK)
	RIGHT OUTER JOIN BhpbioBulkApprovalBatch BBAB WITH (NOLOCK) ON BBAB.Id = BBABP.BulkApprovalBatchId
	INNER JOIN Location L WITH (NOLOCK) 
		ON L.Location_Id = COALESCE(BBABP.ProcessingLocationId, BBAB.LocationId)
	INNER JOIN LocationType LT WITH (NOLOCK) 
		ON LT.Location_Type_Id = L.Location_Type_Id
	WHERE BBAB.Id = @iApprovalId
	ORDER BY BBABP.TimeStamp DESC, BBABP.CountApprovalsProcessed desc
END
GO

GRANT EXECUTE ON dbo.BhpbioGetApprovalProgress TO BhpbioGenericManager
GO