Set Identity_Insert dbo.Report On
GO

Insert Into dbo.Report (Report_Id, Name, Description, Report_Path, Report_Group_Id, Order_No)
	Select 42, 'BhpbioF1F2F3ProductReconContributionReport', '02.9 Product Overview Reconciliation Contribution Report (Pie Charts)', '', 2, 9
GO

Insert Into dbo.SecurityOption (Application_Id, Option_Id, Option_Group_Id, Description, Sort_Order)
	Select 'REC', 'Report_42', 'Reports', 'Access to Product Reconciliation Contribution Report', 99
GO

Insert Into dbo.SecurityRoleOption (Role_Id, Application_Id, Option_Id)
	Select 'REC_ADMIN', 'REC', 'Report_42' Union
	Select 'REC_VIEW', 'REC', 'Report_42' 
GO
	
Set Identity_Insert dbo.Report Off
