-- Remove ALL EXISTING DATA.

DELETE FROM [dbo].[Stockpiles]
DELETE FROM [dbo].[StockpileAdjustmentGrade]
DELETE FROM [dbo].[StockpileAdjustment]
DELETE FROM [dbo].[TransactionGrades]
DELETE FROM [dbo].[Transactions]
DELETE FROM [dbo].[HaulageGrade]
DELETE FROM [dbo].[Haulage]
DELETE FROM [dbo].[Locations]

--Select *  from [Stockpiles]
--Select * FROM [dbo].[StockpileAdjustmentGrade]
--Select *  FROM [dbo].[StockpileAdjustment]
--Select *  FROM [dbo].[TransactionGrades]
--Select *  FROM [dbo].[Transactions]
--Select *  FROM [dbo].[HaulageGrade]
--Select *  FROM [dbo].[Haulage]
--Select *  FROM [dbo].[Locations]


-- Reference Data common to all imports:
INSERT INTO [dbo].[Locations] ([Mine])
			Select 'WB' UNION ALL
			Select 'MW' UNION ALL
			Select 'YD' UNION ALL
			Select 'AC' UNION ALL
			Select 'JB' UNION ALL
			Select '18' UNION ALL
			Select '25' UNION ALL
			Select 'NM' UNION ALL
			Select 'YR'


--Covers test case "Production Import - INSERT": Step 1
INSERT INTO [dbo].[Transactions]
(
	[TransactionDate],
	[Source],
	[SourceType],
	[Destination],
	[DestinationType],
	[Type],
	[SourceMineSite],
	[DestinationMineSite],
	[Tonnes],
	[ProductSize],
	[SampleSource],
	[SampleTonnes],
	[SampleCount],
	[LocationId]
)
SELECT '2017-08-10', 'C1', 'Crusher', '17198B1', 'Post Crusher', 'Movement', 'AC', 'AC', 6573.18, 'FINES', 'SampleSource', 12.34, 1, [Id] FROM dbo.Locations WHERE Mine='WB' UNION ALL
SELECT '2017-08-11', 'C1', 'Crusher', '17198B1', 'Post Crusher', 'Movement', 'AC', 'AC', 6673.28, 'LUMP', 'SampleSource', 22.34, 2, [Id] FROM dbo.Locations WHERE Mine='WB' UNION ALL
SELECT '2017-08-12', 'C1', 'Crusher', '17198B1', 'Post Crusher', 'Movement', 'AC', 'AC', 6773.38, 'FINES', 'SampleSource', 32.34, 3, [Id] FROM dbo.Locations WHERE Mine='WB' UNION ALL
SELECT '2017-08-13', 'C1', 'Crusher', '17198B1', 'Post Crusher', 'Movement', 'AC', 'AC', 6873.48, 'LUMP', 'SampleSource', 42.34, 2, [Id] FROM dbo.Locations WHERE Mine='WB'
GO

INSERT INTO [dbo].[TransactionGrades]
(
	TransactionId,
	GradeName,
	HeadValue
)
SELECT [Id], 'Fe', 58.37 FROM [dbo].[Transactions] UNION ALL
SELECT [Id], 'P', 0.0552 FROM [dbo].[Transactions] UNION ALL
SELECT [Id], 'SiO2', 7.05 FROM [dbo].[Transactions] UNION ALL
SELECT [Id], 'Al2O3', 3.85 FROM [dbo].[Transactions] UNION ALL
SELECT [Id], 'LOI', 47.77 FROM [dbo].[Transactions] UNION ALL
SELECT [Id], 'H2O', 7.01 FROM [dbo].[Transactions] UNION ALL
SELECT [Id], 'H2O-As-Dropped', 6.56 FROM [dbo].[Transactions] UNION ALL
SELECT [Id], 'H2O-As-Shipped', 6.45 FROM [dbo].[Transactions] UNION ALL
SELECT [Id], 'GradeToIgnore', 487.245 FROM [dbo].[Transactions]
GO


