IF OBJECT_ID('dbo.AddOrUpdateBhpbioAnalysisVariance') IS NOT NULL
     DROP PROCEDURE dbo.AddOrUpdateBhpbioAnalysisVariance  
GO 

CREATE PROCEDURE dbo.AddOrUpdateBhpbioAnalysisVariance
(
	@iLocationId INT,
	@iVarianceType CHAR(1),
	@iPercentage FLOAT,
	@iColor VARCHAR(255)
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'AddOrUpdateBhpbioAnalysisVariance',
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
					SELECT 1 
					FROM dbo.BhpbioAnalysisVariance 
					WHERE LocationId = @iLocationId
						AND VarianceType = @iVarianceType
				   )
		BEGIN 
			-- Update the threshold
			UPDATE V
			SET Percentage = @iPercentage,
				Color = @iColor
			FROM dbo.BhpbioAnalysisVariance AS V
			WHERE LocationId = @iLocationId
				AND VarianceType = @iVarianceType
		END
		ELSE
		BEGIN
			INSERT INTO dbo.BhpbioAnalysisVariance
				(LocationId, VarianceType, Percentage, Color)
			SELECT @iLocationId, @iVarianceType, @iPercentage, @iColor
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
GRANT EXECUTE ON dbo.AddOrUpdateBhpbioAnalysisVariance TO BhpbioGenericManager
