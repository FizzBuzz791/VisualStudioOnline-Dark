IF OBJECT_ID('dbo.GetBhpbioWeightometerSampleSourceActualC') IS NOT NULL 
     DROP FUNCTION dbo.GetBhpbioWeightometerSampleSourceActualC
Go 

CREATE FUNCTION dbo.GetBhpbioWeightometerSampleSourceActualC
(
	@iLocationId INT,
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iOreForRailGradesOnly BIT = 0
)
RETURNS @SampleSourceResult TABLE
(
	LocationId INT,
	Weightometer_Id VARCHAR(31),
	MonthPeriod DATETIME,
	SampleSource VARCHAR(255) COLLATE DATABASE_DEFAULT,
	ShouldWeightBySampleTonnes BIT

	PRIMARY KEY (LocationId, Weightometer_Id, MonthPeriod, SampleSource)
)
WITH ENCRYPTION
AS
BEGIN

	DECLARE @CrusherActuals VARCHAR(31)
	DECLARE @BackCalculatedGrades VARCHAR(31)
	DECLARE @UndilutedRakes VARCHAR(31)
	DECLARE @PortActuals VARCHAR(31)
	DECLARE @ShuttleGrades VARCHAR(31)
	SET @CrusherActuals = 'CRUSHER ACTUALS'
	SET @BackCalculatedGrades = 'BACK-CALCULATED GRADES'
	SET @UndilutedRakes = 'UNDILUTED RAKES'
	SET @PortActuals = 'PORT ACTUALS'
	SET @ShuttleGrades = 'SHUTTLE'

	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		IncludeStart DateTime NOT NULL,
		IncludeEnd DateTime NOT NULL,
		
		PRIMARY KEY (LocationId, IncludeStart, IncludeEnd)
	)
	
	DECLARE	@SampleSource TABLE
	(
		LocationId INT,
		Weightometer_Id VARCHAR(31),
		MonthPeriod DATETIME,
		SampleSource VARCHAR(255) COLLATE DATABASE_DEFAULT,
		PRIMARY KEY (LocationId, Weightometer_Id, MonthPeriod, SampleSource)
	)
		
	DECLARE	@SampleSourceCount TABLE
	(
		LocationId INT,
		Weightometer_Id VARCHAR(31),
		MonthPeriod DATETIME,
		SampleSource VARCHAR(255) COLLATE DATABASE_DEFAULT,
		CountSamples INT,
		PRIMARY KEY (LocationId, Weightometer_Id, MonthPeriod, SampleSource)
	)
	
	-- Setup the Locations
	INSERT INTO @Location
		(LocationId, IncludeStart, IncludeEnd)
	SELECT LocationId, IncludeStart, IncludeEnd
	FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 0, 'Site', @iDateFrom, @iDateTo)

	-- skip gathering crusher samples if retrieving Ore For Rail grades
	IF (@iOreForRailGradesOnly IS NULL OR @iOreForRailGradesOnly <> 1)
	BEGIN
		-- CRUSHER ACTUALS and BACK-CALCULATED GRADES
		INSERT INTO @SampleSource
			(LocationId, Weightometer_Id, MonthPeriod, SampleSource)
		SELECT L.LocationId, WS.Weightometer_Id, dbo.GetDateMonth(WS.Weightometer_Sample_Date) As MonthPeriod, WSN.Notes
		FROM @Location AS L
			INNER JOIN dbo.GetBhpbioCrusherLocationWithOverride(@iDateFrom, @iDateTo) AS CL
				ON (CL.Location_Id = L.LocationId)
			INNER JOIN dbo.WeightometerFlowPeriod AS WFP
				ON (WFP.Source_Crusher_Id = CL.Crusher_Id)
			INNER JOIN dbo.WeightometerSample AS WS
				ON (WS.Weightometer_Id = WFP.Weightometer_Id)
				AND (WS.Weightometer_Sample_Date BETWEEN CL.IncludeStart AND CL.IncludeEnd)
				AND (WS.Weightometer_Sample_Date BETWEEN L.IncludeStart AND L.IncludeEnd)
			INNER JOIN dbo.WeightometerSampleNotes AS WSN
				ON (WSN.Weightometer_Sample_Field_Id = 'SampleSource'
					AND WS.Weightometer_Sample_Id = WSN.Weightometer_Sample_Id)
		WHERE WS.Weightometer_Sample_Date BETWEEN @iDateFrom AND @iDateTo
			AND WSN.Notes IN (@CrusherActuals, @BackCalculatedGrades)
		GROUP BY dbo.GetDateMonth(WS.Weightometer_Sample_Date), L.LocationId, WS.Weightometer_Id, WSN.Notes	
	END
	
	-- SHUTTLE
	INSERT INTO @SampleSourceCount
		(LocationId, Weightometer_Id, MonthPeriod, SampleSource, CountSamples)
	SELECT L.LocationId, WS.Weightometer_Id, dbo.GetDateMonth(WS.Weightometer_Sample_Date) As MonthPeriod, WSN.Notes, Count(*)
	FROM @Location AS L
		INNER JOIN dbo.GetBhpbioWeightometerLocationWithOverride(@iDateFrom, @iDateTo) AS WL
			ON (WL.Location_Id = L.LocationId)
		INNER JOIN dbo.WeightometerSample AS WS
			ON (WL.Weightometer_Id = WS.Weightometer_Id)
			AND (WS.Weightometer_Sample_Date BETWEEN WL.IncludeStart AND WL.IncludeEnd)
			AND (WS.Weightometer_Sample_Date BETWEEN L.IncludeStart AND L.IncludeEnd)
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
				AND SS.Weightometer_Id = WS.Weightometer_Id
				AND SS.MonthPeriod = dbo.GetDateMonth(WS.Weightometer_Sample_Date))
	WHERE WS.Weightometer_Sample_Date BETWEEN @iDateFrom AND @iDateTo
		AND WSN.Notes IN (@ShuttleGrades)
		AND SGS.Stockpile_Group_Id in ('HUB Train Rake', 'Port Train Rake')
		AND SS.SampleSource IS NULL
		-- new logic to deal with transistioning phase of RGP4
		AND WS.Weightometer_Sample_Date >= '01-NOV-2009'
	GROUP BY dbo.GetDateMonth(WS.Weightometer_Sample_Date), L.LocationId, WS.Weightometer_Id, WSN.Notes	
	
	-- UNDILUTED RAKES, PORT ACTUALS
	INSERT INTO @SampleSource
		(LocationId, Weightometer_Id, MonthPeriod, SampleSource)
	SELECT L.LocationId, WS.Weightometer_Id, dbo.GetDateMonth(WS.Weightometer_Sample_Date) As MonthPeriod, WSN.Notes
	FROM @Location AS L
		INNER JOIN dbo.GetBhpbioWeightometerLocationWithOverride(@iDateFrom, @iDateTo) AS WL
			ON (WL.Location_Id = L.LocationId)
		INNER JOIN dbo.WeightometerSample AS WS
			ON (WL.Weightometer_Id = WS.Weightometer_Id)
			AND (WS.Weightometer_Sample_Date BETWEEN WL.IncludeStart AND WL.IncludeEnd)
			AND (WS.Weightometer_Sample_Date BETWEEN L.IncludeStart AND L.IncludeEnd)
		INNER JOIN dbo.StockpileGroupStockpile AS SGS
			ON (SGS.Stockpile_Id = WS.Destination_Stockpile_Id)
		INNER JOIN dbo.WeightometerSampleNotes AS WSN
			ON (WSN.Weightometer_Sample_Field_Id = 'SampleSource'
				AND WS.Weightometer_Sample_Id = WSN.Weightometer_Sample_Id)
		LEFT JOIN @SampleSource AS SS
			ON (SS.LocationID = L.LocationId
				AND SS.Weightometer_Id = WS.Weightometer_Id
				AND SS.MonthPeriod = dbo.GetDateMonth(WS.Weightometer_Sample_Date))
		LEFT JOIN @SampleSourceCount SSC
			ON (SSC.LocationID = L.LocationId
				AND SSC.Weightometer_Id = WS.Weightometer_Id
				AND SSC.MonthPeriod = dbo.GetDateMonth(WS.Weightometer_Sample_Date))
	WHERE WS.Weightometer_Sample_Date BETWEEN @iDateFrom AND @iDateTo
		AND WSN.Notes IN (@UndilutedRakes, @PortActuals)
		AND SGS.Stockpile_Group_Id in ('HUB Train Rake', 'Port Train Rake')
		AND SS.SampleSource IS NULL
	GROUP BY dbo.GetDateMonth(WS.Weightometer_Sample_Date), L.LocationId, WS.Weightometer_Id, WSN.Notes	
	HAVING Count(*) > Coalesce(MAX(CountSamples), 0) Or dbo.GetDateMonth(WS.Weightometer_Sample_Date) < '01-NOV-2009'
		
	INSERT INTO @SampleSource
	(LocationId, Weightometer_Id, MonthPeriod, SampleSource)
	SELECT LocationId, Weightometer_Id, MonthPeriod, SampleSource
	FROM @SampleSourceCount
	
	-- Remove non Undiluted Rakes if are also port actuals.
	DELETE SS
	FROM @SampleSource AS SS
		INNER JOIN @SampleSource AS OSS
			ON (SS.LocationID = OSS.LocationId 
				AND SS.MonthPeriod = OSS.MonthPeriod
				AND OSS.SampleSource = @UndilutedRakes)
	WHERE SS.SampleSource = @PortActuals
	
	-- This is the heirachy of results, based of the above code. Hopefully it 
	-- is correct
	DECLARE @SampleHeirachy TABLE (SampleOrder INT, SampleSource VARCHAR(64))
	INSERT INTO @SampleHeirachy 
		SELECT 1, 'CRUSHER ACTUALS' UNION
		SELECT 1, 'BACK-CALCULATED GRADES' UNION
		SELECT 2, 'SHUTTLE' UNION
		SELECT 3, 'PORT ACTUALS' UNION
		SELECT 4, 'UNDILUTED RAKES'
	
	-- This query takes the results we have so far and pulls the weightometers with
	-- the 'best' result for each location and month. The rest are excluded UNLESS they
	-- are in the AlwaysIncludeAsSampleSource group, in which case they will be included
	-- regardless.
	--
	-- The key to the select below is the RANK() function, which allows us to get
	-- the best match for each location, month group
	INSERT INTO @SampleSourceResult
		SELECT LocationId, Weightometer_Id, MonthPeriod, SampleSource, CASE WHEN SampleSource = @BackCalculatedGrades THEN 1 ELSE 0 END as ShouldWeightBySampleTonnes FROM (
			SELECT 
				ss.LocationId,
				ss.MonthPeriod,
				ss.Weightometer_Id,
				ss.SampleSource,
				Rank() OVER (PARTITION BY ss.LocationId, ss.MonthPeriod ORDER BY h.SampleOrder) AS SampleRank,
				w.Weightometer_Group_Id
				
			FROM @SampleSource ss
				INNER JOIN @SampleHeirachy h 
					ON h.SampleSource = ss.SampleSource
				INNER JOIN Weightometer w 
					ON w.Weightometer_Id = ss.Weightometer_Id
			) AS RankedSamples
		WHERE SampleRank = 1 
			OR Weightometer_Group_Id = 'AlwaysIncludeAsSampleSource'

	RETURN
END
GO
