-- In order for them to appear on the Reports page the need to be added to the Reports
-- table. We also need to add them to the relevant security tables so they only appear to the
-- appropriate roles
--
-- Doesn't seem like the best idea to me to base the security option names off the report PK
-- but thats the way its done with all the other reports, so its best to keep things standard

Set Identity_Insert dbo.Report On

Insert Into dbo.Report (Report_Id, Name, Description, Report_Path, Report_Group_Id, Order_No)
	-- report_group_id = 2 = Factor Reports
	Select 38, 'BhpbioF1F2F3HUBGeometReconciliationReport', '02.7 Geomet HUB Reconciliation Report (Happy Faces)', '', 2, 7

Insert Into dbo.SecurityOption (Application_Id, Option_Id, Option_Group_Id, Description, Sort_Order)
	Select 'REC', 'Report_38', 'Reports', 'Access to Geomet Hub Report', 4

-- Hide this report for now - it will be reactivated during a november release - the data is not correct yet, and
-- we don't want to have the whole October release slip because of it
--
--Insert Into dbo.SecurityRoleOption (Role_Id, Application_Id, Option_Id)
--	Select 'REC_ADMIN', 'REC', 'Report_38'
