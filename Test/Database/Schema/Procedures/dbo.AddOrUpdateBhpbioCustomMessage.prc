IF OBJECT_ID('dbo.AddOrUpdateBhpbioCustomMessage') IS NOT NULL
     DROP PROCEDURE dbo.AddOrUpdateBhpbioCustomMessage
GO 
  
CREATE PROCEDURE dbo.AddOrUpdateBhpbioCustomMessage
(
	@iName VARCHAR(63),
	@iUpdateText BIT,
	@iText VARCHAR(MAX),
	@iUpdateExpirationDate BIT,
	@iExpirationDate DATETIME,
	@iUpdateIsActive BIT,
	@iIsActive BIT
)
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @BlockId INT
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'AddOrUpdateBhpbioCustomMessage',
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
				FROM dbo.BhpbioCustomMessage
				WHERE Name = @iName
			)
		BEGIN
			INSERT INTO dbo.BhpbioCustomMessage
			(
				Name, Text, ExpirationDate, IsActive
			)
			SELECT @iName, @iText, @iExpirationDate, @iIsActive
		END
		ELSE
		BEGIN
			UPDATE CM
			SET Text = CASE WHEN @iUpdateText = 1 THEN @iText ELSE Text END,
				ExpirationDate = CASE WHEN @iUpdateExpirationDate = 1 THEN @iExpirationDate ELSE ExpirationDate END,
				IsActive = CASE WHEN @iUpdateIsActive = 1 THEN @iIsActive ELSE IsActive END
			FROM dbo.BhpbioCustomMessage AS CM
			WHERE Name = @iName
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

GRANT EXECUTE ON dbo.AddOrUpdateBhpbioCustomMessage TO BhpbioGenericManager
GO
