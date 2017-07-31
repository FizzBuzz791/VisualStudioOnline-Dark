-- this script was already in the 3.1 folder, but I think it didn't get applied properly
-- so we will add the script here again just to make sure that all users have access to this
INSERT INTO SecurityRoleOption (Role_Id, Application_Id, Option_Id)
	SELECT sr1.Role_Id, sr1.Application_Id, 'ANALYSIS_OUTLIER_ANALYSIS'
	FROM SecurityRoleOption AS sr1
		LEFT OUTER JOIN SecurityRoleOption AS sr2
			ON sr1.Role_Id = sr2.Role_Id
			AND sr1.Application_Id = sr2.Application_Id
			AND sr2.Option_Id = 'ANALYSIS_OUTLIER_ANALYSIS'
	WHERE sr1.Option_Id = 'ANALYSIS_GRANT'
		AND sr2.Role_Id IS NULL 