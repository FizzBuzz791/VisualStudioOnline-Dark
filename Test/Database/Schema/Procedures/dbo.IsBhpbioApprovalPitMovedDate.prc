IF OBJECT_ID('dbo.IsBhpbioApprovalPitMovedDate') IS NOT NULL
     DROP PROCEDURE dbo.IsBhpbioApprovalPitMovedDate  
GO 
  
CREATE PROCEDURE dbo.IsBhpbioApprovalPitMovedDate 
(
	@iLocationId INT,
	@iMonth DATETIME,
	@oMovementsExist BIT OUTPUT
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	
	DECLARE @ReturnValue BIT
	DECLARE @MonthDate DATETIME
	DECLARE @EndMonthDate DATETIME
	
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		PRIMARY KEY (LocationId)
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'IsBhpbioApprovalPitMovedDate',
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

		-- If the location/pit has movements
		IF EXISTS	(
					SELECT d.Digblock_Id
					FROM dbo.Digblock AS D
						INNER JOIN dbo.DigblockLocation AS DL
							ON (D.Digblock_Id = DL.Digblock_Id)
						INNER JOIN @Location AS L
							ON (L.LocationId = DL.Location_Id)
						INNER JOIN dbo.BhpbioImportReconciliationMovement AS RM
							ON (RM.DateFrom >= @MonthDate
								AND RM.DateTo <= @EndMonthDate
								AND DL.Location_Id = RM.BlockLocationId)
					)
		BEGIN
			SET @ReturnValue = 1
		END
		ELSE
		BEGIN
			SET @ReturnValue = 0
		END

		SET @oMovementsExist = @ReturnValue

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

GRANT EXECUTE ON dbo.IsBhpbioApprovalPitMovedDate TO BhpbioGenericManager
GO

/*
DECLARE @TEST BIT
exec dbo.IsBhpbioApprovalPitMovedDate 2615, '1-jan-2008', @TEST OUTPUT
SELECT @TEST
*/