IF Object_Id('dbo.GetBhpbioReportActualX') IS NOT NULL
	DROP FUNCTION dbo.GetBhpbioReportActualX
GO

-- Only works with non-approved live data, as there is no summarize methods
-- for 'X' at the moment
CREATE FUNCTION dbo.GetBhpbioReportActualX
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iGetChildLocations BIT,
	@iLowestStratLevel INT = 0 -- Default to 0 to prevent Stratigraphy grouping/reporting
)
RETURNS @X TABLE
(
	CalendarDate DATETIME NOT NULL,
	DateFrom DATETIME NOT NULL,
	DateTo DATETIME NOT NULL,
	DesignationMaterialTypeId INT NOT NULL,
	LocationId INT NULL,
	ProductSize VARCHAR(5) NULL,
	Attribute INT NULL,
	Value FLOAT NULL,
	StratNum VARCHAR(7) NULL,
	StratLevel INT NULL,
	StratLevelName VARCHAR(15) NULL
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @XIntermediate TABLE
	(
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		DesignationMaterialTypeId INT NOT NULL,
		LocationId INT NULL,
		ProductSize VARCHAR(5) NULL,
		Attribute INT NULL,
		Value FLOAT NULL,
		AssociatedTonnes FLOAT NULL,
		StratNum VARCHAR(7) NULL,
		StratLevel INT NULL,
		StratLevelName VARCHAR(15) NULL
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
		ProductSize VARCHAR(5) NOT NULL,
		Tonnes FLOAT NOT NULL,
		DesignationMaterialTypeId INT NOT NULL,
		StratNum VARCHAR(7) NULL,
		StratLevel INT NULL,
		StratLevelName VARCHAR(15) NULL
	)
	
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		ParentLocationId INT NULL,
		IncludeStart DATETIME NOT NULL,
		IncludeEnd DATETIME NOT NULL
	    PRIMARY KEY (LocationId, IncludeStart)
	)

	DECLARE @FlatStratTable TABLE
	(
		StratId INT NOT NULL,
		GroupId INT NOT NULL
	); -- DO NOT drop this semicolon or the CTE below won't work.

	WITH CTE AS (
		SELECT S.Id, S.Id AS UltimateParent
		FROM BhpbioStratigraphyHierarchy S
		UNION ALL
		SELECT Child.Id, Parent.UltimateParent
		FROM BhpbioStratigraphyHierarchy AS Child
		JOIN CTE AS Parent ON Child.Parent_Id = Parent.Id
	)

	INSERT INTO @FlatStratTable
	SELECT CTE.*
	FROM CTE
	INNER JOIN BhpbioStratigraphyHierarchy S ON S.Id = CTE.UltimateParent
	INNER JOIN BhpbioStratigraphyHierarchyType T ON T.Id = S.StratigraphyHierarchyType_Id
	ORDER BY UltimateParent, CTE.Id -- Not sure if this is strictly necessary, can't hurt though
	
	DECLARE @DigblockNoteField_Strat VARCHAR(31) = 'StratId'
	DECLARE @HighGradeMaterialTypeId INT
	DECLARE @BeneFeedMaterialTypeId INT

	-- set the material types
	SELECT @HighGradeMaterialTypeId = Material_Type_Id
	FROM dbo.MaterialType
	WHERE Abbreviation = 'High Grade'
		AND Material_Category_Id = 'Designation'

	SELECT @BeneFeedMaterialTypeId = Material_Type_Id
	FROM dbo.MaterialType
	WHERE Abbreviation = 'Bene Feed'
		AND Material_Category_Id = 'Designation'
		
	-- setup the Locations
	INSERT INTO @Location
		(LocationId, ParentLocationId, IncludeStart, IncludeEnd)
	SELECT LocationId, ParentLocationId, IncludeStart, IncludeEnd
	FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, @iGetChildLocations, NULL, @iDateFrom, @iDateTo)

	-- retrieve the list of Haulage Records to be used in the calculations
	INSERT INTO @Haulage
		(CalendarDate, DateFrom, DateTo, HaulageId, ParentLocationId, ProductSize, Tonnes, DesignationMaterialTypeId, 
		StratNum, StratLevel, StratLevelName)
	SELECT DISTINCT rd.CalendarDate, rd.DateFrom, rd.DateTo, h.Haulage_Id, l.ParentLocationId, defaultlf.ProductSize, 
		ISNULL(haulagelf.[Percent], defaultlf.[Percent]) * h.Tonnes,
		CASE WHEN W.Weightometer_Id IS NOT NULL THEN @BeneFeedMaterialTypeId ELSE @HighGradeMaterialTypeId END,
		BSH2.StratNum, BSHT.Level, BSHT.Type
	FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1) AS rd
	INNER JOIN dbo.Haulage AS h
		ON (h.Haulage_Date BETWEEN rd.DateFrom AND rd.DateTo)
	INNER JOIN dbo.GetBhpbioReportHauledBlockLocations(@iDateFrom, @iDateTo) dl
		ON (dl.DigblockId = h.Source_Digblock_Id)
	INNER JOIN @Location AS l
		ON (l.LocationId = dl.PitLocationId and h.haulage_date between l.IncludeStart and l.IncludeEnd)
	INNER JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, 1) defaultlf
		ON dl.PitLocationId = defaultlf.LocationId
		AND h.Haulage_Date BETWEEN defaultlf.StartDate AND defaultlf.EndDate
	LEFT JOIN dbo.GetBhpbioHaulageLumpFinesPercent(@iDateFrom, @iDateTo) haulagelf
		ON H.Haulage_Id = haulagelf.HaulageId
		AND defaultlf.ProductSize = haulagelf.ProductSize
	LEFT JOIN dbo.WeightometerFlowPeriodView AS WFPV
		ON (WFPV.Source_Crusher_Id = h.Destination_Crusher_Id
			AND WFPV.Destination_Mill_Id IS NOT NULL
			AND (rd.DateTo > WFPV.Start_Date Or WFPV.Start_Date IS NULL)
			AND (rd.DateFrom < WFPV.End_Date Or WFPV.End_Date IS NULL))
	LEFT JOIN dbo.Weightometer AS W
		ON (W.Weightometer_Id = WFPV.Weightometer_Id)
	LEFT JOIN dbo.DigblockNotes DBNStrat
		ON DBNStrat.Digblock_Id = H.Source_Digblock_Id AND DBNStrat.Digblock_Field_Id = @DigblockNoteField_Strat And @iLowestStratLevel > 0
	LEFT JOIN dbo.BhpbioStratigraphyHierarchy BSH1 -- Used to pull out the StratNum or whatever we finally decide to display
		ON BSH1.StratNum = DBNStrat.Notes
	LEFT JOIN @FlatStratTable FST
		ON FST.StratId = BSH1.Id
	LEFT JOIN dbo.BhpbioStratigraphyHierarchy BSH2 -- Used to filter to only the relevant Groupings.
		ON BSH2.Id = FST.GroupId
	LEFT JOIN dbo.BhpbioStratigraphyHierarchyType BSHT
		ON BSHT.Id = BSH2.StratigraphyHierarchyType_Id AND (BSHT.Level <= @iLowestStratLevel OR @iLowestStratLevel = 0)
	WHERE h.Haulage_State_Id IN ('N', 'A')
		-- don't include lump/fines portion if zero percent
		AND ISNULL(haulagelf.[Percent], defaultlf.[Percent]) > 0
		AND h.Child_Haulage_Id IS NULL
		AND h.Source_Digblock_Id IS NOT NULL
		AND h.Destination_Crusher_Id IS NOT NULL
		AND ((@iLowestStratLevel > 0 AND BSHT.Level <= @iLowestStratLevel) 
			OR (@iLowestStratLevel = 0 AND BSHT.Level IS NULL))


	-- return the TONNES values for individual lump and fines
	INSERT INTO @XIntermediate
		(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, ProductSize, LocationId, Attribute, Value, 
		StratNum, StratLevel, StratLevelName)
	SELECT CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, ProductSize, ParentLocationId, 0, SUM(Tonnes), 
		StratNum, MAX(StratLevel), MAX(StratLevelName)
	FROM @Haulage
	GROUP BY CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, ParentLocationId, ProductSize, StratNum

	DECLARE @HaulageLumpFinesGrade TABLE
	(
		HaulageId Int Not Null,
		ProductSize Varchar(5) Not Null,
		GradeId SmallInt Not Null,
		GradeValue Float Not Null,
		PRIMARY KEY (HaulageId, ProductSize, GradeId)
	)

	INSERT INTO @HaulageLumpFinesGrade
	SELECT h.Haulage_Id, LFG.ProductSize, LFG.GRadeId, LFG.GradeValue
	FROM dbo.GetBhpbioHaulageLumpFinesGrade(@iDateFrom, @iDateTo) LFG
	INNER JOIN Haulage h ON h.Haulage_Raw_Id = LFG.HaulageRawId

	-- return the GRADES values for individual lump and fines
	INSERT INTO @XIntermediate
		(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, ProductSize, LocationId, Attribute, Value, AssociatedTonnes, 
		StratNum, StratLevel, StratLevelName)
	SELECT h.CalendarDate, h.DateFrom, h.DateTo, h.DesignationMaterialTypeId, h.ProductSize, h.ParentLocationId,
		g.Grade_Id, SUM(h.Tonnes * ISNULL(LFG.GradeValue, hg.Grade_Value)) / NULLIF(SUM(h.Tonnes), 0.0), SUM(h.Tonnes), 
		h.StratNum, MAX(h.StratLevel), MAX(h.StratLevelName)
	FROM @Haulage AS h
		-- add the grades
		CROSS JOIN dbo.Grade AS g
		LEFT JOIN dbo.HaulageGrade AS hg
			ON (h.HaulageId = hg.Haulage_Id
				AND g.Grade_Id = hg.Grade_Id)
		LEFT JOIN @HaulageLumpFinesGrade LFG
			ON (LFG.HaulageId = h.HaulageId
				AND LFG.ProductSize = h.ProductSize
				AND LFG.GradeId = g.Grade_Id)
	GROUP BY h.CalendarDate, h.DateFrom, h.DateTo, g.Grade_Id, h.DesignationMaterialTypeId, h.ParentLocationId, h.ProductSize, h.StratNum
	OPTION (RECOMPILE)

		-- insert tonnes into the combined table
	INSERT INTO @X
		(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, ProductSize, LocationId, Attribute, Value, StratNum, StratLevel, StratLevelName)
	SELECT yi.CalendarDate, yi.DateFrom, yi.DateTo, yi.DesignationMaterialTypeId, yi.ProductSize,
		yi.LocationId, yi.Attribute, SUM(yi.Value), yi.StratNum, MAX(yi.StratLevel), MAX(yi.StratLevelName)
	FROM @XIntermediate AS yi
	WHERE yi.Attribute = 0
	GROUP BY  yi.CalendarDate, yi.DateFrom, yi.DateTo, yi.DesignationMaterialTypeId, yi.LocationId, yi.Attribute, yi.ProductSize, yi.StratNum
	
	-- insert grades into the combined table
	INSERT INTO @X
		(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, ProductSize, LocationId, Attribute, Value, StratNum, StratLevel, StratLevelName)
	SELECT yi.CalendarDate, yi.DateFrom, yi.DateTo, yi.DesignationMaterialTypeId, yi.ProductSize,
		yi.LocationId, yi.Attribute, SUM(yi.Value * yi.AssociatedTonnes) / SUM(yi.AssociatedTonnes), yi.StratNum, MAX(yi.StratLevel), MAX(yi.StratLevelName)
	FROM @XIntermediate AS yi
	WHERE yi.Attribute > 0
	GROUP BY  yi.CalendarDate, yi.DateFrom, yi.DateTo, yi.DesignationMaterialTypeId, yi.LocationId, yi.Attribute, yi.ProductSize, yi.StratNum
	
	
	RETURN
END
GO