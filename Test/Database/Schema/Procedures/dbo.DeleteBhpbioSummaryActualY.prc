IF OBJECT_ID('dbo.DeleteBhpbioSummaryActualY') IS NOT NULL
     DROP PROCEDURE dbo.DeleteBhpbioSummaryActualY 
GO 
    
CREATE PROCEDURE dbo.DeleteBhpbioSummaryActualY
(
	@iSummaryMonth DATETIME,
	@iSummaryLocationId INTEGER
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'DeleteBhpbioSummaryActualY',
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
		DECLARE @summaryEntryTypeId INTEGER
		
		-- obtain the Entry Type Id for ActualY storage
		-- this is required because the summary data for ActualY is placed in a general summary storage table
		SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
		FROM BhpbioSummaryEntryType bset
		WHERE bset.Name = 'ActualY'

		-- get the start of month (and start of the next month) based on the provided DateTime
		SELECT @startOfMonth = dbo.GetDateMonth(@iSummaryMonth)
		SELECT @startOfNextMonth = DATEADD(month,1,@iSummaryMonth)

		-- get an existing SummaryId or create a new one
		EXEC dbo.GetBhpbioSummaryIdForMonth @iSummaryMonth = @startOfMonth,
											@oSummaryId = @summaryId OUTPUT

		-- create a table variable to store the set of locations that we are interested in for this summarisation
		DECLARE @Location TABLE
		(
			LocationId INT NOT NULL,
			PRIMARY KEY (LocationId)
		)

		-- populate the location table variable with all locations potentially relevant for this summary
		INSERT INTO @Location(
			LocationId
		)
		SELECT LocationId
		FROM dbo.GetBhpbioReportLocationBreakdown(@iSummaryLocationId, 0, NULL)

		-- delete existing summary actual rows as appropriate based on the provided criteria
		-- this is any data that would be regenerated if the same criterial were sent to the equivalent Summarise procedure
		DELETE bse 
		FROM dbo.BhpbioSummaryEntry bse
			INNER JOIN dbo.GetBhpbioFilteredMaterialTypes(1,null) mt
				ON mt.MaterialTypeId = bse.MaterialTypeId
		WHERE bse.SummaryId = @summaryId
			AND bse.SummaryEntryTypeId = @summaryEntryTypeId
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

GRANT EXECUTE ON dbo.DeleteBhpbioSummaryActualY TO BhpbioGenericManager
GO

/*
-- A call like this is used for F1 related summarisation of ActualY
exec dbo.DeleteBhpbioSummaryActualY
	@iSummaryMonth = '2009-11-01',
	@iLocationId = 3,
	
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.DeleteBhpbioSummaryActualY">
 <Procedure>
	Deletes a set of summary ActualY data based on supplied criteria.
	The criteria is the same as which could be sent to the corresponding SummariseBhpbioActualY procedure
	
	Pass: 
			@iSummaryMonth: the month for which summary data is to be deleted,
			@iSummaryLocationId: the location (typically a Pit) within which child locations will have data removed,
 </Procedure>
</TAG>
*/	