--Covers test case "Haulage Import - INSERT": Step 1
INSERT INTO [dbo].[Haulage]
(
	TransactionDate,
	[Source],
	SourceMineSite,
	DestinationMineSite,
	SourceLocationType,-- 'Pre Crusher', 'Blast Block'
	Destination,
	DestinationType,
	[Type],
	BestTonnes,
	HauledTonnes,
	AerialSurveyTonnes,
	GroundSurveyTonnes,
	LumpPercent,
	LastModifiedTime,
	LocationId
)
SELECT '2017-08-10', 'SP17', 'WB', 'WB', 'Pre Crusher', 'BSP4_1200061', 'Pre Crusher', 'Movement', 6573.78, 6587.49, 6522.54, 6573.78, 0.19, '2013-08-10', [Id] FROM dbo.Locations WHERE Mine='WB' UNION ALL
SELECT '2017-08-11', 'SP18', 'WB', 'WB', 'Pre Crusher', 'BSP4_1200062', 'Pre Crusher', 'Movement', 6573.78, 6587.49, 6522.54, 6573.78, 0.19, '2013-08-10', [Id] FROM dbo.Locations WHERE Mine='WB' UNION ALL
SELECT '2017-08-12', 'SP19', 'WB', 'WB', 'Pre Crusher', 'BSP4_1200063', 'Pre Crusher', 'Movement', 6573.78, 6587.49, 6522.54, 6573.78, 0.19, '2013-08-10', [Id] FROM dbo.Locations WHERE Mine='WB' UNION ALL
SELECT '2017-08-13', 'SP20', 'WB', 'WB', 'Pre Crusher', 'BSP4_1200064', 'Pre Crusher', 'Movement', 6573.78, 6587.49, 6522.54, 6573.78, 0.19, '2013-08-10', [Id] FROM dbo.Locations WHERE Mine='WB' UNION ALL
SELECT '2017-08-14', 'SP21', 'WB', 'WB', 'Pre Crusher', 'BSP4_1200065', 'Pre Crusher', 'Movement', 6573.78, 6587.49, 6522.54, 6573.78, 0.19, '2013-08-10', [Id] FROM dbo.Locations WHERE Mine='WB' UNION ALL
SELECT '2017-08-15', 'SP22', 'WB', 'WB', 'Pre Crusher', 'BSP4_1200066', 'Pre Crusher', 'Movement', 6573.78, 6587.49, 6522.54, 6573.78, 0.19, '2013-08-10', [Id] FROM dbo.Locations WHERE Mine='WB' UNION ALL
SELECT '2017-08-16', 'SP23', 'WB', 'WB', 'Pre Crusher', 'BSP4_1200067', 'Pre Crusher', 'Movement', 6573.78, 6587.49, 6522.54, 6573.78, 0.19, '2013-08-10', [Id] FROM dbo.Locations WHERE Mine='WB'
GO

INSERT INTO [dbo].[HaulageGrade]
(
	HaulageId,
	GradeName,
	HeadValue,
	FinesValue,
	LumpValue
)
SELECT HaulageId, 'Fe', 58.37, 59.67, 51.37 FROM [dbo].[Haulage] UNION ALL
SELECT HaulageId, 'P', 0.0552, 0.0514, 0.0511 FROM [dbo].[Haulage] UNION ALL
SELECT HaulageId, 'SiO2', 7.05, 3.46, 6.32 FROM [dbo].[Haulage] UNION ALL
SELECT HaulageId, 'Al2O3', 3.85, 3.05, 1.82 FROM [dbo].[Haulage] UNION ALL
SELECT HaulageId, 'LOI', 54.77, 59.67, 51.37 FROM [dbo].[Haulage] UNION ALL
SELECT HaulageId, 'H2O', 7.02, 5.46, 2.32 FROM [dbo].[Haulage] UNION ALL
SELECT HaulageId, 'H2O-As-Dropped', 6.05, 5.46, 3.32 FROM [dbo].[Haulage] UNION ALL
SELECT HaulageId, 'H2O-As-Shipped', 5.05, 4.46, 3.02 FROM [dbo].[Haulage] UNION ALL
SELECT HaulageId, 'GradeToIgnore', 358.36, 487.68, 487.245 FROM [dbo].[Haulage]
GO

