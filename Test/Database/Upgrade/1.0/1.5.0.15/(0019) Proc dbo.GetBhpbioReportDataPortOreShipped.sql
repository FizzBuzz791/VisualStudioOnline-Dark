IF OBJECT_ID('dbo.GetBhpbioReportDataPortOreShipped') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportDataPortOreShipped 
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReportDataPortOreShipped
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

	--DECLARE @Location TABLE
	CREATE TABLE #Location
	(
		LocationId INT NOT NULL,
		ParentLocationId INT NULL,
		IncludeStart DATETIME,
		IncludeEnd DATETIME--,
		PRIMARY KEY (LocationId, IncludeStart,IncludeEnd)
	)
	CREATE INDEX tmpLocIX1 ON #Location(ParentLocationID)
	
	DECLARE @OutputTonnes TABLE
	(
		CalendarDate DATETIME,
		DateFrom DATETIME,
		DateTo DATETIME,
		LocationId INTEGER,
		Tonnes FLOAT
	)
	
	DECLARE @OutputGrades TABLE
	(
		CalendarDate DATETIME,
		LocationId INTEGER,
		GradeId INTEGER,
		GradeValue FLOAT,
		Tonnes FLOAT
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioReportDataPortOreShipped',
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
		INSERT INTO #Location
			(LocationId, ParentLocationId, IncludeStart, IncludeEnd)
		SELECT LocationId, ParentLocationId, IncludeStart, IncludeEnd
		FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, @iChildLocations, NULL, @iDateFrom, @iDateTo)

		IF @iChildLocations = 1
		BEGIN
			INSERT INTO #Location (LocationId, ParentLocationId, IncludeStart, IncludeEnd)
			SELECT @iLocationId, @iLocationId, IncludeStart, IncludeEnd
			FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 0, 
					(	SELECT	LT.Description
						FROM	LocationType LT INNER JOIN Location L on LT.Location_Type_Id = L.Location_Type_Id
						WHERE	L.Location_Id = @iLocationId)
					, @iDateFrom, @iDateTo)
		END
		
		IF @iIncludeLiveData = 1
		BEGIN
	
			-- Obtain the Shipping tonnes
			INSERT INTO @OutputTonnes
			(
				CalendarDate,
				DateFrom,
				DateTo,
				LocationId,
				Tonnes
			)
			SELECT B.CalendarDate, B.DateFrom, B.DateTo,
				L.ParentLocationId, SUM(S.Tonnes) AS Tonnes
			FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
				INNER JOIN dbo.BhpbioShippingTransactionNomination AS S
					ON (S.OfficialFinishTime >= B.DateFrom
						AND S.OfficialFinishTime <= DateAdd(Second, 59, DateAdd(Minute, 59, DateAdd(Hour, 23, B.DateTo))))
				INNER JOIN #Location AS L
					ON (S.HubLocationId = L.LocationId
					AND S.OfficialFinishTime BETWEEN L.IncludeStart AND DateAdd(Second, 59, DateAdd(Minute, 59, DateAdd(Hour, 23, L.IncludeEnd))))
				-- this join is used to test whether there is an approval associated with this data
				LEFT JOIN dbo.BhpbioApprovalData bad
					ON bad.TagId = 'F3OreShipped'
					AND bad.LocationId = S.HubLocationId
					AND bad.ApprovedMonth = dbo.GetDateMonth(S.OfficialFinishTime)
					AND bad.ApprovedMonth BETWEEN L.IncludeStart ANd L.IncludeEnd
			WHERE ( @iIncludeApprovedData = 0
					OR bad.TagId IS NULL)		
					-- where approved data is not being included OR there is no associated approval
			GROUP BY B.CalendarDate, B.DateFrom, B.DateTo, L.ParentLocationId
			
			-- Obtain the Shipping Grades
			INSERT INTO @OutputGrades
			(
				CalendarDate,
				LocationId,
				GradeId,
				GradeValue,
				Tonnes
			)
			SELECT B.CalendarDate, L.ParentLocationId, G.Grade_Id AS GradeId,
				 Coalesce(SUM(SG.GradeValue * S.Tonnes) / NullIf(SUM(Tonnes), 0), 0) AS GradeValue,
				 SUM(Tonnes)
			FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
				INNER JOIN dbo.BhpbioShippingTransactionNomination AS S
					ON (S.OfficialFinishTime >= B.DateFrom
						AND S.OfficialFinishTime <= DateAdd(Second, 59, DateAdd(Minute, 59, DateAdd(Hour, 23, B.DateTo))))
				INNER JOIN #Location AS L
					ON (S.HubLocationId = L.LocationId
						AND S.OfficialFinishTime BETWEEN L.IncludeStart AND DateAdd(Second, 59, DateAdd(Minute, 59, DateAdd(Hour, 23, L.IncludeEnd))))

				CROSS JOIN dbo.Grade AS G
				LEFT JOIN dbo.BhpbioShippingTransactionNominationGrade AS SG
					ON (S.BhpbioShippingTransactionNominationId = SG.BhpbioShippingTransactionNominationId
						AND G.Grade_Id = SG.GradeId)
				LEFT JOIN dbo.BhpbioApprovalData bad
					ON bad.TagId = 'F3OreShipped'
					AND bad.LocationId = S.HubLocationId
					AND bad.ApprovedMonth = dbo.GetDateMonth(S.OfficialFinishTime)
					AND bad.ApprovedMonth BETWEEN L.IncludeStart ANd L.IncludeEnd
			WHERE ( 
					@iIncludeApprovedData = 0
					OR 
					bad.TagId IS NULL
				)		
			GROUP BY B.CalendarDate, G.Grade_Id, L.ParentLocationId
		END
		
		IF @iIncludeApprovedData = 1
		BEGIN
			DECLARE @summaryEntryType VARCHAR(24)
			SET @summaryEntryType = 'ShippingTransaction'
			
			-- Retrieve Tonnes
			INSERT INTO @OutputTonnes
			(
				CalendarDate,
				DateFrom,
				DateTo,
				LocationId,
				Tonnes
			)
			SELECT s.CalendarDate, s.DateFrom, s.DateTo, l.ParentLocationId, s.Tonnes
			FROM dbo.GetBhpbioSummaryTonnesBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryType, 1) s
				INNER JOIN #Location l
					ON l.LocationId = s.LocationId
					AND s.CalendarDate BETWEEN l.IncludeStart AND l.IncludeEnd
			
			-- Retrieve Grades
			INSERT INTO @OutputGrades
			(
				CalendarDate,
				LocationId,
				GradeId,
				GradeValue,
				Tonnes
			)
			SELECT s.CalendarDate,  l.ParentLocationId, s.GradeId,  s.GradeValue, s.Tonnes
			FROM dbo.GetBhpbioSummaryGradeBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryType, 1, 1, 0) s
				INNER JOIN #Location l
					ON l.LocationId = s.LocationId
					AND s.CalendarDate BETWEEN l.IncludeStart AND l.IncludeEnd
		END
		
		-- output the tonnes
		SELECT o.CalendarDate, o.DateFrom, o.DateTo, NULL AS MaterialTypeId,
				o.LocationId AS ParentLocationId, SUM(o.Tonnes) AS Tonnes
		FROM @OutputTonnes o
		GROUP BY o.CalendarDate, o.DateFrom, o.DateTo, o.LocationId
			
		-- output the grades
		SELECT o.CalendarDate, g.Grade_Name AS GradeName, o.GradeId, NULL AS MaterialTypeId,
				o.LocationId AS ParentLocationId, Coalesce(SUM(o.GradeValue * o.Tonnes) / NullIf(SUM(o.Tonnes), 0), 0) AS GradeValue
		FROM @OutputGrades o
			INNER JOIN dbo.Grade g
				ON g.Grade_Id = o.GradeId
		GROUP BY o.CalendarDate, g.Grade_Name, o.LocationId, o.GradeId
			
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

GRANT EXECUTE ON dbo.GetBhpbioReportDataPortOreShipped TO BhpbioGenericManager
GO

/*
use reconcilorBHPBIO_Prod_20120906 
EXEC dbo.GetBhpbioReportDataPortOreShipped
	@iDateFrom = '1-JUL-2012', 
	@iDateTo = '31-JUL-2012', 
	@iDateBreakdown = 'MONTH',
	@iLocationId = 8,
	@iChildLocations = 0, @iIncludeLiveData=1, @iIncludeApprovedData=1
*/