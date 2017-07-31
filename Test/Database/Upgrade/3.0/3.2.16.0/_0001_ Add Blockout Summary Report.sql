Set Identity_Insert dbo.Report On

Insert Into dbo.Report (Report_Id, Name, Description, Report_Path, Report_Group_Id, Order_No)
	Select 52, 'BhpbioBlockoutSummaryReport', 'Block-out Summary Report (Happy Faces + Pie charts)', '', 2, 99

Insert Into dbo.SecurityOption (Application_Id, Option_Id, Option_Group_Id, Description, Sort_Order)
	Select 'REC', 'Report_52', 'Reports', 'Access to the Block-out Summary Report', 18


Insert Into dbo.SecurityRoleOption (Role_Id, Application_Id, Option_Id)
	Select 'REC_ADMIN', 'REC', 'Report_52'

Set Identity_Insert dbo.Report Off