--Covers test case "Haulage Import - INSERT": Step 2
INSERT INTO [dbo].[Haulage]
(
	TransactionDate,
	[Source],
	SourceMineSite,
	DestinationMineSite,
	SourceLocationType,
	Destination,
	DestinationType,
	[Type],
	BestTonnes,
	HauledTonnes,
	AerialSurveyTonnes,
	GroundSurveyTonnes,
	LumpPercent,
	LastModifiedTime,
	LocationId
)
SELECT '2017-08-08', 'IOCrusher1', 'WB', 'WB', 'Pre Crusher', 'BSP4_1200061', 'Pre Crusher', 'Movement', Null, Null, Null, Null, Null, '2013-08-14', 1 UNION ALL
SELECT '2017-08-09', 'IOCrusher2', 'WB', 'WB', 'Pre Crusher', 'BSP4_1200062', 'Pre Crusher', 'Movement', Null, Null, Null, Null, Null, '2013-08-14', 1 UNION ALL
SELECT '2017-08-10', 'IOCrusher3', 'WB', 'WB', 'Pre Crusher', 'BSP4_1200063', 'Pre Crusher', 'Movement', Null, Null, Null, Null, Null, '2013-08-14', 1 UNION ALL
SELECT '2017-08-11', 'IOCrusher4', 'WB', 'WB', 'Pre Crusher', 'BSP4_1200064', 'Pre Crusher', 'Movement', Null, Null, Null, Null, Null, '2013-08-14', 1 UNION ALL
SELECT '2017-08-12', 'IOCrusher5', 'WB', 'WB', 'Pre Crusher', 'BSP4_1200065', 'Pre Crusher', 'Movement', Null, Null, Null, Null, Null, '2013-08-14', 1 UNION ALL
SELECT '2017-08-13', 'IOCrusher1', 'WB', 'WB', 'Pre Crusher', 'BSP4_1200066', 'Pre Crusher', 'Movement', Null, Null, Null, Null, Null, '2013-08-14', 1 UNION ALL
SELECT '2017-08-14', 'IOCrusher1', 'WB', 'WB', 'Pre Crusher', 'SP7', 'Pre Crusher', 'Movement', Null, Null, Null, Null, Null, '2013-08-14', 1

INSERT INTO [dbo].[HaulageGrade]
(
	HaulageId,
	GradeName,
	HeadValue,
	FinesValue,
	LumpValue
)
SELECT HaulageId, 'Fe', 57.83, 58.39, 52.01 FROM [dbo].[Haulage] WHERE TransactionDate IN ('2013-08-08','2013-08-09','2013-08-10','2013-08-11','2013-08-12','2013-08-13','2013-08-14') UNION ALL
SELECT HaulageId, 'P', 0.0547, 0.0578, 0.0633 FROM [dbo].[Haulage] WHERE TransactionDate IN ('2013-08-08','2013-08-09','2013-08-10','2013-08-11','2013-08-12','2013-08-13','2013-08-14') UNION ALL
SELECT HaulageId, 'SiO2', 7.157, 4.246, 3.999 FROM [dbo].[Haulage] WHERE TransactionDate IN ('2013-08-08','2013-08-09','2013-08-10','2013-08-11','2013-08-12','2013-08-13','2013-08-14') UNION ALL
SELECT HaulageId, 'Al2O3', 4.3541, 1.5412, 2.784 FROM [dbo].[Haulage] WHERE TransactionDate IN ('2013-08-08','2013-08-09','2013-08-10','2013-08-11','2013-08-12','2013-08-13','2013-08-14') UNION ALL
SELECT HaulageId, 'LOI', 55.27, 58.927, 52.193 FROM [dbo].[Haulage] WHERE TransactionDate IN ('2013-08-08','2013-08-09','2013-08-10','2013-08-11','2013-08-12','2013-08-13','2013-08-14') UNION ALL
SELECT HaulageId, 'H2O', 7.22, 5.26, 2.22 FROM [dbo].[Haulage] WHERE TransactionDate IN ('2013-08-08','2013-08-09','2013-08-10','2013-08-11','2013-08-12','2013-08-13','2013-08-14') UNION ALL
SELECT HaulageId, 'H2O-As-Dropped', 6.25, 5.26, 3.21 FROM [dbo].[Haulage] WHERE TransactionDate IN ('2013-08-08','2013-08-09','2013-08-10','2013-08-11','2013-08-12','2013-08-13','2013-08-14') UNION ALL
SELECT HaulageId, 'H2O-As-Shipped', 5.25, 4.26, 3.22 FROM [dbo].[Haulage] WHERE TransactionDate IN ('2013-08-08','2013-08-09','2013-08-10','2013-08-11','2013-08-12','2013-08-13','2013-08-14') UNION ALL
SELECT HaulageId, 'GradeToIgnore', 358.36, 487.68, 487.245 FROM [dbo].[Haulage] WHERE TransactionDate IN ('2013-08-08','2013-08-09','2013-08-10','2013-08-11','2013-08-12','2013-08-13','2013-08-14')
GO

