 IF OBJECT_ID('dbo.AddOrActivateBhpbioDataExceptionDigblockHasHaulage') IS NOT NULL
     DROP PROCEDURE dbo.AddOrActivateBhpbioDataExceptionDigblockHasHaulage
GO 
  
CREATE PROCEDURE dbo.AddOrActivateBhpbioDataExceptionDigblockHasHaulage
(
	@iDigblockId varchar(31)
)
WITH ENCRYPTION
AS
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'AddOrActivateBhpbioDataExceptionDigblockHasHaulage',
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

		DECLARE @dataExceptionId as Integer
		DECLARE @dataExceptionStatusId as Varchar(5)

		SELECT @dataExceptionId = Data_Exception_Id, @dataExceptionStatusId = Data_Exception_Status_Id
		FROM DataException
		WHERE Data_Exception_Type_Id = @dataExceptionTypeId
			AND Short_Description like @iDigblockId + '%'

		IF @dataExceptionId IS NOT NULL
		BEGIN
			-- if marked as resolved
			IF @dataExceptionStatusId = 'R'
			BEGIN
				-- make the data exception active again
				UPDATE DataException
				SET Data_Exception_Status_Id = 'A', Data_Exception_Date = Convert(date,GetDate())
				WHERE Data_Exception_Id = @dataExceptionId
			END
		END
		ELSE
		BEGIN
			DECLARE @description VARCHAR(250)
			SET @description = @iDigblockId + ' has been modified since haulage has been imported for this block'

			DECLARE @id INTEGER

			-- insert a new data exception
			INSERT INTO DataException(Data_Exception_Type_Id, Data_Exception_Date, Data_Exception_Shift, Data_Exception_Status_Id, Short_Description, Long_Description)
			SELECT @dataExceptionTypeId, Convert(date,GetDate()), 'D', 'A', @description, @description

			SET @id = SCOPE_IDENTITY()

			INSERT INTO BhpbioDataExceptionLocation(DataExceptionId, LocationId)
			SELECT @id, dl.Location_Id
			FROM DigblockLocation dl
			WHERE dl.Digblock_Id = @iDigblockId
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

GRANT EXECUTE ON dbo.AddOrActivateBhpbioDataExceptionDigblockHasHaulage TO BhpbioGenericManager
GO
