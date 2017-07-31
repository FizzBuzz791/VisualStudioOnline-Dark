IF OBJECT_ID('dbo.GetBhpbioReportDataPortBlendedAdjustment') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportDataPortBlendedAdjustment 
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReportDataPortBlendedAdjustment
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
	
	DECLARE @Blending TABLE
	(
		CalendarDate DATETIME,
		DateFrom DATETIME,
		DateTo DATETIME,
		BhpbioPortBlendingId INT,
		ParentLocationId INT,
		Tonnes FLOAT,
		Removal BIT
	)
	
	DECLARE @BlendingGrades TABLE
	(
		CalendarDate DATETIME,
		DateFrom DATETIME,
		DateTo DATETIME,
		ParentLocationId INT,
		GradeId FLOAT,
		GradeValue FLOAT,
		Tonnes FLOAT
	)
		
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioReportDataPortBlendedAdjustment',
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
		-- Determine locations of interest
		INSERT INTO @Location (LocationId, ParentLocationId, IncludeStart, IncludeEnd)
		SELECT	L.LocationId, L.ParentLocationId, L.IncludeStart, L.IncludeEnd
		FROM	dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, @iChildLocations, 'SITE', @iDateFrom, @iDateTo) L
		-- Filter out any HubExclusionFilters 
		LEFT	JOIN GetBhpbioExcludeHubLocation('PortBlending') AS HXF ON L.LocationId = HXF.LocationId
		WHERE	HXF.LocationId IS NULL
		
		IF @iIncludeLiveData = 1
		BEGIN
			INSERT INTO @Blending
				(CalendarDate, DateFrom, DateTo, BhpbioPortBlendingId, ParentLocationId, Tonnes, Removal)
			SELECT B.CalendarDate, B.DateFrom, B.DateTo, BPB.BhpbioPortBlendingId,
				L.ParentLocationId, BPB.Tonnes, CASE WHEN BPB.DestinationHubLocationId = L.LocationId THEN 0 ELSE 1 END
			FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
				INNER JOIN dbo.BhpbioPortBlending AS BPB
					ON (BPB.StartDate >= B.DateFrom
						AND BPB.EndDate <= DateAdd(Second, 59, DateAdd(Minute, 59, DateAdd(Hour, 23, B.DateTo))))
				INNER JOIN @Location AS L
					ON (BPB.DestinationHubLocationId = L.LocationId OR BPB.LoadSiteLocationId = L.LocationId)
					AND B.CalendarDate BETWEEN L.IncludeStart AND L.IncludeEnd

					
				INNER JOIN dbo.BhpbioLocationDate siteLocation
					ON siteLocation.Location_Id = BPB.LoadSiteLocationId
					AND BPB.StartDate BETWEEN siteLocation.Start_Date AND siteLocation.End_Date

				LEFT JOIN GetBhpbioExcludeHubLocation('PortBlending') AS HXF 
					ON siteLocation.Parent_Location_Id = HXF.LocationId
					OR BPB.DestinationHubLocationId = HXF.LocationId
					
				-- This join is used to determine whether there is an approval associated with the data
				LEFT JOIN dbo.BhpbioApprovalData bad
					ON bad.LocationId = CASE WHEN BPB.DestinationHubLocationId = L.LocationId THEN BPB.DestinationHubLocationId ELSE siteLocation.Parent_Location_Id END
					AND bad.TagId = 'F3PortBlendedAdjustment'
					AND bad.ApprovedMonth = dbo.GetDateMonth(BPB.StartDate)
			WHERE	-- where there is no associated approval OR there is and Approved data is not being included
					(	bad.TagId IS NULL
						OR @iIncludeApprovedData = 0)
			AND		HXF.LocationId IS NULL

			-- Obtain the Port Blending Grades
			INSERT INTO @BlendingGrades
			(
				CalendarDate,
				DateFrom,
				DateTo,
				ParentLocationId,
				GradeId,
				GradeValue,
				Tonnes
			)
			SELECT B.CalendarDate,  B.DateFrom, B.DateTo, B.ParentLocationId,
				BPBG.GradeId,
				SUM(ABS(B.Tonnes) * BPBG.GradeValue) / NULLIF(SUM(ABS(B.Tonnes)), 0) AS GradeValue,
				SUM(ABS(B.Tonnes))
			FROM @Blending AS B
				INNER JOIN dbo.BhpbioPortBlendingGrade AS BPBG
					ON BPBG.BhpbioPortBlendingId = B.BhpbioPortBlendingId
			GROUP BY B.CalendarDate, B.DateFrom, B.DateTo, B.ParentLocationId, BPBG.GradeId
		END
		
		IF @iIncludeApprovedData = 1
		BEGIN
			DECLARE @summaryEntryType VARCHAR(24)
			SET @summaryEntryType = 'PortBlending'
			
			-- Retrieve Tonnes
			INSERT INTO @Blending
				(CalendarDate, DateFrom, DateTo, ParentLocationId, Tonnes, Removal)
			SELECT s.CalendarDate, s.DateFrom, s.DateTo, l.ParentLocationId, ABS(s.Tonnes), CASE WHEN s.Tonnes < 0 THEN 1 ELSE 0 END
			FROM dbo.GetBhpbioSummaryTonnesBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryType, 1) s
				INNER JOIN @Location l
					ON l.LocationId = s.LocationId
					AND s.CalendarDate BETWEEN l.IncludeStart AND l.IncludeEnd

				INNER JOIN dbo.BhpbioLocationDate siteLocation
					ON siteLocation.Location_Id = s.LocationId
					AND s.CalendarDate BETWEEN siteLocation.Start_Date AND siteLocation.End_Date
				LEFT JOIN GetBhpbioExcludeHubLocation('PortBlending') AS HXF ON siteLocation.Parent_Location_Id = HXF.LocationId
			WHERE HXF.LocationId IS NULL
			
			-- Retrieve Grades
			INSERT INTO @BlendingGrades
			(
				CalendarDate,
				DateFrom,
				DateTo,
				ParentLocationId,
				GradeId,
				GradeValue,
				Tonnes
			)
			SELECT s.CalendarDate, s.DateFrom, s.DateTo,  l.ParentLocationId,
					s.GradeId, s.GradeValue, s.Tonnes
			FROM dbo.GetBhpbioSummaryGradeBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryType, 1, 1, 0) s
				INNER JOIN @Location l
					ON l.LocationId = s.LocationId
					AND s.CalendarDate BETWEEN l.IncludeStart AND l.IncludeEnd

				INNER JOIN dbo.BhpbioLocationDate siteLocation
					ON siteLocation.Location_Id = s.LocationId
					AND s.CalendarDate BETWEEN siteLocation.Start_Date AND siteLocation.End_Date
				LEFT JOIN GetBhpbioExcludeHubLocation('PortBlending') AS HXF ON siteLocation.Parent_Location_Id = HXF.LocationId
			WHERE HXF.LocationId IS NULL

		END
		
		-- Obtain the Port Blending tonnes
		SELECT B.CalendarDate, B.DateFrom, B.DateTo, B.ParentLocationId, NULL AS MaterialTypeId,
			Sum(CASE WHEN B.Removal = 0 THEN B.Tonnes ELSE -B.Tonnes END) AS Tonnes
		FROM @Blending AS B
		GROUP BY B.CalendarDate, B.DateFrom, B.DateTo, B.ParentLocationId
		
		
		SELECT BG.CalendarDate, G.Grade_Name AS GradeName, BG.ParentLocationId,
			NULL AS MaterialTypeId,
			SUM(ABS(BG.Tonnes) * BG.GradeValue) / NULLIF(SUM(ABS(BG.Tonnes)), 0) AS GradeValue
		FROM @BlendingGrades AS BG
			INNER JOIN dbo.Grade AS G
				ON G.Grade_Id = BG.GradeId
		GROUP BY BG.CalendarDate, BG.ParentLocationId, G.Grade_Name
			
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

GRANT EXECUTE ON dbo.GetBhpbioReportDataPortBlendedAdjustment TO BhpbioGenericManager
GO


/*
exec dbo.GetBhpbioReportDataPortBlendedAdjustment
	@iDateFrom ='01-SEP-2012',	@iDateTo = '30-SEP-2012',
	@iDateBreakdown ='MONTH',	@iLocationId =6,	@iChildLocations =0,	@iIncludeLiveData =01,	@iIncludeApprovedData =01
*/