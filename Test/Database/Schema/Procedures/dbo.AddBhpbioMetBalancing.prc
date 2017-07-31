IF OBJECT_ID('dbo.AddBhpbioMetBalancing') IS NOT NULL
     DROP PROCEDURE dbo.AddBhpbioMetBalancing
GO 
  
CREATE PROCEDURE dbo.AddBhpbioMetBalancing
(
	@iSiteCode VARCHAR(7),
	@iCalendarDate DATETIME,
	@iStartDate DATETIME,
	@iEndDate DATETIME,
	@iPlantName VARCHAR(31),
	@iStreamName VARCHAR(31),
	@iWeightometer VARCHAR(31),
	@iDryTonnes FLOAT,
	@iWetTonnes FLOAT,
	@iSplitCycle FLOAT,
	@iSplitPlant FLOAT,
	@iProductSize VARCHAR(5),
	@iGrades XML = NULL,
	@oBhpbioMetBalancingId INT OUTPUT
)
WITH ENCRYPTION
AS
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @BhpbioMetBalancingId INT

	SET NOCOUNT ON 

	SELECT @TransactionName = 'AddBhpbioMetBalancing',
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
		INSERT INTO dbo.BhpbioMetBalancing
		(
			SiteCode, CalendarDate, StartDate, EndDate, PlantName, StreamName, Weightometer,
			DryTonnes, WetTonnes, SplitCycle, SplitPlant, ProductSize
		)
		VALUES
		(
			@iSiteCode, @iCalendarDate, @iStartDate, @iEndDate, @iPlantName, @iStreamName, @iWeightometer,
			@iDryTonnes, @iWetTonnes, @iSplitCycle, @iSplitPlant, @iProductSize
		)
			
		SET @BhpbioMetBalancingId = Scope_Identity()

		-- add the grade records
		IF @iGrades IS NOT NULL
		BEGIN
			INSERT INTO dbo.BhpbioMetBalancingGrade
			(
				BhpbioMetBalancingId, GradeId, GradeValue
			)
			SELECT @BhpbioMetBalancingId,
				(
					SELECT Grade_Id
					FROM dbo.Grade
					WHERE Grade_Name = Grades.Grade.value('./@Name', 'VARCHAR(31)')
				),
				Grades.Grade.value('./@Value', 'REAL')
			FROM @iGrades.nodes('/Grades/Grade') AS Grades(Grade)
		END

		-- Add to the CVF queue
		EXEC dbo.CalcVirtualFlowRaise @iCalendarDate

		-- return the id generated
		SET @oBhpbioMetBalancingId = @BhpbioMetBalancingId

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

GRANT EXECUTE ON dbo.AddBhpbioMetBalancing TO BhpbioGenericManager
GO
