﻿IF Object_Id('dbo.GetBhpbioReportActualY') IS NOT NULL
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
		IncludeStart DATETIME NOT NULL,
		IncludeEnd DATETIME NOT NULL
		--PRIMARY KEY (LocationId)
	)

	-- setup the Locations
	INSERT INTO @Location
		(LocationId, ParentLocationId, IncludeStart, IncludeEnd)
	SELECT LocationId, ParentLocationId, IncludeStart, IncludeEnd
	FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, @iGetChildLocations, NULL, @iDateFrom, @iDateTo)

	IF @iIncludeLiveData = 1
	BEGIN
		-- retrieve the list of Haulage Records to be used in the calculations
		INSERT INTO @Haulage
			(CalendarDate, DateFrom, DateTo, HaulageId, ParentLocationId, Tonnes, DesignationMaterialTypeId)
		SELECT DISTINCT rd.CalendarDate, rd.DateFrom, rd.DateTo, h.Haulage_Id, l.ParentLocationId, h.Tonnes,
			destinationStockpile.MaterialTypeId
		FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1) AS rd
			INNER JOIN dbo.Haulage AS h
				ON (h.Haulage_Date BETWEEN rd.DateFrom AND rd.DateTo)
			INNER JOIN dbo.DigblockLocation dl
				ON (dl.Digblock_Id = h.Source_Digblock_Id)
			
			INNER JOIN @Location AS l
				ON (l.LocationId = dl.Location_Id and h.haulage_date between l.IncludeStart and l.IncludeEnd)
			
			INNER JOIN BhpbioLocationDate /*@Location*/ block
				ON block.Location_Id = l.LocationId
				AND (rd.CalendarDate BETWEEN block.Start_Date and block.End_Date)
				
			INNER JOIN BhpbioLocationDate /*@Location*/ blast
				ON blast.Location_Id = block.Parent_Location_Id
				AND (rd.CalendarDate BETWEEN blast.Start_Date and blast.End_Date)
			INNER JOIN BhpbioLocationDate /*@Location*/ bench
				ON bench.Location_Id = blast.Parent_Location_Id
				AND (rd.CalendarDate BETWEEN bench.Start_Date and bench.End_Date)
			INNER JOIN BhpbioLocationDate /*@Location*/ pit
				ON pit.Location_Id = bench.Parent_Location_Id
				AND (rd.CalendarDate BETWEEN pit.Start_Date and pit.End_Date)
			-- join to the destination stockpile
			INNER JOIN
				(
					SELECT sl2.Stockpile_Id, sgd2.MaterialTypeId
					FROM dbo.BhpbioStockpileGroupDesignation AS sgd2
						INNER JOIN dbo.StockpileGroupStockpile AS sgs2
							ON (sgs2.Stockpile_Group_Id = sgd2.StockpileGroupId)
						INNER JOIN dbo.BhpbioStockpileLocationDate AS sl2
							ON (sl2.Stockpile_Id = sgs2.Stockpile_Id)
							AND	(sl2.[Start_Date] BETWEEN @iDateFrom AND @iDateTo
								OR sl2.End_Date BETWEEN @iDateFrom AND @iDateTo
								OR (sl2.[Start_Date] < @iDateFrom AND sl2.End_Date >@iDateTo))
				) AS destinationStockpile
				ON (destinationStockpile.Stockpile_Id = h.Destination_Stockpile_Id)
			LEFT JOIN dbo.GetBhpbioFilteredMaterialTypes(1,null) hgmt
				ON hgmt.MaterialTypeId = destinationStockpile.MaterialTypeId
			LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('ActualY') xs
				ON xs.StockpileId = h.Source_Stockpile_Id
				OR xs.StockpileId = h.Destination_Stockpile_Id
		WHERE h.Haulage_State_Id IN ('N', 'A')
			AND h.Child_Haulage_Id IS NULL
			AND h.Source_Digblock_Id IS NOT NULL
			AND xs.StockpileId IS NULL -- No movements to or from excluded groups.
			-- filter out data for approved periods IF we are also retrieving Approved data in this call
			AND NOT (
				@iIncludeApprovedData = 1
				AND EXISTS (
						SELECT bad.TagId
						FROM dbo.BhpbioApprovalData bad
							INNER JOIN dbo.BhpbioReportDataTags brdt
							ON brdt.TagId = bad.TagId
						WHERE	bad.LocationId = pit.Location_Id
							AND bad.ApprovedMonth BETWEEN pit.Start_Date AND pit.End_Date
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
				AND s.SummaryMonth BETWEEN l.IncludeStart AND l.IncludeEnd		/* Added for hierarchy change */
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
				AND s.SummaryMonth BETWEEN l.IncludeStart AND l.IncludeEnd		/* Added for hierarchy change */
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
