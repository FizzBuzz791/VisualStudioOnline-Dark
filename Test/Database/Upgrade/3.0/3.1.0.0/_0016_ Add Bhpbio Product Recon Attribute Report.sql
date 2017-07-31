Set Identity_Insert dbo.Report On
GO

Insert Into dbo.Report (Report_Id, Name, Description, Report_Path, Report_Group_Id, Order_No)
	Select 43, 'BhpbioF1F2F3ReconciliationProductAttributeReport', '02.10 Product Reconciliation by Attribute Report (Line Chart)', '', 2, 10
GO

Insert Into dbo.SecurityOption (Application_Id, Option_Id, Option_Group_Id, Description, Sort_Order)
	Select 'REC', 'Report_43', 'Reports', 'Access to Product Reconciliation by Attribute Report', 99
GO

Insert Into dbo.SecurityRoleOption (Role_Id, Application_Id, Option_Id)
	Select 'REC_ADMIN', 'REC', 'Report_43' Union
	Select 'REC_VIEW', 'REC', 'Report_43' 
GO
	
Set Identity_Insert dbo.Report Off
