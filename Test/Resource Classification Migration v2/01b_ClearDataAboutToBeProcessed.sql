-- ONLY RUN THIS SCRIPT IF REQUIRED
--
-- this will delete any already existing data for data about to be imported
--

-- delete resource classification data for blocks just imported to temporary area
-- mbpv = ModelBlockPartialValue
DELETE mbpv
FROM Staging.ResourceClassificationTempWithMaterialType t
	INNER JOIN Staging.StageBlock sb ON sb.BlockId = t.StageBlock_BlockId
	INNER JOIN ModelBlock mb ON mb.Code = sb.BlockFullName
	INNER JOIN ModelBlockPartial mbp ON mbp.Model_Block_Id = mb.Model_Block_Id
	INNER JOIN [dbo].[ModelBlockPartialValue] mbpv ON mbpv.Model_Block_Id = mbp.Model_Block_Id AND mbpv.Sequence_No = mbp.Sequence_No
WHERE mbpv.Model_Block_Partial_Field_Id LIKE 'Res%' AND t.Processed = 0
GO

-- delete summary data for blocks just imported to temporary area
-- fv = BhpbioSummaryEntryFieldValue
DELETE fv
FROM BhpbioSummaryEntry se
INNER JOIN Location l ON l.Location_Id = se.LocationId AND l.Location_Type_Id = 7
INNER JOIN ModelBlockLocation mbl ON mbl.Location_Id = l.Location_Id
INNER JOIN ModelBlock mb ON mb.Model_Block_Id = mbl.Model_Block_Id AND mb.Block_Model_Id = 1
INNER JOIN BhpbioSummaryEntryFieldValue fv ON fv.SummaryEntryId = se.SummaryEntryId
INNER JOIN BhpbioSummaryEntryField f ON f.SummaryEntryFieldId = fv.SummaryEntryFieldId
INNER JOIN Staging.StageBlock sb ON sb.BlockFullName = mb.Code
INNER JOIN Staging.ResourceClassificationTempWithMaterialType t ON t.StageBlock_BlockId = sb.BlockId
WHERE t.Processed = 0
GO
