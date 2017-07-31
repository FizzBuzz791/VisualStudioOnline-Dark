IF OBJECT_ID('dbo.DeleteBhpbioPortBlending') IS NOT NULL
     DROP PROCEDURE dbo.DeleteBhpbioPortBlending  
GO 
  
CREATE PROCEDURE dbo.DeleteBhpbioPortBlending
(
	@iBhpbioPortBlendingId INT
)
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'DeleteBhpbioPortBlending',
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

		-- remove the nomination
		DELETE
		FROM dbo.BhpbioPortBlending
		WHERE BhpbioPortBlendingId = @iBhpbioPortBlendingId

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

GRANT EXECUTE ON dbo.DeleteBhpbioPortBlending TO BhpbioGenericManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.DeleteBhpbioPortBlending">
 <Procedure>
	Deletes port blending records.
 </Procedure>
</TAG>
*/	
