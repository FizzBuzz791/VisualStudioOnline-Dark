IF OBJECT_ID('dbo.AddOrUpdateBhpbioSampleStationTarget') IS NOT NULL 
     DROP PROCEDURE dbo.AddOrUpdateBhpbioSampleStationTarget
GO 

CREATE PROCEDURE dbo.AddOrUpdateBhpbioSampleStationTarget
(
	@SampleStation_Id INT,
	@StartDate DATE,
	@CoverageTarget DECIMAL(18,2),
	@CoverageWarning DECIMAL(18,2),
	@RatioTarget INT,
	@RatioWarning INT,
	@Id INT = NULL
)
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON

	SELECT @TransactionName = 'AddOrUpdateBhpbioSampleStationTarget',
		@TransactionCount = @@TRANCOUNT

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
		IF EXISTS (SELECT * FROM dbo.BhpbioSampleStationTarget WHERE Id = @Id AND StartDate = @StartDate)
		BEGIN
			UPDATE dbo.BhpbioSampleStationTarget SET
				SampleStation_Id = @SampleStation_Id,
				StartDate = @StartDate,
				CoverageTarget = @CoverageTarget,
				CoverageWarning = @CoverageWarning,
				RatioTarget = @RatioTarget,
				RatioWarning = @RatioWarning
			WHERE Id = @Id
		END
		ELSE
		BEGIN
			INSERT INTO dbo.BhpbioSampleStationTarget (SampleStation_Id, StartDate, CoverageTarget, CoverageWarning, RatioTarget, RatioWarning)
			VALUES (@SampleStation_Id, @StartDate, @CoverageTarget, @CoverageWarning, @RatioTarget, @RatioWarning)
		END
		

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

GRANT EXECUTE ON dbo.AddOrUpdateBhpbioSampleStationTarget TO BhpbioGenericManager
GO