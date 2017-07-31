IF OBJECT_ID('dbo.AddOrUpdateBhpbioShippingTargetValue') IS NOT NULL
     DROP PROCEDURE dbo.AddOrUpdateBhpbioShippingTargetValue
GO 
  
CREATE PROCEDURE dbo.AddOrUpdateBhpbioShippingTargetValue
(
	@iShippingTargetPeriodId int,
	@iAttributeId Int,
	@iUpperControl Float,
	@iTarget Float,
	@iLowerControl Float
)
WITH ENCRYPTION
AS
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'AddOrUpdateBhpbioShippingTargetValue',
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
		
		-- Ensure no clash with existing shipping target
		IF NOT EXISTS (SELECT * FROM BhpbioShippingTargetPeriod WHERE ShippingTargetPeriodId = @iShippingTargetPeriodId)
		BEGIN
			-- raise error... shipping target for period does NOT exist
			RAISERROR('Shipping target does not exist', 16, 1)
		END

		IF EXISTS (SELECT * FROM BhpbioShippingTargetPeriodValue WHERE ShippingTargetPeriodId = @iShippingTargetPeriodId AND AttributeId = @iAttributeId)
		BEGIN
			UPDATE BhpbioShippingTargetPeriodValue
				SET UpperControl = @iUpperControl,
					[Target] = @iTarget,
					LowerControl = @iLowerControl
			WHERE ShippingTargetPeriodId = @iShippingTargetPeriodId
				AND AttributeId = @iAttributeId 
		END
		ELSE
		BEGIN
			INSERT INTO dbo.BhpbioShippingTargetPeriodValue(ShippingTargetPeriodId, AttributeId, UpperControl, [Target], LowerControl)
			VALUES (@iShippingTargetPeriodId, @iAttributeId, @iUpperControl, @iTarget, @iLowerControl)
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

GRANT EXECUTE ON dbo.AddOrUpdateBhpbioShippingTargetValue TO BhpbioGenericManager
GO
