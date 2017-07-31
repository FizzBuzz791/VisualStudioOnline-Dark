IF OBJECT_ID('dbo.GetBhpbioApprovalDataRaw') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioApprovalDataRaw
GO 
  
CREATE PROCEDURE dbo.GetBhpbioApprovalDataRaw
(
	@iMonthFilter DATETIME,
	@iIgnoreUsers BIT = 0
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioApprovalDataRaw',
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
	
		IF @iIgnoreUsers = 1
		BEGIN
			-- Retrieves all the approvals for the month without any user information
			-- This is used by the Approval update page to quickly check which records to update
			SELECT TagId, LocationId, ApprovedMonth
			FROM dbo.BhpbioApprovalData
			WHERE (ApprovedMonth = @iMonthFilter OR @iMonthFilter IS NULL)
			GROUP BY TagId, LocationId, ApprovedMonth
		END
		ELSE
		BEGIN
			-- Retrieves all raw data from the approval table
			SELECT TagId, LocationId, ApprovedMonth, UserId, SignoffDate
			FROM dbo.BhpbioApprovalData
			WHERE (ApprovedMonth = @iMonthFilter OR @iMonthFilter IS NULL)
		END
		
			
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

GRANT EXECUTE ON dbo.GetBhpbioApprovalDataRaw TO BhpbioGenericManager
GO


--EXEC dbo.GetBhpbioApprovalDataRaw '1-nov-2009'

