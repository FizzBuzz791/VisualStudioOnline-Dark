INSERT INTO dbo.Report
(
	Name,
	Description,
	Report_Path,
	Report_Group_Id,
	Order_No
)
SELECT 'BhpbioLiveVersusSummaryReport', 'Live Vs Approved Report', '', rg.Report_Group_Id, null
FROM dbo.ReportGroup rg
WHERE rg.Name = 'BHPBIO Reports'
GO