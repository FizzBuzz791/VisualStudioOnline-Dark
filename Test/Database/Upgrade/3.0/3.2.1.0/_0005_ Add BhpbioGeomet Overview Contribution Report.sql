Set Identity_Insert dbo.Report On

Insert Into dbo.Report (Report_Id, Name, Description, Report_Path, Report_Group_Id, Order_No)
	Select 50, 'BhpbioGeometOverviewReconContributionReport', '02.8 Geomet Overview Reconciliation Contribution Report', '', 2, 8

Insert Into dbo.SecurityOption (Application_Id, Option_Id, Option_Group_Id, Description, Sort_Order)
	Select 'REC', 'Report_50', 'Reports', 'Access to the Geomet Overview Reconciliation Contribution Report', 8

Insert Into dbo.SecurityRoleOption (Role_Id, Application_Id, Option_Id)
	Select 'REC_ADMIN', 'REC', 'Report_50' Union
	Select 'BHP_AREAC', 'REC', 'Report_50' Union
	Select 'BHP_NJV', 'REC', 'Report_50' Union
	Select 'BHP_WAIO', 'REC', 'Report_50' Union
	Select 'BHP_YANDI', 'REC', 'Report_50' Union
	Select 'BHP_JIMBLEBAR', 'REC', 'Report_50' Union
	Select 'BHP_YARRIE', 'REC', 'Report_50'

Set Identity_Insert dbo.Report Off

