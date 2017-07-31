IF OBJECT_ID('dbo.GetBhpbioReportDataPortStockpileDelta') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportDataPortStockpileDelta 
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReportDataPortStockpileDelta
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iChildLocations BIT,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		ParentLocationId INT NULL,
		IncludeStart DATETIME,
		IncludeEnd DATETIME,
		PRIMARY KEY (LocationId, IncludeStart, IncludeEnd)
	)
	
	DECLARE @PortDelta TABLE
	(
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		ParentLocationId INT NULL,
		LastBalanceDate DATETIME NULL,
		Tonnes FLOAT NULL,
		LastTonnes FLOAT NULL
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioReportDataPortStockpileDelta',
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
		-- Determine Locations of interest
		INSERT	INTO @Location (LocationId, ParentLocationId, IncludeStart, IncludeEnd)
		SELECT	L.LocationId, L.ParentLocationId, L.IncludeStart, L.IncludeEnd
		FROM	dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, @iChildLocations, NULL, @iDateFrom, @iDateTo) L
		-- Filter out any HubExclusionFilters 
		LEFT    JOIN GetBhpbioExcludeHubLocation('PortBalance') AS HXF ON L.LocationId = HXF.LocationId
		WHERE	HXF.LocationId IS NULL
		
		IF @iIncludeLiveData = 1
		BEGIN
			INSERT INTO @PortDelta
				(CalendarDate, DateFrom, DateTo, ParentLocationId, LastBalanceDate, Tonnes, LastTonnes)
			SELECT B.CalendarDate, B.DateFrom, B.DateTo, L.ParentLocationId, BPBPREV.BalanceDate, Sum(BPB.Tonnes), Sum(BPBPREV.Tonnes)
			FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
				INNER JOIN dbo.BhpbioPortBalance AS BPB
					ON (BPB.BalanceDate = B.DateTo)
				INNER JOIN @Location AS L
					ON (BPB.HubLocationId = L.LocationId)
					AND BPB.BalanceDate BETWEEN L.IncludeStart AND L.IncludeEnd
				LEFT JOIN dbo.BhpbioPortBalance AS BPBPREV
					ON (BPBPREV.BalanceDate = DateAdd(Day, -1, B.DateFrom)
						And BPB.HubLocationId = BPBPREV.HubLocationId)
				-- this join is used to test whether there is an approval associated with this data
				LEFT JOIN dbo.BhpbioApprovalData bad
					ON bad.TagId = 'F3PortStockpileDelta'
					AND bad.LocationId = BPB.HubLocationId
					AND bad.ApprovedMonth = dbo.GetDateMonth(BPB.BalanceDate)
					AND bad.ApprovedMonth BETWEEN L.IncludeStart AND L.IncludeEnd
			WHERE (@iIncludeApprovedData = 0 OR bad.TagId IS NULL)
			-- where Approved data is not being included in this call OR where there is no associated approval
			GROUP BY B.CalendarDate, B.DateFrom, B.DateTo, BPBPREV.BalanceDate, L.ParentLocationId
		END

		IF @iIncludeApprovedData = 1
		BEGIN
			DECLARE @summaryEntryType VARCHAR(24)
			SET @summaryEntryType = 'PortStockpileDelta'
			
			-- Retrieve Tonnes
			INSERT INTO @PortDelta
				(CalendarDate, DateFrom, DateTo, ParentLocationId, LastBalanceDate, Tonnes, LastTonnes)
			SELECT s.CalendarDate, s.DateFrom, s.DateTo, l.ParentLocationId, NULL, s.Tonnes, 0
			FROM dbo.GetBhpbioSummaryTonnesBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryType, 1) s
				INNER JOIN @Location l
					ON l.LocationId = s.LocationId
					AND s.CalendarDate BETWEEN l.IncludeStart AND l.IncludeEnd
		END
		
		SELECT CalendarDate, DateFrom, DateTo, NULL As MaterialTypeId, ParentLocationId,
			Coalesce(Tonnes - LastTonnes, 0) AS Tonnes
		FROM @PortDelta		
		
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

GRANT EXECUTE ON dbo.GetBhpbioReportDataPortStockpileDelta TO BhpbioGenericManager
GRANT EXECUTE ON dbo.GetBhpbioReportDataPortStockpileDelta TO BhpbioGenericManager
GO

/*
EXEC dbo.GetBhpbioReportDataPortStockpileDelta
	@iDateFrom = '1-SEP-2012', 
	@iDateTo = '30-SEP-2012', 
	@iDateBreakdown = 'MONTH',
	@iLocationId = 6,
	@iChildLocations = 0,
	@iIncludeLiveData = 01,
	@iIncludeApprovedData = 0
*/
