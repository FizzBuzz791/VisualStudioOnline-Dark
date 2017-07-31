IF OBJECT_ID('dbo.AddUpdateDeleteBhpbioPortBlendingGrade') IS NOT NULL
	DROP PROCEDURE dbo.AddUpdateDeleteBhpbioPortBlendingGrade
GO

CREATE PROCEDURE dbo.AddUpdateDeleteBhpbioPortBlendingGrade
(
	@iBhpbioPortBlendingId INT,
	@iGradeId SMALLINT,
	@iGradeValue REAL
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'dbo.AddUpdateDeleteBhpbioPortBlendingGrade',
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
		IF @iGradeValue IS NULL
		BEGIN
			-- Delete the grade
			DELETE
			FROM dbo.BhpbioPortBlendingGrade
			WHERE GradeId = @iGradeId
				AND BhpbioPortBlendingId = @iBhpbioPortBlendingId
		END
		ELSE IF EXISTS
			(
				SELECT 1
				FROM dbo.BhpbioPortBlendingGrade
				WHERE GradeId = @iGradeId
					AND BhpbioPortBlendingId = @iBhpbioPortBlendingId
			)
		BEGIN
			-- Update the grade
			UPDATE dbo.BhpbioPortBlendingGrade
			SET GradeValue = @iGradeValue
			WHERE GradeId = @iGradeId
				AND BhpbioPortBlendingId = @iBhpbioPortBlendingId
		END
		ELSE
		BEGIN
			-- Insert the grade
			INSERT INTO dbo.BhpbioPortBlendingGrade
				(BhpbioPortBlendingId, GradeId, GradeValue)
			VALUES
				(@iBhpbioPortBlendingId, @iGradeId, @iGradeValue)
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

GRANT EXECUTE ON dbo.AddUpdateDeleteBhpbioPortBlendingGrade TO BhpbioGenericManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.AddUpdateDeleteBhpbioPortBlendingGrade">
 <Procedure>
	Adds, updates and deletes transaction nomination grades.
 </Procedure>
</TAG>
*/
