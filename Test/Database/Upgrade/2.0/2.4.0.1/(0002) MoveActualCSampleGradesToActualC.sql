-- copy grades over from the old ActualCSampleTonnes summary type to ActualC
INSERT INTO dbo.BhpbioSummaryEntryGrade(SummaryEntryId, GradeId, GradeValue)
SELECT seac.SummaryEntryId, seg.GradeId, seg.GradeValue
	FROM BhpbioSummaryEntry se 
	INNER JOIN BhpbioSummaryEntry seac ON seac.LocationId = se.LocationId AND seac.MaterialTypeId = se.MaterialTypeId AND seac.ProductSize = se.ProductSize AND seac.SummaryId = se.SummaryId
		AND seac.SummaryEntryTypeId = 3 -- 3 = ActualC
	INNER JOIN BhpbioSummaryEntryGrade seg ON seg.SummaryEntryId = se.SummaryEntryId
	WHERE se.SummaryEntryTypeId = 17 -- 17 = ActualCSampleTonnes
		-- and where grades not already copied
	AND NOT EXISTS (SELECT 1 FROM BhpbioSummaryEntryGrade seg2 WHERE seg2.SummaryEntryId = seac.SummaryEntryId)