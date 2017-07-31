IF OBJECT_ID('dbo.GetBhpbioFloatOptionalAbsolute') IS NOT NULL 
     DROP FUNCTION dbo.GetBhpbioFloatOptionalAbsolute
Go 

CREATE FUNCTION dbo.GetBhpbioFloatOptionalAbsolute
(
	@iValue FLOAT,
	@iReturnAbsolute BIT
)
RETURNS FLOAT
AS 
BEGIN
	DECLARE @returnValue FLOAT
	
	
	IF @iReturnAbsolute = 1
	BEGIN
		SET @returnValue = ABS(@iValue)
	END
	ELSE
	BEGIN
		SET @returnValue = @iValue
	END
	
	RETURN @returnValue
END
GO

GRANT EXECUTE ON dbo.GetBhpbioFloatOptionalAbsolute TO BhpbioGenericManager
GO

IF Object_Id('dbo.GetBhpbioFilteredMaterialTypes') IS NOT NULL
	DROP FUNCTION dbo.GetBhpbioFilteredMaterialTypes
GO

CREATE FUNCTION [dbo].[GetBhpbioFilteredMaterialTypes]
(
	@iIsHighGrade BIT,
	@iSpecificMaterialTypeId INTEGER
)
RETURNS @MaterialType TABLE
(
	MaterialTypeId INT NOT NULL
	PRIMARY KEY (MaterialTypeId)
)
WITH ENCRYPTION
AS
BEGIN
	
	-- Only Designation types are to be considered
	DECLARE @MaterialCategory VARCHAR(31)
	SET @MaterialCategory = 'Designation'
	
	-- insert the Identifiers of MaterialTypes that match the supplied criteria
	INSERT INTO @MaterialType
	(
		MaterialTypeId
	)
	SELECT mt.Material_Type_Id
	FROM dbo.MaterialType mt
		INNER JOIN dbo.GetMaterialsByCategory(@MaterialCategory) mc
			ON (mc.MaterialTypeId = mt.Material_Type_Id)
		INNER JOIN dbo.MaterialType rmt
			ON (rmt.Material_Type_Id = mc.RootMaterialTypeId)
		LEFT JOIN dbo.GetBhpbioReportHighGrade() AS brhg
			ON (brhg.MaterialTypeId = rmt.Material_Type_Id)
	WHERE (@iSpecificMaterialTypeId IS NULL
			OR mt.Material_Type_Id = @iSpecificMaterialTypeId
			OR rmt.Material_Type_Id = @iSpecificMaterialTypeId)
		AND ((@iIsHighGrade = 0 AND brhg.MaterialTypeId IS NULL)
			OR (@iIsHighGrade = 1 AND brhg.MaterialTypeId IS NOT NULL)
			OR (@iIsHighGrade IS NULL))
	
	-- the WHERE clause above can be read as
	-- where
	--   (
	--   there is no specific type specified, 
	--   or the row is an exact match to the specified type
	--   or the row is related to the specified type
	--   )
	-- AND
	--   (
	--   we are looking for High Grade types only and the row is a High Grade type
	--   or we are looking for NON-High Grade types only and the row is NOT a High Grade type
	--   or we are not concerned at all with the High Grade filter
	--   )
	
	RETURN
END
GO

/*

-- returns set of high grade material types
SELECT * FROM dbo.GetBhpbioFilteredMaterialTypes(	@iIsHighGrade = 1,
													@iSpecificMaterialTypeId = null)
													
-- returns a specific material type (and related types ) only
SELECT * FROM dbo.GetBhpbioFilteredMaterialTypes(	@iIsHighGrade = null,
													@iSpecificMaterialTypeId = 6
			

*/


/*
<TAG Name="Data Dictionary" FunctionName="dbo.GetBhpbioFilteredMaterialTypes">
 <Function>
	Gets a table of Material Types that are either classified as High Grade (if high grade flag used) or otherwise are related to a specific material type
			
	Pass: 
			@iIsHighGrade: If 1, only high grade types are included
			@iSpecificMaterialTypeId: if specified, only material types that match this type exactly or are related to this type (child types) wll be returned
	
	Returns: Table of material types that match supplied filter
 </Function>
</TAG>
*/

IF OBJECT_ID('dbo.GetBhpbioWeightometerSampleSource') IS NOT NULL 
     DROP FUNCTION dbo.GetBhpbioWeightometerSampleSource
Go 

