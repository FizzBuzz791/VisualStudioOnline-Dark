IF OBJECT_ID('dbo.GetBhpbioImportExceptionRecords') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioImportExceptionRecords
GO

CREATE PROCEDURE dbo.GetBhpbioImportExceptionRecords
(
	@iUserMessage VARCHAR(MAX),
	@iImportId SMALLINT,
	@iPage INT,
	@iPageSize INT,
	@iValidationFromDate DATETIME = Null
)
WITH ENCRYPTION
AS
BEGIN
	-- note: PageSize can be NULL to allow full exports

	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	
	DECLARE @Result TABLE
	(
		ImportSyncExceptionId BIGINT NOT NULL,
		ImportSyncRowId BIGINT NOT NULL,
		SourceRow XML NOT NULL,
		Page INT NULL,
		PRIMARY KEY CLUSTERED (ImportSyncExceptionId)
	)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetImportExceptionRecords',
		@TransactionCount = @@TranCount 

	-- if there are no transactions available then start a new one
	-- if there is already a transaction then only mark a savepoint
	IF @TransactionCount = 0
	BEGIN
		SET TRANSACTION ISOLATION LEVEL REPEATABLE READ 
		BEGIN TRANSACTION
	END
	ELSE
	BEGIN
		SAVE TRANSACTION @TransactionName
	END
  
	BEGIN TRY
		INSERT INTO @Result
			(ImportSyncExceptionId, ImportSyncRowId, SourceRow, Page)
		SELECT e.ImportSyncExceptionId, r.ImportSyncRowId, r.SourceRow,
			(ROW_NUMBER() OVER (ORDER BY ImportSyncExceptionId ASC) - 1) / @iPageSize AS Page
		FROM dbo.ImportSyncException AS e
			INNER JOIN dbo.ImportSyncQueue AS q
				ON (q.ImportSyncQueueId = e.ImportSyncQueueId)
			INNER JOIN dbo.ImportSyncRow AS r
				ON (r.ImportSyncRowId = q.ImportSyncRowId)
			INNER JOIN dbo.ImportSyncQueue rq
				ON rq.ImportSyncRowId = r.RootImportSyncRowId 
					And rq.SyncAction = 'I'
		WHERE e.UserMessage = @iUserMessage
			AND q.ImportId = @iImportId
			AND q.IsPending = 1
			AND (@iValidationFromDate Is Null Or rq.InitialComparedDateTime > @iValidationFromDate)

		-- return the results for the requested page number
		SELECT ImportSyncExceptionId, ImportSyncRowId, SourceRow, Page
		FROM @Result
		WHERE (@iPageSize IS NULL) OR (Page = @iPage)

		-- return the results for the number of pages that are in the database
		SELECT MAX(Page) AS LastPage
		FROM @Result
		
		-- if we started a new transaction that is still valid then commit the changes
		IF (@TransactionCount = 0) AND (XAct_State() = 1)
		BEGIN
			COMMIT TRANSACTION
		END
	END TRY
	BEGIN CATCH
		-- if we started a transaction then roll it back
		IF (@TransactionCount = 0)
		BEGIN
			ROLLBACK TRANSACTION
		END
		-- if we are part of an existing transaction and 
		ELSE IF (XAct_State() = 1) AND (@TransactionCount > 0)
		BEGIN
			ROLLBACK TRANSACTION @TransactionName
		END

		EXEC dbo.StandardCatchBlock
	END CATCH
END
GO

GRANT EXECUTE ON dbo.GetBhpbioImportExceptionRecords TO CommonImportManager
GO
