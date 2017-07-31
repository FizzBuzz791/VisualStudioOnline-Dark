IF OBJECT_ID('dbo.DeleteBhpbioShippingNominationItem') IS NOT NULL
     DROP PROCEDURE dbo.DeleteBhpbioShippingNominationItem  
GO 
  
CREATE PROCEDURE dbo.DeleteBhpbioShippingNominationItem
(
	@iBhpbioShippingNominationItemId INT
)
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @NominationKey INT

	SET NOCOUNT ON 

	SELECT @TransactionName = 'UpdateBhpbioShippingNominationItem',
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
		-- remember the nomination key
		SET @NominationKey =
			(
				SELECT NominationKey
				FROM BhpbioShippingNominationItem
				WHERE BhpbioShippingNominationItemId = @iBhpbioShippingNominationItemId
			)

		-- remove the nomination
		DELETE
		FROM dbo.BhpbioShippingNominationItem
		WHERE BhpbioShippingNominationItemId = @iBhpbioShippingNominationItemId

		-- remove any orphan transactions
		DELETE
		FROM dbo.BhpbioShippingNomination
		WHERE NominationKey = @NominationKey
			AND NOT EXISTS
				(
					SELECT 1
					FROM dbo.BhpbioShippingNominationItem
					WHERE NominationKey = @NominationKey
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

GRANT EXECUTE ON dbo.DeleteBhpbioShippingNominationItem TO BhpbioGenericManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.DeleteBhpbioShippingNominationItem">
 <Procedure>
	Deletes transaction nomination records, and optionally deletes the parent transaction if there are no children attached.
 </Procedure>
</TAG>
*/	