--Covers test case "Haulage Import - INSERT": Step 3
INSERT INTO [dbo].[Haulage]
(
	TransactionDate,
	[Source],
	SourceMineSite,
	DestinationMineSite,
	SourceLocationType,
	Destination,
	DestinationType,
	[Type],
	BestTonnes,
	HauledTonnes,
	AerialSurveyTonnes,
	GroundSurveyTonnes,
	LumpPercent,
	LastModifiedTime,
	LocationId
)
SELECT '2017-08-08', Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null UNION ALL
SELECT '2017-08-09', Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null UNION ALL
SELECT '2017-08-10', Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null UNION ALL
SELECT '2017-08-11', Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null UNION ALL
SELECT '2017-08-12', Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null UNION ALL
SELECT '2017-08-13', Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null UNION ALL
SELECT '2017-08-14', Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null UNION ALL
SELECT '2017-08-15', Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null



-- For the "Haulage Import - UPDATE" Step 5 test case use existing data imported via Core v6.2 import framework; ensure that the data is available in
--[RECONCILOR2\SQL2005].[ReconcilorBhpbioV64] database, otherwise modify the below script appropriately
INSERT INTO [dbo].[Haulage]
(
	TransactionDate,
	[Source],
	SourceMineSite,
	DestinationMineSite,
	--SourceLocationType,
	Destination,
	--DestinationType,
	--[Type],
	BestTonnes--,
	--HauledTonnes,
	--AerialSurveyTonnes,
	--GroundSurveyTonnes,
	--LumpPercent,
	--LastModifiedTime,
	--LocationId
)
select h.Haulage_Date, h.Source, sl.Name As SourceMineSite, dl.Name As DestinationMineSite, h.Destination, h.Tonnes
from [RECONCILOR2\SQL2005].[ReconcilorBhpbioV64].dbo.HaulageRaw as h
join [RECONCILOR2\SQL2005].[ReconcilorBhpbioV64].dbo.HaulageRawLocation hrl
on h.Haulage_Raw_Id=hrl.HaulageRawId
join [RECONCILOR2\SQL2005].[ReconcilorBhpbioV64].dbo.Location as sl
on hrl.SourceLocationId = sl.Location_Id
join [RECONCILOR2\SQL2005].[ReconcilorBhpbioV64].dbo.Location as dl
on hrl.DestinationLocationId = dl.Location_Id
where h.Haulage_Date between '2017-08-10' and '2017-08-14'
order by h.Haulage_Date desc


