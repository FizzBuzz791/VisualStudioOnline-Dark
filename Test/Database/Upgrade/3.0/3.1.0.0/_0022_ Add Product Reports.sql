Set Identity_Insert dbo.Report On
GO

Insert Into dbo.Report (Report_Id, Name, Description, Report_Path, Report_Group_Id, Order_No)
	Select 45, 'BhpbioFactorsVsTimeProductReport', '03.16 Factors vs Time Report by Product', '', 3, 17 Union
	Select 46, 'BhpbioFactorsVsShippingTargetsReport', '02.12 Product Factors Against Shipping Targets (Line Chart)', '', 2, 10
GO

Insert Into dbo.SecurityOption (Application_Id, Option_Id, Option_Group_Id, Description, Sort_Order)
	Select 'REC', 'Report_45', 'Reports', 'Access to Factors vs Time by Product Report', 99 Union
	Select 'REC', 'Report_46', 'Reports', 'Access to Product Factors Against Shipping Targets Report', 99
GO

Insert Into dbo.SecurityRoleOption (Role_Id, Application_Id, Option_Id)
	Select 'REC_ADMIN', 'REC', 'Report_45' Union
	Select 'REC_VIEW', 'REC', 'Report_45' Union
	Select 'REC_ADMIN', 'REC', 'Report_46'
GO
	
Set Identity_Insert dbo.Report Off
