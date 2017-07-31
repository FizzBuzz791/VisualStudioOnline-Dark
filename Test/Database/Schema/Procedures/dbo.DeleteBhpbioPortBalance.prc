IF OBJECT_ID('dbo.DeleteBhpbioPortBalance') IS NOT NULL
     DROP PROCEDURE dbo.DeleteBhpbioPortBalance  
GO 
  
CREATE PROCEDURE dbo.DeleteBhpbioPortBalance
(
	@iBhpbioPortBalanceId INT
)
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'DeleteBhpbioPortBalance',
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
	
		-- Delete port balance grades first
		DELETE
		FROM dbo.BhpbioPortBalanceGrade
		WHERE BhpbioPortBalanceId = @iBhpbioPortBalanceId

		-- Delete the balance
		DELETE
		FROM dbo.BhpbioPortBalance
		WHERE BhpbioPortBalanceId = @iBhpbioPortBalanceId

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

GRANT EXECUTE ON dbo.DeleteBhpbioPortBalance TO BhpbioGenericManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.DeleteBhpbioPortBalance">
 <Procedure>
	Deletes port Balance records.
 </Procedure>
</TAG>
*/	
