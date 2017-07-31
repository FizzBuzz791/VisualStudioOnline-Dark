IF OBJECT_ID('dbo.AddBhpbioPurgeRequest') IS NOT NULL
     DROP PROCEDURE dbo.AddBhpbioPurgeRequest
GO 

CREATE PROC dbo.AddBhpbioPurgeRequest
(
	@iMonth DATETIME,
	@iRequestingUserId INT,
	@oPurgeRequestId INT OUTPUT
)
WITH ENCRYPTION
AS
BEGIN
	SET @iMonth = CASE WHEN @iMonth IS NOT NULL THEN convert(varchar,datepart(yyyy,@iMonth)) + '-' + convert(varchar,datepart(mm,@iMonth)) + '-01' END
	
	INSERT dbo.BhpbioPurgeRequest
	(
		PurgeMonth, PurgeRequestStatusId, RequestingUserId, LastStatusChangeDateTime
	)
	SELECT @iMonth, 1, @iRequestingUserId, GETDATE()
	WHERE @iMonth IS NOT NULL 
		AND @iRequestingUserId IS NOT NULL
		AND NOT EXISTS (SELECT * 
						FROM dbo.BhpbioPurgeRequest pr
							INNER JOIN dbo.BhpbioPurgeRequestStatus prs ON prs.PurgeRequestStatusId = pr.PurgeRequestStatusId
						WHERE YEAR(pr.PurgeMonth) = YEAR(@iMonth)
							AND MONTH(pr.PurgeMonth) = MONTH(@iMonth)
							-- and not finalised
							AND (prs.IsFinalStatePositive = 0 AND prs.IsFinalStateNegative = 0)
						)
	SET @oPurgeRequestId = CONVERT(INT,SCOPE_IDENTITY())
END
GO

GRANT EXECUTE ON dbo.AddBhpbioPurgeRequest TO BhpbioGenericManager
GO