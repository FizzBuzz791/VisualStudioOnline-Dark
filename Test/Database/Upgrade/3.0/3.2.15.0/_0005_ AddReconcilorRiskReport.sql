Set Identity_Insert dbo.Report On

Insert Into dbo.Report (Report_Id, Name, Description, Report_Path, Report_Group_Id, Order_No)
	Select 53, 'BhpbioRiskProfileReport', '03.16 Risk Profile Report', '', 3, 16

Insert Into dbo.SecurityOption (Application_Id, Option_Id, Option_Group_Id, Description, Sort_Order)
	Select 'REC', 'Report_53', 'Reports', 'Access to the Risk Profile Report', 8

Insert Into dbo.SecurityRoleOption (Role_Id, Application_Id, Option_Id)
	Select 'REC_ADMIN', 'REC', 'Report_53' Union
	Select 'BHP_AREAC', 'REC', 'Report_53' Union
	Select 'BHP_NJV', 'REC', 'Report_53' Union
	Select 'BHP_WAIO', 'REC', 'Report_53' Union
	Select 'BHP_YANDI', 'REC', 'Report_53' Union
	Select 'BHP_JIMBLEBAR', 'REC', 'Report_53' Union
	Select 'BHP_YARRIE', 'REC', 'Report_53'

Set Identity_Insert dbo.Report Off

