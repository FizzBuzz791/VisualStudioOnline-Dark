-- Add a new report to the report list, and create the default security options so that the admin can see and run
-- it. Once this has been updated, you will need to clean and build again to have it take effect.

Set Identity_Insert dbo.Report On

Insert Into dbo.Report (Report_Id, Name, Description, Report_Path, Report_Group_Id, Order_No)
	Select 22, 'BhpbioF1F2F3OverviewReconContributionReport', 'F1F2F3 Overview Reconciliation Contribution Report', '', 2, NULL

Set Identity_Insert dbo.Report Off

Insert Into dbo.SecurityOption (Application_Id, Option_Id, Option_Group_Id, Description, Sort_Order)
	Select 'REC', 'Report_22', 'Reports', 'Access to Report BhpbioF1F2F3OverviewReconContributionReport', 4
	

Insert Into dbo.SecurityRoleOption (Role_Id, Application_Id, Option_Id)
	Select 'REC_ADMIN', 'REC', 'Report_22'