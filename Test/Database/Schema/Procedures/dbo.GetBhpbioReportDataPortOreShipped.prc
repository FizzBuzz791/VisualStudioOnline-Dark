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
		IncludeEnd DATETIME,
		PRIMARY KEY (LocationId, IncludeStart,IncludeEnd)
	)
	CREATE INDEX tmpLocIX1 ON #Location(ParentLocationID)
	
	DECLARE @OutputTonnes TABLE
	(
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		LocationId INTEGER,
		ProductSize VARCHAR(5) NOT NULL,
		Tonnes FLOAT
	)
	
	DECLARE @OutputGrades TABLE
	(
		CalendarDate DATETIME NOT NULL,
		LocationId INTEGER,
		GradeId INTEGER NOT NULL,
		GradeValue FLOAT,
		ProductSize VARCHAR(5) NOT NULL,
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
		--Get locations of interest 
		INSERT INTO #Location
			(LocationId, ParentLocationId, IncludeStart, IncludeEnd)
		SELECT L.LocationId, L.ParentLocationId, L.IncludeStart, L.IncludeEnd
		FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, @iChildLocations, 'SITE', @iDateFrom, @iDateTo) L
		-- Filter out any HubExclusionFilters
		LEFT JOIN GetBhpbioExcludeHubLocation('ShippingTransaction') AS HXF ON L.LocationId = HXF.LocationId
		WHERE HXF.LocationId IS NULL

		IF @iChildLocations = 1
		BEGIN
			INSERT INTO #Location (LocationId, ParentLocationId, IncludeStart, IncludeEnd)
			SELECT @iLocationId, @iLocationId, Loc.IncludeStart, Loc.IncludeEnd
			FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 0, 
					(	SELECT	LT.Description
						FROM	LocationType LT INNER JOIN Location L on LT.Location_Type_Id = L.Location_Type_Id
						WHERE	L.Location_Id = @iLocationId)
					, @iDateFrom, @iDateTo) Loc
			-- Filter out any HubExclusionFilters
			LEFT JOIN GetBhpbioExcludeHubLocation('ShippingTransaction') AS HXF ON Loc.LocationId = HXF.LocationId
			WHERE HXF.LocationId IS NULL
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
				ProductSize,
				Tonnes
			)
			SELECT B.CalendarDate, B.DateFrom, B.DateTo,
				L.ParentLocationId, 
				ISNULL(S.ShippedProductSize, defaultlf.ProductSize),
				SUM(ISNULL(defaultlf.[Percent], 1) * SNP.Tonnes) AS Tonnes
			FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
				INNER JOIN dbo.BhpbioShippingNominationItem AS S
					ON (S.OfficialFinishTime >= B.DateFrom
						AND S.OfficialFinishTime <= DateAdd(Second, 59, DateAdd(Minute, 59, DateAdd(Hour, 23, B.DateTo))))
				INNER JOIN dbo.BhpbioShippingNominationItemParcel AS SNP
					ON (S.BhpbioShippingNominationItemId = SNP.BhpbioShippingNominationItemId)
				INNER JOIN #Location AS L
					ON (SNP.HubLocationId = L.LocationId
					AND S.OfficialFinishTime BETWEEN L.IncludeStart AND DateAdd(Second, 59, DateAdd(Minute, 59, DateAdd(Hour, 23, L.IncludeEnd))))
				LEFT JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf
					ON S.ShippedProductSize IS NULL
					AND SNP.HubLocationId = defaultlf.LocationId
					AND S.OfficialFinishTime BETWEEN defaultlf.StartDate AND defaultlf.EndDate
				-- this join is used to test whether there is an approval associated with this data
				LEFT JOIN dbo.BhpbioApprovalData bad
					ON bad.TagId = 'F3OreShipped'
					AND bad.LocationId = SNP.HubLocationId
					AND bad.ApprovedMonth = dbo.GetDateMonth(S.OfficialFinishTime)
					AND bad.ApprovedMonth BETWEEN L.IncludeStart ANd L.IncludeEnd
			-- where approved data is not being included OR there is no associated approval
			WHERE ( @iIncludeApprovedData = 0
					OR bad.TagId IS NULL)	
			AND	(ISNULL(defaultlf.[Percent], 1) > 0)
			GROUP BY B.CalendarDate, B.DateFrom, B.DateTo, L.ParentLocationId, ISNULL(S.ShippedProductSize, defaultlf.ProductSize)
			
			-- roll up lump/fines tonnes for total
			INSERT INTO @OutputTonnes
			(
				CalendarDate,
				DateFrom,
				DateTo,
				LocationId,
				ProductSize,
				Tonnes
			)
			SELECT CalendarDate, DateFrom, DateTo, LocationId, 'TOTAL', SUM(Tonnes)
			FROM @OutputTonnes
			GROUP BY CalendarDate, DateFrom, DateTo, LocationId
			
			-- Obtain the Shipping Grades
			INSERT INTO @OutputGrades
			(
				CalendarDate,
				LocationId,
				ProductSize,
				GradeId,
				GradeValue,
				Tonnes
			)
			SELECT B.CalendarDate, L.ParentLocationId, 
				ISNULL(S.ShippedProductSize, defaultlf.ProductSize),
				G.Grade_Id AS GradeId,
				CASE 
						WHEN G.Grade_Name = 'Ultrafines' AND ISNULL(S.ShippedProductSize, defaultlf.ProductSize) = 'FINES' THEN Coalesce(SUM(S.Undersize * SNP.Tonnes) / SUM(SNP.Tonnes), 0)
						ELSE Coalesce(SUM(SG.GradeValue * ISNULL(defaultlf.[Percent], 1) * SNP.Tonnes) / NullIf(SUM(ISNULL(defaultlf.[Percent], 1) * SNP.Tonnes), 0), 0)
					END AS GradeValue,
				SUM(ISNULL(defaultlf.[Percent], 1) * SNP.Tonnes) AS Tonnes
			
			FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
				INNER JOIN dbo.BhpbioShippingNominationItem AS S 
					ON S.OfficialFinishTime >= B.DateFrom
						AND S.OfficialFinishTime <= DateAdd(Second, 59, DateAdd(Minute, 59, DateAdd(Hour, 23, B.DateTo)))
				INNER JOIN dbo.BhpbioShippingNominationItemParcel AS SNP 
					ON S.BhpbioShippingNominationItemId = SNP.BhpbioShippingNominationItemId
				INNER JOIN #Location AS L 
					ON SNP.HubLocationId = L.LocationId
						AND S.OfficialFinishTime BETWEEN L.IncludeStart AND DateAdd(Second, 59, DateAdd(Minute, 59, DateAdd(Hour, 23, L.IncludeEnd)))
				CROSS JOIN dbo.Grade AS G
				LEFT OUTER JOIN dbo.BhpbioShippingNominationItemParcelGrade AS SG 
					ON SNP.BhpbioShippingNominationItemParcelId = SG.BhpbioShippingNominationItemParcelId
						AND G.Grade_Id = SG.GradeId
				LEFT JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf 
					ON S.ShippedProductSize IS NULL
						AND SNP.HubLocationId = defaultlf.LocationId 
						AND S.OfficialFinishTime BETWEEN defaultlf.StartDate AND defaultlf.EndDate
				LEFT JOIN dbo.BhpbioApprovalData bad 
					ON bad.TagId = 'F3OreShipped' 
						AND bad.LocationId = SNP.HubLocationId
						AND	bad.ApprovedMonth = dbo.GetDateMonth(S.OfficialFinishTime) 
						AND bad.ApprovedMonth BETWEEN L.IncludeStart AND L.IncludeEnd
			WHERE @iIncludeApprovedData = 0 OR bad.TagId IS NULL
			GROUP BY B.CalendarDate, G.Grade_Id, G.Grade_Name, L.ParentLocationId, ISNULL(S.ShippedProductSize, defaultlf.ProductSize)
			
			-- roll up lump/fines grades for total
			INSERT INTO @OutputGrades
			(
				CalendarDate,
				LocationId,
				ProductSize,
				GradeId,
				GradeValue,
				Tonnes
			)
			SELECT CalendarDate, LocationId, 'TOTAL', GradeId,
				SUM(Tonnes * GradeValue) / SUM(Tonnes),
				SUM(Tonnes)
			FROM @OutputGrades
			GROUP BY CalendarDate, LocationId, GradeId
			
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
				ProductSize,
				Tonnes
			)
			SELECT s.CalendarDate, s.DateFrom, s.DateTo, l.ParentLocationId, s.ProductSize, s.Tonnes
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
				ProductSize,
				Tonnes
			)
			SELECT s.CalendarDate,  l.ParentLocationId, s.GradeId,  s.GradeValue, s.ProductSize, s.Tonnes
			FROM dbo.GetBhpbioSummaryGradeBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryType, 1, 1, 0) s
				INNER JOIN #Location l
					ON l.LocationId = s.LocationId
					AND s.CalendarDate BETWEEN l.IncludeStart AND l.IncludeEnd
		END
		
		-- output the tonnes
		SELECT o.CalendarDate, o.DateFrom, o.DateTo, NULL AS MaterialTypeId,
				o.LocationId AS ParentLocationId, o.ProductSize, SUM(o.Tonnes) AS Tonnes
		FROM @OutputTonnes o
		GROUP BY o.CalendarDate, o.DateFrom, o.DateTo, o.LocationId, o.ProductSize
			
		-- output the grades
		SELECT o.CalendarDate, g.Grade_Name AS GradeName, o.GradeId, NULL AS MaterialTypeId, o.ProductSize,
				o.LocationId AS ParentLocationId, Coalesce(SUM(o.GradeValue * o.Tonnes) / NullIf(SUM(o.Tonnes), 0), 0) AS GradeValue
		FROM @OutputGrades o
			INNER JOIN dbo.Grade g
				ON g.Grade_Id = o.GradeId
		GROUP BY o.CalendarDate, g.Grade_Name, o.LocationId, o.GradeId, o.ProductSize
			
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
--use reconcilorBHPBIO_Prod_20120906 
EXEC dbo.GetBhpbioReportDataPortOreShipped
	@iDateFrom = '01-Nov-2012', 
	@iDateTo = '30-Nov-2012', 
	@iDateBreakdown = 'MONTH',
	@iLocationId = 1,
	@iChildLocations = 0, @iIncludeLiveData=01, @iIncludeApprovedData=0

2012-11-01 00:00:00.000	2012-11-01 00:00:00.000	2012-11-30 00:00:00.000	NULL	NULL	3987330
2012-11-01 00:00:00.000	2012-11-01 00:00:00.000	2012-11-30 00:00:00.000	NULL	NULL	15022234

2012-11-01 00:00:00.000	Al2O3	4	NULL	NULL	1.74569714069366
2012-11-01 00:00:00.000	Fe	1	NULL	NULL	61.5936317443848
2012-11-01 00:00:00.000	LOI	5	NULL	NULL	5.96304321289063
2012-11-01 00:00:00.000	P	2	NULL	NULL	0.0727644115686417
2012-11-01 00:00:00.000	SiO2	3	NULL	NULL	3.7694571018219
*/