
PRINT 'Correcting Live Lump % data'

UPDATE lp
SET lp.LumpPercent = sbm.LumpPercent / 100.0
FROM ModelBlock mb
INNER JOIN BlockModel bm ON bm.Block_Model_Id = mb.Block_Model_Id
LEFT JOIN Staging.StageBlock sb ON sb.BlockFullName = mb.Code
INNER JOIN ModelBlockPartial mbp ON mbp.Model_Block_Id= mb.Model_Block_Id
INNER JOIN MaterialType mt ON mt.Material_Type_Id = mbp.Material_Type_Id
LEFT JOIN Staging.StageBlockModel sbm ON sbm.BlockId = sb.BlockId AND sbm.BlockModelName like bm.Name AND sbm.MaterialTypeName = mt.Abbreviation
INNER JOIN [BhpbioBlastBlockLumpPercent] lp ON lp.ModelBlockId = mb.Model_Block_Id AND lp.SequenceNo=mbp.Sequence_No
WHERE NOT sbm.LumpPercent IS NULL
GO

PRINT 'Live Correction complete'
GO
