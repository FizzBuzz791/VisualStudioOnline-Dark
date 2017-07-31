
-----------------------------------------
IF OBJECT_ID('dbo.AddUpdateSummaryEntryFieldValue') IS NOT NULL
     DROP PROCEDURE dbo.AddUpdateSummaryEntryFieldValue
GO 
  
CREATE PROCEDURE dbo.AddUpdateSummaryEntryFieldValue
(
	@iSummaryEntryFieldValueId Int,
	@iSummaryEntryFieldId Int,
	@iSummaryEntryId Int,
	@iValue Float = NULL
)
WITH ENCRYPTION
AS
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'dbo.AddUpdateSummaryEntryFieldValue',
		@TransactionCount = @@TranCount

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

		  IF (SELECT SummaryEntryFieldValueId
			FROM BhpbioSummaryEntryFieldValue
			WHERE SummaryEntryFieldValueId = @iSummaryEntryFieldValueId) IS NOT NULL
		
		BEGIN
				UPDATE dbo.BhpbioSummaryEntryFieldValue
				SET SummaryEntryFieldId = @iSummaryEntryFieldId
					,SummaryEntryId = @iSummaryEntryId
					,Value = @iValue
				WHERE SummaryEntryFieldValueId = @iSummaryEntryFieldValueId
		END
		ELSE
		BEGIN
				INSERT INTO dbo.BhpbioSummaryEntryFieldValue
					(SummaryEntryFieldId,SummaryEntryId,Value)
				VALUES
					(@iSummaryEntryFieldId,@iSummaryEntryId,@iValue)
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

GRANT EXECUTE ON dbo.AddUpdateSummaryEntryFieldValue TO BhpbioGenericManager
GO

