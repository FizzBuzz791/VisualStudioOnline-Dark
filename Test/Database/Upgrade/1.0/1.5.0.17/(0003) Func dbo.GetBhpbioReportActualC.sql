IF Object_Id('dbo.GetBhpbioReportActualC') IS NOT NULL
	DROP FUNCTION dbo.GetBhpbioReportActualC
GO

CREATE FUNCTION dbo.GetBhpbioReportActualC
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iGetChildLocations BIT,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT
)
RETURNS @C TABLE
(
	CalendarDate DATETIME NOT NULL,
	DateFrom DATETIME NOT NULL,
	DateTo DATETIME NOT NULL,
	DesignationMaterialTypeId INT NOT NULL,
	LocationId INT NULL,
	SampleTonnes FLOAT NULL,
	Attribute SMALLINT NULL,
	Value FLOAT NULL
)
WITH ENCRYPTION
AS
BEGIN
	-- this DOES NOT and CAN NOT return data below the site level
	-- this is because:
	-- (1) weightometers & crushers are at the SITE level, and
	-- (2) the way Sites aggregate is based on the "Sample" tonnes method,
	--     .. hence these records need to be returned at the Site level
	-- note that data must not be returned at the Hub/Company level either

	-- 'C' - all crusher removals
	-- returns [High Grade] & [Bene Feed] as designation types

	DECLARE @Weightometer TABLE
	(
		CalendarDate DATETIME NOT NULL,
		WeightometerSampleId INT NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		SiteLocationId INT NULL,
		RealTonnes FLOAT NULL,
		SampleTonnes FLOAT NOT NULL,
		DesignationMaterialTypeId INT NOT NULL,
		PRIMARY KEY (WeightometerSampleId, CalendarDate)
	)
	
	DECLARE @GradeLocation TABLE
	(
		CalendarDate DATETIME NOT NULL,
		SiteLocationId INT NOT NULL,
		PRIMARY KEY (SiteLocationId, CalendarDate)
	)
	
	DECLARE @SiteLocation TABLE
	(
		LocationId INT NOT NULL,
		IncludeStart DATETIME NOT NULL,
		IncludeEnd DATETIME NOT NULL
		PRIMARY KEY (LocationId, IncludeStart, IncludeEnd)
	)
	
	DECLARE @DesiredLocation TABLE
	(
		LocationId INT NOT NULL,
		ParentLocationId INT NULL,
		IncludeStart DATETIME NOT NULL,
		IncludeEnd DATETIME NOT NULL
		--,PRIMARY KEY (LocationId)
	)

	DECLARE @HighGradeMaterialTypeId INT
	DECLARE @BeneFeedMaterialTypeId INT
	DECLARE @SampleTonnesField VARCHAR(31)
	DECLARE @SampleSourceField VARCHAR(31)
	DECLARE @SiteLocationTypeId SMALLINT
	
	DECLARE @CSite TABLE
	(
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		DesignationMaterialTypeId INT NOT NULL,
		SiteLocationId INT NOT NULL,
		SampleTonnes FLOAT NULL,
		Attribute SMALLINT NOT NULL,
		Value FLOAT NULL,
		PRIMARY KEY (CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, SiteLocationId, Attribute)
	)
	
	SET @SampleTonnesField = 'SampleTonnes'
	SET @SampleSourceField = 'SampleSource'
	
	SET @HighGradeMaterialTypeId =
		(
			SELECT Material_Type_Id
			FROM dbo.MaterialType
			WHERE Abbreviation = 'High Grade'
				AND Material_Category_Id = 'Designation'
		)

	SET @BeneFeedMaterialTypeId = 
		(
			SELECT Material_Type_Id
			FROM dbo.MaterialType
			WHERE Abbreviation = 'Bene Feed'
				AND Material_Category_Id = 'Designation'
		)
	
	-- Setup the Locations
	-- collect at site level (this is used to ensure the site's sampled tonnes are collated)
	--SET @SiteLocationTypeId =
	--	(
	--		SELECT Location_Type_Id
	--		FROM dbo.LocationType
	--		WHERE Description = 'Site'
	--	)
	
	INSERT INTO @SiteLocation
		(LocationId, IncludeStart, IncludeEnd)
	SELECT LocationId, IncludeStart, IncludeEnd
	--FROM dbo.GetLocationSubtreeByLocationType(@iLocationId, @SiteLocationTypeId, @SiteLocationTypeId)
	FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 1, 'Site', @iDateFrom, @iDateTo)

	IF EXISTS (	SELECT	1 FROM Location L 
				INNER JOIN Locationtype LT ON L.Location_Type_Id = LT.Location_Type_Id
				WHERE	L.location_id = @iLocationId
				AND		LT.Description='Site')
	BEGIN
		INSERT INTO @SiteLocation
			(LocationId, IncludeStart, IncludeEnd)
		SELECT LocationId, IncludeStart, IncludeEnd
		FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 0, 'Site', @iDateFrom, @iDateTo)
	END

	-- this represents the location tree for what's desired	
	INSERT INTO @DesiredLocation
		(LocationId, ParentLocationId, IncludeStart, IncludeEnd)
	SELECT LocationId, ParentLocationId, IncludeStart, IncludeEnd
	--FROM dbo.GetBhpbioReportLocationBreakdown(@iLocationId, @iGetChildLocations, 'Site')
	FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, @iGetChildLocations, 'Site', @iDateFrom, @iDateTo)
	
	IF @iIncludeLiveData = 1
	BEGIN
		-- retrieve the list of Weightometer Records to be used in the calculations
		INSERT INTO @Weightometer
			(
				CalendarDate, DateFrom, DateTo, WeightometerSampleId, SiteLocationId,
				RealTonnes, SampleTonnes, DesignationMaterialTypeId
			)
		SELECT b.CalendarDate, b.DateFrom, b.DateTo, w.WeightometerSampleId, l.LocationId,
			-- calculate the REAL tonnes
			CASE
				WHEN w.UseAsRealTonnes = 1
					THEN ISNULL(ws.Corrected_Tonnes, ws.Tonnes)
				ELSE NULL
			END AS RealTonnes,
			-- calculate the SAMPLE tonnes
			-- if a sample tonnes hasn't been provided then use the actual tonnes recorded for the transaction
			-- not all flows will have this recorded (in particular CVF corrected plant balanced records)
			CASE BeneFeed
				WHEN 1 THEN ISNULL(ws.Corrected_Tonnes, ws.Tonnes)
				ELSE ISNULL(wsv.Field_Value, 0.0)
			END AS SampleTonnes,
			-- return the Material Type based on whether it is bene feed
			CASE w.BeneFeed
				WHEN 1 THEN @BeneFeedMaterialTypeId
				WHEN 0 THEN @HighGradeMaterialTypeId
			END AS MaterialTypeId
		FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1) AS b
			INNER JOIN dbo.WeightometerSample AS ws
				ON (ws.Weightometer_Sample_Date BETWEEN b.DateFrom AND b.DateTo)
			INNER JOIN
				(
					-- collect the weightometer sample id's for all movements from the crusher
					-- these are used to ease lookup and ensure uniqueness of the weightometer_sample_ids returned
					SELECT dttf.Weightometer_Sample_Id AS WeightometerSampleId, 1 AS UseAsRealTonnes,
						CASE
							WHEN m.Mill_Id IS NOT NULL
								THEN 1
							ELSE 0
						END AS BeneFeed, l.LocationId
					FROM dbo.DataTransactionTonnes AS dtt
						INNER JOIN dbo.DataTransactionTonnesFlow AS dttf
							ON (dttf.Data_Transaction_Tonnes_Id = dtt.Data_Transaction_Tonnes_Id)
						INNER JOIN dbo.CrusherLocation AS cl
							ON (dttf.Source_Crusher_Id = cl.Crusher_Id)
						LEFT JOIN dbo.Mill AS m
							ON (dttf.Destination_Stockpile_Id = m.Stockpile_Id)
						INNER JOIN @SiteLocation AS l
							ON (cl.Location_Id = l.LocationId 
							AND dtt.Data_Transaction_Tonnes_Date BETWEEN l.IncludeStart AND l.IncludeEnd
							)
					WHERE dtt.Data_Transaction_Tonnes_Date BETWEEN @iDateFrom AND @iDateTo
						AND dttf.Destination_Crusher_Id IS NULL  -- ignore crusher to crusher feeds
					GROUP BY dttf.Weightometer_Sample_Id, m.Mill_Id, l.LocationId
					UNION 
					-- collect weightometer sample id's for all movements to train rakes
					-- (by definition it's always delivers to train rake stockpiles...
					--  the grades (but not the tonnes) from these weightometers samples are important to us)
					SELECT dttf.Weightometer_Sample_Id, 0, 0, l.LocationId
					FROM dbo.DataTransactionTonnes AS dtt
						INNER JOIN dbo.DataTransactionTonnesFlow AS dttf
							ON (dttf.Data_Transaction_Tonnes_Id = dtt.Data_Transaction_Tonnes_Id)
						INNER JOIN dbo.WeightometerSample AS ws
							ON (dttf.Weightometer_Sample_Id = ws.Weightometer_Sample_Id)
						INNER JOIN dbo.StockpileGroupStockpile AS sgs
							ON (sgs.Stockpile_Id = dttf.Destination_Stockpile_Id)
						INNER JOIN dbo.WeightometerLocation AS wl
							ON (ws.Weightometer_Id = wl.Weightometer_Id)
						INNER JOIN @SiteLocation AS l
							ON (wl.Location_Id = l.LocationId
							AND dtt.Data_Transaction_Tonnes_Date BETWEEN l.IncludeStart AND l.IncludeEnd
							)
					WHERE dtt.Data_Transaction_Tonnes_Date BETWEEN @iDateFrom AND @iDateTo
						AND sgs.Stockpile_Group_Id = 'Port Train Rake'
					GROUP BY dttf.Weightometer_Sample_Id, l.LocationId
				  ) AS w
				ON (ws.Weightometer_Sample_Id = w.WeightometerSampleId)
				-- ensure the weightometer belongs to the required location
			INNER JOIN dbo.WeightometerLocation AS wl
				ON (wl.Weightometer_Id = ws.Weightometer_Id)
			INNER JOIN @SiteLocation AS l
				ON (l.LocationId = wl.Location_Id
				AND ws.Weightometer_Sample_Date BETWEEN l.IncludeStart AND l.IncludeEnd
				)
			LEFT OUTER JOIN dbo.WeightometerSampleValue AS wsv
				ON (ws.Weightometer_Sample_Id = wsv.Weightometer_Sample_Id
					AND wsv.Weightometer_Sample_Field_Id = @SampleTonnesField)
			-- This join is a way of testing whether there is an approval for the same location and period as this weightometer sample
			-- if so, the row will be ignored
			LEFT JOIN dbo.BhpbioApprovalData bad
				ON bad.LocationId = l.LocationId
				AND bad.ApprovedMonth BETWEEN l.IncludeStart AND l.IncludeEnd
				AND bad.ApprovedMonth = dbo.GetDateMonth(ws.Weightometer_Sample_Date)
				AND bad.TagId = 'F2MineProductionActuals'
		WHERE	-- Where there is no matching approval, or there is but we are not retrieving approved data in this call
				(bad.LocationId IS NULL
				OR @iIncludeApprovedData = 0)
		
		-- return the TONNES values
		-- these are literally the "best tonnes" provided by the weightometer sample
		INSERT INTO @CSite
			(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, SiteLocationId, SampleTonnes, Attribute, Value)
		SELECT CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, 
			SiteLocationId, NULL, 0, SUM(RealTonnes)
		FROM @Weightometer
		GROUP BY CalendarDate, DateFrom, DateTo, SiteLocationId, DesignationMaterialTypeId
		HAVING SUM(RealTonnes) IS NOT NULL
		
		-- Get the valid locations to be used for the grades. 
		-- This is so locations with no valid real tonnes are not included in the calc.
		INSERT INTO @GradeLocation
			(CalendarDate, SiteLocationId)
		SELECT CalendarDate, SiteLocationId
		FROM @Weightometer
		WHERE RealTonnes IS NOT NULL
		GROUP BY CalendarDate, SiteLocationId

		-- return the GRADES values
		INSERT INTO @CSite
		(
			CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId,
			SiteLocationId, SampleTonnes, Attribute, Value
		)
		SELECT w.CalendarDate, w.DateFrom, w.DateTo, w.DesignationMaterialTypeId,
			w.SiteLocationId, SUM(w.SampleTonnes), g.Grade_Id As GradeId,
			SUM(w.SampleTonnes * wsg.Grade_Value) / 
			NULLIF(SUM(CASE WHEN wsg.Grade_Value IS NULL THEN NULL ELSE w.SampleTonnes END), 0.0) As GradeValue
		FROM @Weightometer AS w
			-- check the membership with the Sample Source
			LEFT OUTER JOIN
				(
					SELECT ws.Weightometer_Sample_Id
					FROM dbo.WeightometerSample AS ws
						INNER JOIN dbo.WeightometerLocation AS wl
							ON (ws.Weightometer_Id = wl.Weightometer_Id)
						INNER JOIN dbo.WeightometerSampleNotes AS wsn
							ON (wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
								AND wsn.Weightometer_Sample_Field_Id = @SampleSourceField)
						INNER JOIN dbo.GetBhpbioWeightometerSampleSource(@iLocationId, @iDateFrom, @iDateTo) AS ss
							ON (dbo.GetDateMonth(ws.Weightometer_Sample_Date) = ss.MonthPeriod
								AND wl.Location_Id = ss.LocationId
								AND wsn.Notes = ss.SampleSource)
				) AS sSource
				ON (sSource.Weightometer_Sample_Id = w.WeightometerSampleId)
			-- add the grades
			CROSS JOIN dbo.Grade AS g
			LEFT JOIN dbo.WeightometerSampleGrade AS wsg
				ON (w.WeightometerSampleId = wsg.Weightometer_Sample_Id
					AND g.Grade_Id = wsg.Grade_Id)
			INNER JOIN @GradeLocation AS gl
				ON (gl.CalendarDate = w.CalendarDate
					AND ISNULL(gl.SiteLocationId, -1) = ISNULL(w.SiteLocationId, -1))
		WHERE
			-- only include if:
			-- 1. the Material Type is Bene Feed and there is no Sample Source
			-- 2. the Material Type is High Grade and there is a matching SampleSource
			CASE
				WHEN (DesignationMaterialTypeId = @BeneFeedMaterialTypeId) AND (sSource.Weightometer_Sample_Id IS NULL) THEN 1
				WHEN (DesignationMaterialTypeId = @HighGradeMaterialTypeId) AND (sSource.Weightometer_Sample_Id IS NOT NULL) THEN 1
				ELSE 0
			END = 1
		GROUP BY w.CalendarDate, w.DateFrom, w.DateTo, g.Grade_Id, w.SiteLocationId, w.DesignationMaterialTypeId
	END
	
	-- If we are including approved data
	IF @iIncludeApprovedData = 1
	BEGIN
		-- then retrieve tonnes and grades for the time period for Actual C summary type
		DECLARE @summaryEntryType VARCHAR(24)
		SET @summaryEntryType = 'ActualC'
		
		-- Retrieve Tonnes
		INSERT INTO @CSite
			(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, SiteLocationId, SampleTonnes, Attribute, Value)
		SELECT s.CalendarDate, s.DateFrom, s.DateTo, s.MaterialTypeId, s.LocationId, NULL, 0,  s.Tonnes
		FROM dbo.GetBhpbioSummaryTonnesBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryType, 0) s
			INNER JOIN @SiteLocation l
				ON l.LocationId = s.LocationId
				AND s.CalendarDate BETWEEN l.IncludeStart AND l.IncludeEnd
		
		
		-- Retrieve Grades
		SET @summaryEntryType = 'ActualCSampleTonnes'
		
		INSERT INTO @CSite
			(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, SiteLocationId, SampleTonnes, Attribute, Value)
		SELECT s.CalendarDate, s.DateFrom, s.DateTo, s.MaterialTypeId, s.LocationId, s.Tonnes, s.GradeId,  s.GradeValue
		FROM dbo.GetBhpbioSummaryGradeBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryType, 0, 1, 0) s
			INNER JOIN @SiteLocation l
				ON l.LocationId = s.LocationId
				AND s.CalendarDate BETWEEN l.IncludeStart AND l.IncludeEnd
	END
	
	-- aggregate the results (live and/or approved) to the desired location
	-- tonnes
	INSERT INTO @C
	(
		CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId,
		LocationId, Attribute, Value
	)
	SELECT c.CalendarDate, c.DateFrom, c.DateTo, c.DesignationMaterialTypeId,
		l.ParentLocationId, c.Attribute, SUM(c.Value)
	FROM @CSite AS c
		INNER JOIN @DesiredLocation AS l
			ON (c.SiteLocationId = l.LocationId AND c.CalendarDate BETWEEN l.IncludeStart AND l.IncludeEnd)
	WHERE c.Attribute = 0
	GROUP BY c.CalendarDate, c.DateFrom, c.DateTo, c.DesignationMaterialTypeId,
		l.ParentLocationId, c.Attribute

	-- grades	
	INSERT INTO @C
	(
		CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId,
		LocationId, SampleTonnes, Attribute, Value
	)
	SELECT cg.CalendarDate, cg.DateFrom, cg.DateTo, cg.DesignationMaterialTypeId,
		l.ParentLocationId, SUM(ct.Value), cg.Attribute,
		SUM(cg.Value * ct.Value) / NULLIF(SUM(ct.Value), 0.0)
	FROM @CSite AS cg
		INNER JOIN @DesiredLocation AS l
			ON (cg.SiteLocationId = l.LocationId and cg.CalendarDate BETWEEN l.IncludeStart AND l.IncludeEnd)
		INNER JOIN @CSite AS ct
			ON (cg.CalendarDate = ct.CalendarDate
				AND cg.DateFrom = ct.DateFrom
				AND cg.DateTo = ct.DateTo
				AND cg.DesignationMaterialTypeId = ct.DesignationMaterialTypeId
				AND cg.SiteLocationId = ct.SiteLocationId)
	WHERE cg.Attribute > 0
		AND ct.Attribute = 0
	GROUP BY cg.CalendarDate, cg.DateFrom, cg.DateTo, cg.DesignationMaterialTypeId,
		l.ParentLocationId, cg.Attribute
	
	
	RETURN
