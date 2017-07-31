-- THIS SCRIPT WILL INVERT DENSITY VALUES
-- NOTE: This should only be run on Density values that have been stored in inverse (once only script)..

-- Even if the Density vales are uninverted, outlier processing must be run to ensure standard deviation and other results are calculated correctly

-- ONLY RUN THIS IF EXPLICITLY REQUIRED


-- DO NOT RUN THIS TWICE!
BEGIN TRANSACTION
	UPDATE sp
		SET sp.Value = 1/sp.Value
	FROM DataSeries.SeriesPoint sp
		INNER JOIN DataSeries.Series s ON s.Id = sp.SeriesId
		INNER JOIN DataSeries.SeriesType st ON st.Id = s.SeriesTypeId
		INNER JOIN DataSeries.SeriesAttribute satt ON satt.SeriesId = s.Id AND satt.Name = 'Grade'
	WHERE st.Id like '%Grade%'
		AND satt.StringValue = 'Density'
		AND ISNULL(sp.Value,0) <> 0	
COMMIT TRANSACTION


-- NOW QUEUE OUTLIER PROCESSING (WITHOUT DATA RETRIEVAL)
BEGIN TRANSACTION
	DECLARE @currentDate DATETIME
	DECLARE @monthStart DATETIME
	DECLARE @startRange INTEGER
	DECLARE @endRange INTEGER

	SET @currentDate = GetDate()
	SET @monthStart = DATEADD(day, DATEPART(day,@currentDate) * -1, @currentDate)

	SET @startRange = 1
	SELECT @endRange = DATEDIFF(MONTH, CONVERT(datetime,'2009-03-01'), @monthStart)

	INSERT INTO DataSeries.SeriesQueueEntry(SeriesQueueEntryTypeId, SeriesTypeGroupId, SeriesPointOrdinal, ProcessedDateTime, AddedDateTime, SeriesQueueEntryStatusId)
	SELECT (SELECT Id From DataSeries.SeriesQueueEntryType WHERE code = 'OutlierProcessRequest'), 'DataRetrievalGroup', s.SummaryId, null, GETDATE(), 1 -- pending
	FROM BhpbioSummary s 
	WHERE s.SummaryId BETWEEN @startRange AND @endRange
		AND NOT EXISTS (SELECT * FROM DataSeries.SeriesQueueEntry q2 WHERE q2.SeriesPointOrdinal = s.SummaryId AND q2.SeriesQueueEntryTypeId = (SELECT Id From DataSeries.SeriesQueueEntryType WHERE code = 'DataRetrievalRequest') AND q2.SeriesQueueEntryStatusId = 1)
COMMIT TRANSACTION