CREATE FUNCTION dbo.GetBhpbioWeightometerSampleSource
(
	@iLocationId INT,
	@iDateFrom DATETIME,
	@iDateTo DATETIME
)
RETURNS @SampleSource TABLE
(
	LocationId INT,
	MonthPeriod DATETIME,
	SampleSource VARCHAR(255) COLLATE DATABASE_DEFAULT
	PRIMARY KEY (LocationId, MonthPeriod, SampleSource)
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @CrusherActuals VARCHAR(31)
	DECLARE @UndilutedRakes VARCHAR(31)
	DECLARE @PortActuals VARCHAR(31)
	DECLARE @ShuttleGrades VARCHAR(31)
	SET @CrusherActuals = 'CRUSHER ACTUALS'
	SET @UndilutedRakes = 'UNDILUTED RAKES'
	SET @PortActuals = 'PORT ACTUALS'
	SET @ShuttleGrades = 'SHUTTLE'

	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		ParentLocationId INT NULL,
		PRIMARY KEY (LocationId)
	)
	
	DECLARE	@SampleSourceCount TABLE
	(
		LocationId INT,
		MonthPeriod DATETIME,
		SampleSource VARCHAR(255) COLLATE DATABASE_DEFAULT,
		CountSamples INT,
		PRIMARY KEY (LocationId, MonthPeriod, SampleSource)
	)
	
	-- Setup the Locations
	INSERT INTO @Location
		(LocationId, ParentLocationId)
	SELECT LocationId, ParentLocationId
	FROM dbo.GetBhpbioReportLocationBreakdown(@iLocationId, 0, 'Site')

	INSERT INTO @SampleSource
		(LocationId, MonthPeriod, SampleSource)
	SELECT L.LocationId, dbo.GetDateMonth(WS.Weightometer_Sample_Date) As MonthPeriod, WSN.Notes
	FROM @Location AS L
		INNER JOIN dbo.CrusherLocation AS CL
			ON (CL.Location_Id = L.LocationId)
		INNER JOIN dbo.WeightometerFlowPeriod AS WFP
			ON (WFP.Source_Crusher_Id = CL.Crusher_Id)
		INNER JOIN dbo.WeightometerSample AS WS
			ON (WS.Weightometer_Id = WFP.Weightometer_Id)
		INNER JOIN dbo.WeightometerSampleNotes AS WSN
			ON (WSN.Weightometer_Sample_Field_Id = 'SampleSource'
				AND WS.Weightometer_Sample_Id = WSN.Weightometer_Sample_Id)
	WHERE WS.Weightometer_Sample_Date BETWEEN @iDateFrom AND @iDateTo
		AND WSN.Notes IN (@CrusherActuals)
	GROUP BY dbo.GetDateMonth(WS.Weightometer_Sample_Date), L.LocationId, WSN.Notes
	
	INSERT INTO @SampleSourceCount
		(LocationId, MonthPeriod, SampleSource, CountSamples)
	SELECT L.LocationId, dbo.GetDateMonth(WS.Weightometer_Sample_Date) As MonthPeriod, WSN.Notes, Count(*)
	FROM @Location AS L
		INNER JOIN dbo.WeightometerLocation AS WL
			ON (WL.Location_Id = L.LocationId)
		INNER JOIN dbo.WeightometerSample AS WS
			ON (WL.Weightometer_Id = WS.Weightometer_Id)
		LEFT JOIN dbo.WeightometerFlowPeriodView AS WFPV
			ON (WFPV.Weightometer_Id = WS.Weightometer_Id
				AND (WS.Weightometer_Sample_Date > WFPV.Start_Date Or WFPV.Start_Date IS NULL)
				AND (WS.Weightometer_Sample_Date < WFPV.End_Date Or WFPV.End_Date IS NULL))	
		INNER JOIN dbo.StockpileGroupStockpile AS SGS
			ON (SGS.Stockpile_Id = Coalesce(WFPV.Destination_Stockpile_Id, WS.Destination_Stockpile_Id))
		INNER JOIN dbo.WeightometerSampleNotes AS WSN
			ON (WSN.Weightometer_Sample_Field_Id = 'SampleSource'
				AND WS.Weightometer_Sample_Id = WSN.Weightometer_Sample_Id)
		LEFT JOIN @SampleSource AS SS
			ON (SS.LocationID = L.LocationId
				AND SS.MonthPeriod = dbo.GetDateMonth(WS.Weightometer_Sample_Date))
	WHERE WS.Weightometer_Sample_Date BETWEEN @iDateFrom AND @iDateTo
		AND WSN.Notes IN (@ShuttleGrades)
		AND SGS.Stockpile_Group_Id in ('HUB Train Rake', 'Port Train Rake')
		AND SS.SampleSource IS NULL
		-- new logic to deal with transistioning phase of RGP4
		AND WS.Weightometer_Sample_Date >= '01-NOV-2009'
	GROUP BY dbo.GetDateMonth(WS.Weightometer_Sample_Date), L.LocationId, WSN.Notes	
		
	INSERT INTO @SampleSource
		(LocationId, MonthPeriod, SampleSource)
	SELECT L.LocationId, dbo.GetDateMonth(WS.Weightometer_Sample_Date) As MonthPeriod, WSN.Notes
	FROM @Location AS L
		INNER JOIN dbo.WeightometerLocation AS WL
			ON (WL.Location_Id = L.LocationId)
		INNER JOIN dbo.WeightometerSample AS WS
			ON (WL.Weightometer_Id = WS.Weightometer_Id)
		INNER JOIN dbo.StockpileGroupStockpile AS SGS
			ON (SGS.Stockpile_Id = WS.Destination_Stockpile_Id)
		INNER JOIN dbo.WeightometerSampleNotes AS WSN
			ON (WSN.Weightometer_Sample_Field_Id = 'SampleSource'
				AND WS.Weightometer_Sample_Id = WSN.Weightometer_Sample_Id)
		LEFT JOIN @SampleSource AS SS
			ON (SS.LocationID = L.LocationId
				AND SS.MonthPeriod = dbo.GetDateMonth(WS.Weightometer_Sample_Date))
		LEFT JOIN @SampleSourceCount SSC
			ON (SSC.LocationID = L.LocationId
				AND SSC.MonthPeriod = dbo.GetDateMonth(WS.Weightometer_Sample_Date))
	WHERE WS.Weightometer_Sample_Date BETWEEN @iDateFrom AND @iDateTo
		AND WSN.Notes IN (@UndilutedRakes, @PortActuals)
		AND SGS.Stockpile_Group_Id in ('HUB Train Rake', 'Port Train Rake')
		AND SS.SampleSource IS NULL
	GROUP BY dbo.GetDateMonth(WS.Weightometer_Sample_Date), L.LocationId, WSN.Notes	
	HAVING Count(*) > Coalesce(MAX(CountSamples), 0) Or dbo.GetDateMonth(WS.Weightometer_Sample_Date) < '01-NOV-2009'
		
	INSERT INTO @SampleSource
	(LocationId, MonthPeriod, SampleSource)
	SELECT LocationId, MonthPeriod, SampleSource
	FROM @SampleSourceCount
	
	-- Remove non Undiluted Rakes if are also port actuals.
	DELETE SS
	FROM @SampleSource AS SS
		INNER JOIN @SampleSource AS OSS
			ON (SS.LocationID = OSS.LocationId 
				AND SS.MonthPeriod = OSS.MonthPeriod
				AND OSS.SampleSource = @UndilutedRakes)
	WHERE SS.SampleSource = @PortActuals
	
	RETURN
END
GO

/*
select ws.*, l.name, lt.description
from dbo.GetBhpbioWeightometerSampleSource(1, '01-apr-2009', '30-jun-2009') as ws
	inner join location as l
		on l.location_id = ws.locationId
	inner join locationtype as lt
		on l.location_type_id = lt.location_type_id
*/


IF Object_Id('dbo.GetBhpbioIntCollection') IS NOT NULL
	DROP FUNCTION dbo.GetBhpbioIntCollection
GO

CREATE FUNCTION dbo.GetBhpbioIntCollection
(
	@iText VARCHAR(1000)
)
RETURNS @Values TABLE
(
	Value INT NOT NULL
)
WITH ENCRYPTION
AS 
BEGIN
	DECLARE @Index INT, @Value VARCHAR(10)
	SET @iText = RTRIM(LTRIM(@iText))
	IF ISNULL(@iText,'') != ''
	BEGIN
		WHILE @iText IS NOT NULL AND LEN(@iText) > 0
		BEGIN
			SET @Index = CHARINDEX(',',@iText)
			IF @Index > 0
			BEGIN
				SET @Value = SUBSTRING(@iText,0,@Index)
				SET @iText = SUBSTRING(@iText,@Index + 1,1000)
			END
			ELSE
			BEGIN
				SET @Value = @iText
				SET @iText = NULL
			END
			IF ISNUMERIC(@Value) = 1
			BEGIN
				INSERT @Values 
				SELECT CONVERT(INT,@Value)
				WHERE NOT EXISTS (SELECT * FROM @Values WHERE Value = CONVERT(INT,@Value))
				
			END
		END
	END
	RETURN
END
GO

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
		PRIMARY KEY (LocationId)
	)
	
	DECLARE @DesiredLocation TABLE
	(
		LocationId INT NOT NULL,
		ParentLocationId INT NULL,
		PRIMARY KEY (LocationId)
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
	SET @SiteLocationTypeId =
		(
			SELECT Location_Type_Id
			FROM dbo.LocationType
			WHERE Description = 'Site'
		)
	
	INSERT INTO @SiteLocation
		(LocationId)
	SELECT LocationId
	FROM dbo.GetLocationSubtreeByLocationType(@iLocationId, @SiteLocationTypeId, @SiteLocationTypeId)

	-- this represents the location tree for what's desired	
	INSERT INTO @DesiredLocation
		(LocationId, ParentLocationId)
	SELECT LocationId, ParentLocationId
	FROM dbo.GetBhpbioReportLocationBreakdown(@iLocationId, @iGetChildLocations, 'Site')
	
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
							ON (cl.Location_Id = l.LocationId)
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
							ON (wl.Location_Id = l.LocationId)
					WHERE dtt.Data_Transaction_Tonnes_Date BETWEEN @iDateFrom AND @iDateTo
						AND sgs.Stockpile_Group_Id = 'Port Train Rake'
					GROUP BY dttf.Weightometer_Sample_Id, l.LocationId
				  ) AS w
				ON (ws.Weightometer_Sample_Id = w.WeightometerSampleId)
				-- ensure the weightometer belongs to the required location
			INNER JOIN dbo.WeightometerLocation AS wl
				ON (wl.Weightometer_Id = ws.Weightometer_Id)
			INNER JOIN @SiteLocation AS l
				ON (l.LocationId = wl.Location_Id)
			LEFT OUTER JOIN dbo.WeightometerSampleValue AS wsv
				ON (ws.Weightometer_Sample_Id = wsv.Weightometer_Sample_Id
					AND wsv.Weightometer_Sample_Field_Id = @SampleTonnesField)
			-- This join is a way of testing whether there is an approval for the same location and period as this weightometer sample
			-- if so, the row will be ignored
			LEFT JOIN dbo.BhpbioApprovalData bad
				ON bad.LocationId = l.LocationId
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
		
		
		-- Retrieve Grades
		SET @summaryEntryType = 'ActualCSampleTonnes'
		
		INSERT INTO @CSite
			(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, SiteLocationId, SampleTonnes, Attribute, Value)
		SELECT s.CalendarDate, s.DateFrom, s.DateTo, s.MaterialTypeId, s.LocationId, s.Tonnes, s.GradeId,  s.GradeValue
		FROM dbo.GetBhpbioSummaryGradeBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryType, 0, 1, 0) s
			INNER JOIN @SiteLocation l
				ON l.LocationId = s.LocationId
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
			ON (c.SiteLocationId = l.LocationId)
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
			ON (cg.SiteLocationId = l.LocationId)
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

