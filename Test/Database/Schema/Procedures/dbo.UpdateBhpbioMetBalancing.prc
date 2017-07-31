IF OBJECT_ID('dbo.UpdateBhpbioMetBalancing') IS NOT NULL
     DROP PROCEDURE dbo.UpdateBhpbioMetBalancing
GO 
  
CREATE PROCEDURE dbo.UpdateBhpbioMetBalancing
(
	@iBhpbioMetBalancingId INT,
	@iStartDate DATETIME,
	@iEndDate DATETIME,
	@iWeightometer VARCHAR(31),
	@iDryTonnes FLOAT,
	@iWetTonnes FLOAT,
	@iSplitCycle FLOAT,
	@iSplitPlant FLOAT,
	@iProductSize VARCHAR(5),
	@iGrades XML = NULL
)
WITH ENCRYPTION
AS
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'UpdateBhpbioMetBalancing',
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
		-- add the base record
		UPDATE dbo.BhpbioMetBalancing
		SET StartDate = @iStartDate,
			EndDate = @iEndDate,
			Weightometer = @iWeightometer,
			DryTonnes = @iDryTonnes,
			WetTonnes = @iWetTonnes,
			SplitCycle = @iSplitCycle,
			SplitPlant = @iSplitPlant,
			ProductSize = @iProductSize
		WHERE BhpbioMetBalancingId = @iBhpbioMetBalancingId
			
		-- refresh the grade records
		IF @iGrades IS NOT NULL
		BEGIN
			DELETE
			FROM dbo.BhpbioMetBalancingGrade
			WHERE GradeId NOT IN
				(
					SELECT Grade_Id
					FROM dbo.Grade AS g
						INNER JOIN @iGrades.nodes('/Grades/Grade') AS Grades(Grade)
							ON (g.Grade_Name = Grades.Grade.value('./@Name', 'VARCHAR(31)'))
				)
				AND BhpbioMetBalancingId = @iBhpbioMetBalancingId	
				
			UPDATE mbg
			SET GradeValue = 
				(
					SELECT Grades.Grade.value('./@Value', 'REAL')
					FROM dbo.Grade AS g
						INNER JOIN @iGrades.nodes('/Grades/Grade') AS Grades(Grade)
							ON (g.Grade_Name = Grades.Grade.value('./@Name', 'VARCHAR(31)'))
					WHERE g.Grade_Id = mbg.GradeId
				)
			FROM dbo.BhpbioMetBalancingGrade AS mbg
			WHERE BhpbioMetBalancingId = @iBhpbioMetBalancingId	

			INSERT INTO dbo.BhpbioMetBalancingGrade
			(
				BhpbioMetBalancingId, GradeId, GradeValue
			)
			SELECT @iBhpbioMetBalancingId, g.Grade_Id, Grades.Grade.value('./@Value', 'REAL')
			FROM @iGrades.nodes('/Grades/Grade') AS Grades(Grade)
				INNER JOIN dbo.Grade AS g
					ON (g.Grade_Name = Grades.Grade.value('./@Name', 'VARCHAR(31)'))
			WHERE g.Grade_Id NOT IN
				(
					SELECT GradeId
					FROM dbo.BhpbioMetBalancingGrade
					WHERE BhpbioMetBalancingId = @iBhpbioMetBalancingId
				)
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

GRANT EXECUTE ON dbo.UpdateBhpbioMetBalancing TO BhpbioGenericManager
GO
