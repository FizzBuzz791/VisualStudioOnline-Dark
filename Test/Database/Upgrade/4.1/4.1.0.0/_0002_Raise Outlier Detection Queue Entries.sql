BEGIN TRANSACTION
	DECLARE @startMonth DATETIME --= '2016-01-01'
	DECLARE @endMonth DATETIME --= '2017-01-01'
	DECLARE @startRange INTEGER
	DECLARE @endRange INTEGER

	IF (@startMonth is null)
		select	@startRange = min(SummaryId)
		FROM	BhpbioSummary
	else
		SELECT	@startRange = min(SummaryId)
		FROM	BhpbioSummary
		WHERE	SummaryMonth = @startMonth
	
	IF (@endMonth is null)
		SELECT	@endRange = max(SummaryId)
		FROM	BhpbioSummary
	ELSE
		SELECT	@endRange = SummaryId
		FROM	BhpbioSummary
		WHERE	SummaryMonth = @endMonth

	INSERT INTO DataSeries.SeriesQueueEntry(SeriesQueueEntryTypeId, SeriesTypeGroupId, SeriesPointOrdinal, ProcessedDateTime, AddedDateTime, SeriesQueueEntryStatusId)
	SELECT (SELECT Id From DataSeries.SeriesQueueEntryType WHERE code = 'DataRetrievalRequest'), 
			'DataRetrievalRequest', 
			s.SummaryId, 
			null, 
			GETDATE(), 
			1 -- pending
	FROM	BhpbioSummary s 
	WHERE	s.SummaryId BETWEEN @startRange AND @endRange
	AND NOT EXISTS (SELECT	* 
					FROM	DataSeries.SeriesQueueEntry q2 
					WHERE	q2.SeriesPointOrdinal = s.SummaryId 
					AND		q2.SeriesQueueEntryTypeId = (	SELECT Id 
															From DataSeries.SeriesQueueEntryType 
															WHERE code = 'DataRetrievalRequest') 
					AND q2.SeriesQueueEntryStatusId = 1)
COMMIT TRANSACTION