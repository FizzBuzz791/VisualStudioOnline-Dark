-- OVERRIDE DEFINITION FOR BHPB IO to avoid clash between outlier detection and bulk approval

/*  --- MUST Deploy any changes as an upgrade script (as schema and other dependencies are defined in the consulting toolkit DataSeries project) ---

IF OBJECT_ID('DataSeries.GetNextPendingQueueEntry') IS NOT NULL
     DROP PROCEDURE DataSeries.GetNextPendingQueueEntry
GO 

CREATE PROCEDURE [DataSeries].[GetNextPendingQueueEntry]
	@iQueueEntryType VARCHAR(50)
WITH ENCRYPTION
AS
BEGIN
	SELECT TOP 1 qe.Id, qe.SeriesPointOrdinal, qt.Code as QueueEntryType, qe.SeriesQueueEntryStatusId, qe.SeriesTypeGroupId, qe.AddedDateTime, qe.ProcessedDateTime, GetDate() as RetrievedDateTime,
				qt.CausesAutomaticPointRemoval
	FROM DataSeries.SeriesQueueEntry qe
		INNER JOIN DataSeries.SeriesQueueEntryStatus ss ON ss.Id = qe.SeriesQueueEntryStatusId
		INNER JOIN DataSeries.SeriesQueueEntryType qt ON qt.Id = qe.SeriesQueueEntryTypeId
	WHERE (@iQueueEntryType IS NULL OR qt.Code = @iQueueEntryType)
		AND ss.IsPending = 1
		AND NOT EXISTS(SELECT * FROM BhpbioBulkApprovalBatch bbab WHERE bbab.Status = 'PENDING') -- avoid clash with running bulk approval
	ORDER BY qe.SeriesPointOrdinal, qt.[Priority], qe.AddedDateTime, qe.Id
END
GO


GRANT EXECUTE ON [DataSeries].[GetNextPendingQueueEntry] TO BhpbioGenericManager
GO

*/