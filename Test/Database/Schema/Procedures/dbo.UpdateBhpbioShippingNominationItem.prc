IF OBJECT_ID('dbo.UpdateBhpbioShippingNominationItem') IS NOT NULL
     DROP PROCEDURE dbo.UpdateBhpbioShippingNominationItem  
GO 
  
CREATE PROCEDURE dbo.UpdateBhpbioShippingNominationItem
(
	@iBhpbioShippingNominationItemId INT,
	@iNominationKey INT,
	@iItemNo INT,
	@iOfficialFinishTime DATETIME,
	@iLastAuthorisedDate DATETIME = NULL,
	@iVesselName VARCHAR(63),
	@iCustomerNo INT,
	@iCustomerName VARCHAR(63),
	@iShippedProduct VARCHAR(63),
	@iShippedProductSize VARCHAR(5),
	@iCOA DATETIME = NULL,
	@iUndersize FLOAT = NULL,
	@iOversize FLOAT = NULL
)
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

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
		-- note that NominationKey is part of the pk so there is no chance of orphaning transaction records
		EXEC dbo.AddOrUpdateBhpbioShippingNomination
			@iNominationKey = @iNominationKey,
			@iVesselName = @iVesselName

		-- update the nomination record
		UPDATE dbo.BhpbioShippingNominationItem
		SET	NominationKey = @iNominationKey,
			ItemNo = @iItemNo,
			OfficialFinishTime = @iOfficialFinishTime,
			LastAuthorisedDate = @iLastAuthorisedDate,
			CustomerNo = @iCustomerNo,
			CustomerName = @iCustomerName,
			ShippedProduct = @iShippedProduct,
			ShippedProductSize = @iShippedProductSize,
			COA = @iCOA,
			Undersize = @iUndersize,
			Oversize = @iOversize
		WHERE BhpbioShippingNominationItemId = @iBhpbioShippingNominationItemId

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

GRANT EXECUTE ON dbo.UpdateBhpbioShippingNominationItem TO BhpbioGenericManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.UpdateBhpbioShippingNominationItem">
 <Procedure>
	Updates transaction nomination records as required, optionally adding transaction records as required.
 </Procedure>
</TAG>
*/	
 