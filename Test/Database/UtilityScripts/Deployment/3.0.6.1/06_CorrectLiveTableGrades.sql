BEGIN TRANSACTION
	INSERT INTO Staging.[TmpLumpFinesBhpbioBlastBlockLumpFinesGradeCorrection]
		(
			[ModelBlockId],
			[SequenceNo],
			[GradeId],
			[LumpValue],
			[FinesValue],
			CorrectedLumpValue,
			CorrectedFinesValue
		)
	SELECT lfg.ModelBlockId, lfg.SequenceNo, lfg.GradeId, lfg.LumpValue, lfg.FinesValue, 0,0
	FROM Staging.TmpStageLumpFinesBlockCorrectionBlocks cb
		INNER JOIN ModelBlock mb ON mb.Code = cb.BlockFullName
		INNER JOIN BlockModel bm ON bm.Block_Model_Id = mb.Block_Model_Id
		INNER JOIN BhpbioBlastBlockLumpFinesGrade lfg ON lfg.ModelBlockId = mb.Model_Block_Id
	WHERE (NOT bm.Name like '%Grade Control%')
		AND ISNULL(lfg.LumpValue,0) <> ISNULL(lfg.FinesValue,0)
		AND EXISTS (SELECT * FROM Staging.TmpStageImportSyncBlockChangesLog cl
					WHERE cl.ModelBlockId = mb.Model_Block_Id AND cl.ProcessedDateTime > cb.MinLastUpdateDateTime)

	-- determine the corrected value
	UPDATE lfgc
		SET lfgc.CorrectedLumpValue=  lfgc.FinesValue, -- switch lump and fines back
			lfgc.CorrectedFinesValue=  lfgc.LumpValue -- switch lump and fines back
	FROM Staging.[TmpLumpFinesBhpbioBlastBlockLumpFinesGradeCorrection] lfgc

	-- Make the correction
	UPDATE lfg
	SET lfg.LumpValue = lfgc.CorrectedLumpValue,
		lfg.FinesValue = lfgc.CorrectedFinesValue
	FROM Staging.[TmpLumpFinesBhpbioBlastBlockLumpFinesGradeCorrection] lfgc
		INNER JOIN BhpbioBlastBlockLumpFinesGrade lfg ON lfg.ModelBlockId = lfgc.ModelBlockId AND lfg.GradeId = lfgc.GradeId AND lfg.SequenceNo = lfgc.SequenceNo

	-- also correct the head grade for H2O related grades (recalc from Lump and Fines as per import)
	UPDATE mbpg
		SET mbpg.Grade_Value = (lfg.LumpValue * (lp.LumpPercent/100.0)) + (lfg.FinesValue * ((100 - lp.LumpPercent)/100.0))
	FROM Staging.TmpStageLumpFinesBlockCorrectionBlocks cb
		INNER JOIN ModelBlock mb ON mb.Code = cb.BlockFullName
		INNER JOIN BlockModel bm ON bm.Block_Model_Id = mb.Block_Model_Id
		INNER JOIN ModelBlockPartial mbp ON mbp.Model_Block_Id = mb.Model_Block_Id
		INNER JOIN ModelBlockPartialGrade mbpg ON mbpg.Model_Block_Id = mbp.Model_Block_Id AND mbpg.Sequence_No = mbp.Sequence_No
		INNER JOIN Grade g ON g.Grade_Id = mbpg.Grade_Id
		INNER JOIN dbo.BhpbioBlastBlockLumpPercent lp ON lp.ModelBlockId = mb.Model_Block_Id
		INNER JOIN dbo.BhpbioBlastBlockLumpFinesGrade lfg ON lfg.ModelBlockId = mb.Model_Block_Id AND lfg.SequenceNo = mbp.Sequence_No AND lfg.GradeId = mbpg.Grade_Id
	WHERE (NOT bm.Name like '%Grade Control%') AND g.Grade_Name like 'H2O-As%'
		AND ISNULL(lfg.LumpValue,0) > 0 AND ISNULL(lfg.FinesValue,0) > 0 AND ISNULL(lfg.LumpValue,0) <> ISNULL(lfg.FinesValue,0)
		AND EXISTS (SELECT * FROM Staging.TmpStageImportSyncBlockChangesLog cl
					WHERE cl.ModelBlockId = mb.Model_Block_Id AND cl.ProcessedDateTime > cb.MinLastUpdateDateTime)
					
--ROLLBACK TRANSACTION -- FOR TESTING
COMMIT TRANSACTION
	
GO