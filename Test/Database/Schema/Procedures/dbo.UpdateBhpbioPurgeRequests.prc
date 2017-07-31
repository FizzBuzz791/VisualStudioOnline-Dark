IF OBJECT_ID('dbo.UpdateBhpbioPurgeRequests') IS NOT NULL
     DROP PROCEDURE dbo.UpdateBhpbioPurgeRequests
GO 

CREATE PROC dbo.UpdateBhpbioPurgeRequests
(
	@iIds VARCHAR(1000),
	@iPurgeRequestStatusId INT,
	@iApprovingUserId INT = NULL
)
WITH ENCRYPTION
AS
BEGIN
	UPDATE R
	SET PurgeRequestStatusId = @iPurgeRequestStatusId,
		ApprovingUserId = ISNULL(@iApprovingUserId, R.ApprovingUserId),
		LastStatusChangeDateTime = GETDATE()
	FROM dbo.BhpbioPurgeRequest AS R
		INNER JOIN dbo.GetBhpbioIntCollection(@iIds) AS I
			ON (R.PurgeRequestId = I.Value)
	WHERE
		R.PurgeRequestStatusId != @iPurgeRequestStatusId 
END
GO

GRANT EXECUTE ON dbo.UpdateBhpbioPurgeRequests TO BhpbioGenericManager
GO