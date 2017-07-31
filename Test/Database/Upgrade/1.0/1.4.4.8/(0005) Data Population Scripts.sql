INSERT AuditTypeGroup
(
	Audit_Type_Group_Id, [Name], [Description]
)
SELECT 6, 'Purge', 'Events triggered by the Purge Agent & UI Interface related to purge activities'
GO
SET IDENTITY_INSERT dbo.AuditType ON
INSERT dbo.AuditType
(
	Audit_Type_Id, Audit_Type_Group_Id, [Name]
)
SELECT 35, 6, 'Purge Requested' UNION
SELECT 36, 6, 'Purge Approved' UNION
SELECT 37, 6, 'Purge Cancelled' UNION
SELECT 38, 6, 'Purge Obsolete' UNION
SELECT 39, 6, 'Purge Initiated' UNION
SELECT 40, 6, 'Purge Completed' UNION
SELECT 41, 6, 'Purge Failed' UNION
SELECT 42, 6, 'Purge Agent Error' UNION
SELECT 43, 6, 'Purge Agent Started' UNION
SELECT 44, 6, 'Purge Agent Stopped'

SET IDENTITY_INSERT dbo.AuditType OFF
GO
INSERT dbo.BhpbioPurgeRequestStatus
(
	PurgeRequestStatusId, [Name], IsReadyForApproval, IsReadyForPurging, IsFinalStatePositive, IsFinalStateNegative
)
SELECT 1, 'Requested', 1, 0, 0, 0 UNION
SELECT 2, 'Cancelled', 0, 0, 0, 1 UNION
SELECT 3, 'Obsolete', 0, 0, 0, 1 UNION
SELECT 4, 'Approved', 0, 1, 1, 0 UNION
SELECT 5, 'Initiated', 0, 0, 0, 0 UNION
SELECT 6, 'Completed', 0, 0, 1, 0 UNION
SELECT 7, 'Failed', 0, 0, 0, 1
GO
INSERT INTO dbo.BhpbioSummaryEntryType
(
	SummaryEntryTypeId, 
	Name
)
VALUES (1,'ActualY')
GO
INSERT INTO dbo.BhpbioSummaryEntryType
(
	SummaryEntryTypeId, 
	Name
)
VALUES (2,'ActualZ')
GO
INSERT INTO dbo.BhpbioSummaryEntryType
(
	SummaryEntryTypeId, 
	Name
)
VALUES (3,'ActualC')
GO
INSERT INTO dbo.BhpbioSummaryEntryType
(
	SummaryEntryTypeId, 
	Name
)
VALUES (4,'SitePostCrusherStockpileDelta')
GO
INSERT INTO dbo.BhpbioSummaryEntryType
(
	SummaryEntryTypeId, 
	Name
)
VALUES (5,'HubPostCrusherStockpileDelta')
GO
INSERT INTO dbo.BhpbioSummaryEntryType
(
	SummaryEntryTypeId, 
	Name
)
VALUES (6,'PortStockpileDelta')
GO
INSERT INTO dbo.BhpbioSummaryEntryType
(
	SummaryEntryTypeId, 
	Name,
	AssociatedBlockModelId
)
SELECT 7,'GeologyModelMovement', bm.Block_Model_Id
FROM dbo.BlockModel bm
	INNER JOIN dbo.BlockModelType bmt
		ON bmt.Block_Model_Type_Id = bm.Block_Model_Type_Id
WHERE bmt.Name = 'Geology'
	AND bm.Is_Default = 1
GO
INSERT INTO dbo.BhpbioSummaryEntryType
(
	SummaryEntryTypeId, 
	Name,
	AssociatedBlockModelId
)
SELECT 8,'MiningModelMovement', bm.Block_Model_Id
FROM dbo.BlockModel bm
	INNER JOIN dbo.BlockModelType bmt
		ON bmt.Block_Model_Type_Id = bm.Block_Model_Type_Id
WHERE bmt.Name = 'Mining'
	AND bm.Is_Default = 1
GO
INSERT INTO dbo.BhpbioSummaryEntryType
(
	SummaryEntryTypeId, 
	Name,
	AssociatedBlockModelId
)
SELECT 9,'GradeControlModelMovement', bm.Block_Model_Id
FROM dbo.BlockModel bm
	INNER JOIN dbo.BlockModelType bmt
		ON bmt.Block_Model_Type_Id = bm.Block_Model_Type_Id
