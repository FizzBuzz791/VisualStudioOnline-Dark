IF OBJECT_ID('dbo.UnapproveBhpbioApprovalDigblock') IS NOT NULL
     DROP PROCEDURE dbo.UnapproveBhpbioApprovalDigblock  
GO 
  
CREATE PROCEDURE dbo.UnapproveBhpbioApprovalDigblock
(
	@iDigblockId VARCHAR(31),
	@iApprovalMonth DATETIME
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'UnapproveBhpbioApprovalDigblock',
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
		IF NOT EXISTS (SELECT 1 FROM dbo.Digblock WHERE Digblock_Id = @iDigblockId)
		BEGIN
			RAISERROR('The digblock does not exist', 16, 1)
		END
	
		IF @iApprovalMonth <> dbo.GetDateMonth(@iApprovalMonth)
		BEGIN
			RAISERROR('The date supplied is not the start of a month', 16, 1)
		END
		
		IF NOT EXISTS (SELECT 1 FROM dbo.BhpbioApprovalDigblock WHERE DigblockId = @iDigblockId AND ApprovedMonth = @iApprovalMonth)
		BEGIN
			RAISERROR('The digblock and month provided has not been approved.', 16, 1)
		END
		
		DELETE
		FROM dbo.BhpbioApprovalDigblock
		WHERE DigblockId = @iDigblockId 
			AND ApprovedMonth = @iApprovalMonth
		

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

GRANT EXECUTE ON dbo.UnapproveBhpbioApprovalDigblock TO BhpbioGenericManager
GO
