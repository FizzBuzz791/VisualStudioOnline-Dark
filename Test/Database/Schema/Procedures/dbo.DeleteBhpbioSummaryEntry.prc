IF OBJECT_ID('dbo.DeleteBhpbioSummaryEntry') IS NOT NULL
     DROP PROCEDURE dbo.DeleteBhpbioSummaryEntry 
GO 
    
CREATE PROCEDURE dbo.DeleteBhpbioSummaryEntry
(
	@iSummaryMonth DATETIME,
	@iSummaryLocationId INTEGER,
	@iSummaryEntryTypeId INTEGER
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'DeleteBhpbioSummaryEntry',
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
		DECLARE @summaryId INT
		DECLARE @startOfMonth DATETIME
		DECLARE @startOfNextMonth DATETIME
		
		-- get the start of month (and start of the next month) based on the provided DateTime
		SELECT @startOfMonth = dbo.GetDateMonth(@iSummaryMonth)

		-- get an existing SummaryId or create a new one
		EXEC dbo.GetBhpbioSummaryIdForMonth @iSummaryMonth = @startOfMonth,
											@oSummaryId = @summaryId OUTPUT

		-- create a table variable to store the set of locations that we are interested in for this summarisation
		DECLARE @Location TABLE
		(
			LocationId INT NOT NULL,
			ParentLocationId INT NULL,
			PRIMARY KEY (LocationId)
		)

		-- populate the location table variable with all locations potentially relevant for this summary
		INSERT INTO @Location(
			LocationId, 
			ParentLocationId)
		SELECT LocationId, ParentLocationId
		FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iSummaryLocationId, 1, NULL, @iSummaryMonth, @iSummaryMonth)
		UNION 
		SELECT l.Location_Id, l.Parent_Location_Id
		FROM Location l
		WHERE l.Location_Id = @iSummaryLocationId
		
		-- delete existing summary entry rows as appropriate based on the provided criteria
		DELETE bse 
		FROM dbo.BhpbioSummaryEntry bse
		WHERE bse.SummaryId = @summaryId
			AND bse.SummaryEntryTypeId = @iSummaryEntryTypeId
			AND EXISTS (
						SELECT * 
						FROM @Location loc 
						WHERE loc.LocationId = bse.LocationId
						)
		
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

GRANT EXECUTE ON dbo.DeleteBhpbioSummaryEntry TO BhpbioGenericManager
GO

/*
exec dbo.DeleteBhpbioSummaryEntry
	@iSummaryMonth = '2009-11-01',
	@iLocationId = 3,
	@iEntryTypeId = 1
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.DeleteBhpbioSummaryEntry">
 <Procedure>
	Deletes a set of summary data based on supplied criteria.
	
	Pass: 
			@iSummaryMonth: the month for which summary data is to be deleted,
			@iSummaryLocationId: the location within which child locations will have data removed
			@iSummaryEntryTypeId: the type of summary data to remove
			
 </Procedure>
</TAG>
*/	