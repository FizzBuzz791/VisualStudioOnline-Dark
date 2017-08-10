IF OBJECT_ID('dbo.DeleteBhpbioSampleStation') IS NOT NULL 
     DROP PROCEDURE dbo.DeleteBhpbioSampleStation
GO 

CREATE PROCEDURE dbo.DeleteBhpbioSampleStation
(
	@Id INT
)
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON

	SELECT @TransactionName = 'DeleteBhpbioSampleStation', @TransactionCount = @@TRANCOUNT

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
		DELETE FROM dbo.BhpbioSampleStationTarget WHERE SampleStation_Id = @Id
		DELETE FROM dbo.BhpbioSampleStation WHERE Id = @Id

		-- if we started a new transaction that is still valid then commit the changes
		IF (@TransactionCount = 0) AND (XACT_STATE() = 1)
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
		ELSE IF (XACT_STATE() = 1) AND (@TransactionCount > 0)
		BEGIN
			ROLLBACK TRANSACTION @TransactionName
		END

		EXEC dbo.StandardCatchBlock
	END CATCH
END
GO

GRANT EXECUTE ON dbo.DeleteBhpbioSampleStation TO BhpbioGenericManager
GO