IF Object_Id('dbo.GetBhpbioImportExceptionGrouping') Is Not Null 
     DROP PROCEDURE dbo.GetBhpbioImportExceptionGrouping
GO
  
CREATE PROCEDURE dbo.GetBhpbioImportExceptionGrouping
(
	@iImportId SMALLINT,
	@iValidationFromDate DATETIME = Null
)
WITH ENCRYPTION
AS
BEGIN 
	Select e.UserMessage, Count(1) AS Occurrence 
	From dbo.ImportSyncException e
		Inner Join dbo.ImportSyncQueue AS q
			ON (q.ImportSyncQueueId = e.ImportSyncQueueId
				AND q.ImportId = @iImportId)
		INNER JOIN dbo.ImportSyncRow As r
			ON r.ImportSyncRowId = q.ImportSyncRowId
		INNER JOIN dbo.ImportSyncQueue rq
			ON rq.ImportSyncRowId = r.RootImportSyncRowId 
				And rq.SyncAction = 'I'
	WHERE q.IsPending = 1
		And (@iValidationFromDate Is Null Or rq.InitialComparedDateTime > @iValidationFromDate)
	GROUP BY e.UserMessage

END
GO	

GRANT EXECUTE ON dbo.GetBhpbioImportExceptionGrouping TO CommonImportManager
GO

