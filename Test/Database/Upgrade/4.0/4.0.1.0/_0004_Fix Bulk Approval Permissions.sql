
Delete From dbo.SecurityRoleOption
Where Option_Id in ('APPROVAL_BULK', 'APPROVAL_SUMMARY')

Insert Into dbo.SecurityRoleOption (Role_Id, Application_Id, Option_Id)
	Select 'REC_ADMIN', 'REC', 'APPROVAL_BULK' Union
	Select 'REC_ADMIN', 'REC', 'APPROVAL_SUMMARY' Union
	Select 'REC_VIEW', 'REC', 'APPROVAL_SUMMARY'
