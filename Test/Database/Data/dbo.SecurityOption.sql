INSERT dbo.SecurityOption
(
	Option_Id, Option_Group_Id, Application_Id, Description, Sort_Order
)
SELECT 'PURGE_DATA', 'Purge', 'REC', 'Access to Purge Functionality', 1
GO
INSERT SecurityOption
(
	Option_Id, Option_Group_Id, Application_Id, Description, Sort_Order
)
SELECT 'Report_' + convert(varchar,r.Report_Id), 'Reports', 'Rec', 'Access to Report ''' + r.Description + '''',99
FROM dbo.Report r
WHERE r.Name = 'BhpbioLiveVersusSummaryReport'
GO
