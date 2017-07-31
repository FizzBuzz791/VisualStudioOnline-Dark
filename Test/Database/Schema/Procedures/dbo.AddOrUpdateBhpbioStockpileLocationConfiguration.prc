 IF OBJECT_ID('dbo.AddOrUpdateBhpbioStockpileLocationConfiguration') IS NOT NULL
     DROP PROCEDURE dbo.AddOrUpdateBhpbioStockpileLocationConfiguration
GO 
  
CREATE PROCEDURE dbo.AddOrUpdateBhpbioStockpileLocationConfiguration
(
	@iImageData VARBINARY(MAX),
	@iUpdateImageData BIT,
	@iLocationId INT,
	@iUpdatePromoteStockpiles BIT,
	@iPromoteStockpiles BIT
)
WITH ENCRYPTION
AS
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'AddOrUpdateBhpbioStockpileImageLocation',
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
	
		IF NOT EXISTS
			(
				SELECT TOP 1 1
				FROM dbo.BhpbioLocationStockpileConfiguration
				WHERE LocationId = @iLocationId
			)
		BEGIN
			INSERT INTO dbo.BhpbioLocationStockpileConfiguration
			(LocationId, ImageData, PromoteStockpiles)
			VALUES(@iLocationId, @iImageData, @iPromoteStockpiles)
		END
		ELSE
		BEGIN
			UPDATE dbo.BhpbioLocationStockpileConfiguration
			SET ImageData = CASE WHEN @iUpdateImageData = 1 THEN @iImageData ELSE ImageData END,
			PromoteStockpiles = CASE WHEN @iUpdatePromoteStockpiles = 1 THEN @iPromoteStockpiles ELSE PromoteStockpiles END
			WHERE LocationId = @iLocationId
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

GRANT EXECUTE ON dbo.AddOrUpdateBhpbioStockpileLocationConfiguration TO BhpbioGenericManager
GO
