IF OBJECT_ID('dbo.GetBhpbioReconciliationMovements') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReconciliationMovements
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReconciliationMovements
(
	@iLocationId AS INT = NULL
)
AS
BEGIN

	DECLARE @LocationTypeId TINYINT
	
	SELECT @LocationTypeId = Location_Type_Id
	FROM LocationType
	WHERE Description = 'Block'

	SELECT DL.Digblock_Id,
		BIRM.MinedPercentage * Sum(CASE WHEN BM.Name = 'Grade Control' THEN MBP.Tonnes ELSE NULL END) AS Depleted_Blast_Block,
		BIRM.MinedPercentage * Sum(CASE WHEN BM.Name = 'Geology' THEN MBP.Tonnes ELSE NULL END) AS Depleted_Resource,
		BIRM.MinedPercentage * Sum(CASE WHEN BM.Name = 'Mining' THEN MBP.Tonnes ELSE NULL END) AS Depleted_Reserve
	FROM dbo.BhpbioImportReconciliationMovement AS BIRM
		INNER JOIN dbo.GetLocationSubtreeByLocationType(@iLocationId, @LocationTypeId, @LocationTypeId) GLS
			ON GLS.LocationId = BIRM.BlockLocationId
		INNER JOIN dbo.DigblockLocation AS DL
			ON BIRM.BlockLocationId = DL.Location_Id
		INNER JOIN dbo.DigblockModelBlock AS DMB
			ON DMB.Digblock_Id = DL.Digblock_Id
		INNER JOIN dbo.ModelBlock AS MB
			ON DMB.Model_Block_Id = MB.Model_Block_Id
		INNER JOIN dbo.ModelBlockPartial AS MBP
			ON MBP.Model_Block_Id = MB.Model_Block_Id
		INNER JOIN dbo.BlockModel AS BM
			ON MB.Block_Model_Id = BM.Block_Model_Id
	GROUP BY DL.Digblock_Id, BIRM.MinedPercentage
			
END

GO 

GRANT EXECUTE ON dbo.GetBhpbioReconciliationMovements TO CoreDigblockManager