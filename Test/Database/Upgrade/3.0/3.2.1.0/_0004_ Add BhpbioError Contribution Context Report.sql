Set Identity_Insert dbo.Report On

Insert Into dbo.Report (Report_Id, Name, Description, Report_Path, Report_Group_Id, Order_No)
	Select 49, 'BhpbioErrorContributionContextReport', '03.15 Error Contribution with Context Report', '', 3, 15

Insert Into dbo.SecurityOption (Application_Id, Option_Id, Option_Group_Id, Description, Sort_Order)
	Select 'REC', 'Report_49', 'Reports', 'Access to the Error Contribution with Context Report', 15


Insert Into dbo.SecurityRoleOption (Role_Id, Application_Id, Option_Id)
	Select 'REC_ADMIN', 'REC', 'Report_49'

Set Identity_Insert dbo.Report Off

