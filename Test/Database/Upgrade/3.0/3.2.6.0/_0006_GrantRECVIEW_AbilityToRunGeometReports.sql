IF NOT EXISTS (SELECT * FROM SecurityRoleOption WHERE Role_ID = 'REC_VIEW' AND Option_Id = 'Report_50')
BEGIN
	Insert Into SecurityRoleOption
	(
		Role_Id, Option_Id, Application_Id
	)
	Select 'REC_VIEW', 'Report_50', 'REC' 
END

IF NOT EXISTS (SELECT * FROM SecurityRoleOption WHERE Role_ID = 'REC_VIEW' AND Option_Id = 'Report_51')
BEGIN
	Insert Into SecurityRoleOption
	(
		Role_Id, Option_Id, Application_Id
	)
	Select 'REC_VIEW', 'Report_51', 'REC' 
END
GO
