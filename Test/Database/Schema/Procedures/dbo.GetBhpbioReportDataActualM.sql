IF OBJECT_ID('dbo.GetBhpbioReportDataActualM') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportDataActualM
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReportDataActualM
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

	DECLARE @HauledFieldId VARCHAR(31)
	DECLARE @SurveyedFieldId VARCHAR(31)
	DECLARE @SummaryTypeId INT
	
	SELECT @SummaryTypeId = SummaryEntryTypeId 
	FROM BhpbioSummaryEntryType
	WHERE Name = 'BlastBlockMonthlyBest'
	
	DECLARE @MaterialCategory VARCHAR(31)
	SET @MaterialCategory = 'Designation'
	
	-- create and populate a table variable to store Identifiers for relevant locations
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		ParentLocationId INT NULL,
		PRIMARY KEY (LocationId)
	)
	
	INSERT INTO @Location(LocationId, ParentLocationId)
		SELECT DISTINCT LocationId, ParentLocationId
		FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, @iChildLocations, null, @iDateFrom, @iDateTo)
	
	DECLARE @Staging TABLE
	(
		LocationId INT NOT NULL,
		ParentLocationId INT NULL,
		MaterialTypeId INT NULL,
		HaulageDate DATETIME NOT NULL,
		Tonnes REAL NOT NULL
	)
	
	IF @iIncludeLiveData = 1
	BEGIN
	
		DECLARE @ActiveDigblock TABLE (DigblockId VARCHAR(31))

		-- find the digblocks active through either BhpbioImportReconciliationMovement or Haulage
		INSERT INTO @ActiveDigblock
		SELECT DISTINCT d.Digblock_Id
		FROM (
			SELECT DISTINCT dl.Digblock_Id
			FROM dbo.BhpbioImportReconciliationMovement rm
				INNER JOIN dbo.DigblockLocation dl ON dl.Location_Id = rm.BlockLocationId
			WHERE rm.DateTo >= @iDateFrom AND rm.DateTo <= @iDateTo
			UNION
			SELECT DISTINCT h.Source_Digblock_Id
			FROM dbo.Haulage h
			WHERE h.Haulage_Date BETWEEN @iDateFrom  AND @iDateTo
		) as d
		
		-- calculate the best, hauled and survey tonnes
		INSERT INTO @Staging (LocationId, ParentLocationId, MaterialTypeId, HaulageDate, Tonnes)
		SELECT 
			l.LocationId,
			l.ParentLocationId, 
			d.Material_Type_Id,
			h.Haulage_Date,
			COALESCE(SUM(h.Tonnes), 0) As Tonnes
		FROM @ActiveDigblock ad
			INNER JOIN dbo.Digblock d
				ON d.Digblock_Id = ad.DigblockId
			INNER JOIN dbo.DigblockLocation dl
				ON dl.Digblock_Id = d.Digblock_Id
			INNER JOIN @Location l
				ON l.LocationId = dl.Location_Id
			LEFT JOIN dbo.Haulage h
				ON h.Source_Digblock_Id = ad.DigblockId
				AND h.Haulage_Date BETWEEN @iDateFrom  AND @iDateTo
				AND h.Haulage_State_Id IN ('N', 'A')
				AND h.Child_Haulage_Id IS NULL
			LEFT JOIN dbo.HaulageValue AS hauled
				ON h.Haulage_Id = hauled.Haulage_Id
					AND hauled.Haulage_Field_Id = @HauledFieldId
			LEFT JOIN dbo.HaulageValue AS survey
				ON h.Haulage_Id = survey.Haulage_Id
					AND survey.Haulage_Field_Id = @SurveyedFieldId
		WHERE h.Haulage_Date IS NOT NULL
			AND (@iIncludeApprovedData = 0 OR l.LocationId NOT IN (
				SELECT se.LocationId 
				FROM dbo.BhpbioSummary s
					inner join dbo.BhpbioSummaryEntry se on se.summaryid = s.summaryid
				WHERE 
					s.SummaryMonth between @iDateFrom and @iDateTo and
					se.ProductSize = 'TOTAL' and
					se.SummaryEntryTypeId = @SummaryTypeId
			))
		GROUP BY l.LocationId, l.ParentLocationId, d.Material_Type_Id, h.Haulage_Date
	END
	
	IF @iIncludeApprovedData = 1
	BEGIN

		INSERT INTO @Staging (LocationId, ParentLocationId, MaterialTypeId, HaulageDate, Tonnes)
		SELECT
			l.LocationId,
			l.ParentLocationId,
			se.MaterialTypeId,
			s.SummaryMonth as HaulageDate,
			COALESCE(se.Tonnes, 0) as Tonnes
		FROM dbo.BhpbioSummary s
			INNER JOIN dbo.BhpbioSummaryEntry se
				ON se.summaryid = s.summaryid
			INNER JOIN @Location l
				ON l.LocationId = se.LocationId
		WHERE 
			s.SummaryMonth between @iDateFrom and @iDateTo and
			se.ProductSize = 'TOTAL' and
			se.SummaryEntryTypeId = @SummaryTypeId
			
	END
	
	-- Insert missing material type, designation, location and date combinations 
	-- these missing combinations will have a 0 tonnes value inserted... this is just to ensure that all designations are represented for calculations that require them
	INSERT INTO @Staging(LocationId, ParentLocationId, MaterialTypeId, HaulageDate, Tonnes)
	SELECT	IsNull(l.ParentLocationId,0),  -- the Location Id  is not used... in order to avoind unneccessary output the parent location Id is used if one is available, otherwise 0
			l.ParentLocationId, 
			mt.Material_Type_Id, 
			rb.DateFrom, 
			0 -- a zero tonnes value
	FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 0) rb
		-- and material type id combination
		CROSS JOIN (
				SELECT m.Material_Type_Id 
				FROM MaterialType m 
				WHERE m.Material_Category_Id = 'Designation' 
				AND m.[Description] <> 'Bene Product'
		 ) mt
		-- and location combination
		CROSS JOIN (SELECT DISTINCT ParentLocationId FROM @Location) l
	-- include every combinaton except those where a representation already exists
	WHERE NOT EXISTS (
		SELECT TOP 1 * 
		FROM @Staging s
			INNER JOIN dbo.GetMaterialsByCategory(@MaterialCategory) AS MC
				ON MC.MaterialTypeId = s.MaterialTypeId
		WHERE s.ParentLocationId = l.ParentLocationId and MC.RootMaterialTypeId = mt.Material_Type_Id AND s.HaulageDate BETWEEN rb.DateFrom AND rb.DateTo
	)
	
	-- Select Tonnes
	SELECT 
		dbo.GetDateMonth(HaulageDate) AS CalendarDate,
		s.ParentLocationId,
		dbo.GetDateMonth(HaulageDate) AS DateFrom,
		DateAdd(day, -1, DateAdd(month, 1, dbo.GetDateMonth(HaulageDate))) AS DateTo,
		MC.RootMaterialTypeId AS MaterialTypeId,
		'TOTAL' AS ProductSize,
		SUM(s.Tonnes) AS Tonnes
	FROM @Staging s
		INNER JOIN dbo.GetMaterialsByCategory(@MaterialCategory) AS MC
			ON MC.MaterialTypeId = s.MaterialTypeId
	GROUP BY s.ParentLocationId, MC.RootMaterialTypeId, dbo.GetDateMonth(HaulageDate)
	
	-- select blank grades table - this is needed to make the vb calc classes work properly. They expect a tonnes
	-- and a grade table for the standard calculations. This will return no rows, but the correct field names
	SELECT 
		NULL AS CalendarDate,
		NULL AS ParentLocationId, 
		NULL AS GradeId,
		NULL AS MaterialTypeId,
		NULL AS ProductSize,
		NULL AS GradeName,
		NULL AS GradeValue
	WHERE 0 = 1
		
END 
GO

GRANT EXECUTE ON dbo.GetBhpbioReportDataActualM TO BhpbioGenericManager
GO