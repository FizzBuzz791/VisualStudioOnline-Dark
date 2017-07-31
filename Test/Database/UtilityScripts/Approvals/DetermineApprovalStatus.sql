-----------------------------------------------------------------------------------------------------------------
-- PLEASE USE THE ApprovalUtilityScript instead of this script if possible...
--
-- The ApprovalUtilityScript takes temporary location hierarchy positions into account while this script does not
-----------------------------------------------------------------------------------------------------------------

DECLARE @earliestMonth DATETIME
DECLARE @latestMonth DATETIME
DECLARE @outputMissingApprovalsOnly BIT
DECLARE @removeTemporaryTableAfterScriptRun BIT
-------------------------------------------------
-- Script variable initilization
-------------------------------------------------
SET @earliestMonth = '2009-04-01'
SET @latestMonth = '2011-03-01'
SET @outputMissingApprovalsOnly = 1
SET @removeTemporaryTableAfterScriptRun =0
--------------------------------------------------

IF OBJECT_ID('tempdb.dbo.#BhpbioTemporaryApprovalStatus') IS NOT NULL
BEGIN
	DROP TABLE #BhpbioTemporaryApprovalStatus
END

CREATE TABLE #BhpbioTemporaryApprovalStatus
(
	ApprovalMonth DateTime,
	LocationId INT,
	DigblockId VARCHAR(31),
	TagId VARCHAR(124),
	IsApproved BIT,
	ApprovalLevel VARCHAR(31)
)

INSERT INTO #BhpbioTemporaryApprovalStatus
(
	ApprovalMonth,
	LocationId,
	DigblockId,
	TagId,
	IsApproved,
	ApprovalLevel
)
SELECT DISTINCT ActivityMonth, 
		dl.Location_Id,
		d.Digblock_Id,
		'Digblock',
		CASE WHEN bad.DigblockId IS NULL THEN 0 ELSE 1 END As IsApproved,
		'1: Digblock'
FROM 
(
		SELECT DISTINCT d1.Digblock_Id, dbo.GetDateMonth(h1.Haulage_Date) AS ActivityMonth
		FROM dbo.Digblock d1
		INNER JOIN dbo.DigblockLocation dl1 ON dl1.Digblock_Id = d1.Digblock_Id
		INNER JOIN dbo.Haulage h1 ON h1.Source_Digblock_Id = d1.Digblock_Id
	UNION
		SELECT DISTINCT d2.Digblock_Id, dbo.GetDateMonth(RM.DateFrom) AS ActivityMonth
		FROM dbo.Digblock d2
		INNER JOIN dbo.DigblockLocation dl2 ON dl2.Digblock_Id = d2.Digblock_Id
		INNER JOIN dbo.BhpbioImportReconciliationMovement RM ON RM.BlockLocationId = dl2.Location_Id
		WHERE RM.MinedPercentage IS NOT NULL 
		
) d
	INNER JOIN dbo.DigblockLocation dl ON dl.Digblock_Id = d.Digblock_Id
	INNER JOIN dbo.Location block ON block.Location_Id = dl.Location_Id
	INNER JOIN dbo.LocationType lt ON lt.Location_Type_Id = block.Location_Type_Id
	INNER JOIN dbo.Location blast ON blast.Location_Id = block.Parent_Location_Id
	INNER JOIN dbo.Location bench ON bench.Location_Id = blast.Parent_Location_Id
	INNER JOIN dbo.Location pit ON pit.Location_Id = bench.Parent_Location_Id
	INNER JOIN dbo.Location ste ON ste.Location_Id = pit.Parent_Location_Id
	INNER JOIN dbo.Location hub ON hub.Location_Id = ste.Parent_Location_Id
	LEFT JOIN dbo.BhpbioApprovalDigblock bad ON bad.DigblockId = d.Digblock_Id
	AND bad.ApprovedMonth = d.ActivityMonth
