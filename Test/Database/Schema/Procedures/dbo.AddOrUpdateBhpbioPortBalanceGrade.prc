IF OBJECT_ID('dbo.AddOrUpdateBhpbioPortBalanceGrade') IS NOT NULL
	DROP PROCEDURE dbo.AddOrUpdateBhpbioPortBalanceGrade
GO

CREATE PROCEDURE dbo.AddOrUpdateBhpbioPortBalanceGrade
(
	@iBhpbioPortBalanceId INT,
	@iGradeId SMALLINT,
	@iGradeValue FLOAT
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'dbo.AddOrUpdateBhpbioPortBalanceGrade',
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
		IF @iGradeId IS NOT NULL AND @iGradeValue IS NOT NULL
		BEGIN
			IF EXISTS
			(
				SELECT 1
				FROM dbo.BhpbioPortBalanceGrade
				WHERE GradeId = @iGradeId
					AND BhpbioPortBalanceId = @iBhpbioPortBalanceId
			)
			BEGIN
				-- Update the grade
				UPDATE dbo.BhpbioPortBalanceGrade
				SET GradeValue = @iGradeValue
				WHERE GradeId = @iGradeId
					AND BhpbioPortBalanceId = @iBhpbioPortBalanceId
			END
			ELSE
			BEGIN
				-- Insert the grade
				INSERT INTO dbo.BhpbioPortBalanceGrade
				(
					BhpbioPortBalanceId, GradeId, GradeValue
				)
				SELECT @iBhpbioPortBalanceId, @iGradeId, @iGradeValue
			END
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

GRANT EXECUTE ON dbo.AddOrUpdateBhpbioPortBalanceGrade TO BhpbioGenericManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.AddOrUpdateBhpbioPortBalanceGrade">
 <Procedure>
	Adds or updates port balance grade.
 </Procedure>
</TAG>
*/
