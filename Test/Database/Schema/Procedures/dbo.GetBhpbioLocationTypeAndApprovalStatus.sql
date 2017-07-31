IF OBJECT_ID('dbo.GetBhpbioLocationTypeAndApprovalStatus') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioLocationTypeAndApprovalStatus
GO 
  
CREATE PROCEDURE dbo.GetBhpbioLocationTypeAndApprovalStatus
(
	@iLocationId INT,
	@iMonth DATETIME
)
AS
BEGIN

	SELECT 
		Name, 
		loc.Location_Type_Id As LocationTypeId,
		CASE 
			WHEN bad.LocationId IS NULL THEN 0 
			ELSE 1 
		END As IsApproved,
		bad.SignoffDate,
		su.FirstName + ' ' + su.LastName AS ApproverName
	FROM dbo.[Location] loc 
		INNER JOIN [dbo].[LocationType] lt 
			ON loc.Location_Type_Id = lt.Location_Type_Id
		LEFT JOIN [dbo].[BhpbioApprovalData] bad 
			ON bad.LocationId = loc.Location_Id
				AND bad.ApprovedMonth = @iMonth
		LEFT JOIN [dbo].[SecurityUser] su 
			ON bad.UserId = su.UserId
	WHERE loc.Location_Id = @iLocationId
	Order By bad.SignoffDate desc

END
GO

GRANT EXECUTE ON dbo.GetBhpbioLocationTypeAndApprovalStatus TO BhpbioGenericManager
GO
