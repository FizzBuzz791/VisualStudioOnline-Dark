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
	@iGetChildLocations BIT
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
	Value FLOAT NULL
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
		ProductSize VARCHAR(5) NOT NULL,
		Tonnes FLOAT NOT NULL,
		DesignationMaterialTypeId INT NOT NULL,
		PRIMARY KEY (HaulageId, ProductSize)
	)
	
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		ParentLocationId INT NULL,
		IncludeStart DATETIME NOT NULL,
		IncludeEnd DATETIME NOT NULL
	    PRIMARY KEY (LocationId, IncludeStart)
	)
	
	
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
		(CalendarDate, DateFrom, DateTo, HaulageId, ParentLocationId, ProductSize, Tonnes, DesignationMaterialTypeId)
	SELECT DISTINCT rd.CalendarDate, rd.DateFrom, rd.DateTo, h.Haulage_Id, l.ParentLocationId, defaultlf.ProductSize, 
		ISNULL(haulagelf.[Percent], defaultlf.[Percent]) * h.Tonnes,
		CASE WHEN W.Weightometer_Id IS NOT NULL THEN @BeneFeedMaterialTypeId ELSE @HighGradeMaterialTypeId END
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
	WHERE h.Haulage_State_Id IN ('N', 'A')
		-- don't include lump/fines portion if zero percent
		AND ISNULL(haulagelf.[Percent], defaultlf.[Percent]) > 0
		AND h.Child_Haulage_Id IS NULL
		AND h.Source_Digblock_Id IS NOT NULL
		AND h.Destination_Crusher_Id IS NOT NULL

	-- return the TONNES values for individual lump and fines
	INSERT INTO @XIntermediate
		(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, ProductSize, LocationId, Attribute, Value)
	SELECT CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, ProductSize, ParentLocationId, 0, SUM(Tonnes)
	FROM @Haulage
	GROUP BY CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, ParentLocationId, ProductSize

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
		(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, ProductSize, LocationId, Attribute, Value, AssociatedTonnes)
	SELECT h.CalendarDate, h.DateFrom, h.DateTo, h.DesignationMaterialTypeId, h.ProductSize, h.ParentLocationId,
		g.Grade_Id, SUM(h.Tonnes * ISNULL(LFG.GradeValue, hg.Grade_Value)) / NULLIF(SUM(h.Tonnes), 0.0), SUM(h.Tonnes)
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
	GROUP BY h.CalendarDate, h.DateFrom, h.DateTo, g.Grade_Id, h.DesignationMaterialTypeId, h.ParentLocationId, h.ProductSize
	OPTION (RECOMPILE)


		-- insert tonnes into the combined table
	INSERT INTO @X
		(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, ProductSize, LocationId, Attribute, Value)
	SELECT yi.CalendarDate, yi.DateFrom, yi.DateTo, yi.DesignationMaterialTypeId, yi.ProductSize,
		yi.LocationId, yi.Attribute, SUM(yi.Value)
	FROM @XIntermediate AS yi
	WHERE yi.Attribute = 0
	GROUP BY  yi.CalendarDate, yi.DateFrom, yi.DateTo, yi.DesignationMaterialTypeId, yi.LocationId, yi.Attribute, yi.ProductSize
	
	-- insert grades into the combined table
	INSERT INTO @X
		(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, ProductSize, LocationId, Attribute, Value)
	SELECT yi.CalendarDate, yi.DateFrom, yi.DateTo, yi.DesignationMaterialTypeId, yi.ProductSize,
		yi.LocationId, yi.Attribute, SUM(yi.Value * yi.AssociatedTonnes) / SUM(yi.AssociatedTonnes)
	FROM @XIntermediate AS yi
	WHERE yi.Attribute > 0
	GROUP BY  yi.CalendarDate, yi.DateFrom, yi.DateTo, yi.DesignationMaterialTypeId, yi.LocationId, yi.Attribute, yi.ProductSize
	
	
	RETURN
END
GO
