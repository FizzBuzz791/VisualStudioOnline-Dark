-- 5. Correct Summary data
BEGIN TRANSACTION

	-- locate the data to correct
	INSERT INTO Staging.TmpBhpbioSummaryEntryGradeCorrection(
		TotalSummaryEntryGradeId,
		FinesSummaryEntryGradeId,
		LumpSummaryEntryGradeId,
		TotalSummaryEntryId,
		FinesSummaryEntryId,
		LumpSummaryEntryId,
		GradeId,
		TotalGradeValue,
		FinesGradeValue,
		LumpGradeValue,
		LumpPercent
	)
	SELECT totalseg.SummaryEntryGradeId, fineseg.SummaryEntryGradeId, lumpseg.SummaryEntryGradeId, totalse.SummaryEntryId,
		finese.SummaryEntryId, lumpse.SummaryEntryId,
		 totalseg.GradeId, totalseg.GradeValue, fineseg.GradeValue, lumpseg.GradeValue, 
		CASE WHEN ISNULL(totalse.Tonnes,0)> 0 AND ISNULL(lumpse.Tonnes, 0)> 0 THEN lumpse.Tonnes / totalse.Tonnes
		ELSE NULL
		END
	FROM Staging.TmpStageLumpFinesBlockCorrectionBlocks cb
		INNER JOIN ModelBlock mb ON mb.Code = cb.BlockFullName
		INNER JOIN BlockModel bm ON bm.Block_Model_Id = mb.Block_Model_Id
		INNER JOIN ModelBlockLocation mbl ON mbl.Model_Block_Id = mb.Model_Block_Id
		INNER JOIN Location l ON l.Location_Id = mbl.Location_Id
		INNER JOIN Location blast ON blast.Location_Id = l.Parent_Location_Id
		INNER JOIN Location bench ON bench.Location_Id = blast.Parent_Location_Id
		INNER JOIN Location pit ON pit.Location_Id = bench.Parent_Location_Id
		-- get the total grades
		INNER JOIN BhpbioSummaryEntry totalse ON totalse.LocationId = l.Location_Id
			AND totalse.ProductSize = 'TOTAL'
		INNER JOIN BhpbioSummary s ON s.SummaryId = totalse.SummaryId
		INNER JOIN BhpbioSummaryEntryType st ON st.SummaryEntryTypeId = totalse.SummaryEntryTypeId
			AND st.AssociatedBlockModelId = bm.Block_Model_Id
		INNER JOIN BhpbioSummaryEntryGrade totalseg ON totalseg.SummaryEntryId = totalse.SummaryEntryId
		
		-- get LUMP
		LEFT JOIN BhpbioSummaryEntry lumpse ON lumpse.LocationId = totalse.LocationId
			AND lumpse.MaterialTypeId = totalse.MaterialTypeId
			AND lumpse.SummaryEntryTypeId = totalse.SummaryEntryTypeId
			AND lumpse.SummaryId = totalse.SummaryId
			AND lumpse.ProductSize = 'LUMP'
		LEFT JOIN BhpbioSummaryEntryGrade lumpseg ON lumpseg.SummaryEntryId = lumpse.SummaryEntryId
					AND lumpseg.GradeId = totalseg.GradeId
		-- get FINES	
		LEFT JOIN BhpbioSummaryEntry finese ON finese.LocationId = totalse.LocationId
			AND finese.MaterialTypeId = totalse.MaterialTypeId
			AND finese.SummaryEntryTypeId = totalse.SummaryEntryTypeId
			AND finese.SummaryId = totalse.SummaryId
			AND finese.ProductSize = 'FINES'
		LEFT JOIN BhpbioSummaryEntryGrade fineseg ON fineseg.SummaryEntryId = finese.SummaryEntryId
					AND fineseg.GradeId = totalseg.GradeId
		INNER JOIN Grade g ON g.Grade_Id = totalseg.GradeId
		
		-- get the F1 Factor approval
		INNER JOIN BhpbioApprovalData bad ON bad.LocationId = pit.Location_Id AND bad.ApprovedMonth = s.SummaryMonth AND bad.TagId = 'F1Factor'
		
	WHERE (NOT bm.Name like '%Grade Control%')
	-- where F1 approval occured at a time when data would be effected
	 AND EXISTS (SELECT * FROM Staging.TmpStageImportSyncBlockChangesLog cl
					WHERE cl.ModelBlockId = mb.Model_Block_Id AND cl.ProcessedDateTime > cb.MinLastUpdateDateTime AND cl.ProcessedDateTime < bad.SignoffDate)
	 AND EXISTS (SELECT * FROM BhpbioBlastBlockLumpFinesGrade mblfg WHERE mblfg.ModelBlockId = mb.Model_Block_Id
		AND (mblfg.FinesValue > 0 OR mblfg.LumpValue >0) AND mblfg.LumpValue <> mblfg.FinesValue)
	 AND NOT g.Grade_Name = 'Density'

	UPDATE glf
	SET glf.CorrectedTotalGradeValue = glf.TotalGradeValue,
		glf.CorrectedLumpGradeValue = glf.FinesGradeValue, -- swap lump and fines
		glf.CorrectedFinesGradeValue = glf.LumpGradeValue -- swap lump and fines
	FROM Staging.TmpBhpbioSummaryEntryGradeCorrection glf

	-- for H2O grades, recalculate TOTAL Grade based on lump and fines split
	UPDATE glf
	SET glf.CorrectedTotalGradeValue = (glf.CorrectedLumpGradeValue * glf.LumpPercent) + (glf.CorrectedFinesGradeValue * (1.0-glf.LumpPercent))
	FROM Staging.TmpBhpbioSummaryEntryGradeCorrection glf
	INNER JOIN Grade g ON g.Grade_Id = glf.GradeId
	WHERE (NOT glf.CorrectedLumpGradeValue IS NULL)
	 AND (NOT glf.CorrectedFinesGradeValue IS NULL)
	 AND (NOT glf.LumpPercent IS NULL)
	 AND g.Grade_Name like 'H2O-As%'

	-- do the bulk corrections -- TOTAL
	UPDATE seg
		SET seg.GradeValue = glf.CorrectedTotalGradeValue
	FROM Staging.TmpBhpbioSummaryEntryGradeCorrection glf
	INNER JOIN BhpbioSummaryEntryGrade seg ON Seg.SummaryEntryGradeId = glf.TotalSummaryEntryGradeId
	WHERE glf.CorrectedTotalGradeValue <> glf.TotalGradeValue
	
	-- do the bulk corrections via swap value where possible -- LUMP
	UPDATE seg
		SET seg.GradeValue = glf.CorrectedLumpGradeValue
	FROM Staging.TmpBhpbioSummaryEntryGradeCorrection glf
		INNER JOIN BhpbioSummaryEntryGrade seg ON Seg.SummaryEntryGradeId = glf.LumpSummaryEntryGradeId
	WHERE glf.FinesSummaryEntryGradeId IS NOT NULL
	
	-- do the bulk corrections via swap value where possible -- FINES
	UPDATE seg
		SET seg.GradeValue = glf.CorrectedFinesGradeValue
	FROM Staging.TmpBhpbioSummaryEntryGradeCorrection glf
		INNER JOIN BhpbioSummaryEntryGrade seg ON Seg.SummaryEntryGradeId = glf.FinesSummaryEntryGradeId
	WHERE glf.LumpSummaryEntryGradeId IS NOT NULL
		
	-- do the bulk corrections via swap fk otherwise
	UPDATE seg
		SET seg.SummaryEntryId = glf.FinesSummaryEntryId
	FROM Staging.TmpBhpbioSummaryEntryGradeCorrection glf
		INNER JOIN BhpbioSummaryEntryGrade seg ON Seg.SummaryEntryGradeId = glf.LumpSummaryEntryGradeId
		INNER JOIN BhpbioSummaryEntry fse ON fse.SummaryEntryId = glf.FinesSummaryEntryId
	WHERE glf.FinesSummaryEntryGradeId IS NULL AND fse.Tonnes > 0
		AND ISNULL(seg.GradeValue,0) > 0
	
	UPDATE seg
		SET seg.SummaryEntryId = glf.LumpSummaryEntryId
	FROM Staging.TmpBhpbioSummaryEntryGradeCorrection glf
		INNER JOIN BhpbioSummaryEntryGrade seg ON Seg.SummaryEntryGradeId = glf.FinesSummaryEntryGradeId
		INNER JOIN BhpbioSummaryEntry lse ON lse.SummaryEntryId = glf.LumpSummaryEntryId
	WHERE glf.LumpSummaryEntryGradeId IS NULL
		AND ISNULL(seg.GradeValue,0) > 0 AND lse.Tonnes > 0 -- can't switch to entry unless non-zero tonnes
--ROLLBACK TRANSACTION -- for testing
COMMIT TRANSACTION
GO
---