*/

IF Object_Id('dbo.GetBhpbioReportActualY') IS NOT NULL
	DROP FUNCTION dbo.GetBhpbioReportActualY
GO

CREATE FUNCTION dbo.GetBhpbioReportActualY
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iGetChildLocations BIT,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT
)
RETURNS @Y TABLE
(
	CalendarDate DATETIME NOT NULL,
	DateFrom DATETIME NOT NULL,
	DateTo DATETIME NOT NULL,
	DesignationMaterialTypeId INT NOT NULL,
	LocationId INT NULL,
	Attribute INT NULL,
	Value FLOAT NULL
)
WITH ENCRYPTION
AS
BEGIN

	DECLARE @YIntermediate TABLE
	(
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		DesignationMaterialTypeId INT NOT NULL,
		LocationId INT NULL,
		Attribute INT NULL,
		Value FLOAT NULL,
		AssociatedTonnes FLOAT NULL
	)
	-- 'y' - pit to pre-crusher stockpiles
	-- the material types must be reported accurately

	DECLARE @Haulage TABLE
	(
		CalendarDate DATETIME NOT NULL,
		HaulageId INT NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		ParentLocationId INT NULL,
		Tonnes FLOAT NOT NULL,
		DesignationMaterialTypeId INT NOT NULL,
		PRIMARY KEY (HaulageId, CalendarDate)
	)
	
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		ParentLocationId INT NULL,
		PRIMARY KEY (LocationId)
	)

	-- setup the Locations
	INSERT INTO @Location
		(LocationId, ParentLocationId)
	SELECT LocationId, ParentLocationId
	FROM dbo.GetBhpbioReportLocationBreakdown(@iLocationId, @iGetChildLocations, NULL)

	IF @iIncludeLiveData = 1
	BEGIN
		-- retrieve the list of Haulage Records to be used in the calculations
		INSERT INTO @Haulage
			(CalendarDate, DateFrom, DateTo, HaulageId, ParentLocationId, Tonnes, DesignationMaterialTypeId)
		SELECT rd.CalendarDate, rd.DateFrom, rd.DateTo, h.Haulage_Id, l.ParentLocationId, h.Tonnes,
			destinationStockpile.MaterialTypeId
		FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1) AS rd
			INNER JOIN dbo.Haulage AS h
				ON (h.Haulage_Date BETWEEN rd.DateFrom AND rd.DateTo)
			INNER JOIN dbo.DigblockLocation dl
				ON (dl.Digblock_Id = h.Source_Digblock_Id)
			INNER JOIN @Location AS l
				ON (l.LocationId = dl.Location_Id)
			INNER JOIN dbo.Location block
				ON block.Location_Id = l.LocationId
			INNER JOIN dbo.Location blast
				ON blast.Location_Id = block.Parent_Location_Id
			INNER JOIN dbo.Location bench
				ON bench.Location_Id = blast.Parent_Location_Id
			INNER JOIN dbo.Location pit
				ON pit.Location_Id = bench.Parent_Location_Id
			-- join to the destination stockpile
			INNER JOIN
				(
					SELECT sl2.Stockpile_Id, sgd2.MaterialTypeId
					FROM dbo.BhpbioStockpileGroupDesignation AS sgd2
						INNER JOIN dbo.StockpileGroupStockpile AS sgs2
							ON (sgs2.Stockpile_Group_Id = sgd2.StockpileGroupId)
						INNER JOIN dbo.StockpileLocation AS sl2
							ON (sl2.Stockpile_Id = sgs2.Stockpile_Id)
				) AS destinationStockpile
				ON (destinationStockpile.Stockpile_Id = h.Destination_Stockpile_Id)
			LEFT JOIN dbo.GetBhpbioFilteredMaterialTypes(1,null) hgmt
				ON hgmt.MaterialTypeId = destinationStockpile.MaterialTypeId
		WHERE h.Haulage_State_Id IN ('N', 'A')
			AND h.Child_Haulage_Id IS NULL
			AND h.Source_Digblock_Id IS NOT NULL
			-- filter out data for approved periods IF we are also retrieving Approved data in this call
			AND NOT (
				@iIncludeApprovedData = 1
				AND EXISTS (
						SELECT bad.TagId
						FROM dbo.BhpbioApprovalData bad
							INNER JOIN dbo.BhpbioReportDataTags brdt
							ON brdt.TagId = bad.TagId
						WHERE	bad.LocationId = pit.Location_Id
							AND bad.ApprovedMonth = dbo.GetDateMonth(h.Haulage_Date)
							AND
							(
								(	bad.TagId = 'F1Factor'
									AND hgmt.MaterialTypeId IS NOT NULL	)
								OR 
								(	bad.TagId like 'Other%'
									AND destinationStockpile.MaterialTypeId = brdt.OtherMaterialTypeId )
							)
						)
					)
				

		-- return the TONNES values
		INSERT INTO @YIntermediate
			(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value)
		SELECT CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, ParentLocationId, 0, SUM(Tonnes)
		FROM @Haulage
		GROUP BY CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, ParentLocationId

		-- return the GRADES values
		INSERT INTO @YIntermediate
			(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value, AssociatedTonnes)
		SELECT h.CalendarDate, h.DateFrom, h.DateTo, h.DesignationMaterialTypeId, h.ParentLocationId,
			g.Grade_Id, SUM(h.Tonnes * hg.Grade_Value) / NULLIF(SUM(h.Tonnes), 0.0), SUM(h.Tonnes)
		FROM @Haulage AS h
			-- add the grades
			CROSS JOIN dbo.Grade AS g
			LEFT JOIN dbo.HaulageGrade AS hg
				ON (h.HaulageId = hg.Haulage_Id
					AND g.Grade_Id = hg.Grade_Id)
		GROUP BY h.CalendarDate, h.DateFrom, h.DateTo, g.Grade_Id, h.DesignationMaterialTypeId, h.ParentLocationId
	END
	
	-- if including approved data
	IF @iIncludeApprovedData = 1
	BEGIN
		-- Determine the SummaryEntryTypeIds for the appropriate types (ActualY and ActualOMToStockpile)
		-- Both these types are need to include movements of all material types
		DECLARE @actualYSummaryEntryTypeId INTEGER
		DECLARE @otherToStockpileSummaryEntryTypeId INTEGER
		
		SELECT @actualYSummaryEntryTypeId = bset.SummaryEntryTypeId 
		FROM dbo.BhpbioSummaryEntryType bset
		WHERE bset.Name = 'ActualY'
		
		SELECT @otherToStockpileSummaryEntryTypeId = bset.SummaryEntryTypeId 
		FROM dbo.BhpbioSummaryEntryType bset
		WHERE bset.Name = 'ActualOMToStockpile'
		
		-- Retrieve Tonnes
		INSERT INTO @YIntermediate
			(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value)
		SELECT B.CalendarDate AS CalendarDate, B.DateFrom, B.DateTo, bse.MaterialTypeId, l.ParentLocationId, 0,  SUM(bse.Tonnes) AS Tonnes
		FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
			INNER JOIN dbo.BhpbioSummary s WITH (NOLOCK)
				ON s.SummaryMonth >= B.DateFrom AND s.SummaryMonth < B.DateTo
			INNER JOIN dbo.BhpbioSummaryEntry AS bse WITH (NOLOCK)
				ON bse.SummaryId = s.SummaryId
				AND (bse.SummaryEntryTypeId IN (@actualYSummaryEntryTypeId, @otherToStockpileSummaryEntryTypeId))
			INNER JOIN @Location l
				ON l.LocationId = bse.LocationId
		GROUP BY B.CalendarDate, B.DateFrom, B.DateTo, bse.MaterialTypeId, l.ParentLocationId

		-- Retrieve Grades
		INSERT INTO @YIntermediate
			(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value, AssociatedTonnes)
		SELECT B.CalendarDate AS CalendarDate, B.DateFrom, B.DateTo, bse.MaterialTypeId, l.ParentLocationId, 
			bseg.GradeId,
			SUM(bse.Tonnes * bseg.GradeValue) / SUM(bse.Tonnes) As GradeValue, SUM(bse.Tonnes)
		FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
			INNER JOIN dbo.BhpbioSummary s WITH (NOLOCK)
				ON s.SummaryMonth >= B.DateFrom AND s.SummaryMonth < B.DateTo
			INNER JOIN dbo.BhpbioSummaryEntry AS bse WITH (NOLOCK)
				ON bse.SummaryId = s.SummaryId
				AND (bse.SummaryEntryTypeId IN (@actualYSummaryEntryTypeId, @otherToStockpileSummaryEntryTypeId))
			INNER JOIN @Location l
				ON l.LocationId = bse.LocationId
			INNER JOIN dbo.BhpbioSummaryEntryGrade AS bseg WITH (NOLOCK)
				ON bseg.SummaryEntryId = bse.SummaryEntryId
		GROUP BY B.CalendarDate, B.DateFrom, B.DateTo, bse.MaterialTypeId, l.ParentLocationId, bseg.GradeId
	END
	
		-- insert tonnes into the combined table
	INSERT INTO @Y
		(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value)
	SELECT yi.CalendarDate, yi.DateFrom, yi.DateTo, yi.DesignationMaterialTypeId,
		yi.LocationId, yi.Attribute, SUM(yi.Value)
	FROM @YIntermediate AS yi
	WHERE yi.Attribute = 0
	GROUP BY  yi.CalendarDate, yi.DateFrom, yi.DateTo, yi.DesignationMaterialTypeId, yi.LocationId, yi.Attribute
	
	-- insert grades into the combined table
	INSERT INTO @Y
		(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value)
	SELECT yi.CalendarDate, yi.DateFrom, yi.DateTo, yi.DesignationMaterialTypeId,
		yi.LocationId, yi.Attribute, SUM(yi.Value * yi.AssociatedTonnes) / SUM(yi.AssociatedTonnes)
	FROM @YIntermediate AS yi
	WHERE yi.Attribute > 0
	GROUP BY  yi.CalendarDate, yi.DateFrom, yi.DateTo, yi.DesignationMaterialTypeId, yi.LocationId, yi.Attribute
	
	
	RETURN
