INSERT dbo.BhpbioPurgeRequestStatus
(
	PurgeRequestStatusId, [Name], IsReadyForApproval, IsReadyForPurging, IsFinalStatePositive, IsFinalStateNegative
)
SELECT 1, 'Requested', 1, 0, 0, 0 UNION
SELECT 2, 'Cancelled', 0, 0, 0, 1 UNION
SELECT 3, 'Obsolete', 0, 0, 0, 1 UNION
SELECT 4, 'Approved', 0, 1, 1, 0 UNION
SELECT 5, 'Initiated', 0, 0, 0, 0 UNION
SELECT 6, 'Completed', 0, 0, 1, 0 UNION
SELECT 7, 'Failed', 0, 0, 0, 1