WHERE d.ActivityMonth BETWEEN @earliestMonth AND @latestMonth
	AND (@outputMissingApprovalsOnly = 0 OR bad.ApprovedMonth IS NULL)
ORDER BY 1, 2, 3, 4, 5

-- pit approvals
INSERT INTO #BhpbioTemporaryApprovalStatus
(
	ApprovalMonth,
	LocationId,
	DigblockId,
	TagId,
	IsApproved,
	ApprovalLevel
)
SELECT DISTINCT dbo.GetDateMonth(h.Haulage_Date), 
		pit.Location_Id,
		null,
		brdt.TagId, 
		CASE WHEN bad.LocationId IS NULL THEN 0 ELSE 1 END AS IsApproved,
		'2: Pit'
FROM dbo.Haulage h
	INNER JOIN dbo.Digblock d ON d.Digblock_Id = h.Source_Digblock_Id
	INNER JOIN dbo.DigblockLocation dl ON dl.Digblock_Id = d.Digblock_Id
	INNER JOIN dbo.Location block ON block.Location_Id = dl.Location_Id
	INNER JOIN dbo.LocationType lt ON lt.Location_Type_Id = block.Location_Type_Id
	INNER JOIN dbo.Location blast ON blast.Location_Id = block.Parent_Location_Id
	INNER JOIN dbo.Location bench ON bench.Location_Id = blast.Parent_Location_Id
	INNER JOIN dbo.Location pit ON pit.Location_Id = bench.Parent_Location_Id
	CROSS JOIN dbo.BhpbioReportDataTags brdt
	LEFT JOIN dbo.BhpbioApprovalData bad ON bad.LocationId = pit.Location_Id
		AND bad.ApprovedMonth = dbo.GetDateMonth(h.Haulage_Date)
		AND bad.TagId = brdt.TagId
WHERE brdt.TagId IN ('F1Factor','F1GeologyModel','F1GradeControlModel','F1MiningModel','OtherMaterial_Low_Grade',
					'OtherMaterial_Pyritic_Waste','OtherMaterial_Waste','OtherMaterial_Blend_Grade')
	AND dbo.GetDateMonth(h.Haulage_Date) BETWEEN @earliestMonth AND @latestMonth
	AND (@outputMissingApprovalsOnly = 0 OR bad.ApprovedMonth IS NULL)				
ORDER BY 1, 2, 3, 4

-- site approvals
INSERT INTO #BhpbioTemporaryApprovalStatus
(
	ApprovalMonth,
	LocationId,
	DigblockId,
	TagId,
	IsApproved,
	ApprovalLevel
)

SELECT months.Start_Date as [Month], ste.Location_Id, null, brdt.TagId,
	CASE WHEN bad.LocationId IS NULL THEN 0 ELSE 1 END AS IsApproved,
	'3: Site'
FROM dbo.Location ste
	INNER JOIN dbo.LocationType lt ON lt.Location_Type_Id = ste.Location_Type_Id
	CROSS JOIN (SELECT Start_Date FROM dbo.GetDateRangeList(@earliestMonth,@latestMonth,'MONTH',1)) months
	CROSS JOIN dbo.BhpbioReportDataTags brdt
	LEFT JOIN dbo.BhpbioApprovalData bad ON bad.LocationId = ste.Location_Id
		AND bad.ApprovedMonth = months.Start_Date
		AND bad.TagId = brdt.TagId
WHERE lt.Description = 'Site'
	AND brdt.TagId IN ('F2ExPitToOreStockpile','F2Factor','F2GradeControlModel','F2MineProductionActuals','F2MineProductionExpitEqulivent','F2StockpileToCrusher')
	AND (@outputMissingApprovalsOnly = 0 OR bad.ApprovedMonth IS NULL)			
ORDER BY 1, 2, 3, 4