END
GO

/*
SELECT * FROM dbo.GetBhpbioReportActualY('01-APR-2008', '30-JUN-2008', 'MONTH', 1, 1, 1, 1)
SELECT * FROM dbo.GetBhpbioReportActualY('01-APR-2008', '30-JUN-2008', 'MONTH', 1, 0, 1, 1)
SELECT * FROM dbo.GetBhpbioReportActualY('01-APR-2008', '30-JUN-2008', NULL, 1, 0, 1, 1)
*/
IF Object_Id('dbo.GetBhpbioReportActualZ') IS NOT NULL
	DROP FUNCTION dbo.GetBhpbioReportActualZ
GO

CREATE FUNCTION dbo.GetBhpbioReportActualZ
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iGetChildLocations BIT,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT
)
RETURNS @Z TABLE
(
	CalendarDate DATETIME NOT NULL,
	DateFrom DATETIME NOT NULL,
	DateTo DATETIME NOT NULL,
	DesignationMaterialTypeId INT NOT NULL,
	LocationId INT NULL,
	Attribute INT NULL,
	Value FLOAT NULL
)
WITH ENCRYPTION
AS
BEGIN

	DECLARE @ZIntermediate TABLE
	(
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		DesignationMaterialTypeId INT NOT NULL,
		LocationId INT NULL,
		Attribute INT NULL,
		Value FLOAT NULL,
		AssociatedTonnes FLOAT NULL
	)
	
	
	
	-- 'Z' - pre crusher stockpiles to crusher
	-- movements through the crusher must be reported as [High Grade] and [Bene Feed] only

	DECLARE @Haulage TABLE
	(
		CalendarDate DATETIME NOT NULL,
		HaulageId INT NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		ParentLocationId INT NULL,
		Tonnes FLOAT NOT NULL,
		DesignationMaterialTypeId INT NOT NULL,
		PRIMARY KEY (HaulageId, CalendarDate)
	)
	
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		ParentLocationId INT NULL,
		PRIMARY KEY (LocationId)
	)

	DECLARE @HighGradeMaterialTypeId INT
	DECLARE @BeneFeedMaterialTypeId INT

	-- set the material types
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
	
	-- setup the Locations
	INSERT INTO @Location
		(LocationId, ParentLocationId)
	SELECT LocationId, ParentLocationId
	FROM dbo.GetBhpbioReportLocationBreakdown(@iLocationId, @iGetChildLocations, NULL)
	
	IF @iGetChildLocations = 1
	BEGIN
		INSERT INTO @Location (LocationId, ParentLocationId)
		SELECT @iLocationId, @iLocationId
	END
	
	IF @iIncludeLiveData = 1
	BEGIN
		-- collect the haualge data that matches:
		-- 1. the date range specified
		-- 2. delivers to a crusher (which belongs to the location subtree specified)
		-- 3. sources from a designation stockpile group
		--
		-- for the Material Type, the following rule applies:
		-- If the Weightometer deliveres to a plant then it is BENE, otherwise it is High Grade.

		-- retrieve the list of Haulage Records to be used in the calculations
		INSERT INTO @Haulage	
			(CalendarDate, DateFrom, DateTo, HaulageId, ParentLocationId, Tonnes, DesignationMaterialTypeId)
		SELECT b.CalendarDate, b.DateFrom, b.DateTo, h.Haulage_Id, l.ParentLocationId, h.Tonnes,
			CASE WHEN W.Weightometer_Id IS NOT NULL THEN @BeneFeedMaterialTypeId ELSE @HighGradeMaterialTypeId END
		FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS b
				INNER JOIN dbo.Haulage AS h
					ON (h.Haulage_Date BETWEEN b.DateFrom AND b.DateTo)
				INNER JOIN dbo.Crusher AS c
					ON (c.Crusher_Id = h.Destination_Crusher_Id)
				INNER JOIN dbo.CrusherLocation AS cl
					ON (cl.Crusher_Id = c.Crusher_Id)
				INNER JOIN @Location AS l
					ON (l.LocationId = cl.Location_Id)
				INNER JOIN dbo.Stockpile AS s
					ON (h.Source_Stockpile_Id = s.Stockpile_Id)
				INNER JOIN dbo.StockpileGroupStockpile AS sgs
					ON (sgs.Stockpile_Id = s.Stockpile_Id)
				INNER JOIN dbo.BhpbioStockpileGroupDesignation AS sgd
					ON (sgd.StockpileGroupId = sgs.Stockpile_Group_Id)
				LEFT JOIN dbo.WeightometerFlowPeriodView AS WFPV
					ON (WFPV.Source_Crusher_Id = c.Crusher_Id
						AND WFPV.Destination_Mill_Id IS NOT NULL
						AND (b.DateTo > WFPV.Start_Date Or WFPV.Start_Date IS NULL)
						AND (b.DateFrom < WFPV.End_Date Or WFPV.End_Date IS NULL))
				LEFT JOIN dbo.Weightometer AS W
					ON (W.Weightometer_Id = WFPV.Weightometer_Id)
				-- This join is used to test whethere there is an associated Approval for this data
				LEFT JOIN dbo.BhpbioApprovalData bad
					ON bad.LocationId = cl.Location_Id
					AND bad.ApprovedMonth = dbo.GetDateMonth(h.Haulage_Date)
					AND bad.TagId = 'F2StockpileToCrusher'
			WHERE h.Haulage_State_Id IN ('N', 'A')
				AND h.Child_Haulage_Id IS NULL
				AND (W.Weightometer_Type_Id LIKE '%L1%' OR W.Weightometer_Type_Id IS NULL)
				AND h.Source_Stockpile_Id IS NOT NULL
				-- And either there is no associated approval for the data, or there is but we are not retrieving approved data in this call
				AND (bad.TagId IS NULL OR @iIncludeApprovedData = 0)
				
		-- return the TONNES values
		INSERT INTO @ZIntermediate
			(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value)
		SELECT CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, ParentLocationId, 0, SUM(Tonnes)
		FROM @Haulage
		GROUP BY CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, ParentLocationId

		-- return the GRADES values
		INSERT INTO @ZIntermediate
			(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value, AssociatedTonnes)
		SELECT h.CalendarDate, h.DateFrom, h.DateTo, h.DesignationMaterialTypeId, h.ParentLocationId,
			g.Grade_Id, SUM(h.Tonnes * hg.Grade_Value) / NULLIF(SUM(h.Tonnes), 0.0), SUM(h.Tonnes)
		FROM @Haulage AS h
			-- add the grades
			CROSS JOIN dbo.Grade AS g
			LEFT JOIN dbo.HaulageGrade AS hg
				ON (h.HaulageId = hg.Haulage_Id
					AND g.Grade_Id = hg.Grade_Id)
		GROUP BY h.CalendarDate, h.DateFrom, h.DateTo, g.Grade_Id, h.DesignationMaterialTypeId, h.ParentLocationId
	END
	
	-- if including approved data
	IF @iIncludeApprovedData = 1
	BEGIN
		-- obtain the related SummaryEntryTypeId
		DECLARE @summaryEntryType VARCHAR(24)
		SET @summaryEntryType = 'ActualZ'
		
		-- Retrieve Tonnes
		INSERT INTO @ZIntermediate
			(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value)
		SELECT s.CalendarDate, s.DateFrom, s.DateTo, s.MaterialTypeId, l.ParentLocationId, 0,  s.Tonnes
		FROM dbo.GetBhpbioSummaryTonnesBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryType, 0) s
			INNER JOIN @Location l
				ON l.LocationId = s.LocationId
		
		-- Retrieve Grades
		INSERT INTO @ZIntermediate
			(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value, AssociatedTonnes)
		SELECT s.CalendarDate, s.DateFrom, s.DateTo, s.MaterialTypeId, l.ParentLocationId, s.GradeId,  s.GradeValue, s.Tonnes
		FROM dbo.GetBhpbioSummaryGradeBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryType, 0, 1, 0) s
			INNER JOIN @Location l
				ON l.LocationId = s.LocationId
		ORDER BY s.CalendarDate, s.LocationId, s.GradeId, s.MaterialTypeId
	END
	
	-- insert tonnes into the combined table
	INSERT INTO @Z
		(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value)
	SELECT zi.CalendarDate, zi.DateFrom, zi.DateTo, zi.DesignationMaterialTypeId,
		zi.LocationId, zi.Attribute, SUM(zi.Value)
	FROM @ZIntermediate AS zi
	WHERE zi.Attribute = 0
	GROUP BY  zi.CalendarDate, zi.DateFrom, zi.DateTo, zi.DesignationMaterialTypeId, zi.LocationId, zi.Attribute
	
	-- insert grades into the combined table
	INSERT INTO @Z
		(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value)
	SELECT zi.CalendarDate, zi.DateFrom, zi.DateTo, zi.DesignationMaterialTypeId,
		zi.LocationId, zi.Attribute, SUM(zi.Value * zi.AssociatedTonnes) / SUM(zi.AssociatedTonnes)
	FROM @ZIntermediate AS zi
	WHERE zi.Attribute > 0
	GROUP BY  zi.CalendarDate, zi.DateFrom, zi.DateTo, zi.DesignationMaterialTypeId, zi.LocationId, zi.Attribute
	
	RETURN
