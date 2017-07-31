Set Identity_Insert dbo.Report On
GO

Insert Into dbo.Report (Report_Id, Name, Description, Report_Path, Report_Group_Id, Order_No)
	Select 44, 'BhpbioFactorsByLocationVsShippingTargetsReport', '02.11 Product Factors by Location Against Shipping Targets (Line Chart)', '', 2, 11
GO

Insert Into dbo.SecurityOption (Application_Id, Option_Id, Option_Group_Id, Description, Sort_Order)
	Select 'REC', 'Report_44', 'Reports', 'Access to Product Factors by Location Against Shipping Targets Report', 99
GO

Insert Into dbo.SecurityRoleOption (Role_Id, Application_Id, Option_Id)
	Select 'REC_ADMIN', 'REC', 'Report_44' Union
	Select 'REC_VIEW', 'REC', 'Report_44' 
GO
	
Set Identity_Insert dbo.Report Off