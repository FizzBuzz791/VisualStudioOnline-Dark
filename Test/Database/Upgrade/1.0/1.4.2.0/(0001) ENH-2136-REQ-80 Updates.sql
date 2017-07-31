INSERT INTO dbo.Report ( [Name], [Description], Report_Path, Report_Group_id, Order_No)
SELECT 'BhpbioF1F2F3ReconciliationComparisonReport', 'F1F2F3 Reconciliation Comparison Report (Line-Chart)', '',  2, null UNION ALL
SELECT 'BhpbioF1F2F3ReconciliationLocationComparisonReport', 'F1F2F3 Reconciliation Location Comparison Report', '',  2, null UNION ALL
SELECT 'BhpbioF1F2F3OverviewReconReport', 'F1F2F3 Overview Reconciliation Report', '',  2, null

--Add Reports
Declare @ReportId Int
Declare @ReportName Varchar(255)
Declare @Cursor Cursor
Declare @Reports Table
(
	ReportId Int,
	ReportName Varchar(255)
)

Insert Into @Reports
Select Report_Id, Description
From Report 
Where Name In ('BhpbioF1F2F3ReconciliationComparisonReport', 'BhpbioF1F2F3ReconciliationLocationComparisonReport', 'BhpbioF1F2F3OverviewReconReport')

Set @Cursor = Cursor Fast_Forward Read_Only For
Select ReportId, ReportName 
From @Reports

Open @Cursor

Fetch Next From @Cursor Into @ReportId, @ReportName

While @@FETCH_STATUS = 0
Begin
	If Not Exists (Select 1 From SecurityOption Where Option_Id = 'Report_' + Convert(Varchar, @ReportId)) 
	Begin
		Insert Into dbo.SecurityOption
		(
			Application_Id, Option_Id, Option_Group_Id, Description, Sort_Order
		)
		Select 'REC', 'Report_' + Convert(Varchar, @ReportId), 'Reports', 
			'Access To ' + @ReportName, 99
	End

	Insert Into dbo.SecurityRoleOption
	(
		Role_Id, Application_Id, Option_Id
	)
	Select R.RoleId, 'REC', 'Report_' + Convert(Varchar, @ReportId)
	From dbo.SecurityRole As R
		Left Outer Join dbo.SecurityRoleOption As SRO
			On (R.RoleId = SRO.Role_Id
				And SRO.Option_Id = 'Report_' + Convert(Varchar, @ReportId))
	Where SRO.Role_Id Is Null

	Fetch Next From @Cursor Into @ReportId, @ReportName
End


INSERT INTO dbo.BhpbioReportColor (TagId, [Description], IsVisible, Color, LineStyle, MarkerShape)
SELECT 'Attribute Al2O3', 'Al2O3', 1, 'Black', 'Solid', 'None'
UNION 
SELECT 'Attribute Fe', 'Fe', 1, 'Yellow', 'Solid', 'None'
UNION 
SELECT 'Attribute LOI',	'LOI', 1, 'Brown', 'Solid', 'None'
UNION 
SELECT 'Attribute P', 'P', 1, 'Blue', 'Solid', 'None'
UNION 
SELECT 'Attribute SiO2', 'SiO2', 1, 'Green', 'Solid', 'None'
UNION 
SELECT 'Attribute Tonnes', 'Tonnes', 1, 'Red'	, 'Solid', 'None'