END
GO

/*
select * FROM dbo.GetBhpbioReportActualZ('1-apr-2008', '30-apr-2008', Null, 6, 1, 1, 1) 
SELECT * FROM dbo.GetBhpbioReportActualZ('01-APR-2008', '30-JUN-2008', 'MONTH', 1, 1, 1, 1)
SELECT * FROM dbo.GetBhpbioReportActualZ('01-APR-2008', '30-JUN-2008', 'MONTH', 1, 0, 1, 1)
SELECT * FROM dbo.GetBhpbioReportActualZ('01-APR-2008', '30-JUN-2008', NULL, 1, 0, 1, 1)
*/

IF Object_Id('dbo.GetBhpbioReportModel') IS NOT NULL
	DROP FUNCTION dbo.GetBhpbioReportModel
GO

CREATE FUNCTION dbo.GetBhpbioReportModel
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iGetChildLocations BIT,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT
)
RETURNS @M TABLE
(
	CalendarDate DATETIME NOT NULL,
	BlockModelId INT NOT NULL,
	DateFrom DATETIME NOT NULL,
	DateTo DATETIME NOT NULL,
	DesignationMaterialTypeId INT NOT NULL,
	LocationId INT NULL,
	Attribute SMALLINT NULL,
	Value FLOAT NULL
)
WITH ENCRYPTION
AS
BEGIN
	-- 'M' - all model movements
	-- returns all designation types
	DECLARE @Model TABLE
	(
		CalendarDate DATETIME NOT NULL,
		BlockModelId INT NOT NULL,
		ModelBlockId INT NOT NULL,
		SequenceNo INT NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		ParentLocationId INT NULL,
		Tonnes FLOAT NOT NULL,
		DesignationMaterialTypeId INT NOT NULL,
		PRIMARY KEY (ModelBlockId, SequenceNo, BlockModelId, CalendarDate)
	)
	
	DECLARE @outputStaging TABLE
	(
		CalendarDate DATETIME NOT NULL,
		BlockModelId INT NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		DesignationMaterialTypeId INT NOT NULL,
		LocationId INT NULL,
		Attribute SMALLINT NULL,
		Value FLOAT NULL,
		AssociatedTonnes FLOAT NULL
	)
	
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		ParentLocationId INT NULL,
		PRIMARY KEY (LocationId)
	)

	DECLARE @MaterialCategory VARCHAR(31)
	SET @MaterialCategory = 'Designation'
	
	-- Setup the Locations
	INSERT INTO @Location
		(LocationId, ParentLocationId)
	SELECT LocationId, ParentLocationId
	FROM dbo.GetBhpbioReportLocationBreakdown(@iLocationId, @iGetChildLocations, NULL)

	IF @iIncludeLiveData = 1
	BEGIN
		-- retrieve the list of Model Block Partials to be used in the calculations
		INSERT INTO @Model
			(CalendarDate, DateFrom, DateTo, BlockModelId, ModelBlockId, SequenceNo, ParentLocationId, Tonnes, DesignationMaterialTypeId)
		SELECT b.CalendarDate, b.DateFrom, b.DateTo, mb.Block_Model_Id, mbp.Model_Block_Id, mbp.Sequence_No, l.ParentLocationId,
			SUM(mbp.Tonnes * rm.MinedPercentage), MT.Material_Type_Id
		FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1) AS b
			INNER JOIN dbo.BhpbioImportReconciliationMovement AS rm WITH (NOLOCK)
				ON (rm.DateFrom >= b.DateFrom
					AND rm.DateTo <= b.DateTo)
			INNER JOIN dbo.ModelBlockLocation AS mbl WITH (NOLOCK)
				ON (mbl.Location_Id = rm.BlockLocationId)
			INNER JOIN dbo.ModelBlock AS mb WITH (NOLOCK)
				ON (mb.Model_Block_Id = mbl.Model_Block_Id)
			INNER JOIN dbo.ModelBlockPartial AS mbp WITH (NOLOCK)
				ON (mbp.Model_Block_Id = mb.Model_Block_Id)
			INNER JOIN dbo.BlockModel bm WITH (NOLOCK)
				ON bm.Block_Model_Id = mb.Block_Model_Id
			-- filter by location
			INNER JOIN @Location AS l
				ON (mbl.Location_Id = l.LocationId)
			INNER JOIN dbo.GetMaterialsByCategory(@MaterialCategory) AS MC
				ON (MC.MaterialTypeId = MBP.Material_Type_Id)
			INNER JOIN dbo.MaterialType AS MT WITH (NOLOCK)
				ON (MC.RootMaterialTypeId = MT.Material_Type_Id)
			LEFT JOIN dbo.GetBhpbioReportHighGrade() AS BRHG
				ON (BRHG.MaterialTypeId = MT.Material_Type_Id)
			INNER JOIN dbo.Location block  WITH (NOLOCK)
				ON block.Location_Id = L.LocationId
			INNER JOIN dbo.Location blast  WITH (NOLOCK)
				ON blast.Location_Id = block.Parent_Location_Id
			INNER JOIN dbo.Location bench WITH (NOLOCK)
				ON bench.Location_Id = blast.Parent_Location_Id
			INNER JOIN dbo.Location pit WITH (NOLOCK)
				ON pit.Location_Id = bench.Parent_Location_Id
			-- This join is used to determine whether there is an associated approval for this data
			LEFT JOIN dbo.BhpbioApprovalData a WITH (NOLOCK)
				ON a.LocationId = pit.Location_Id
				AND a.TagId = 'F1' + REPLACE(bm.Name,' ','') + 'Model'
				AND a.ApprovedMonth = dbo.GetDateMonth(RM.DateFrom)
				AND BRHG.MaterialTypeId IS NOT NULL
		WHERE	@iIncludeApprovedData = 0 -- we are not including approved data in this call
				OR -- or we are and
				(	a.LocationId IS NULL -- there is no associated approval for this data
					AND NOT EXISTS
					(
						SELECT aOther.TagId 
						FROM dbo.BhpbioApprovalData aOther
							INNER JOIN dbo.BhpbioReportDataTags brdt
								ON brdt.TagId = aOther.TagId
						WHERE aOther.LocationId = pit.Location_Id
							AND aOther.ApprovedMonth = dbo.GetDateMonth(RM.DateFrom)
							AND brdt.OtherMaterialTypeId = MT.Material_Type_Id
					)	
				)
		GROUP BY b.CalendarDate, b.DateFrom, b.DateTo, mb.Block_Model_Id, mbp.Model_Block_Id, mbp.Sequence_No, l.ParentLocationId,
			MT.Material_Type_Id
		
		-- return the TONNES values
		INSERT INTO @outputStaging
			(CalendarDate, BlockModelId, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value)
		SELECT CalendarDate, BlockModelId, DateFrom, DateTo, DesignationMaterialTypeId, 
			ParentLocationId, 0, SUM(Tonnes)
		FROM @Model
		GROUP BY CalendarDate, BlockModelId, DateFrom, DateTo, ParentLocationId, DesignationMaterialTypeId

		-- return the GRADES values
		INSERT INTO @outputStaging
			(CalendarDate, BlockModelId, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value, AssociatedTonnes)
		SELECT m.CalendarDate, m.BlockModelId, m.DateFrom, m.DateTo, m.DesignationMaterialTypeId,
			m.ParentLocationId, g.Grade_Id As GradeId,
			SUM(m.Tonnes * mbpg.Grade_Value) / NULLIF(SUM(m.Tonnes), 0.0) As GradeValue,
			SUM(m.Tonnes)
		FROM @Model AS m
			-- add the grades
			CROSS JOIN dbo.Grade AS g
			LEFT JOIN dbo.ModelBlockPartialGrade AS mbpg
				ON (mbpg.Model_Block_Id = m.ModelBlockId
					AND mbpg.Sequence_No = m.SequenceNo
					AND g.Grade_Id = mbpg.Grade_Id)
		GROUP BY m.CalendarDate, m.BlockModelId, m.DateFrom, m.DateTo, g.Grade_Id, m.ParentLocationId, m.DesignationMaterialTypeId
	END
	
	-- If Including Approved Summary Data
	IF @iIncludeApprovedData = 1
	BEGIN
			-- These 2 queries retrieve summary tonnes and grades for all summary types
			-- that are associated with a block model
	
			-- Retrieve Tonnes from Approved Data
			INSERT INTO @outputStaging
				(CalendarDate, BlockModelId, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value)
			SELECT B.CalendarDate AS CalendarDate, bset.AssociatedBlockModelId, B.DateFrom, B.DateTo, mt.Parent_Material_Type_Id, l.ParentLocationId AS ParentLocationId,
				 0, -- meaning Tonnes
				 SUM(bse.Tonnes) AS Tonnes
			FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
				INNER JOIN dbo.BhpbioSummary s WITH (NOLOCK)
					ON s.SummaryMonth >= B.DateFrom AND s.SummaryMonth < B.DateTo
				INNER JOIN dbo.BhpbioSummaryEntry AS bse WITH (NOLOCK)
					ON bse.SummaryId = s.SummaryId
				INNER JOIN @Location AS l
					ON l.LocationId = bse.LocationId
				INNER JOIN dbo.BhpbioSummaryEntryType AS bset WITH (NOLOCK)
					ON bset.SummaryEntryTypeId = bse.SummaryEntryTypeId
				INNER JOIN dbo.MaterialType mt WITH (NOLOCK)
					ON mt.Material_Type_Id = bse.MaterialTypeId
			WHERE bset.AssociatedBlockModelId IS NOT NULL
				AND bset.Name like '%ModelMovement'
			GROUP BY B.CalendarDate, bset.AssociatedBlockModelId, B.DateFrom, B.DateTo, mt.Parent_Material_Type_Id, l.ParentLocationId

			-- Retrieve Grades from Approved Data
			INSERT INTO @outputStaging
				(CalendarDate, BlockModelId, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value, AssociatedTonnes)
			SELECT B.CalendarDate AS CalendarDate, bset.AssociatedBlockModelId, B.DateFrom, B.DateTo, mt.Parent_Material_Type_Id, l.ParentLocationId AS ParentLocationId,
				 bseg.GradeId,
				SUM(bse.Tonnes * bseg.GradeValue) / SUM(bse.Tonnes) As GradeValue,
				SUM(bse.Tonnes)
			FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
				INNER JOIN dbo.BhpbioSummary s WITH (NOLOCK)
					ON s.SummaryMonth >= B.DateFrom AND s.SummaryMonth < B.DateTo
				INNER JOIN dbo.BhpbioSummaryEntry AS bse WITH (NOLOCK)
					ON bse.SummaryId = s.SummaryId
				INNER JOIN dbo.BhpbioSummaryEntryType AS bset WITH (NOLOCK)
					ON bset.SummaryEntryTypeId = bse.SummaryEntryTypeId
				INNER JOIN @Location AS l
					ON l.LocationId = bse.LocationId
				INNER JOIN dbo.BhpbioSummaryEntryGrade AS bseg WITH (NOLOCK)
					ON bseg.SummaryEntryId = bse.SummaryEntryId
				INNER JOIN dbo.MaterialType mt WITH (NOLOCK)
					ON mt.Material_Type_Id = bse.MaterialTypeId
			WHERE bset.AssociatedBlockModelId IS NOT NULL
				AND bset.Name like '%ModelMovement'
			GROUP BY B.CalendarDate, bset.AssociatedBlockModelId, l.ParentLocationId, B.DateFrom, B.DateTo, mt.Parent_Material_Type_Id, bseg.GradeId
	END
	
	-- insert tonnes values into the table
	INSERT INTO @M
			(CalendarDate, BlockModelId, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value)
		SELECT os.CalendarDate, os.BlockModelId, os.DateFrom, os.DateTo, os.DesignationMaterialTypeId, os.LocationId, os.Attribute, Sum(os.Value)
		FROM @outputStaging os
		WHERE os.Attribute = 0
		GROUP BY os.CalendarDate, os.BlockModelId, os.DateFrom, os.DateTo, os.LocationId, os.DesignationMaterialTypeId, os.Attribute
		
	-- insert grade values into the table
	INSERT INTO @M
			(CalendarDate, BlockModelId, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value)
		SELECT os.CalendarDate, os.BlockModelId, os.DateFrom, os.DateTo, os.DesignationMaterialTypeId, os.LocationId, os.Attribute, Sum(os.Value * os.AssociatedTonnes) / Sum(os.AssociatedTonnes)
		FROM @outputStaging os
		WHERE os.Attribute <> 0
		GROUP BY os.CalendarDate, os.BlockModelId, os.DateFrom, os.DateTo, os.LocationId, os.DesignationMaterialTypeId, os.Attribute
	
	RETURN
