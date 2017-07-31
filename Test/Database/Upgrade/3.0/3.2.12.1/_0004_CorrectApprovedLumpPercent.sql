PRINT 'Correcting Approved Lump % data'

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TmpBhpbioSummaryEntrySplitCorrection]') AND type in (N'U'))
BEGIN
	DROP TABLE [dbo].[TmpBhpbioSummaryEntrySplitCorrection]
END
GO

BEGIN TRANSACTION

	-- correct summary data
	SELECT mb.Code, se.SummaryEntryId, sel.SummaryEntryId as LumpSummaryEntryId, sef.SummaryEntryId as FinesSummaryEntryId, se.Tonnes, sel.Tonnes as LumpTonnes, sef.Tonnes As FinesTonnes, se.Volume, sel.Volume as LumpVolume, sef.Volume as FinesVolume, lp.LumpPercent, 1.0-lp.LumpPercent as FinesPercent
	INTO dbo.[TmpBhpbioSummaryEntrySplitCorrection]
	FROM BhpbioSummaryEntryType st
		INNER JOIN BhpbioSummaryEntry se ON se.SummaryEntryTypeId = st.SummaryEntryTypeId AND se.ProductSize = 'TOTAL'
		LEFT JOIN BhpbioSummaryEntry sel ON sel.SummaryEntryTypeId = se.SummaryEntryTypeId AND sel.ProductSize = 'LUMP' AND sel.SummaryId = se.SummaryId AND sel.LocationId = se.LocationId AND sel.MaterialTypeId = se.MaterialTypeId
		LEFT JOIN BhpbioSummaryEntry sef ON sef.SummaryEntryTypeId = se.SummaryEntryTypeId AND sef.ProductSize = 'FINES' AND sef.SummaryId = se.SummaryId AND sef.LocationId = se.LocationId AND sef.MaterialTypeId = se.MaterialTypeId
		INNER JOIN ModelBlockLocation mbl ON mbl.Location_Id = se.LocationId
		INNER JOIN ModelBlock mb ON mb.Model_Block_Id = mbl.Model_Block_Id AND mb.Block_Model_Id = CASE WHEN st.AssociatedBlockModelId = 5 THEN 1 ELSE st.AssociatedBlockModelId END
		INNER JOIN ModelBlockPartial mbp ON mbp.Model_Block_Id = mb.Model_Block_Id AND mbp.Material_Type_Id = se.MaterialTypeId
		INNER JOIN [BhpbioBlastBlockLumpPercent] lp ON lp.ModelBlockId = mbp.Model_Block_Id AND lp.SequenceNo = mbp.Sequence_No
	WHERE (NOT sel.LocationId IS NULL Or NOT sef.LocationId IS NULL)

	-- Update lump records
	UPDATE se
		SET se.Tonnes = CASE WHEN se.Tonnes IS NULL THEN NULL ELSE sc.Tonnes * sc.LumpPercent END,
			se.Volume = CASE WHEN se.Volume IS NULL THEN NULL ELSE sc.Volume * sc.LumpPercent END
	FROM BhpbioSummaryEntry se
	INNER JOIN [TmpBhpbioSummaryEntrySplitCorrection] sc ON sc.LumpSummaryEntryId = se.SummaryEntryId


	-- Update Fines records
	UPDATE se
		SET se.Tonnes = CASE WHEN se.Tonnes IS NULL THEN NULL ELSE sc.Tonnes * sc.FinesPercent END,
			se.Volume = CASE WHEN se.Volume IS NULL THEN NULL ELSE sc.Volume * sc.FinesPercent END
	FROM BhpbioSummaryEntry se
	INNER JOIN [TmpBhpbioSummaryEntrySplitCorrection] sc ON sc.FinesSummaryEntryId = se.SummaryEntryId

COMMIT TRANSACTION

PRINT 'Finished Correcting Approved Lump % data'
GO