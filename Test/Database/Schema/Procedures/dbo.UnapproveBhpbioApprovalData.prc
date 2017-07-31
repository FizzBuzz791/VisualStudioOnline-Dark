IF OBJECT_ID('dbo.UnapproveBhpbioApprovalData') IS NOT NULL
     DROP PROCEDURE dbo.UnapproveBhpbioApprovalData
GO 
  
CREATE PROCEDURE dbo.UnapproveBhpbioApprovalData
(
	@iTagId VARCHAR(63),
	@iLocationId INT,
	@iApprovalMonth DATETIME
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'UnapproveBhpbioApprovalData',
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
		IF NOT EXISTS (SELECT 1 FROM dbo.BhpbioReportDataTags WHERE TagId = @iTagId)
		BEGIN
			RAISERROR('The tag does not exist', 16, 1)
		END
	
		IF NOT EXISTS (SELECT 1 FROM dbo.Location WHERE Location_Id = @iLocationId)
		BEGIN
			RAISERROR('The location does not exist', 16, 1)
		END
		
		IF @iApprovalMonth <> dbo.GetDateMonth(@iApprovalMonth)
		BEGIN
			RAISERROR('The date supplied is not the start of a month', 16, 1)
		END

		-- Determine the latest month that was purged
		-- and ensure that the user is not attempting an unapproval in a month that has already been purged
		DECLARE @latestPurgedMonth DATETIME
		exec dbo.GetBhpbioLatestPurgedMonth @oLatestPurgedMonth = @latestPurgedMonth OUTPUT
		
		IF @latestPurgedMonth IS NOT NULL AND @latestPurgedMonth >= @iApprovalMonth
		BEGIN
			RAISERROR('It is not possible to unapprove data in this period as the period has been purged', 16, 1)
		END

		IF NOT EXISTS	(
							SELECT 1 
							FROM dbo.BhpbioApprovalData 
							WHERE TagId = @iTagId 
								AND ApprovedMonth = @iApprovalMonth 
									AND LocationID = @iLocationId
						)
		BEGIN
			RAISERROR('The calculation and month provided has not been approved. Please ensure this calculation has not been approved at a higher level.', 16, 1)
		END
		
		DELETE
		FROM dbo.BhpbioApprovalData
		WHERE TagId = @iTagId 
			AND ApprovedMonth = @iApprovalMonth
			AND LocationId = @iLocationId


		-- Clear out any summary data that is no longer valid due to the unapproval
		exec dbo.DeleteBhpbioSummaryDataRelatedToApproval	@iTagId = @iTagId,
															@iLocationId = @iLocationId,
															@iApprovalMonth = @iApprovalMonth


		exec dbo.AddBhpbioDataRetrievalQueueEntry @iApprovalMonth
															
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

GRANT EXECUTE ON dbo.UnapproveBhpbioApprovalData TO BhpbioGenericManager
GO