-- hub approvals
INSERT INTO #BhpbioTemporaryApprovalStatus
(
	ApprovalMonth,
	LocationId,
	DigblockId,
	TagId,
	IsApproved,
	ApprovalLevel
)
SELECT  months.Start_Date as [Month], hub.Location_Id as HubId, null,
	brdt.TagId, CASE WHEN bad.LocationId IS NULL THEN 0 ELSE 1 END AS IsApproved,
	'4: Hub'
FROM dbo.Location hub
	INNER JOIN dbo.LocationType lt ON lt.Location_Type_Id = hub.Location_Type_Id
	CROSS JOIN (SELECT Start_Date FROM dbo.GetDateRangeList(@earliestMonth,@latestMonth,'MONTH',1)) months
	CROSS JOIN dbo.BhpbioReportDataTags brdt
	LEFT JOIN dbo.BhpbioApprovalData bad ON bad.LocationId = hub.Location_Id
		AND bad.ApprovedMonth = months.Start_Date
		AND bad.TagId = brdt.TagId
WHERE lt.Description = 'Hub'
	AND brdt.TagId IN ('F3Factor',
		'F3MiningModel',
		'F3MiningModelCrusherEquivalent',
		'F3MiningModelShippingEquivalent',
		'F3OreShipped',
		'F3ExPitToOreStockpile',
		'F3PortBlendedAdjustment',
		'F3PortStockpileDelta',
		'F3PostCrusherStockpileDelta',
		'F3StockpileToCrusher'
	)
	AND (@outputMissingApprovalsOnly = 0 OR bad.ApprovedMonth IS NULL)		
ORDER BY 1, 2, 3, 4

SELECT	ApprovalMonth,
		LocationId,
		DigblockId,
		TagId,
		IsApproved,
		ApprovalLevel,
		CASE WHEN ggggGrandParentLoc.Name IS NULL THEN '' ELSE ggggGrandParentLoc.Name + '-> ' END
	+	CASE WHEN gggGrandParentLoc.Name IS NULL THEN '' ELSE gggGrandParentLoc.Name + '-> ' END
	+	CASE WHEN ggGrandParentLoc.Name IS NULL THEN '' ELSE ggGrandParentLoc.Name + '-> ' END
	+	CASE WHEN greatGrandParentLoc.Name IS NULL THEN '' ELSE greatGrandParentLoc.Name + '-> ' END
	+	CASE WHEN grandParentLoc.Name IS NULL THEN '' ELSE grandParentLoc.Name + '-> ' END
	+	CASE WHEN parentLoc.Name IS NULL THEN '' ELSE parentLoc.Name + '-> ' END
	+	CASE WHEN loc.Name IS NULL THEN '' ELSE loc.Name END
	As LocationString
FROM #BhpbioTemporaryApprovalStatus btas
	LEFT JOIN dbo.Location loc ON loc.Location_Id = btas.LocationId
	LEFT JOIN dbo.Location parentLoc ON parentLoc.Location_Id = loc.Parent_Location_Id
	LEFT JOIN dbo.Location grandParentLoc ON grandParentLoc.Location_Id = parentLoc.Parent_Location_Id
	LEFT JOIN dbo.Location greatGrandParentLoc ON greatGrandParentLoc.Location_Id = grandParentLoc.Parent_Location_Id
	LEFT JOIN dbo.Location ggGrandParentLoc ON ggGrandParentLoc.Location_Id = greatGrandParentLoc.Parent_Location_Id
	LEFT JOIN dbo.Location gggGrandParentLoc ON gggGrandParentLoc.Location_Id = ggGrandParentLoc.Parent_Location_Id
	LEFT JOIN dbo.Location ggggGrandParentLoc ON ggggGrandParentLoc.Location_Id = gggGrandParentLoc.Parent_Location_Id
ORDER BY btas.ApprovalMonth, btas.ApprovalLevel, btas.TagId, 7 

IF @removeTemporaryTableAfterScriptRun = 1 AND OBJECT_ID('tempdb.dbo.#BhpbioTemporaryApprovalStatus') IS NOT NULL
BEGIN
	DROP TABLE #BhpbioTemporaryApprovalStatus
END