IF OBJECT_ID('dbo.AddOrUpdateBhpbioImportLoadRowMessages') IS NOT NULL
     DROP PROCEDURE dbo.AddOrUpdateBhpbioImportLoadRowMessages  
GO 
    
CREATE PROCEDURE dbo.AddOrUpdateBhpbioImportLoadRowMessages
(
	@iBlockNumber VARCHAR(16),
	@iBlockName VARCHAR(14),
	@iSite VARCHAR(9),
	@iOrebody VARCHAR(2),
	@iPit VARCHAR(10),
	@iBench VARCHAR(4),
	@iPatternNumber VARCHAR(4),
	@iModelName VARCHAR(31)
)
AS
BEGIN

	DECLARE @ImportLoadRowId INT
	DECLARE @ImportRowXML XML
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'AddOrUpdateBhpbioImportLoadRowMessages',
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
	
		CREATE TABLE #Block
		(
			BlockNumber VARCHAR(16),
			BlockName VARCHAR(14),
			Site VARCHAR(9),
			Orebody VARCHAR(2),
			Pit VARCHAR(10),
			Bench VARCHAR(4),
			PatternNumber VARCHAR(4),
			ModelName VARCHAR(31)
		)
		
		INSERT INTO #Block
		Select @iBlockNumber, @iBlockName, @iSite, @iOrebody, @iPit, @iBench, @iPatternNumber, @iModelName

		--Create xml
		Select @ImportRowXML = (Select *
			FROM #Block
			FOR XML Path('Block'))
		
		INSERT INTO dbo.ImportLoadRow
		(
			ImportId, ImportSource, SyncAction, ImportRow
		)
		Select ImportId, 'ReconBlocks','L',@ImportRowXML
		From Import
		Where ImportName = 'ReconBlockInsertUpdate'
		
		SET @ImportLoadRowId = Scope_Identity()	
		
		INSERT INTO dbo.ImportLoadRowMessages
		Select @ImportLoadRowId, 'Missing Block'
		
		DROP TABLE #Block

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

End
GO

GRANT EXECUTE ON dbo.AddOrUpdateBhpbioImportLoadRowMessages TO BhpbioGenericManager
GO
