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