-- Test Case: Stockpile Import - INSERT, Step 1
INSERT INTO [dbo].[Stockpiles]
(
	[LocationId],
	[Name],
	[BusinessId],
	[StockpileType],
	[Description],
	[OreType],
	[Type],
	[Active],
	[StartDate],
	[ProductSize],
	[BalanceDate],
	[Hub],
	[Product],
	[Tonnes]
)
Select loc.Id, 'Stockpile1', 'Business1', 'Average', 'Test stockpile data for import', 'SCR', 'ExampleType', 1, '2013-07-01', 'LUMP', '2017-07-01', 'Yandi', 'ExampleProduct', 1000 From dbo.Locations loc Where loc.Mine = 'YD' UNION ALL
Select loc.Id, 'Stockpile2', 'Business2', 'FIFO', 'Test stockpile data for import', 'LTS', 'ExampleType', 1, '2013-07-02', 'FINES', '2017-07-01', 'Yandi', 'ExampleProduct', 1000 From dbo.Locations loc Where loc.Mine = 'YD' UNION ALL
Select loc.Id, 'Stockpile3', 'Business3', 'LIFO', 'Test stockpile data for import', 'MG', 'ExampleType', 1, '2013-07-03', 'LUMP', '2017-07-01', 'Yandi', 'ExampleProduct', 1000 From dbo.Locations loc Where loc.Mine = 'YD' UNION ALL
Select loc.Id, 'Stockpile4', 'Business4', 'Average', 'Test stockpile data for import', 'MG', 'ExampleType', 1, '2013-07-04', 'FINES', '2017-07-01', 'Yandi', 'ExampleProduct', 1000 From dbo.Locations loc Where loc.Mine = 'YD' UNION ALL
Select loc.Id, 'Stockpile5', 'Business5', 'FIFO', 'Test stockpile data for import', 'ROM', 'ExampleType', 1, '2013-07-05', 'LUMP', '2017-07-01', 'Yandi', 'ExampleProduct', 1000 From dbo.Locations loc Where loc.Mine = 'YD' UNION ALL
Select loc.Id, 'Stockpile6', 'Business6', 'LIFO', 'Test stockpile data for import', 'SW', 'ExampleType', 1, '2013-07-06', 'FINES', '2017-07-01', 'Yandi', 'ExampleProduct', 1000 From dbo.Locations loc Where loc.Mine = 'YD' UNION ALL
Select loc.Id, 'Stockpile7', 'Business7', 'Average', 'Test stockpile data for import', 'WS', 'ExampleType', 1, '2013-07-07', 'LUMP', '2017-07-01', 'Yandi', 'ExampleProduct', 1000 From dbo.Locations loc Where loc.Mine = 'YD'

-- Test Case: Stockpile Import - INSERT, Step 2
INSERT INTO [dbo].[Stockpiles]
(
	[LocationId], --*
	[Name], --*
	[BusinessId],
	[StockpileType], --*
	[Description],
	[OreType],
	[Type],
	[Active],
	[StartDate],
	[ProductSize],
	[BalanceDate],
	[Hub],
	[Product],
	[Tonnes] --*
)
Select loc.Id, 'Stockpile1', NULL, 'Average', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 100 From dbo.Locations loc Where loc.Mine = '18' UNION ALL
Select loc.Id, 'Stockpile2', NULL, 'FIFO', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 200 From dbo.Locations loc Where loc.Mine = '18' UNION ALL
Select loc.Id, 'Stockpile3', NULL, 'LIFO', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 300 From dbo.Locations loc Where loc.Mine = '18' UNION ALL
Select loc.Id, 'Stockpile4', NULL, 'Average', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 400 From dbo.Locations loc Where loc.Mine = '18' UNION ALL
Select loc.Id, 'Stockpile5', NULL, 'FIFO', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 500 From dbo.Locations loc Where loc.Mine = '18' UNION ALL
Select loc.Id, 'Stockpile6', NULL, 'LIFO', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 600 From dbo.Locations loc Where loc.Mine = '18' UNION ALL
Select loc.Id, 'Stockpile7', NULL, 'Average', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 700 From dbo.Locations loc Where loc.Mine = '18'

