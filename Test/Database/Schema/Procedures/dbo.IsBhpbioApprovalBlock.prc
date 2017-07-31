IF OBJECT_ID('dbo.IsBhpbioApprovalBlock') IS NOT NULL
     DROP PROCEDURE dbo.IsBhpbioApprovalBlock  
GO 
  
CREATE PROCEDURE dbo.IsBhpbioApprovalBlock 
(
	@iDigblockId VARCHAR(31),
	@oIsApproved BIT OUTPUT
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @ReturnValue BIT

	SET NOCOUNT ON 

	SELECT @TransactionName = 'IsBhpbioApprovalBlock',
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
		-- If the block has ever been approved, return true
		IF EXISTS	(
					SELECT TOP 1 1
					FROM dbo.BhpbioApprovalDigblock
					WHERE DigblockId = @iDigblockId
					)
		BEGIN
			SET @ReturnValue = 1
		END
		ELSE
		BEGIN
			SET @ReturnValue = 0
		END
		
		SET @oIsApproved = @ReturnValue

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

GRANT EXECUTE ON dbo.IsBhpbioApprovalBlock TO BhpbioGenericManager
GO
