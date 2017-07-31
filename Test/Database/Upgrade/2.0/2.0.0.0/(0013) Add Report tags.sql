INSERT INTO dbo.BhpbioReportDataTags 
(
	TagId, TagGroupId, TagGroupLocationTypeId, OtherMaterialTypeId
) 
SELECT * FROM (
	SELECT 'F1FactorLump' as TagId, 'F1Factor' as TagGroupId, 4 as TagGroupLocationTypeId, Null as OtherMaterialTypeId UNION ALL
	SELECT 'F1FactorFines', 'F1Factor', 4, Null UNION ALL 
	SELECT 'F2FactorLump', 'F2Factor', 3, Null UNION ALL
	SELECT 'F2FactorFines', 'F2Factor', 3, Null UNION ALL
	SELECT 'F25Factor', 'F25Factor', 2, Null UNION ALL
	SELECT 'F25FactorLump', 'F25Factor', 2, Null UNION ALL
	SELECT 'F25FactorFines', 'F25Factor', 2, Null UNION ALL
	SELECT 'F3FactorLump', 'F3Factor', 2, Null UNION ALL
	SELECT 'F3FactorFines', 'F3Factor', 2, Null UNION ALL
	SELECT 'F25GradeControlModel', 'F25Factor', 2, Null UNION ALL
	SELECT 'F25ExPitToOreStockpile', 'F25Factor', 2, Null UNION ALL
	SELECT 'F25MiningModel', 'F25Factor', 2, Null UNION ALL
	SELECT 'F25MiningModelLump', 'F25Factor', 2, Null UNION ALL
	SELECT 'F25MiningModelFines', 'F25Factor', 2, Null UNION ALL
	SELECT 'F25MiningModelCrusherEquivalent', 'F25Factor', 2, Null UNION ALL
	SELECT 'F25MiningModelOreForRailEquivalent', 'F25Factor', 2, Null UNION ALL
	SELECT 'F25OreForRail', 'F25Factor', 2, Null UNION ALL
	SELECT 'F25StockpileToCrusher', 'F25Factor', 2, Null UNION ALL
	SELECT 'F25PostCrusherStockpileDelta', 'F25Factor', 2, Null UNION ALL
	SELECT 'F1GeologyModelFines', 'F1Factor', 4, Null UNION ALL 
	SELECT 'F1GeologyModelLump', 'F1Factor', 4, Null
) as newTags
WHERE NOT EXISTS (SELECT TOP 1 * FROM BhpbioReportDataTags brd WHERE brd.TagId = newTags.TagId)
GO

INSERT INTO dbo.BhpbioReportThresholdType
(
	ThresholdTypeId, Description
)
Select 'F25Factor','F2.5 Factor'
Go

INSERT INTO BhpbioReportThreshold
(
	LocationId, FieldId, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold
)
Select 1,0,'F25Factor',5,10,0 Union All
Select 1,1,'F25Factor',0.3,0.6,1 Union All
Select 1,2,'F25Factor',5,10,0 Union All
Select 1,3,'F25Factor',5,10,0 Union All
Select 1,4,'F25Factor',5,10,0 Union All
Select 1,5,'F25Factor',5,10,0 Union All
Select 1,6,'F25Factor',5,10,0
GO

INSERT INTO BhpbioReportColor
(
	TagId, Description, IsVisible, Color, LineStyle, MarkerShape
)
Select 'F25Factor','F2.5 Factor',1,'Red','Solid','None'
GO

-- reset approval order of al records temporarily
UPDATE dbo.BhpbioReportDataTags
SET ApprovalOrder =0
GO

-- set main factor values to order 6
UPDATE dbo.BhpbioReportDataTags
SET ApprovalOrder = 6
WHERE TagId = TagGroupId
GO

-- set lump fines geology model to 2
UPDATE dbo.BhpbioReportDataTags
SET ApprovalOrder = 2
WHERE TagId IN (
	'F1GeologyModelFines',
	'F1GeologyModelLump'
	)
GO

-- set geology model to 3
UPDATE dbo.BhpbioReportDataTags
SET ApprovalOrder = 3
WHERE TagId IN (
	'F1GeologyModel'
	)
GO


-- set F2 components
UPDATE dbo.BhpbioReportDataTags
SET ApprovalOrder = 3
WHERE TagId IN (
	'F2MineProductionActuals', 
	'F2StockpileToCrusher',
	'F2ExPitToOreStockpile'
	)
AND TagGroupId = 'F2Factor'
GO

-- set lump fines versions to order 5
UPDATE dbo.BhpbioReportDataTags
SET ApprovalOrder = 5
WHERE TagId IN (
	'F1FactorFines',
	'F1FactorLump',
	'F2FactorFines',
	'F2FactorLump',
	'F25FactorFines',
	'F25FactorLump',
	'F3FactorFines',
	'F3FactorLump'
	)
GO

-- set order number of all other tags to 4
UPDATE dbo.BhpbioReportDataTags
SET ApprovalOrder = 4
WHERE ApprovalOrder = 0
GO