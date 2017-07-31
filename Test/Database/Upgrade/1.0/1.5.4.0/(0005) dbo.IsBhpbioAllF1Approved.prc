IF OBJECT_ID('dbo.IsBhpbioAllF1Approved') IS NOT NULL
     DROP PROCEDURE dbo.IsBhpbioAllF1Approved  
GO 
  
CREATE PROCEDURE dbo.IsBhpbioAllF1Approved
(
	@iLocationId INT,
	@iMonth DATETIME,
	@oAllApproved BIT OUTPUT
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	
	DECLARE @ReturnValue BIT
	DECLARE @MonthDate DATETIME
	DECLARE @EndMonthDate DATETIME
	DECLARE @PitLocationTypeId TinyInt
	
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		PRIMARY KEY (LocationId)
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'IsBhpbioAllF1Approved',
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
		SET @PitLocationTypeId = (SELECT Location_Type_Id FROM LocationType WHERE Description = 'Pit')
		
		INSERT INTO @Location
		SELECT LocationId
		FROM dbo.GetBhpbioReportLocationWithOverride(@iLocationId, @MonthDate, @EndMonthDate)
							
		-- If the block has been approved for on the month, return true
		IF EXISTS	(
					SELECT *
					FROM (
							SELECT distinct dbo.GetLocationTypeLocationId(L.LocationId, @PitLocationTypeId) AS PitLocation
							FROM dbo.Digblock AS D
								INNER JOIN dbo.DigblockLocation AS DL
									ON (D.Digblock_Id = DL.Digblock_Id)
								INNER JOIN @Location AS L
									ON (L.LocationId = DL.Location_Id)
								INNER JOIN dbo.BhpbioImportReconciliationMovement AS RM
									ON (RM.DateFrom >= @MonthDate
										AND RM.DateTo <= @EndMonthDate
										AND DL.Location_Id = RM.BlockLocationId)
							) P
						CROSS JOIN (
							SELECT BRDT.TagId 
							FROM dbo.BhpbioReportDataTags BRDT 
							WHERE TagGroupId = 'F1Factor'
						) As T
						LEFT JOIN dbo.BhpbioApprovalData AS BAD
							ON (P.PitLocation = BAD.LocationId
								AND BAD.ApprovedMonth = @MonthDate
								AND BAD.TagId = T.TagId)
					WHERE BAD.TagId Is Null
					)
		BEGIN
			SET @ReturnValue = 0
		END
		ELSE
		BEGIN
			SET @ReturnValue = 1
		END

		SET @oAllApproved = @ReturnValue

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

GRANT EXECUTE ON dbo.IsBhpbioAllF1Approved TO BhpbioGenericManager
GO

/*
DECLARE @TEST BIT
exec dbo.IsBhpbioAllF1Approved 3, '1-nov-2009', @TEST OUTPUT
SELECT @TEST
*/