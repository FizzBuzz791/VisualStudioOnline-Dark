 IF OBJECT_ID('dbo.DeleteBhpbioDataExceptionDigblockHasHaulage') IS NOT NULL
     DROP PROCEDURE dbo.DeleteBhpbioDataExceptionDigblockHasHaulage
GO 
  
CREATE PROCEDURE dbo.DeleteBhpbioDataExceptionDigblockHasHaulage
(
	@iDigblockId varchar(31)
)
WITH ENCRYPTION
AS
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'DeleteBhpbioDataExceptionDigblockHasHaulage',
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
		

		DECLARE @dataExceptionTypeId as Integer
		SELECT @dataExceptionTypeId = Data_Exception_Type_Id
		FROM DataExceptionType WHERE Name = 'Block changed after haulage imported'
		
		DELETE de
		FROM DataException de
		WHERE de.Data_Exception_Type_Id = @dataExceptionTypeId
			AND de.Short_Description like @iDigblockId + '%'
		
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

GRANT EXECUTE ON dbo.DeleteBhpbioDataExceptionDigblockHasHaulage TO BhpbioGenericManager
GO
