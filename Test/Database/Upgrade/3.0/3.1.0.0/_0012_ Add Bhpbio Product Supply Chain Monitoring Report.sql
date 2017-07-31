Set Identity_Insert dbo.Report On
GO
Insert Into dbo.Report (Report_Id, Name, Description, Report_Path, Report_Group_Id, Order_No)
	Select 41, 'BhpbioProductSupplyChainMonitoringReport', '03.15 Product Supply Chain Monitoring Report', '', 3, 16
GO
Insert Into dbo.SecurityOption (Application_Id, Option_Id, Option_Group_Id, Description, Sort_Order)
	Select 'REC', 'Report_41', 'Reports', 'Access to Product Supply Chain Monitoring Report', 99
GO

Insert Into dbo.SecurityRoleOption (Role_Id, Application_Id, Option_Id)
	Select 'REC_ADMIN', 'REC', 'Report_41' Union
	Select 'REC_VIEW', 'REC', 'Report_41' 
GO
	
Set Identity_Insert dbo.Report On