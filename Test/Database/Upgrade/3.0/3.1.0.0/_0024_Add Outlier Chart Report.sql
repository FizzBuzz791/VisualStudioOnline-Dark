Set Identity_Insert dbo.Report On

Insert Into dbo.Report (Report_Id, Name, Description, Report_Path, Report_Group_Id, Order_No)
	Select 48, 'BhpbioOutlierAnalysisChart', 'Bhpbio Outlier Analysis Chart', '', 3, 30

Insert Into dbo.SecurityOption (Application_Id, Option_Id, Option_Group_Id, Description, Sort_Order)
	Select 'REC', 'Report_48', 'Reports', 'Access to Outlier Analysis Chart', 4
	
--Insert Into dbo.SecurityRoleOption (Role_Id, Application_Id, Option_Id)
--	Select 'REC_ADMIN', 'REC', 'Report_48'

Set Identity_Insert dbo.Report Off