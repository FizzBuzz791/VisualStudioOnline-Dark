IF OBJECT_ID('dbo.DeleteBhpbioCustomMessage') IS NOT NULL
     DROP PROCEDURE dbo.DeleteBhpbioCustomMessage
GO 
  
CREATE PROCEDURE dbo.DeleteBhpbioCustomMessage
(
	@iName VARCHAR(63)
)
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @BlockId INT
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'DeleteBhpbioCustomMessage',
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
		DELETE
		FROM dbo.BhpbioCustomMessage
		WHERE Name = @iName


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

GRANT EXECUTE ON dbo.DeleteBhpbioCustomMessage TO BhpbioGenericManager
GO
