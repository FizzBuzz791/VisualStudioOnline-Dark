 IF OBJECT_ID('dbo.GetBhpbioPortBalance') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioPortBalance
GO 
  
CREATE PROCEDURE dbo.GetBhpbioPortBalance
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iLocationId INT
)
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioPortBalance',
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
	
		--For Grade Pivoting
		CREATE TABLE dbo.#RecordGrade
		(
			BhpbioPortBalanceId INT NOT NULL,
			GradeName  VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
			GradeValue Real Null,
			
			PRIMARY KEY (BhpbioPortBalanceId, GradeName)
		)
		
		--Main Result SET
		CREATE TABLE dbo.#Record
		(
			BhpbioPortBalanceId INT NOT NULL,
			HubLocationId INT NOT NULL,
			BalanceDate DATETIME NOT NULL,
			Tonnes FLOAT NOT NULL,
			ProductSize VARCHAR(5) NULL,
			HubLocationName VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
			
			PRIMARY KEY (BhpbioPortBalanceId)
		)	

		
		INSERT INTO dbo.#Record
		(
			BhpbioPortBalanceId, HubLocationId, BalanceDate, Tonnes, ProductSize, HubLocationName
		)
		SELECT bpb.BhpbioPortBalanceId, bpb.HubLocationId, bpb.BalanceDate, bpb.Tonnes, bpb.ProductSize, l.Name AS HubLocationName
		FROM dbo.BhpbioPortBalance AS bpb
			INNER JOIN dbo.Location AS l
				ON (bpb.HubLocationId = l.Location_Id)
		WHERE bpb.BalanceDate >= ISNULL(@iDateFrom, bpb.BalanceDate)
			AND bpb.BalanceDate <= ISNULL(@iDateTo, bpb.BalanceDate)
			AND bpb.HubLocationId IN
				(
					SELECT rl.LocationId
					FROM dbo.GetBhpbioReportLocation(@iLocationId) AS rl
				)
		
		
		INSERT INTO dbo.#RecordGrade
		(
			BhpbioPortBalanceId, GradeName,	GradeValue
		)
		SELECT r.BhpbioPortBalanceId, G.Grade_Name, bpbg.GradeValue
		FROM dbo.#Record AS r
			INNER JOIN dbo.BhpbioPortBalanceGrade AS bpbg
				ON r.BhpbioPortBalanceId = bpbg.BhpbioPortBalanceId
			INNER JOIN dbo.Grade AS g
				ON bpbg.GradeId = g.Grade_Id
		UNION ALL	
		--Dummy Grade Values Ensure All Grade are Pivoted
		SELECT -1 AS BhpbioPortBalanceId, G.Grade_Name, Null AS Grade_Value
		FROM dbo.Grade AS G
		WHERE G.Is_Visible = 1 

	
		--Pivot Grades Onto Main table
		EXEC dbo.PivotTable
			@iTargetTable='#Record',
			@iPivotTable='#RecordGrade',
			@iJoinColumns='#Record.BhpbioPortBalanceId = #RecordGrade.BhpbioPortBalanceId',
			@iPivotColumn='GradeName',
			@iPivotValue='GradeValue',
			@iPivotType='REAL'		
	
		-- output port balancing information
		SELECT *
		FROM #Record
		
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

GRANT EXECUTE ON dbo.GetBhpbioPortBalance TO BhpbioGenericManager
GO

