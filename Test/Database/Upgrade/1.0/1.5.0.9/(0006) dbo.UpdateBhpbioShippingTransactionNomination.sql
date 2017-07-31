IF OBJECT_ID('dbo.UpdateBhpbioShippingTransactionNomination') IS NOT NULL
     DROP PROCEDURE dbo.UpdateBhpbioShippingTransactionNomination  
GO 
  
CREATE PROCEDURE dbo.UpdateBhpbioShippingTransactionNomination
(
	@iBhpbioShippingTransactionNominationId INT,
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
	@iOversize FLOAT = NULL
)
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'UpdateBhpbioShippingTransactionNomination',
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
		-- note that NominationKey is part of the pk so there is no chance of orphaning transaction records
		EXEC dbo.AddOrUpdateBhpbioShippingTransaction
			@iNominationKey = @iNominationKey,
			@iVesselName = @iVesselName

		-- update the nomination record
		UPDATE dbo.BhpbioShippingTransactionNomination
		SET	NominationKey = @iNominationKey,
			Nomination = @iNomination,
			OfficialFinishTime = @iOfficialFinishTime,
			LastAuthorisedDate = @iLastAuthorisedDate,
			CustomerNo = @iCustomerNo,
			CustomerName = @iCustomerName,
			HubLocationId = @iHubLocationId,
			ProductCode = @iProductCode,
			Tonnes = @iTonnes,
			COA = @iCOA,
			H2O = @iH2O,
			Undersize = @iUndersize,
			Oversize = @iOversize
		WHERE BhpbioShippingTransactionNominationId = @iBhpbioShippingTransactionNominationId

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

GRANT EXECUTE ON dbo.UpdateBhpbioShippingTransactionNomination TO BhpbioGenericManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.UpdateBhpbioShippingTransactionNomination">
 <Procedure>
	Updates transaction nomination records as required, optionally adding transaction records as required.
 </Procedure>
</TAG>
*/	
 