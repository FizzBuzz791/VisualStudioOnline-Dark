DECLARE @startRange INTEGER
DECLARE @endRange INTEGER

SET @startRange = 77
SET @endRange = 80

INSERT INTO DataSeries.SeriesQueueEntry(SeriesQueueEntryTypeId, SeriesTypeGroupId, SeriesPointOrdinal, ProcessedDateTime, AddedDateTime, SeriesQueueEntryStatusId)
SELECT (SELECT Id From DataSeries.SeriesQueueEntryType WHERE code = 'DataRetrievalRequest'), 'DataRetrievalGroup', s.SummaryId, null, GETDATE(), 1 -- pending
FROM BhpbioSummary s 
WHERE s.SummaryId BETWEEN @startRange AND @endRange
	AND NOT EXISTS (SELECT * FROM DataSeries.SeriesQueueEntry q2 WHERE q2.SeriesPointOrdinal = s.SummaryId AND q2.SeriesQueueEntryTypeId = (SELECT Id From DataSeries.SeriesQueueEntryType WHERE code = 'DataRetrievalRequest') AND q2.SeriesQueueEntryStatusId = 1)
	