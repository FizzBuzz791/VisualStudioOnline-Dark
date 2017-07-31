Set Identity_Insert dbo.Report On

Insert Into dbo.Report (Report_Id, Name, Description, Report_Path, Report_Group_Id, Order_No)
	Select 54, 'BhpbioForwardErrorContributionContextReport', 'Forward Error Contribution with Context Report (Bar Charts)', '', 3, 99

Insert Into dbo.SecurityOption (Application_Id, Option_Id, Option_Group_Id, Description, Sort_Order)
	Select 'REC', 'Report_54', 'Reports', 'Access to the Forward Error Contribution with Context Report', 18


Insert Into dbo.SecurityRoleOption (Role_Id, Application_Id, Option_Id)
	Select 'REC_ADMIN', 'REC', 'Report_54'

Set Identity_Insert dbo.Report Off