WHERE bmt.Name = 'Grade Control'
	AND bm.Is_Default = 1
GO
INSERT INTO dbo.BhpbioSummaryEntryType
(
	SummaryEntryTypeId, 
	Name
)
VALUES (10,'ShippingTransaction')
GO
INSERT INTO dbo.BhpbioSummaryEntryType
(
	SummaryEntryTypeId, 
	Name
)
VALUES (11,'PortBlending')
GO
INSERT INTO dbo.BhpbioSummaryEntryType
(
	SummaryEntryTypeId, 
	Name
)
VALUES (12,'ActualOMToStockpile')
GO
INSERT INTO dbo.BhpbioSummaryEntryType
(
	SummaryEntryTypeId, 
	Name
)
VALUES (13,'BlastBlockMonthlyHauled')
GO
INSERT INTO dbo.BhpbioSummaryEntryType
(
	SummaryEntryTypeId, 
	Name
)
VALUES (14,'BlastBlockMonthlyBest')
GO
INSERT INTO dbo.BhpbioSummaryEntryType
(
	SummaryEntryTypeId, 
	Name
)
VALUES (15,'BlastBlockSurvey')
GO
INSERT INTO dbo.BhpbioSummaryEntryType
(
	SummaryEntryTypeId, 
	Name
)
VALUES (16,'ActualBeneProduct')
GO
INSERT INTO dbo.BhpbioSummaryEntryType
(
	SummaryEntryTypeId, 
	Name
)
VALUES (17,'ActualCSampleTonnes')
GO
INSERT INTO dbo.BhpbioSummaryEntryType
(
	SummaryEntryTypeId, 
	Name
)
VALUES (18,'SitePostCrusherSpDeltaGrades')
GO
INSERT INTO dbo.BhpbioSummaryEntryType
(
	SummaryEntryTypeId, 
	Name
)
VALUES (19,'HubPostCrusherSpDeltaGrades')
GO
INSERT INTO dbo.BhpbioSummaryEntryType
(
	SummaryEntryTypeId, 
	Name
)
VALUES (20,'BlastBlockCumulativeHauled')
GO
INSERT INTO dbo.BhpbioSummaryEntryType
(
	SummaryEntryTypeId, 
	Name,
	AssociatedBlockModelId
)
SELECT 21,'BlastBlockTotalGradeControl', bm.Block_Model_Id
FROM dbo.BlockModel bm
	INNER JOIN dbo.BlockModelType bmt
		ON bmt.Block_Model_Type_Id = bm.Block_Model_Type_Id
WHERE bmt.Name = 'Grade Control'
	AND bm.Is_Default = 1
GO
INSERT INTO dbo.BhpbioReportThresholdType
(
	ThresholdTypeId,
	Description
)
VALUES ('LiveVsSummaryProportionDiff', 'LiveVsSummaryProportionDiff')
GO
DECLARE @locationId INTEGER
SELECT @locationId = Location_Id FROM dbo.Location WHERE Name = 'WAIO'

IF NOT @locationId IS NULL
BEGIN
	INSERT INTO dbo.BhpbioReportThreshold
	(
		LocationId,
		FieldId,
		ThresholdTypeId,
		LowThreshold,
		HighThreshold,
		AbsoluteThreshold
	)
	VALUES (@locationId,0,'LiveVsSummaryProportionDiff',0.01,0.05, 0)

	INSERT INTO dbo.BhpbioReportThreshold
	(
		LocationId,
		FieldId,
		ThresholdTypeId,
		LowThreshold,
		HighThreshold,
		AbsoluteThreshold
	)
	SELECT @locationId,g.Grade_Id,'LiveVsSummaryProportionDiff',0.0001,0.0005, 0
	FROM dbo.Grade g
END
GO
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
INSERT dbo.SecurityOptionGroup
(
	Option_Group_Id, Sort_Order
)
VALUES
(
	'Purge', 10
)
GO
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
INSERT dbo.SecurityRole
(
	RoleId, Description
)
VALUES
(
	'REC_PURGE', 'Reconcilor Data Purge'
)
GO
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