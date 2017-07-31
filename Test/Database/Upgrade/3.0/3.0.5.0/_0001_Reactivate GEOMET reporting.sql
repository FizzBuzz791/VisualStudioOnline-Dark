--
-- Turn the geomet setting back on & Give admins permission to the geomet report
--
-- In addition to this script we will need to make some modifications to the Hub Report RDL, and 
-- deploy the linked report for the geomet hub
--


Update Setting Set Value = 'TRUE'
Where Setting_Id = 'GEOMET_REPORTING_ENABLED'

Insert Into dbo.SecurityRoleOption (Role_Id, Application_Id, Option_Id)
	Select 'REC_ADMIN', 'REC', 'Report_38'
