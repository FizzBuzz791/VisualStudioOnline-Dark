IF OBJECT_ID('dbo.GetBhpbioPurgeRequests') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioPurgeRequests
GO 

CREATE PROC dbo.GetBhpbioPurgeRequests
(
	@iIsReadyForApproval BIT = NULL,
	@iIsReadyForPurging BIT = NULL,
	@iOnlyLatestForEachMonth BIT = 1
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @latestPerMonth TABLE (
		PurgeMonth DATETIME,
		LastStatusChangeDateTime DATETIME
	)
	
	-- find the latest request per month
	INSERT INTO @latestPerMonth
	SELECT pr.PurgeMonth, MAX(pr.LastStatusChangeDateTime)
	FROM dbo.BhpbioPurgeRequest pr
	GROUP BY pr.PurgeMonth
	
	SELECT
		R.PurgeRequestId AS Id,
		R.PurgeMonth As Month,
		S.PurgeRequestStatusId As Status,
		RU.UserId AS RequestingUserId,
		RU.FirstName AS RequestingUserFirstName,
		RU.LastName AS RequestingUserLastName,
		R.LastStatusChangeDateTime AS Timestamp,
		AU.UserId AS ApprovingUserId,
		AU.FirstName AS ApprovingUserFirstName,
		AU.LastName AS ApprovingUserLastName,
		S.IsReadyForApproval,
		S.IsReadyForPurging
	FROM dbo.BhpbioPurgeRequest AS R WITH (NOLOCK)
		INNER JOIN dbo.BhpbioPurgeRequestStatus AS S WITH (NOLOCK)
			ON (R.PurgeRequestStatusId = S.PurgeRequestStatusId)
		INNER JOIN dbo.SecurityUser AS RU WITH (NOLOCK)
			ON (R.RequestingUserId = RU.UserId)
		LEFT JOIN dbo.SecurityUser AS AU WITH (NOLOCK)
			ON (R.ApprovingUserId = AU.UserId)
		LEFT JOIN @latestPerMonth lpm
			ON lpm.PurgeMonth = R.PurgeMonth
			AND lpm.LastStatusChangeDateTime = R.LastStatusChangeDateTime
	WHERE (@iIsReadyForApproval IS NULL OR S.IsReadyForApproval = @iIsReadyForApproval)
		AND (@iIsReadyForPurging IS NULL OR S.IsReadyForPurging = @iIsReadyForPurging)
		-- and we are not restricting output to latest change request per month, or we are and this row is the latest for the month
		AND (NOT @iOnlyLatestForEachMonth = 1 OR lpm.PurgeMonth IS NOT NULL)
	ORDER BY R.PurgeMonth DESC
END
GO

GRANT EXECUTE ON dbo.GetBhpbioPurgeRequests TO BhpbioGenericManager
GO