END
GO

/*
SELECT * FROM dbo.GetBhpbioReportModel('01-APR-2008', '30-JUN-2008', 'MONTH', 1, 1, 1, 1)
SELECT * FROM dbo.GetBhpbioReportModel('01-APR-2008', '30-JUN-2008', 'QUARTER', 1, 0, 1, 1)
SELECT * FROM dbo.GetBhpbioReportModel('01-APR-2008', '30-JUN-2008', NULL, 1, 0, 1, 1)
*/

IF OBJECT_ID('dbo.GetBhpbioSummaryGradeBreakdown') IS NOT NULL 
     DROP FUNCTION dbo.GetBhpbioSummaryGradeBreakdown
GO

CREATE FUNCTION dbo.GetBhpbioSummaryGradeBreakdown
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iSummaryEntryTypeName VARCHAR(31),
	@iIgnoreMaterialTypes BIT,
	@iUseAbsoluteTonnesAtIndividualRows BIT,
	@iUseAbsoluteTonnesAtGradeSummary BIT
)
RETURNS @SummaryGrades TABLE
(
	CalendarDate DATETIME NOT NULL,
	DateFrom DATETIME NOT NULL,
	DateTo DATETIME NOT NULL,
	LocationId INT NOT NULL,
	ParentLocationId INT NULL,
	MaterialTypeId INT NULL,
	GradeId INTEGER NOT NULL,
	GradeValue FLOAT,
	Tonnes FLOAT
)
WITH ENCRYPTION
AS
BEGIN
	-- Find the summary entry type based on the supplied name
	DECLARE @summaryEntryTypeId INTEGER
			
	SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId 
	FROM dbo.BhpbioSummaryEntryType bset
	WHERE bset.Name = @iSummaryEntryTypeName	
	
	-- Insert the summary data into the result table
	INSERT INTO @SummaryGrades
	(
		CalendarDate,
		DateFrom,
		DateTo,
		LocationId,
		ParentLocationId,
		MaterialTypeId,
		GradeId,
		GradeValue,
		Tonnes
	)
	SELECT	B.CalendarDate AS CalendarDate, 
			B.DateFrom, 
			B.DateTo,
			bse.LocationId,
			l.Parent_Location_Id,
			CASE WHEN @iIgnoreMaterialTypes = 1 THEN NULL ELSE bse.MaterialTypeId END,
			bseg.GradeId,
			-- get a sum of tonnes by grade...(calculating absolute value at pre-summed or post summed value as appropriate)
			dbo.GetBhpbioFloatOptionalAbsolute(
				SUM(bseg.GradeValue * dbo.GetBhpbioFloatOptionalAbsolute(bse.Tonnes, @iUseAbsoluteTonnesAtIndividualRows))
				,@iUseAbsoluteTonnesAtGradeSummary)
			/  -- divide by sum of tonnes... (taking absolute value as appropriate)
			dbo.GetBhpbioFloatOptionalAbsolute(
				SUM(dbo.GetBhpbioFloatOptionalAbsolute(bse.Tonnes, @iUseAbsoluteTonnesAtIndividualRows))
				,@iUseAbsoluteTonnesAtGradeSummary
			),
			SUM(bse.Tonnes) AS Tonnes
	FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
		INNER JOIN dbo.BhpbioSummary s WITH (NOLOCK)
			ON s.SummaryMonth >= B.DateFrom AND s.SummaryMonth < B.DateTo
		INNER JOIN dbo.BhpbioSummaryEntry AS bse WITH (NOLOCK)
			ON bse.SummaryId = s.SummaryId
			AND bse.SummaryEntryTypeId = @summaryEntryTypeId
		INNER JOIN dbo.BhpbioSummaryEntryGrade AS bseg WITH (NOLOCK)
			ON bseg.SummaryEntryId = bse.SummaryEntryId
		INNER JOIN Location l WITH (NOLOCK)
			ON l.Location_Id = bse.LocationId
	GROUP BY B.CalendarDate, B.DateFrom, B.DateTo, bse.LocationId, l.Parent_Location_Id, CASE WHEN @iIgnoreMaterialTypes = 1 THEN NULL ELSE bse.MaterialTypeId END, bseg.GradeId
	HAVING SUM(ABS(bse.Tonnes)) > 0
	RETURN
