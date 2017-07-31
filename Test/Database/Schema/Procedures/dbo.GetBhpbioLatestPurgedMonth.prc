IF OBJECT_ID('dbo.GetBhpbioLatestPurgedMonth') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioLatestPurgedMonth  
GO 
  
CREATE PROCEDURE dbo.GetBhpbioLatestPurgedMonth 
(
	@oLatestPurgedMonth DATETIME OUTPUT
)
WITH ENCRYPTION
AS 
BEGIN 
	SET NOCOUNT ON
	
	SELECT @oLatestPurgedMonth = MAX(pr.PurgeMonth)
	FROM dbo.BhpbioPurgeRequest pr WITH (NOLOCK)
		INNER JOIN dbo.BhpbioPurgeRequestStatus prs ON prs.PurgeRequestStatusId = pr.PurgeRequestStatusId
	WHERE prs.IsFinalStatePositive = 1
	
END 
GO

GRANT EXECUTE ON dbo.GetBhpbioLatestPurgedMonth TO BhpbioGenericManager
GO

/*
DECLARE @TestDate DATETIME
exec dbo.GetBhpbioLatestPurgedMonth @oLatestPurgedMonth = @TestDate OUTPUT
SELECT @TestDate
*/


/*
<TAG Name="Data Dictionary" FunctionName="dbo.GetBhpbioLatestPurgedMonth">
 <Function>
	Gets a DateTime that represents the latest month in the system that has been purged
	
	Parameters:	@oLatestPurgedMonth OUTPUT - the latest purged month (or NULL if no purging has occured)
 </Function>
</TAG>
*/	