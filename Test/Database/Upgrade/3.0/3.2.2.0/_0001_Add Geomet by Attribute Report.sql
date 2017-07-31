Set Identity_Insert dbo.Report On
GO

Insert Into dbo.Report (Report_Id, Name, Description, Report_Path, Report_Group_Id, Order_No)
    Select 51, 'BhpbioF1F2F3GeometReconciliationAttributeReport', '02.10 Geomet Reconciliation by Attribute Report (Line Chart)', '', 2, 10
GO

Insert Into dbo.SecurityOption (Application_Id, Option_Id, Option_Group_Id, Description, Sort_Order)
    Select 'REC', 'Report_51', 'Reports', 'Access to Geomet Reconciliation by Attribute Report', 99
GO

Insert Into dbo.SecurityRoleOption (Role_Id, Application_Id, Option_Id)
    Select 'REC_ADMIN', 'REC', 'Report_51' Union
	Select 'BHP_AREAC', 'REC', 'Report_51' Union
	Select 'BHP_NJV', 'REC', 'Report_51' Union
	Select 'BHP_WAIO', 'REC', 'Report_51' Union
	Select 'BHP_YANDI', 'REC', 'Report_51' Union
	Select 'BHP_JIMBLEBAR', 'REC', 'Report_51' Union
	Select 'BHP_YARRIE', 'REC', 'Report_51'
GO
    
Set Identity_Insert dbo.Report Off