END
GO

/*

-- returns summary tonnes
SELECT * FROM dbo.GetBhpbioSummaryGradeBreakdown(	@iDateFrom = '2009-11-01',
													@iDateTo = '2009-11-30', 
													@iDateBreakdown = null,
													@iSummaryEntryTypeName = 'GradeControlModelMovement',
													@iIgnoreMaterialTypes = 1,
													@iUseAbsoluteTonnesAtIndividualRows = 0,
													@iUseAbsoluteTonnesAtGradeSummary = 0)

*/


/*
<TAG Name="Data Dictionary" FunctionName="dbo.GetBhpbioSummaryGradeBreakdown">
 <Function>
	Gets a table of Grades by Location, time period and optionallty material type for a specified type of summary data
			
	Pass: 
			@iDateFrom: Specifies the from date of the query
			@iDateTo: Specifies the to date of the query
			@iDateBreakdown: Specifies the type of reporting date breakdown being retrieved
			@iSummaryEntryTypeName: Specifies the summary type that tonnes values should be retrieved for
			@iIgnoreMaterialTypes: If 1, the material of different types will be summed together
			@iUseAbsoluteTonnesAtIndividualRows: If 1, absolute tonnage values will be used for each line item being rolled up
			@iUseAbsoluteTonnesAtGradeSummary: If 1, absolute values for the summarised rows will be used
	
	Returns: Table of Grade values for each Location based on criteria
 </Function>
</TAG>
*/	

