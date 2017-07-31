Set Identity_Insert dbo.Report On

Insert Into dbo.Report (Report_Id, Name, Description, Report_Path, Report_Group_Id, Order_No)
	Select 40, 'BhpbioYearlyReconciliationReport', '01.5 Annual Report – Yearly Reconciliations', '', 1, 5


Insert Into SecurityOption
(
	Option_Id, Option_Group_Id, Application_Id, Description, Sort_Order
)
Select 'Report_40', 'Reports', 'REC', 'Access to Yearly Reconciliation Report', 99 

Insert Into SecurityRoleOption
(
	Role_Id, Option_Id, Application_Id
)
Select 'REC_ADMIN', 'Report_40', 'REC' 

Set Identity_Insert dbo.Report Off
