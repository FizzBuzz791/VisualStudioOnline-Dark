IF OBJECT_ID('dbo.AddBhpbioShippingTransactionNomination') IS NOT NULL
    DROP PROCEDURE dbo.AddBhpbioShippingTransactionNomination  
GO 
  
CREATE PROCEDURE dbo.AddBhpbioShippingTransactionNomination
(
	@iNominationKey INT,
	@iNomination INT,
	@iOfficialFinishTime DATETIME,
	@iLastAuthorisedDate DATETIME = NULL,
	@iVesselName VARCHAR(63),
	@iCustomerNo INT,
	@iCustomerName VARCHAR(63),
	@iHubLocationId INT,
	@iProductCode VARCHAR(63),
	@iTonnes FLOAT,
	@iCOA DATETIME = NULL,
	@iH2O FLOAT = NULL,
	@iUndersize FLOAT = NULL,
	@iOversize FLOAT = NULL,
	@oBhpbioShippingTransactionNominationId INT OUTPUT
)
AS
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'AddBhpbioShippingTransactionNomination',
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
		EXEC dbo.AddOrUpdateBhpbioShippingTransaction
			@iNominationKey = @iNominationKey,
			@iVesselName = @iVesselName

		-- create/update the nomination record
		INSERT INTO dbo.BhpbioShippingTransactionNomination
		(
			NominationKey, Nomination, OfficialFinishTime, LastAuthorisedDate, CustomerNo, CustomerName,
			HubLocationId, ProductCode, Tonnes, COA, H2O, Undersize, Oversize
		)
		SELECT @iNominationKey, @iNomination, @iOfficialFinishTime, @iLastAuthorisedDate, @iCustomerNo, @iCustomerName,
			@iHubLocationId, @iProductCode, @iTonnes, @iCOA, @iH2O, @iUndersize, @iOversize

		SET @oBhpbioShippingTransactionNominationId = Scope_Identity()

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

GRANT EXECUTE ON dbo.AddBhpbioShippingTransactionNomination TO BhpbioGenericManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.AddBhpbioShippingTransactionNomination">
 <Procedure>
	Adds transaction nomination records, creating parent transaction records as required.
 </Procedure>
</TAG>
*/
 