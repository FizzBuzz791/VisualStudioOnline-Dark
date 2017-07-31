IF OBJECT_ID('dbo.AddOrUpdateBhpbioMetBalancingGrade') IS NOT NULL
     DROP PROCEDURE dbo.AddOrUpdateBhpbioMetBalancingGrade
GO 
  
CREATE PROCEDURE dbo.AddOrUpdateBhpbioMetBalancingGrade
(
	@iBhpbioMetBalancingId INT OUTPUT,
	@iGradeId SMALLINT,
	@iGradeValue FLOAT
)
WITH ENCRYPTION
AS
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'AddOrUpdateBhpbioMetBalancingGrade',
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
			SELECT 1
			FROM dbo.BhpbioMetBalancing
			WHERE BhpbioMetBalancingId = @iBhpbioMetBalancingId
		)
		BEGIN
			RAISERROR ('BhpbioMetBalancingId does not exist.', 16, 1)
		END
			
		IF EXISTS
		(
			SELECT 1
			FROM dbo.BhpbioMetBalancingGrade
			WHERE BhpbioMetBalancingId = @iBhpbioMetBalancingId
				AND GradeId = @iGradeId
		)
		BEGIN
			UPDATE dbo.BhpbioMetBalancingGrade
			SET GradeValue = @iGradeValue
			WHERE BhpbioMetBalancingId = @iBhpbioMetBalancingId
				AND GradeId = @iGradeId
		END
		ELSE
		BEGIN
			INSERT INTO dbo.BhpbioMetBalancingGrade
			(
				BhpbioMetBalancingId, GradeId, GradeValue
			)
			SELECT @iBhpbioMetBalancingId, @iGradeId, @iGradeValue
		END

		-- Add to the CVF queue
		Declare @CalendarDate Datetime
		
		SELECT @CalendarDate = CalendarDate 
		FROM dbo.BhpbioMetBalancing 
		WHERE BhpbioMetBalancingId = @iBhpbioMetBalancingId
		
		EXEC dbo.CalcVirtualFlowRaise @CalendarDate

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

GRANT EXECUTE ON dbo.AddOrUpdateBhpbioMetBalancingGrade TO BhpbioGenericManager
GO
