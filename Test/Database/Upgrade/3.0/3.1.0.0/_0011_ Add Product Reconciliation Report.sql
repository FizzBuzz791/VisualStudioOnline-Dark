-- In order for a report to appear on the Reports page, a record needs to be added to the Reports
-- table. We also need to add record(s) to the relevant security tables so teh reports only appear to the
-- appropriate roles
--

Set Identity_Insert dbo.Report On

Insert Into dbo.Report (Report_Id, Name, Description, Report_Path, Report_Group_Id, Order_No)
	-- report_group_id = 2 = Factor Reports
	Select 39, 'BhpbioHUBProductReconciliationReport', '02.8 Product HUB Reconciliation Report (Happy Faces)', '', 2, 8

Insert Into dbo.SecurityOption (Application_Id, Option_Id, Option_Group_Id, Description, Sort_Order)
	Select 'REC', 'Report_39', 'Reports', 'Access to Product HUB Reconciliation Report', 4


Insert Into dbo.SecurityRoleOption (Role_Id, Application_Id, Option_Id)
	Select 'REC_ADMIN', 'REC', 'Report_39'

Set Identity_Insert dbo.Report Off