END
GO


/*
SELECT CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value FROM dbo.GetBhpbioReportActualC('01-JUL-2009', '31-JUL-2009', NULL, 1, 1) where attribute in (0, 1) order by locationid
SELECT CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value FROM dbo.GetBhpbioReportActualC('01-JUL-2009', '31-JUL-2009', NULL, 1, 0) where attribute in (0, 1) order by locationid

SELECT * FROM dbo.GetBhpbioReportActualC('01-APR-2009', '30-JUN-2009', NULL, 1, 0, 1, 1) where Attribute = 1
SELECT * FROM dbo.GetBhpbioReportActualC('01-APR-2009', '30-JUN-2009', NULL, NULL, 1, 1, 1) where Attribute = 1
SELECT * FROM dbo.GetBhpbioReportActualC('01-APR-2009', '30-JUN-2009', NULL, 1, 1, 1, 1) where Attribute = 1
SELECT * FROM dbo.GetBhpbioReportActualC('01-APR-2009', '30-JUN-2009', NULL, 1, 0, 1, 1) where Attribute = 1
SELECT * FROM dbo.GetBhpbioReportActualC('01-APR-2009', '30-JUN-2009', NULL, 6, 0, 1, 1) where Attribute = 1
SELECT * FROM dbo.GetBhpbioReportActualC('01-APR-2009', '30-JUN-2009', NULL, 7, 0, 1, 1) where Attribute = 1
SELECT * FROM dbo.GetBhpbioReportActualC('01-APR-2009', '30-JUN-2009', NULL, 6334, 0, 1, 1) where Attribute = 1

SELECT LocationId, ParentLocationId
FROM dbo.GetBhpbioReportLocationBreakdown(8, 1, 'Site')

SELECT LocationId, ParentLocationId
FROM dbo.GetBhpbioReportLocationBreakdown(8, 0, 'Site')
exec dbo.GetBhpbioReportDataActualMineProduction @iDateFrom='2012-07-01 00:00:00',@iDateTo='2012-07-31 00:00:00',@iDateBreakdown=NULL,@iLocationId=12,@iChildLocations=0,@iIncludeLiveData=1,@iIncludeApprovedData=1
*/
