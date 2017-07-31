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
	SELECT (SELECT Id From DataSeries.SeriesQueueEntryType WHERE code = 'DataRetrievalRequest'), 'DataRetrievalGroup', s.SummaryId, null, GETDATE(), 1 -- pending
	FROM BhpbioSummary s 
	WHERE s.SummaryId BETWEEN @startRange AND @endRange
		AND NOT EXISTS (SELECT * FROM DataSeries.SeriesQueueEntry q2 WHERE q2.SeriesPointOrdinal = s.SummaryId AND q2.SeriesQueueEntryTypeId = (SELECT Id From DataSeries.SeriesQueueEntryType WHERE code = 'DataRetrievalRequest') AND q2.SeriesQueueEntryStatusId = 1)
COMMIT TRANSACTION