IF OBJECT_ID('dbo.GetBhpbioSummaryTonnesBreakdown') IS NOT NULL 
     DROP FUNCTION dbo.GetBhpbioSummaryTonnesBreakdown
GO

CREATE FUNCTION dbo.GetBhpbioSummaryTonnesBreakdown
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iSummaryEntryTypeName VARCHAR(31),
	@iIgnoreMaterialTypes BIT
)
RETURNS @SummaryTonnes TABLE
(
	CalendarDate DATETIME,
	DateFrom DATETIME,
	DateTo DATETIME,
	LocationId INT NOT NULL,
	ParentLocationId INT NULL,
	MaterialTypeId INT NULL,
	Tonnes FLOAT
)
WITH ENCRYPTION
AS
BEGIN
	-- Find the summary entry type based on the supplied summary entry type name
	DECLARE @summaryEntryTypeId INTEGER
			
	SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId 
	FROM dbo.BhpbioSummaryEntryType bset
	WHERE bset.Name = @iSummaryEntryTypeName
	
	-- Insert the summary data into the results table
	INSERT INTO @SummaryTonnes
	(
		CalendarDate,
		DateFrom,
		DateTo,
		LocationId,
		ParentLocationId,
		MaterialTypeId,
		Tonnes
	)
	SELECT	B.CalendarDate AS CalendarDate, 
			B.DateFrom, 
			B.DateTo,
			bse.LocationId,
			l.Parent_Location_Id,
			CASE WHEN @iIgnoreMaterialTypes = 1 THEN NULL ELSE bse.MaterialTypeId END,
			SUM(bse.Tonnes) AS Tonnes
	FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
		INNER JOIN dbo.BhpbioSummary s WITH (NOLOCK)
			ON s.SummaryMonth >= B.DateFrom AND s.SummaryMonth < B.DateTo
		INNER JOIN dbo.BhpbioSummaryEntry AS bse WITH (NOLOCK)
			ON bse.SummaryId = s.SummaryId
			AND bse.SummaryEntryTypeId = @summaryEntryTypeId
		INNER JOIN Location l WITH (NOLOCK)
			ON l.Location_Id = bse.LocationId
	GROUP BY B.CalendarDate, B.DateFrom, B.DateTo, bse.LocationId, l.Parent_Location_Id, CASE WHEN @iIgnoreMaterialTypes = 1 THEN NULL ELSE bse.MaterialTypeId END

	RETURN
END
GO

/*

-- returns summary tonnes
SELECT * FROM dbo.GetBhpbioSummaryTonnesBreakdown(	@iDateFrom = '2009-11-01',
													@iDateTo = '2009-11-30', 
													@iDateBreakdown = null,
													@iSummaryEntryTypeName = 'GradeControlModelMovement',
													@iIgnoreMaterialTypes = 1)

*/


/*
<TAG Name="Data Dictionary" FunctionName="dbo.GetBhpbioSummaryTonnesBreakdown">
 <Function>
	Gets a table of Tonnes by Location, time period and optionallty material type for a specified type of summary data
			
	Pass: 
			@iDateFrom: Specifies the from date of the query
			@iDateTo: Specifies the to date of the query
			@iDateBreakdown: Specifies the type of reporting date breakdown being retrieved
			@iSummaryEntryTypeName: Specifies the summary type that tonnes values should be retrieved for
			@iIgnoreMaterialTypes: If 1, the material of different types will be summed together
	
	Returns: Table of Tonnes for each Location based on criteria
 </Function>
</TAG>
*/	
IF OBJECT_ID('dbo.GetBhpbioSummaryTonnesByLocation') IS NOT NULL 
     DROP FUNCTION dbo.GetBhpbioSummaryTonnesByLocation
GO

CREATE FUNCTION dbo.GetBhpbioSummaryTonnesByLocation
(
	@iSummaryId INTEGER,
	@iSummaryEntryTypeName VARCHAR(30),
	@iMaterialTypeId INTEGER
)
RETURNS @SummaryTonnes TABLE
(
	LocationId INT NOT NULL,
	Tonnes FLOAT,
	PRIMARY KEY (LocationId)
)
WITH ENCRYPTION
AS
BEGIN
	
	-- Insert a sum of Tonnes against each LocationId in the summary table
	-- based on the supplied criteria
	INSERT INTO @SummaryTonnes
	(
		LocationId,
		Tonnes
	)
	SELECT se.LocationId, Sum(se.Tonnes) AS Tonnes
	FROM dbo.BhpbioSummaryEntry se
		INNER JOIN dbo.BhpbioSummaryEntryType bset 
			ON bset.SummaryEntryTypeId = se.SummaryEntryTypeId
	WHERE se.SummaryId = @iSummaryId
		AND (
				@iMaterialTypeId IS NULL
				OR se.MaterialTypeId = @iMaterialTypeId
			)
		AND bset.Name = @iSummaryEntryTypeName
	GROUP BY se.LocationId
	
	RETURN
END
GO

/*

-- returns summary tonnes
SELECT * FROM dbo.GetBhpbioSummaryTonnesByLocation(@iSummaryId = 1, 
												 @iSummaryEntryTypeName = 'GradeControlModelMovement',
												 @iMaterialTypeId = NULL)

*/


/*
<TAG Name="Data Dictionary" FunctionName="dbo.GetBhpbioSummaryTonnesByLocation">
 <Function>
	Gets a table of Tonnes by Location for a particular Summary and Summary Entry Type
	
			
	Pass: 
			@iSummaryId : Identifies the summary to return data for
			@iSummaryEntryTypeName: The type of summary entry data to return a tonnes value for
			@iMaterialTypeId: An optional MaterialTypeId used to filter the results
	
	Returns: Table of Tonnes for each Location based on criteria
 </Function>
</TAG>
*/	

