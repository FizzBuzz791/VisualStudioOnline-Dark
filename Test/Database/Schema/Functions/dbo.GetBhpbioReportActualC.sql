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
	ProductSize VARCHAR(5) NOT NULL,
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
		WeightometerId VARCHAR(31) NOT NULL,
		WeightometerSampleId INT NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		SiteLocationId INT NULL,
		ProductSize VARCHAR(5) NOT NULL,
		RealTonnes FLOAT NULL,
		SampleTonnes FLOAT NOT NULL,
		DesignationMaterialTypeId INT NOT NULL,
		IncludeInCTonnes BIT DEFAULT(1),
		PRIMARY KEY (WeightometerSampleId, ProductSize)
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
	DECLARE @ProductSizeField VARCHAR(31)
	DECLARE @SiteLocationTypeId SMALLINT
	
	DECLARE @CSite TABLE
	(
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		DesignationMaterialTypeId INT NOT NULL,
		SiteLocationId INT NOT NULL,
		RealTonnes FLOAT NULL,
		SampleTonnes FLOAT NULL,
		ProductSize VARCHAR(5) NOT NULL,
		Attribute SMALLINT NOT NULL,
		Value FLOAT NULL
		PRIMARY KEY (CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, SiteLocationId, Attribute, ProductSize)
	)
	
	DECLARE @InterimGrade TABLE
	(
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		WeightometerId VARCHAR(31) NULL,
		DesignationMaterialTypeId INT NOT NULL,
		SiteLocationId INT NOT NULL,
		RealTonnes FLOAT NULL,
		SampleTonnes FLOAT NULL,
		ProductSize VARCHAR(5) NOT NULL,
		Attribute SMALLINT NOT NULL,
		Value FLOAT NULL,
		ShouldWeightBySampleTonnes BIT NOT NULL
		PRIMARY KEY (CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, SiteLocationId, Attribute, ProductSize,ShouldWeightBySampleTonnes)
	)
	
	SET @SampleTonnesField = 'SampleTonnes'
	SET @SampleSourceField = 'SampleSource'
	SET @ProductSizeField = 'ProductSize'
	
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
	
	-- get all the sublocations that are sites
	INSERT INTO @SiteLocation (LocationId, IncludeStart, IncludeEnd)
	SELECT LocationId, IncludeStart, IncludeEnd
	FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 1, 'Site', @iDateFrom, @iDateTo) b
		INNER JOIN Location l ON l.Location_Id = b.LocationId
		INNER JOIN LocationType lt ON l.Location_Type_Id = lt.Location_Type_Id
	WHERE lt.Description = 'Site'

	IF EXISTS (	SELECT	1 FROM Location L 
				INNER JOIN Locationtype LT ON L.Location_Type_Id = LT.Location_Type_Id
				WHERE	L.location_id = @iLocationId
				AND		LT.Description='Site')
	BEGIN
		-- the current location is a site - add it to the list. It should be the only item
		-- in there
		INSERT INTO @SiteLocation
			(LocationId, IncludeStart, IncludeEnd)
		SELECT LocationId, IncludeStart, IncludeEnd
		FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 0, 'Site', @iDateFrom, @iDateTo)
	END

	-- this represents the location tree for what's desired	
	INSERT INTO @DesiredLocation
		(LocationId, ParentLocationId, IncludeStart, IncludeEnd)
	SELECT LocationId, ParentLocationId, IncludeStart, IncludeEnd
	FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, @iGetChildLocations, 'Site', @iDateFrom, @iDateTo)
	
	IF @iIncludeLiveData = 1
	BEGIN
		-- retrieve the list of Weightometer Records to be used in the calculations
		INSERT INTO @Weightometer
			(
				CalendarDate, DateFrom, DateTo, WeightometerId, WeightometerSampleId, SiteLocationId, ProductSize,
				RealTonnes, SampleTonnes, DesignationMaterialTypeId, IncludeInCTonnes
			)
		SELECT b.CalendarDate, b.DateFrom, b.DateTo, ws.Weightometer_Id, w.WeightometerSampleId, l.LocationId, ISNULL(wsn.Notes, defaultlf.ProductSize) As ProductSize,
			-- calculate the REAL tonnes
			ISNULL(ISNULL(defaultlf.[Percent], 1) * ws.Corrected_Tonnes, ISNULL(defaultlf.[Percent], 1) * ws.Tonnes) AS RealTonnes,
			-- calculate the SAMPLE tonnes
			-- if a sample tonnes hasn't been provided then use the actual tonnes recorded for the transaction
			-- not all flows will have this recorded (in particular CVF corrected plant balanced records)
			CASE w.BeneFeed
				WHEN 1 THEN ISNULL(ISNULL(defaultlf.[Percent], 1) * ws.Corrected_Tonnes, ISNULL(defaultlf.[Percent], 1) * ws.Tonnes)
				ELSE ISNULL(ISNULL(defaultlf.[Percent], 1) * wsv.Field_Value, 0.0)
			END AS SampleTonnes,
			-- return the Material Type based on whether it is bene feed
			CASE w.BeneFeed
				WHEN 1 THEN @BeneFeedMaterialTypeId
				WHEN 0 THEN @HighGradeMaterialTypeId
			END AS MaterialTypeId,
			w.IncludeInCTonnes
		FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1) AS b
			INNER JOIN dbo.WeightometerSample AS ws
				ON (ws.Weightometer_Sample_Date BETWEEN b.DateFrom AND b.DateTo)
			INNER JOIN
				(
					-- collect the weightometer sample id's for all movements from the crusher
					-- these are used to ease lookup and ensure uniqueness of the weightometer_sample_ids returned
					SELECT DISTINCT dttf.Weightometer_Sample_Id AS WeightometerSampleId, 1 AS IncludeInCTonnes,
						CASE
							WHEN m.Mill_Id IS NOT NULL
								THEN 1
							ELSE 0
						END AS BeneFeed, l.LocationId
					FROM dbo.DataTransactionTonnes AS dtt
						INNER JOIN dbo.DataTransactionTonnesFlow AS dttf
							ON (dttf.Data_Transaction_Tonnes_Id = dtt.Data_Transaction_Tonnes_Id)
						INNER JOIN dbo.GetBhpbioCrusherLocationWithOverride(@iDateFrom, @iDateTo) AS cl
							ON (dttf.Source_Crusher_Id = cl.Crusher_Id) 
							AND (dtt.Data_Transaction_Tonnes_Date BETWEEN cl.IncludeStart AND cl.IncludeEnd)
						LEFT JOIN dbo.Mill AS m
							ON (dttf.Destination_Stockpile_Id = m.Stockpile_Id)
						INNER JOIN @SiteLocation AS l
							ON (cl.Location_Id = l.LocationId 
							AND dtt.Data_Transaction_Tonnes_Date BETWEEN l.IncludeStart AND l.IncludeEnd
							)
						LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('ActualC') xs
							ON xs.StockpileId = dttf.Source_Stockpile_Id
							OR xs.StockpileId = dttf.Destination_Stockpile_Id
					WHERE dtt.Data_Transaction_Tonnes_Date BETWEEN @iDateFrom AND @iDateTo
						AND dttf.Destination_Crusher_Id IS NULL  -- ignore crusher to crusher feeds
						AND xs.StockpileId IS NULL -- No movements to or from excluded groups.
					GROUP BY dttf.Weightometer_Sample_Id, m.Mill_Id, l.LocationId
					UNION ALL
					-- collect weightometer sample id's for all movements to train rakes
					-- (by definition it's always delivers to train rake stockpiles...
					--  the grades (but not the tonnes) from these weightometers samples are important to us)
					SELECT DISTINCT dttf.Weightometer_Sample_Id, 0, 0, l.LocationId
					FROM dbo.DataTransactionTonnes AS dtt
						INNER JOIN dbo.DataTransactionTonnesFlow AS dttf
							ON (dttf.Data_Transaction_Tonnes_Id = dtt.Data_Transaction_Tonnes_Id)
						INNER JOIN dbo.WeightometerSample AS ws
							ON (dttf.Weightometer_Sample_Id = ws.Weightometer_Sample_Id)
						INNER JOIN dbo.StockpileGroupStockpile AS sgs
							ON (sgs.Stockpile_Id = dttf.Destination_Stockpile_Id)
						INNER JOIN dbo.GetBhpbioWeightometerLocationWithOverride(@iDateFrom, @iDateTo) AS wl
							ON (ws.Weightometer_Id = wl.Weightometer_Id)
							AND (dtt.Data_Transaction_Tonnes_Date BETWEEN wl.IncludeStart AND wl.IncludeEnd)
						INNER JOIN @SiteLocation AS l
							ON (wl.Location_Id = l.LocationId
							AND dtt.Data_Transaction_Tonnes_Date BETWEEN l.IncludeStart AND l.IncludeEnd
							)
						LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('ActualC') xs
							ON xs.StockpileId = dttf.Source_Stockpile_Id
							OR xs.StockpileId = dttf.Destination_Stockpile_Id
					WHERE dtt.Data_Transaction_Tonnes_Date BETWEEN @iDateFrom AND @iDateTo
						AND sgs.Stockpile_Group_Id = 'Port Train Rake'
						AND xs.StockpileId IS NULL -- No movements to or from excluded stockpiles
					GROUP BY dttf.Weightometer_Sample_Id, l.LocationId
				  ) AS w
				ON (ws.Weightometer_Sample_Id = w.WeightometerSampleId)
				-- ensure the weightometer belongs to the required location
			INNER JOIN dbo.GetBhpbioWeightometerLocationWithOverride(@iDateFrom, @iDateTo) AS wl
				ON (ws.Weightometer_Id = wl.Weightometer_Id)
				AND (ws.Weightometer_Sample_Date BETWEEN wl.IncludeStart AND wl.IncludeEnd)
			INNER JOIN @SiteLocation AS l
				ON (l.LocationId = wl.Location_Id
				AND ws.Weightometer_Sample_Date BETWEEN l.IncludeStart AND l.IncludeEnd)
			LEFT OUTER JOIN dbo.WeightometerSampleValue AS wsv
				ON (ws.Weightometer_Sample_Id = wsv.Weightometer_Sample_Id
					AND wsv.Weightometer_Sample_Field_Id = @SampleTonnesField)
			LEFT JOIN dbo.WeightometerSampleNotes wsn
				ON (ws.Weightometer_Sample_Id = wsn.Weightometer_Sample_Id
					AND wsn.Weightometer_Sample_Field_Id = @ProductSizeField)
			LEFT JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf
				ON wsn.Notes IS NULL
				AND wl.Location_Id = defaultlf.LocationId
				AND ws.Weightometer_Sample_Date BETWEEN defaultlf.StartDate AND defaultlf.EndDate
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
				AND ISNULL(defaultlf.[Percent], 1) > 0
		
		-- return the TONNES values for lump and fines
		-- these are literally the "best tonnes" provided by the weightometer sample
		INSERT INTO @CSite
			(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, SiteLocationId, ProductSize, SampleTonnes, Attribute, Value)
		SELECT CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, 
			SiteLocationId, ProductSize, NULL, 0, SUM(RealTonnes)
		FROM @Weightometer
		WHERE IncludeInCTonnes = 1
		GROUP BY CalendarDate, DateFrom, DateTo, SiteLocationId, DesignationMaterialTypeId, ProductSize
		HAVING SUM(RealTonnes) IS NOT NULL
		
		-- return the TONNES values rolled up
		-- these are literally the "best tonnes" provided by the weightometer sample
		INSERT INTO @CSite
			(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, SiteLocationId, ProductSize, SampleTonnes, Attribute, Value)
		SELECT CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, 
			SiteLocationId, 'TOTAL', NULL, 0, SUM(RealTonnes)
		FROM @Weightometer
		WHERE IncludeInCTonnes = 1
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

		-- insert grades values into an interim table (for lump and fines)... keeping back-calculated grades seperate
		--					as they are weighted together by sample tonnes (within weightometer_id) before being combined with other results through tonnes weighting
		INSERT INTO @InterimGrade
		(
			CalendarDate, DateFrom, DateTo, WeightometerId, DesignationMaterialTypeId,
			SiteLocationId, ProductSize, RealTonnes, SampleTonnes, Attribute, Value, ShouldWeightBySampleTonnes
		)
		SELECT w.CalendarDate, w.DateFrom, w.DateTo, CASE WHEN sSource.ShouldWeightBySampleTonnes = 1 THEN w.WeightometerId ELSE NULL END, w.DesignationMaterialTypeId,
			w.SiteLocationId, w.ProductSize, SUM(w.RealTonnes), SUM(w.SampleTonnes), g.Grade_Id As GradeId,
			
			CASE WHEN sSource.ShouldWeightBySampleTonnes = 1 THEN
				-- weight by sample tonnes
				SUM(w.SampleTonnes * wsg.Grade_Value) / 
				CASE 
					WHEN SUM(w.SampleTonnes) > 0 THEN SUM(w.SampleTonnes)
					ELSE SUM(w.RealTonnes)
				END
			ELSE
				SUM(w.RealTonnes * wsg.Grade_Value) / SUM(w.RealTonnes)
			END,
			IsNull(sSource.ShouldWeightBySampleTonnes,0)
		FROM @Weightometer AS w
			-- check the membership with the Sample Source
			LEFT OUTER JOIN
				(
					SELECT ws.Weightometer_Sample_Id, ss.ShouldWeightBySampleTonnes
					FROM dbo.WeightometerSample AS ws
						INNER JOIN dbo.GetBhpbioWeightometerLocationWithOverride(@iDateFrom, @iDateTo) AS wl
							ON (ws.Weightometer_Id = wl.Weightometer_Id)
							AND (ws.Weightometer_Sample_Date BETWEEN wl.IncludeStart AND wl.IncludeEnd)
						INNER JOIN dbo.WeightometerSampleNotes AS wsn
							ON (wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
								AND wsn.Weightometer_Sample_Field_Id = @SampleSourceField)
						INNER JOIN dbo.GetBhpbioWeightometerSampleSourceActualC(@iLocationId, @iDateFrom, @iDateTo, 0) AS ss
							ON (dbo.GetDateMonth(ws.Weightometer_Sample_Date) = ss.MonthPeriod
								AND ws.Weightometer_Id = ss.Weightometer_Id
								AND wl.Location_Id = ss.LocationId
								AND wsn.Notes = ss.SampleSource)
				) AS sSource
				ON (sSource.Weightometer_Sample_Id = w.WeightometerSampleId)
			-- add the grades
			INNER JOIN dbo.WeightometerSampleGrade AS wsg
				ON (wsg.Weightometer_Sample_Id = w.WeightometerSampleId)
			INNER JOIN dbo.Grade AS g 
				ON g.Grade_Id = wsg.Grade_Id
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
			AND EXISTS (
				SELECT * FROM dbo.WeightometerSampleGrade AS wsg
				WHERE wsg.Weightometer_Sample_Id = w.WeightometerSampleId AND wsg.Grade_Value IS NOT NULL
			)
		GROUP BY w.CalendarDate, w.DateFrom, w.DateTo, CASE WHEN sSource.ShouldWeightBySampleTonnes = 1 THEN w.WeightometerId ELSE NULL END, g.Grade_Id, w.SiteLocationId, w.DesignationMaterialTypeId, w.ProductSize, sSource.ShouldWeightBySampleTonnes
		HAVING SUM(w.RealTonnes) > 0
		
		-- now insert the lump and fines grade values
		INSERT INTO @CSite
		(
			CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId,
			SiteLocationId, ProductSize, RealTonnes, SampleTonnes, Attribute, Value
		)
		SELECT w.CalendarDate, w.DateFrom, w.DateTo, w.DesignationMaterialTypeId,
			w.SiteLocationId, w.ProductSize, SUM(w.RealTonnes), SUM(w.SampleTonnes), w.Attribute, SUM(w.Value * w.RealTonnes) / SUM(w.RealTonnes)
		FROM @InterimGrade AS w
		GROUP BY w.CalendarDate, w.DateFrom, w.DateTo, w.DesignationMaterialTypeId,
			w.SiteLocationId, w.ProductSize, w.Attribute
		HAVING SUM(w.RealTonnes) > 0
		
		-- insert the TOTAL GRADES values rolled up
		INSERT INTO @CSite
			(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, SiteLocationId, ProductSize, 
			RealTonnes,SampleTonnes, Attribute, Value)
		SELECT CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, SiteLocationId, 'TOTAL', 
			SUM(RealTonnes),SUM(SampleTonnes), Attribute, 
			SUM(RealTonnes * Value) / 
			NULLIF(SUM(CASE WHEN Value IS NULL THEN NULL ELSE RealTonnes END), 0.0) 
		FROM @CSite
		WHERE Attribute > 0 -- ie... not tonnes
		GROUP BY CalendarDate, DateFrom, DateTo, SiteLocationId, DesignationMaterialTypeId, Attribute
		HAVING SUM(RealTonnes) > 0
	END
	
	-- If we are including approved data
	IF @iIncludeApprovedData = 1
	BEGIN
		-- then retrieve tonnes and grades for the time period for Actual C summary type
		DECLARE @summaryEntryType VARCHAR(24)
		SET @summaryEntryType = 'ActualC'
		
		-- Retrieve Tonnes
		INSERT INTO @CSite
			(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, SiteLocationId, ProductSize, SampleTonnes, Attribute, Value)
		SELECT s.CalendarDate, s.DateFrom, s.DateTo, s.MaterialTypeId, s.LocationId, s.ProductSize, NULL, 0,  s.Tonnes
		FROM dbo.GetBhpbioSummaryTonnesBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryType, 0) s
			INNER JOIN @SiteLocation l
				ON l.LocationId = s.LocationId
				AND s.CalendarDate BETWEEN l.IncludeStart AND l.IncludeEnd
		
		-- Retrieve Grades
		INSERT INTO @CSite
			(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, SiteLocationId, ProductSize, SampleTonnes, Attribute, Value)
		SELECT s.CalendarDate, s.DateFrom, s.DateTo, s.MaterialTypeId, s.LocationId, s.ProductSize, s.Tonnes, s.GradeId,  s.GradeValue
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
		LocationId, ProductSize, Attribute, Value
	)
	SELECT c.CalendarDate, c.DateFrom, c.DateTo, c.DesignationMaterialTypeId,
		l.ParentLocationId, c.ProductSize, c.Attribute, SUM(c.Value)
	FROM @CSite AS c
		INNER JOIN @DesiredLocation AS l
			ON (c.SiteLocationId = l.LocationId AND c.CalendarDate BETWEEN l.IncludeStart AND l.IncludeEnd)
	WHERE c.Attribute = 0
	GROUP BY c.CalendarDate, c.DateFrom, c.DateTo, c.DesignationMaterialTypeId,
		l.ParentLocationId, c.Attribute, c.ProductSize

	-- grades	
	INSERT INTO @C
	(
		CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId,
		LocationId, ProductSize, SampleTonnes, Attribute, Value
	)
	SELECT cg.CalendarDate, cg.DateFrom, cg.DateTo, cg.DesignationMaterialTypeId,
		l.ParentLocationId, cg.ProductSize, SUM(ct.Value), cg.Attribute,
		SUM(cg.Value * ct.Value) / NULLIF(SUM(ct.Value), 0.0)
	FROM @CSite AS cg
		INNER JOIN @DesiredLocation AS l
			ON (cg.SiteLocationId = l.LocationId and cg.CalendarDate BETWEEN l.IncludeStart AND l.IncludeEnd)
		INNER JOIN @CSite AS ct -- tonnes used for weighting
			ON (cg.CalendarDate = ct.CalendarDate
				AND cg.DateFrom = ct.DateFrom
				AND cg.DateTo = ct.DateTo
				AND cg.DesignationMaterialTypeId = ct.DesignationMaterialTypeId
				AND cg.SiteLocationId = ct.SiteLocationId
				AND cg.ProductSize = ct.ProductSize)
	WHERE cg.Attribute > 0
		AND ct.Attribute = 0
	GROUP BY cg.CalendarDate, cg.DateFrom, cg.DateTo, cg.DesignationMaterialTypeId,
		l.ParentLocationId, cg.Attribute, cg.ProductSize
	
	RETURN
END
GO