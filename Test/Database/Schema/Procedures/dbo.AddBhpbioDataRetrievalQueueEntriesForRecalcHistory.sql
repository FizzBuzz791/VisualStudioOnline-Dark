IF OBJECT_ID('dbo.AddBhpbioDataRetrievalQueueEntriesForRecalcHistory') IS NOT NULL 
     DROP PROCEDURE dbo.AddBhpbioDataRetrievalQueueEntriesForRecalcHistory 
GO 

-- add queue entries to the Data processing queue for data retrieval for months required based on recalc history
CREATE PROCEDURE dbo.AddBhpbioDataRetrievalQueueEntriesForRecalcHistory
	@iHistoryLookbackMinutes INT
WITH ENCRYPTION
AS
BEGIN
	DECLARE @ordinalOneMonth DATETIME = '2009-04-01'
	DECLARE @currentMonth DATETIME
	DECLARE @priorMonth DATETIME
	DECLARE @currentDate DATETIME
	SET @currentDate = GetDate()
	SET @currentMonth = CONVERT(datetime, convert(varchar,DATEPART(year, @currentDate)) + '-' + RIGHT('0' +convert(varchar,DATEPART(month, @currentDate)),2) + '-01')
	SET @priorMonth = DATEADD(month,-1,@currentMonth)

	-- calculate a lookback time
	DECLARE @lookbackDateTime DATETIME
	SET @lookbackDateTime = DATEADD(minute, -1 * @iHistoryLookbackMinutes, GETDATE())
	
	-- add queue entries
	INSERT INTO DataSeries.SeriesQueueEntry(AddedDateTime, SeriesPointOrdinal, SeriesQueueEntryStatusId, SeriesQueueEntryTypeId, SeriesTypeGroupId)
	SELECT GetDate(), recalculatedMonth.OrdinalRequiringProcessing, stat.Id, qtype.Id, 'DataRetrievalGroup'
	FROM	(SELECT Id FROM DataSeries.SeriesQueueEntryStatus WHERE IsPending = 1) stat,
			(SELECT Id FROM DataSeries.SeriesQueueEntryType WHERE Code = 'DataRetrievalRequest') qtype,
			(
				SELECT 1 + DATEDIFF(month, @ordinalOneMonth,months.SummaryMonth) as OrdinalRequiringProcessing, MAX(h.End_Datetime) as MaxProcessedDate
				FROM RecalcHistory h
					INNER JOIN 
					(
						SELECT s.SummaryMonth
						FROM BhpbioSummary s
						WHERE s.SummaryMonth < @priorMonth
						UNION
						SELECT @priorMonth
						UNION
						SELECT @currentMonth
					) months ON DATEADD(day, -1, DATEADD(month, 1, months.SummaryMonth)) BETWEEN h.Start_Date AND h.Current_Processing_Date -- last day of month within processing window
				-- where L2 recalculation ended within the lookback
				WHERE h.Recalc_Type_Id = 'Level 2' AND 
					(
						 h.End_Datetime >= @lookbackDateTime -- recalculated in the lookback window
						 OR (h.End_Datetime IS NULL AND h.Current_Processing_Date >= DATEADD(month, 1, months.SummaryMonth)) -- or still processing but has moved beyond the month
					)

				GROUP BY months.SummaryMonth
			) recalculatedMonth
	WHERE NOT EXISTS  -- where a queue entry was not already added for this month
			(
				SELECT *
				FROM DataSeries.SeriesQueueEntry qe 
					INNER JOIN DataSeries.SeriesQueueEntryStatus stat ON stat.Id = qe.SeriesQueueEntryStatusId
					INNER JOIN DataSeries.SeriesQueueEntryType qtype ON qtype.Id = qe.SeriesQueueEntryTypeId
				WHERE 
					qe.AddedDateTime >= recalculatedMonth.MaxProcessedDate -- added since the recalc
					AND qtype.Code = 'DataRetrievalRequest' -- for the relevant queue type
					AND qe.SeriesTypeGroupId = 'DataRetrievalGroup' -- and data group
					AND qe.SeriesPointOrdinal = recalculatedMonth.OrdinalRequiringProcessing -- and same month
					AND (stat.IsPending = 1 OR stat.IsProcessed = 1) -- where the queue record was processed or is still pending
			)
END
GO

GRANT EXECUTE ON dbo.AddBhpbioDataRetrievalQueueEntriesForRecalcHistory TO BhpbioGenericManager
GO
