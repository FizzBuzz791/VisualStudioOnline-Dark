IF OBJECT_ID('dbo.AreBhpbioLocationChildrenApproved') IS NOT NULL
     DROP PROCEDURE dbo.AreBhpbioLocationChildrenApproved
GO 
  
CREATE PROCEDURE dbo.AreBhpbioLocationChildrenApproved
(
	@iLocationId	INT,
	@iMonth			DATETIME,
	@oIsApproved	BIT OUTPUT
)
AS
BEGIN
	SELECT 	@oIsApproved = CASE WHEN COUNT(*)=SUM(al.IsApproved) THEN 1 ELSE 0 END
	FROM
	(
		SELECT 
			Name, 
			loc.Location_Type_Id As LocationTypeId,
			CASE WHEN bad.LocationId IS NULL THEN 0 ELSE 1 END As IsApproved,
			bad.SignoffDate,
			su.FirstName AS ApproverName
		FROM [dbo].[Location] loc 
			INNER JOIN [dbo].[LocationType] lt ON loc.Location_Type_Id=lt.Location_Type_Id
			LEFT JOIN [dbo].[BhpbioApprovalData] bad ON bad.LocationId=loc.Location_Id
				AND bad.ApprovedMonth=@iMonth
				AND
				(
					(lt.Description = 'Hub' AND bad.TagId = 'F3Factor') OR
					(lt.Description = 'Site' AND bad.TagId = 'F2Factor') OR
					(lt.Description = 'Pit' AND bad.TagId = 'F1Factor')
				)
			LEFT JOIN [dbo].[SecurityUser] su ON bad.UserId=su.UserId
		WHERE loc.Parent_Location_Id =@iLocationId
		) AS al
END
GO
	
GRANT EXECUTE ON dbo.AreBhpbioLocationChildrenApproved TO BhpbioGenericManager
Go