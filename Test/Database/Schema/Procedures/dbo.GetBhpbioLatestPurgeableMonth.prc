IF OBJECT_ID('dbo.GetBhpbioLatestPurgeableMonth') IS NOT NULL
     DROP PROC dbo.GetBhpbioLatestPurgeableMonth
GO 

CREATE PROC dbo.GetBhpbioLatestPurgeableMonth
(
	@oMonth DATETIME OUTPUT
)
WITH ENCRYPTION
AS
BEGIN
SET NOCOUNT ON;
WITH data
AS
(
	SELECT [Month], Approved 
	FROM dbo.BhpbioApprovalStatusByMonth WITH (NOLOCK)
), 
result AS 
(
	SELECT d.Month
	FROM data d
	WHERE Approved = 1
		AND NOT EXISTS(SELECT * FROM data e WHERE e.Month <= d.Month AND Approved = 0)

)

SELECT @oMonth = MAX(Month) FROM result
END
GO

GRANT EXECUTE ON dbo.GetBhpbioLatestPurgeableMonth TO BhpbioGenericManager
GO