-- Test Case: Stockpile Import - INSERT, Step 3
INSERT INTO [dbo].[Stockpiles]
(
	[LocationId],
	[Name],
	[BusinessId],
	[StockpileType],
	[Description],
	[OreType],
	[Type],
	[Active],
	[StartDate],
	[ProductSize],
	[BalanceDate],
	[Hub],
	[Product],
	[Tonnes]
)
Select loc.Id, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL From dbo.Locations loc Where loc.Mine = 'AC' UNION ALL
Select loc.Id, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL From dbo.Locations loc Where loc.Mine = 'AC' UNION ALL
Select loc.Id, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL From dbo.Locations loc Where loc.Mine = 'AC' UNION ALL
Select loc.Id, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL From dbo.Locations loc Where loc.Mine = 'AC' UNION ALL
Select loc.Id, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL From dbo.Locations loc Where loc.Mine = 'AC' UNION ALL
Select loc.Id, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL From dbo.Locations loc Where loc.Mine = 'AC' UNION ALL
Select loc.Id, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL From dbo.Locations loc Where loc.Mine = 'AC'

-- Test Case: Stockpile Import - INSERT, Step 4
INSERT INTO [dbo].[Stockpiles]
(
	[LocationId],
	[Name],
	[BusinessId],
	[StockpileType],
	[Description],
	[OreType],
	[Type],
	[Active],
	[StartDate],
	[ProductSize],
	[BalanceDate],
	[Hub],
	[Product],
	[Tonnes]
)
Select loc.Id, 'Stockpile9', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL From dbo.Locations loc Where loc.Mine = 'WB' UNION ALL
Select loc.Id, 'Stockpile9', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL From dbo.Locations loc Where loc.Mine = 'WB'



-- Test Case: Stockpile Adjustment Import
INSERT INTO dbo.StockpileAdjustment
(
	LocationId, StockpileName, AdjustmentType, AdjustmentDate, Tonnes, FinesPercent, LumpPercent, BCM, LastModifiedTime
)
SELECT Id, '06001PL', '+', '2017-08-10', 237.548, 0.1254, 0.5687, 3.457, GETDATE() FROM dbo.Locations WHERE Mine = '18' UNION ALL
SELECT Id, '06001PL', '-', '2017-08-11', 237.548, 0.1254, 0.5687, 3.457, GETDATE() FROM dbo.Locations WHERE Mine = '18' UNION ALL
SELECT Id, '06001PL', '+', '2017-08-12', 237.548, 0.1254, 0.5687, 3.457, GETDATE() FROM dbo.Locations WHERE Mine = '18' UNION ALL
SELECT Id, '06001PL', '-', '2017-08-13', 237.548, 0.1254, 0.5687, 3.457, GETDATE() FROM dbo.Locations WHERE Mine = '18'
GO

INSERT INTO dbo.StockpileAdjustmentGrade
(
	StockpileAdjustmentId,
	GradeName,
	HeadValue
)
SELECT StockpileAdjustmentId, 'Fe', 58.37 FROM dbo.StockpileAdjustment UNION ALL
SELECT StockpileAdjustmentId, 'P', 0.0552 FROM dbo.StockpileAdjustment UNION ALL
SELECT StockpileAdjustmentId, 'SiO2', 7.05 FROM dbo.StockpileAdjustment UNION ALL
SELECT StockpileAdjustmentId, 'Al2O3', 3.85 FROM dbo.StockpileAdjustment UNION ALL
SELECT StockpileAdjustmentId, 'LOI', 47.77 FROM dbo.StockpileAdjustment UNION ALL
SELECT StockpileAdjustmentId, 'H2O', 7.01 FROM dbo.StockpileAdjustment UNION ALL
SELECT StockpileAdjustmentId, 'H2O-As-Dropped', 6.56 FROM dbo.StockpileAdjustment UNION ALL
SELECT StockpileAdjustmentId, 'H2O-As-Shipped', 6.45 FROM dbo.StockpileAdjustment UNION ALL
SELECT StockpileAdjustmentId, 'GradeToIgnore', 487.245 FROM dbo.StockpileAdjustment
GO