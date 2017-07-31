IF OBJECT_ID('dbo.ResolveBhpbioLocationByName') IS NOT NULL
     DROP PROCEDURE dbo.ResolveBhpbioLocationByName  
GO 
  
CREATE PROCEDURE dbo.ResolveBhpbioLocationByName
(
	@iLocationName VARCHAR(63),
	@oLocationId INT OUTPUT
)
WITH ENCRYPTION
AS 
BEGIN 
	
	DECLARE @StockpileId INT
	DECLARE @DigblockId VARCHAR(31)
	DECLARE @CrusherId VARCHAR(31)
	DECLARE @MillId VARCHAR(31)
	DECLARE @LocationId INT
	
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(40)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'ResolveBhpbioLocationByName',
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
	

		SELECT @StockpileId = Stockpile_Id
		FROM dbo.Stockpile
		WHERE Stockpile_Name = @iLocationName

		IF @StockpileId IS NULL
		BEGIN
			SELECT @DigblockId = Digblock_Id
			FROM dbo.Digblock
			WHERE Digblock_Id = @iLocationName
		
			IF @DigblockId IS NULL
			BEGIN	
				
				SELECT @CrusherId = Crusher_Id
				FROM dbo.Crusher
				WHERE Crusher_Id = @iLocationName

				IF @CrusherId IS NULL
				BEGIN
					SELECT @MillId = Mill_Id
					FROM dbo.Mill
					WHERE Mill_Id = @iLocationName
				END
			END
		END

		--If we still haven't resolved, then try and resolve through haulage raw.
		IF 
			(
				@MillId IS NULL AND
				@CrusherId IS NULL AND
				@DigblockId IS NULL AND
				@StockpileId IS NULL
			)
		BEGIN
			SELECT @StockpileId = hr.Stockpile_Id,
				@DigblockId = hr.Digblock_Id,
				@CrusherId = hr.Crusher_Id,
				@MillId = hr.Mill_Id
			FROM dbo.HaulageResolveBasic AS hr
			WHERE Code = @iLocationName
		END

		IF @StockpileId IS NOT NULL
		BEGIN
			SELECT @LocationId = Location_Id
			FROM dbo.StockpileLocation
			WHERE Stockpile_Id = @StockpileId
		END

		IF @DigblockId IS NOT NULL
		BEGIN
			SELECT @LocationId = Location_Id
			FROM dbo.DigblockLocation
			WHERE Digblock_Id = @DigblockId
		END

		IF @CrusherId IS NOT NULL
		BEGIN
			SELECT @LocationId = Location_Id
			FROM dbo.DigblockLocation
			WHERE Digblock_Id = @DigblockId
		END

		IF @MillId IS NOT NULL
		BEGIN
			SELECT @LocationId = Location_Id
			FROM dbo.MillLocation
			WHERE Mill_Id = @MillId
		END
		
		SET @oLocationId = @LocationId

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

GRANT EXECUTE ON dbo.ResolveBhpbioLocationByName TO BhpbioGenericManager
GO
