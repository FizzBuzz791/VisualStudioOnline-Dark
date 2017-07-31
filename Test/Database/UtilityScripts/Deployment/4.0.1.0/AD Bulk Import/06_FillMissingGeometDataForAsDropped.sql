
-- This script fills in gaps in the As-Dropped data based on As-Shipped for data for which no geomet as-dropped information was available
-- This is a post migration step
DECLARE @month DATETIME
DECLARE @endTime DATETIME

DECLARE @summaryShippedToCopy TABLE (
	SummaryEntryId INT
)

SELECT @month = convert(datetime,(SELECT Value FROM Setting WHERE Setting_Id = 'LUMP_FINES_CUTOVER_DATE'))
--SET @endTime = DATEADD(month,1,@month)
SET @endTime = GETDATE()

WHILE @month <= @endTime
BEGIN
	PRINT convert(varchar,@month,103)
	DELETE FROM @summaryShippedToCopy
	
	-- work out which elements to copy
	INSERT INTO @summaryShippedToCopy
	SELECT seshipped.SummaryEntryId
	FROM BhpbioSummaryEntry seshipped
		INNER JOIN BhpbioSummary s ON s.SummaryId = seshipped.SummaryId
		INNER JOIN BhpbioSummaryEntryType st ON st.SummaryEntryTypeId = seshipped.SummaryEntryTypeId
		LEFT JOIN BhpbioSummaryEntry sedropped ON 
			sedropped.SummaryId = seshipped.SummaryId AND
			sedropped.LocationId = seshipped.LocationId AND 
			sedropped.MaterialTypeId = seshipped.MaterialTypeId AND 
			sedropped.ProductSize = seshipped.ProductSize AND
			sedropped.SummaryEntryTypeId = seshipped.SummaryEntryTypeId AND
			sedropped.GeometType = 'As-Dropped'
	WHERE seshipped.GeometType = 'As-Shipped'
	 AND sedropped.SummaryEntryId IS NULL
	 AND s.SummaryMonth = @month
	 AND NOT (st.AssociatedBlockModelId IS NULL)
	 
	 BEGIN TRANSACTION
		 -- copy the summary records
		 INSERT INTO dbo.BhpbioSummaryEntry(SummaryId, SummaryEntryTypeId, LocationId, MaterialTypeId, Tonnes, ProductSize, ModelFilename, Volume, GeometType)
		 SELECT seshipped.SummaryId,seshipped.SummaryEntryTypeId,seshipped.LocationId,seshipped.MaterialTypeId,seshipped.Tonnes,seshipped.ProductSize,seshipped.ModelFilename,seshipped.Volume,'As-Dropped'
		 FROM BhpbioSummaryEntry seshipped
			INNER JOIN @summaryShippedToCopy stc ON stc.SummaryEntryId = seshipped.SummaryEntryId
			
		-- Copy the shipped grade records to the As-Dropped grade records... as there is no As-Dropped Lump%, the As-Shipped and As-Dropped tonnes will be the same in this case
		INSERT INTO BhpbioSummaryEntryGrade(SummaryEntryId, GradeId, GradeValue)
		SELECT sedropped.SummaryEntryId,seshippedgrade.GradeId,seshippedgrade.GradeValue
		FROM BhpbioSummaryEntry seshipped
			INNER JOIN @summaryShippedToCopy stc ON stc.SummaryEntryId = seshipped.SummaryEntryId
			INNER JOIN BhpbioSummaryEntryGrade seshippedgrade ON seshippedgrade.SummaryEntryId = seshipped.SummaryEntryId
			INNER JOIN BhpbioSummaryEntry sedropped ON 
				sedropped.SummaryId = seshipped.SummaryId AND
				sedropped.LocationId = seshipped.LocationId AND 
				sedropped.MaterialTypeId = seshipped.MaterialTypeId AND 
				sedropped.ProductSize = seshipped.ProductSize AND
				sedropped.SummaryEntryTypeId = seshipped.SummaryEntryTypeId AND
				sedropped.GeometType = 'As-Dropped'
				
	COMMIT TRANSACTION
	
	SET @month = DATEADD(month,1,@month)
END
