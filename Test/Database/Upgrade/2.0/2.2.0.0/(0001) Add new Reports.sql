-- In order for them to appear on the Reports page the need to be added to the Reports
-- table. We also need to add them to the relevant security tables so they only appear to the
-- appropriate roles
--
-- Doesn't seem like the best idea to me to base the security option names off the report PK
-- but thats the way its done with all the other reports, so its best to keep things standard

Set Identity_Insert dbo.ReportGroup On

Insert Into dbo.ReportGroup (Report_Group_Id, [Name], Description, Order_No)
	Select 3, 'Investigative Reports', 'Investigative Reports', 3 Union
	Select 4, 'Presentation Reports', 'Presentation Reports', 4

Set Identity_Insert dbo.ReportGroup Off
Go

Set Identity_Insert dbo.Report On

Insert Into dbo.Report (Report_Id, Name, Description, Report_Path, Report_Group_Id, Order_No)
	Select 24, 'BhpbioBenchErrorByAttributeReport', 'Bench Error Reconciliation by Attribute Report', '', 2, 2 Union
	Select 25, 'BhpbioBenchErrorByLocationReport', 'Bench Error Reconciliation by Location Report', '', 2, 3 Union
	Select 26, 'BhpbioSupplyChainMonitoringReport', 'Supply Chain Monitoring Report', '', 2, 29 Union
	Select 27, 'BhpbioReconciliationRangeReport', 'Reconciliation Range Report', '', 2, 4 Union
	-- Presentation Reports
	Select 36, 'BhpbioMonthlySiteReconciliationReport', 'Site Monthly Reconciliation Report', '', 4, 4 Union
	Select 28, 'BhpbioQuarterlySiteReconciliationReport', 'Site Quarterly Reconciliation Report', '', 4, 5 Union
	Select 29, 'BhpbioQuarterlyHubReconciliationReport', 'Perth Quarterly Reconciliation Report', '', 4, 6 Union
	
	-- Investigative Reports
	Select 30, 'BhpbioFactorsVsTimeDensityReport', 'Factors vs Time Report - Density', '', 3, 20 Union
	Select 31, 'BhpbioFactorsVsTimeMoistureReport', 'Factors vs Time Report - Moisture', '', 3, 21 Union
	Select 32, 'BhpbioFactorsVsTimeVolumeReport', 'Factors vs Time Report - Volume', '', 3, 22 Union
	Select 33, 'BhpbioSupplyChainMoistureReport', 'Supply Chain Moisture Profile Report', '', 3, 30 Union
	Select 34, 'BhpbioDensityReconciliationReport', 'Density Reconciliation Report', '', 3, 31 Union
	Select 35, 'BhpbioDensityAnalysisReport', 'Density Analysis Report', '', 3, 32 Union
	Select 37, 'BhpbioSampleCoverageReport', 'Sample Coverage Report', '', 3, 33

Set Identity_Insert dbo.Report Off

Insert Into dbo.SecurityOption (Application_Id, Option_Id, Option_Group_Id, Description, Sort_Order)
	Select 'REC', 'ReportGroup_3', 'Reports', 'Access to Report Group ''Investigative Reports''', 3 Union
	Select 'REC', 'ReportGroup_4', 'Reports', 'Access to Report Group ''Presentation Reports''', 4 Union
	Select 'REC', 'Report_24', 'Reports', 'Access to Bench Error Reconciliation by Attribute Report', 4 Union
	Select 'REC', 'Report_25', 'Reports', 'Access to Bench Error Reconciliation by Location Report', 4 Union
	Select 'REC', 'Report_26', 'Reports', 'Access to Supply Chain Monitoring Report', 4 Union
	Select 'REC', 'Report_27', 'Reports', 'Access to Reconciliation Range Report', 4 Union
	Select 'REC', 'Report_28', 'Reports', 'Access to Site Quarterly Reconciliation Report', 4 Union
	Select 'REC', 'Report_29', 'Reports', 'Access to Hub Quarterly Reconciliation Report', 4 Union
	Select 'REC', 'Report_30', 'Reports', 'Access to Factors vs Time Report - Density', 4 Union
	Select 'REC', 'Report_31', 'Reports', 'Access to Factors vs Time Report - Moisture', 4 Union
	Select 'REC', 'Report_32', 'Reports', 'Access to Factors vs Time Report - Volume', 4 Union
	Select 'REC', 'Report_33', 'Reports', 'Access to Supply Chain Moisture Profile Report', 4 Union
	Select 'REC', 'Report_34', 'Reports', 'Access to Density Reconciliation Report', 4 Union
	Select 'REC', 'Report_35', 'Reports', 'Access to Density Analysis Report', 4 Union
	Select 'REC', 'Report_36', 'Reports', 'Access to Site Monthly Reconciliation Report', 4 Union
	Select 'REC', 'Report_37', 'Reports', 'Access to Sample Coverage Report', 4

Insert Into dbo.SecurityRoleOption (Role_Id, Application_Id, Option_Id)
	Select 'REC_ADMIN', 'REC', 'ReportGroup_3' Union
	Select 'REC_ADMIN', 'REC', 'ReportGroup_4' Union
	Select 'REC_ADMIN', 'REC', 'Report_24' Union
	Select 'REC_ADMIN', 'REC', 'Report_25' Union
	Select 'REC_ADMIN', 'REC', 'Report_26' Union
	Select 'REC_ADMIN', 'REC', 'Report_27' Union
	Select 'REC_ADMIN', 'REC', 'Report_28' Union
	Select 'REC_ADMIN', 'REC', 'Report_29' Union
	Select 'REC_ADMIN', 'REC', 'Report_30' Union
	Select 'REC_ADMIN', 'REC', 'Report_31' Union
	Select 'REC_ADMIN', 'REC', 'Report_32' Union
	Select 'REC_ADMIN', 'REC', 'Report_33' Union
	Select 'REC_ADMIN', 'REC', 'Report_34' Union
	Select 'REC_ADMIN', 'REC', 'Report_35' Union
	Select 'REC_ADMIN', 'REC', 'Report_36' Union
	Select 'REC_ADMIN', 'REC', 'Report_37'
