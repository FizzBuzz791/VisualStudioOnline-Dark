IF OBJECT_ID('dbo.IsBhpbioApprovalBlockLocationDate') IS NOT NULL
     DROP PROCEDURE dbo.IsBhpbioApprovalBlockLocationDate  
GO 
  
CREATE PROCEDURE dbo.IsBhpbioApprovalBlockLocationDate 
(
	@iLocationId INT,
	@iMonth DATETIME,
	@oApproved BIT OUTPUT
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	
	DECLARE @ReturnValue BIT
	DECLARE @MonthDate DATETIME
	DECLARE @EndMonthDate DATETIME

	DECLARE @Results TABLE
	(
		DigblockId VARCHAR(31) COLLATE DATABASE_DEFAULT NULL,
		Approved BIT NULL
	)
	
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		PRIMARY KEY (LocationId)
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'IsBhpbioApprovalBlockLocationDate',
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
		SET @MonthDate = dbo.GetDateMonth(@iMonth)
		SET @EndMonthDate = DateAdd(Day, -1, DateAdd(Month, 1, @MonthDate))

		INSERT INTO @Location
		SELECT LocationId
		FROM dbo.GetBhpbioReportLocationWithOverride(@iLocationId, @MonthDate, @EndMonthDate)

		INSERT INTO @Results
			(
				DigblockId, Approved
			)
		SELECT d.Digblock_Id, CASE WHEN a.DigblockId IS NOT NULL THEN 1 ELSE 0 END
		FROM dbo.Digblock AS D
			INNER JOIN dbo.DigblockLocation AS DL
				ON (D.Digblock_Id = DL.Digblock_Id)
			INNER JOIN @Location AS L
				ON (L.LocationId = DL.Location_Id)
			INNER JOIN dbo.BhpbioImportReconciliationMovement AS RM
				ON (RM.DateFrom >= @MonthDate
					AND RM.DateTo <= @EndMonthDate
					AND DL.Location_Id = RM.BlockLocationId)
			LEFT JOIN dbo.BhpbioApprovalDigblock AS a
				ON d.Digblock_Id = a.DigblockId
					AND @MonthDate = a.ApprovedMonth

		-- If the block has been approved for on the month, return true
		IF EXISTS	(
					SELECT TOP 1 1
					FROM @Results
					WHERE Approved = 1
					)
		BEGIN
			SET @ReturnValue = 1
		END
		ELSE
		BEGIN
			SET @ReturnValue = 0
		END

		SET @oApproved = @ReturnValue

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

GRANT EXECUTE ON dbo.IsBhpbioApprovalBlockLocationDate TO BhpbioGenericManager
GO

/*
DECLARE @TEST BIT
exec dbo.IsBhpbioApprovalBlockLocationDate 2615, '1-jan-2008', @TEST OUTPUT
SELECT @TEST
*/