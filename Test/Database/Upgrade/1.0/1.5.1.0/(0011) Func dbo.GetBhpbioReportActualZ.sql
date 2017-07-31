﻿IF Object_Id('dbo.GetBhpbioReportActualZ') IS NOT NULL
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
		IncludeStart DATETIME NOT NULL,
		IncludeEnd DATETIME NOT NULL
		--PRIMARY KEY (LocationId)
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
		(LocationId, ParentLocationId, IncludeStart, IncludeEnd)
	SELECT LocationId, ParentLocationId, IncludeStart, IncludeEnd
	FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, @iGetChildLocations, NULL, @iDateFrom, @iDateTo)

	IF @iGetChildLocations = 1
	BEGIN
		INSERT	INTO @Location (LocationId, ParentLocationId, IncludeStart, IncludeEnd)
		--SELECT @iLocationId, @iLocationId
		SELECT	@iLocationId, @iLocationId, IncludeStart, IncludeEnd
		FROM 	GetBhpbioReportLocationBreakdownWithOverride(@iLocationId,0,
					(SELECT lt.[Description] 
					 FROM	location l INNER JOIN locationtype lt ON lt.location_type_id = l.location_type_id 
					 WHERE l.location_id = @iLocationId)
					, @iDateFrom, @iDateTo)
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
		SELECT DISTINCT b.CalendarDate, b.DateFrom, b.DateTo, h.Haulage_Id, l.ParentLocationId, h.Tonnes,
			CASE WHEN W.Weightometer_Id IS NOT NULL THEN @BeneFeedMaterialTypeId ELSE @HighGradeMaterialTypeId END
		FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS b
				INNER JOIN dbo.Haulage AS h
					ON (h.Haulage_Date BETWEEN b.DateFrom AND b.DateTo)
				INNER JOIN dbo.Crusher AS c
					ON (c.Crusher_Id = h.Destination_Crusher_Id)
				INNER JOIN dbo.CrusherLocation AS cl
					ON (cl.Crusher_Id = c.Crusher_Id)
				INNER JOIN @Location AS l
					ON (l.LocationId = cl.Location_Id) AND (h.Haulage_Date BETWEEN l.IncludeStart AND l.IncludeEnd)
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
					AND bad.ApprovedMonth BETWEEN l.IncludeStart AND l.IncludeEnd
					AND bad.ApprovedMonth = dbo.GetDateMonth(h.Haulage_Date)
					AND bad.TagId = 'F2StockpileToCrusher'
			  LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('ActualZ') xs
				  ON xs.StockpileId = h.Source_Stockpile_Id
				  OR xs.StockpileId = h.Destination_Stockpile_Id
			WHERE h.Haulage_State_Id IN ('N', 'A')
				AND h.Child_Haulage_Id IS NULL
				AND (W.Weightometer_Type_Id LIKE '%L1%' OR W.Weightometer_Type_Id IS NULL)
				AND h.Source_Stockpile_Id IS NOT NULL
				-- And either there is no associated approval for the data, or there is but we are not retrieving approved data in this call
				AND (bad.TagId IS NULL OR @iIncludeApprovedData = 0)
				AND xs.StockpileId IS NULL -- No movements to or from excluded groups.
				
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
				AND s.CalendarDate BETWEEN l.IncludeStart AND l.IncludeEnd
		
		-- Retrieve Grades
		INSERT INTO @ZIntermediate
			(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value, AssociatedTonnes)
		SELECT s.CalendarDate, s.DateFrom, s.DateTo, s.MaterialTypeId, l.ParentLocationId, s.GradeId,  s.GradeValue, s.Tonnes
		FROM dbo.GetBhpbioSummaryGradeBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryType, 0, 1, 0) s
			INNER JOIN @Location l
				ON l.LocationId = s.LocationId
				AND s.CalendarDate BETWEEN l.IncludeStart AND l.IncludeEnd
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
