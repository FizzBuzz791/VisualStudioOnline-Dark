IF OBJECT_ID('dbo.AddBhpbioDataRetrievalQueueEntry') IS NOT NULL 
     DROP PROCEDURE dbo.AddBhpbioDataRetrievalQueueEntry 
GO 
  
-- add a queue entry to the Data processing queue for data retrieval for a given month
CREATE PROCEDURE dbo.AddBhpbioDataRetrievalQueueEntry
	@iMonth DATETIME
WITH ENCRYPTION
AS
BEGIN

	-- work out a lookback period for checking existing pending queue entries
	-- this is to avoid adding unneccessary pending entries, although this is not absolutely critical to avoid
	-- a simple lookback is sufficient.. if there is an existing pending entry that was added longer ago, then adding a new duplicate now will not cause harm
	DECLARE @lookBackDate DATETIME
	SET @lookBackDate = DATEADD(month, -1, GetDate())

	DECLARE @ordinalOneMonth DATETIME = '2009-04-01'
	DECLARE @ordinal BIGINT
	
	-- Determine the ordinal
	SELECT @ordinal = 1 + DATEDIFF(month, @ordinalOneMonth, @iMonth)
	
	IF NOT EXISTS(
					SELECT *
					FROM DataSeries.SeriesQueueEntry qe 
						INNER JOIN DataSeries.SeriesQueueEntryStatus stat ON stat.Id = qe.SeriesQueueEntryStatusId
						INNER JOIN DataSeries.SeriesQueueEntryType qtype ON qtype.Id = qe.SeriesQueueEntryTypeId
					WHERE 
						qe.AddedDateTime >= @lookBackDate -- added since the recalc
						AND qtype.Code = 'DataRetrievalRequest' -- for the relevant queue type
						AND qe.SeriesTypeGroupId = 'DataRetrievalGroup' -- and data group
						AND qe.SeriesPointOrdinal = @ordinal -- and same month
						AND stat.IsPending = 1  -- where the queue record is still pending
				)
	BEGIN
		-- Add the queue entry
		INSERT INTO DataSeries.SeriesQueueEntry(AddedDateTime, SeriesPointOrdinal, SeriesQueueEntryStatusId, SeriesQueueEntryTypeId, SeriesTypeGroupId)
		SELECT GetDate(), @ordinal, stat.Id, qtype.Id, 'DataRetrievalGroup'
		FROM DataSeries.SeriesQueueEntryStatus stat,
			 DataSeries.SeriesQueueEntryType qtype
		WHERE stat.IsPending = 1
			AND qtype.Code = 'DataRetrievalRequest'
	END
END
GO

GRANT EXECUTE ON dbo.AddBhpbioDataRetrievalQueueEntry TO BhpbioGenericManager
GO
