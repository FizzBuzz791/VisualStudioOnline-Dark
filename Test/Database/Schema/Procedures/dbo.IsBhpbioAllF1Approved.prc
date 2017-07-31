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
	
	DECLARE @PitLocation TABLE
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
		
		INSERT INTO @PitLocation
		SELECT LocationId
		FROM dbo.GetBhpbioReportLocationWithOverride(@iLocationId, @MonthDate, @EndMonthDate) lwo
			-- join the main location table... all locations (even those with overrides) exist in the main location table and the location type is not something that can change
			INNER JOIN Location loc ON loc.Location_Id = lwo.LocationId
		WHERE loc.Location_Type_Id = @PitLocationTypeId
						
		-- If a pit exists that is missing an approval for the month, return true
		IF EXISTS	(
					SELECT *
					FROM @PitLocation l
						-- join across to find the matching F1Factor approval
						LEFT JOIN dbo.BhpbioApprovalData AS BAD
							ON (l.LocationId = BAD.LocationId
								-- just check the F1Factor itself... as now, all F1 components must be approved before F1Factor is approved
								-- with the exception of Lump and Fines which are only required beyond the cutoff date
								-- the requirements above are managed through Approval validation...here just the main factor is checked
								AND BAD.TagId = 'F1Factor' 
								AND BAD.ApprovedMonth = @MonthDate
								)
					WHERE BAD.TagId Is Null -- meaning that there is no joined approval record
					)
		BEGIN
			-- there is at least one approval missing
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