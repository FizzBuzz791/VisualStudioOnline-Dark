INSERT dbo.SecurityRoleOption
(
	Role_Id, Application_Id, Option_Id
)
VALUES
(
	'REC_PURGE', 'REC', 'PURGE_DATA'
)
GO
-- Grant access to the Live versus Summary report to all roles that have access to the F1F2F3 overview
DECLARE @optionId VARCHAR(31)
DECLARE @optionToCopyId VARCHAR(31)

SELECT @optionId = 'Report_' + convert(varchar,r.Report_Id)
FROM dbo.Report r
WHERE r.Name = 'BhpbioLiveVersusSummaryReport'

SELECT @optionToCopyId = 'Report_' + convert(varchar,r.Report_Id)
FROM dbo.Report r
WHERE r.Name = 'BhpbioF1F2F3OverviewReconReport'

INSERT dbo.SecurityRoleOption
(
	Role_Id, Application_Id, Option_Id
)
SELECT sro.Role_Id, sro.Application_Id, @optionId
FROM dbo.SecurityRoleOption sro
WHERE sro.Option_Id = @optionToCopyId
GO