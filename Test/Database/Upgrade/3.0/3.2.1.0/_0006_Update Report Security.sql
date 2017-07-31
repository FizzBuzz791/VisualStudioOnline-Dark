-- Insert new report group
Declare @groupId int
Declare @ReportGroupName Varchar(128) = 'Product and Shipping Targets Reports'


Select @groupId = Report_Group_Id 
From reportgroup 
Where name = @ReportGroupName

INSERT INTO SecurityRoleOption (Role_Id, Application_Id, Option_Id)
	SELECT sr.RoleId, so.Application_Id, so.Option_Id
	FROM SecurityRole AS sr
		CROSS JOIN Report AS r
		INNER JOIN SecurityOption AS so
			ON 'Report_' + CAST(r.Report_Id AS varchar(10)) = so.Option_Id
		LEFT OUTER JOIN SecurityRoleOption AS sro
			ON sr.RoleId = sro.Role_Id
			AND so.Application_Id = sro.Application_Id
			AND so.Option_Id = sro.Option_Id
	WHERE sr.RoleId LIKE 'BHP_%'
		AND r.Report_Group_Id = @groupId
		AND sro.Role_Id IS NULL
