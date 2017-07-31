IF OBJECT_ID('dbo.UpdateBhpbioShippingNominationItemParcel') IS NOT NULL
	DROP PROCEDURE dbo.UpdateBhpbioShippingNominationItemParcel
GO

CREATE PROCEDURE dbo.UpdateBhpbioShippingNominationItemParcel
(
	@iBhpbioShippingNominationItemParcelId INT,
	@iHubLocationId INT,
	@iHubProduct VARCHAR(63),
	@iHubProductSize VARCHAR(5),
	@iTonnes Float	
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'dbo.UpdateBhpbioShippingNominationItemParcel',
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
		IF EXISTS
			(
				SELECT 1
				FROM dbo.BhpbioShippingNominationItemParcel
				WHERE BhpbioShippingNominationItemParcelId = @iBhpbioShippingNominationItemParcelId
			)
		BEGIN
			UPDATE dbo.BhpbioShippingNominationItemParcel
				SET HubLocationId = @iHubLocationId, 
				HubProduct = @iHubProduct, 
				HubProductSize = @iHubProductSize, 
				Tonnes = @iTonnes 
			WHERE BhpbioShippingNominationItemParcelId = @iBhpbioShippingNominationItemParcelId
		END
		ELSE
		BEGIN
			RAISERROR(N'Shipping nomination item parcel with Id %d does not exist.', 16, 1, @iBhpbioShippingNominationItemParcelId)
		END
		
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

GRANT EXECUTE ON dbo.UpdateBhpbioShippingNominationItemParcel TO BhpbioGenericManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.UpdateBhpbioShippingNominationItemParcel">
 <Procedure>
	Adds, updates and deletes transaction nomination parcels.
 </Procedure>
</TAG>
*/
