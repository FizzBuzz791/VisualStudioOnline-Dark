IF OBJECT_ID('dbo.BhpbioGetPendingApprovalID') IS NOT NULL 
     DROP PROCEDURE dbo.BhpbioGetPendingApprovalID
GO

CREATE PROCEDURE [dbo].BhpbioGetPendingApprovalID
	@iUserId		INT,
	@iLocationId	INT,
	@oApprovalId	INT OUTPUT
AS
BEGIN
	SELECT @oApprovalId=BAP.Id 
	FROM dbo.BhpbioBulkApprovalBatch BAP 
	WHERE BAP.Status IN ('QUEUING','PENDING') AND BAP.UserId = @iUserId AND ((BAP.LocationId = @iLocationId AND BAP.IsBulk = 0) OR (@iLocationId = -1 AND BAP.IsBulk = 1))
END
GO

GRANT EXECUTE ON dbo.BhpbioGetPendingApprovalID TO BhpbioGenericManager
GO