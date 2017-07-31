DECLARE @month DATETIME
DECLARE @endTime DATETIME

DECLARE @summaryShippedToCopy TABLE (
	SummaryEntryId INT
)

SELECT @month = convert(datetime,(SELECT Value FROM Setting WHERE Setting_Id = 'LUMP_FINES_CUTOVER_DATE'))
SET @endTime = GETDATE()

WHILE @month <= @endTime
BEGIN
	PRINT convert(varchar,@month,103)
	
	 
	 BEGIN TRANSACTION
		 
		INSERT INTO BhpbioSummaryEntryGrade(SummaryEntryId,GradeId,GradeValue)
		SELECT sedropped.SummaryEntryId, 6, seg.GradeValue
		FROM BhpbioSummaryEntry seshipped
			INNER JOIN BhpbioSummary s ON s.SummaryId = seshipped.SummaryId
			INNER JOIN BhpbioSummaryEntryType st ON st.SummaryEntryTypeId = seshipped.SummaryEntryTypeId
			INNER JOIN BhpbioSummaryEntry sedropped ON 
				sedropped.SummaryId = seshipped.SummaryId AND
				sedropped.LocationId = seshipped.LocationId AND 
				sedropped.MaterialTypeId = seshipped.MaterialTypeId AND 
				sedropped.ProductSize = seshipped.ProductSize AND
				sedropped.SummaryEntryTypeId = seshipped.SummaryEntryTypeId AND
				sedropped.GeometType = 'As-Dropped'
			INNER JOIN BhpbioSummaryEntryGrade seg ON seg.SummaryEntryId = seshipped.SummaryEntryId AND seg.GradeId = 6
			LEFT JOIN BhpbioSummaryEntryGrade segDropped ON segDropped.SummaryEntryId = sedropped.SummaryEntryId AND segDropped.GradeId = 6
		WHERE seshipped.GeometType = 'As-Shipped'
			AND segDropped.SummaryEntryId IS NULL -- ie. Is Dropped Value is missing
			AND s.SummaryMonth = @month
			AND NOT (st.AssociatedBlockModelId IS NULL)
	COMMIT TRANSACTION
	
	SET @month = DATEADD(month,1,@month)
END
