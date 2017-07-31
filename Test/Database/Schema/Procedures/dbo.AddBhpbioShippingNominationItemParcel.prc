IF OBJECT_ID('dbo.AddBhpbioShippingNominationItemParcel') IS NOT NULL
    DROP PROCEDURE dbo.AddBhpbioShippingNominationItemParcel  
GO 
  
CREATE PROCEDURE dbo.AddBhpbioShippingNominationItemParcel
(
	@iBhpbioShippingNominationItemId INT,
	@iHubLocationId INT,
	@iHubProduct VARCHAR(63),
	@iHubProductSize VARCHAR(5),
	@iTonnes Float,
	@oBhpbioShippingNominationItemParcelId INT OUTPUT
)
AS
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'AddBhpbioShippingNominationItemParcel',
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
		-- create/update the nomination item parcel record
		INSERT INTO dbo.BhpbioShippingNominationItemParcel
		(
			BhpbioShippingNominationItemId, HubLocationId, HubProduct, HubProductSize, Tonnes
		)
		SELECT @iBhpbioShippingNominationItemId, @iHubLocationId, @iHubProduct, @iHubProductSize, @iTonnes


		SET @oBhpbioShippingNominationItemParcelId = Scope_Identity()

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

GRANT EXECUTE ON dbo.AddBhpbioShippingNominationItemParcel TO BhpbioGenericManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.AddBhpbioShippingNominationItemParcel">
 <Procedure>
	Adds nomination item parcel records.
 </Procedure>
</TAG>
*/
 