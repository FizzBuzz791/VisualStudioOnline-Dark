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
		IncludeStart DATETIME, 
		IncludeEnd DATETIME,
		PRIMARY KEY (LocationId, IncludeStart, IncludeEnd)
	)

	DECLARE @MaterialCategory VARCHAR(31)
	SET @MaterialCategory = 'Designation'
	
	-- Setup the Locations
	INSERT INTO @Location
		(LocationId, ParentLocationId, IncludeStart, IncludeEnd)
	SELECT LocationId, ParentLocationId, IncludeStart, IncludeEnd
	--FROM dbo.GetBhpbioReportLocationBreakdown(@iLocationId, @iGetChildLocations, NULL)
	FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, @iGetChildLocations, NULL, @iDateFrom, @iDateTo)

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
				AND (rm.DateFrom BETWEEN l.IncludeStart AND l.IncludeEnd)
			INNER JOIN dbo.GetMaterialsByCategory(@MaterialCategory) AS MC
				ON (MC.MaterialTypeId = MBP.Material_Type_Id)
			INNER JOIN dbo.MaterialType AS MT WITH (NOLOCK)
				ON (MC.RootMaterialTypeId = MT.Material_Type_Id)
			LEFT JOIN dbo.GetBhpbioReportHighGrade() AS BRHG
				ON (BRHG.MaterialTypeId = MT.Material_Type_Id)

			INNER JOIN dbo.BhpbioLocationDate block  WITH (NOLOCK)
				ON block.Location_Id = L.LocationId
				AND (B.CalendarDate BETWEEN block.Start_Date AND block.End_Date)
				
			INNER JOIN dbo.BhpbioLocationDate blast  WITH (NOLOCK)
				ON blast.Location_Id = block.Parent_Location_Id
				AND (B.CalendarDate BETWEEN blast.Start_Date AND blast.End_Date)
			INNER JOIN dbo.BhpbioLocationDate bench WITH (NOLOCK)
				ON bench.Location_Id = blast.Parent_Location_Id
				AND (B.CalendarDate BETWEEN bench.Start_Date AND bench.End_Date)
			INNER JOIN dbo.BhpbioLocationDate pit WITH (NOLOCK)
				ON pit.Location_Id = bench.Parent_Location_Id
				AND (B.CalendarDate BETWEEN pit.Start_Date AND pit.End_Date)

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
SELECT * FROM dbo.GetBhpbioReportModel('01-JAN-2012', '31-JAN-2012', NULL, 12, 0, 1, 1)

*/
