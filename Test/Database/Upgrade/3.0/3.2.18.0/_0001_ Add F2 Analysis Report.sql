Declare @ReportName Varchar(64) = 'BhpbioFactorAnalysisReport'

If Not Exists (Select 1 From dbo.Report Where [Name] = @ReportName)
Begin
	Set Identity_Insert dbo.Report On

	Insert Into dbo.Report (Report_Id, Name, Description, Report_Path, Report_Group_Id, Order_No)
		Select 55, @ReportName, 'Factor Analysis with Context Report (Line & Bar Charts)', '', 2, 100

	Insert Into dbo.SecurityOption (Application_Id, Option_Id, Option_Group_Id, Description, Sort_Order)
		Select 'REC', 'Report_55', 'Reports', 'Access to the Factor Analysis with Context Report', 19


	Insert Into dbo.SecurityRoleOption (Role_Id, Application_Id, Option_Id)
		Select 'REC_ADMIN', 'REC', 'Report_55' Union
		Select 'REC_VIEW', 'REC', 'Report_55'

	Set Identity_Insert dbo.Report Off
	End
Else
Begin
	-- This report has been renamed, so if it already exists, it might have the old name
	-- - update it just in case
	Update dbo.Report
	Set Description = 'Factor Analysis with Context Report (Line & Bar Charts)'
	Where Name = @ReportName
End

