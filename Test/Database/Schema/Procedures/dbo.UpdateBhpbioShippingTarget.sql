IF OBJECT_ID('dbo.UpdateBhpbioShippingTarget') IS NOT NULL
     DROP PROCEDURE dbo.UpdateBhpbioShippingTarget
GO 
  
CREATE PROCEDURE dbo.UpdateBhpbioShippingTarget
(
	@iShippingTargetPeriodId int,
	@iEffectiveFromDateTime DateTime,
	@iProductTypeId int,
	@iUserId Int
)
WITH ENCRYPTION
AS
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'UpdateBhpbioShippingTarget',
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
		
		-- Ensure shipping target exists
		IF NOT EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @iShippingTargetPeriodId)
		BEGIN
			-- raise error... 
			RAISERROR('Shipping target not found', 16, 1)
		END
		
		IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ProductTypeId = @iProductTypeId AND EffectiveFromDateTime = @iEffectiveFromDateTime AND ShippingTargetPeriodId <>  @iShippingTargetPeriodId)
		BEGIN
			-- raise error... shipping target for period already exists
			RAISERROR('A shipping target for this product type and period already exists', 16, 1)
		END

		UPDATE dbo.BhpbioShippingTargetPeriod
			SET LastModifiedUserId = @iUserId,
				EffectiveFromDateTime = @iEffectiveFromDateTime,
				LastModifiedDateTime = GetDate()
		WHERE ShippingTargetPeriodId = @iShippingTargetPeriodId 

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

GRANT EXECUTE ON dbo.UpdateBhpbioShippingTarget TO BhpbioGenericManager
GO
