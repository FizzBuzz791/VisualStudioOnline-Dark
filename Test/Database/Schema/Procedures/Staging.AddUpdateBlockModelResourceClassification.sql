
-----------------------------------------
IF OBJECT_ID('Staging.AddUpdateBlockModelResourceClassification') IS NOT NULL
     DROP PROCEDURE Staging.AddUpdateBlockModelResourceClassification
GO 
  
CREATE PROCEDURE Staging.AddUpdateBlockModelResourceClassification
(
	
	@iBlockModelId Int,
	@iResourceClassification Varchar(32),
	@iPercentage Float
)
WITH ENCRYPTION
AS
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'Staging.AddUpdateBlockModelResourceClassification',
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

		IF EXISTS (
			SELECT 1 FROM Staging.StageBlockModelResourceClassification 
			WHERE BlockModelId = @iBlockModelId 
				AND ResourceClassification = @iResourceClassification
		)
		BEGIN
			EXEC Staging.DeleteBlockModelResourceClassification @iBlockModelId , @iResourceClassification
		END
		
		INSERT INTO [Staging].[StageBlockModelResourceClassification]
		   (BlockModelId
		   ,ResourceClassification
		   ,Percentage)
		 VALUES
		   (@iBlockModelId
		   ,@iResourceClassification
		   ,@iPercentage)
		
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

GRANT EXECUTE ON Staging.AddUpdateBlockModelResourceClassification TO BhpbioGenericManager
GO
