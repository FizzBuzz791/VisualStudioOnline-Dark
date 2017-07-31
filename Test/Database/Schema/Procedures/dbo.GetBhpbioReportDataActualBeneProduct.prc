IF OBJECT_ID('dbo.GetBhpbioReportDataActualBeneProduct') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportDataActualBeneProduct
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReportDataActualBeneProduct
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
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		ParentLocationId INT NULL,
		IncludeStart DATETIME,
		IncludeEnd DATETIME,
		PRIMARY KEY (LocationId,IncludeStart,IncludeEnd)
	)

	DECLARE @ProductRecord TABLE
	(
		CalendarDate DATETIME NOT NULL,
		WeightometerSampleId INT NOT NULL,
		EffectiveTonnes FLOAT NOT NULL,
		MaterialTypeId INT NOT NULL,
		ProductSize VARCHAR(5) NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		ParentLocationId INT NULL,
		PRIMARY KEY (WeightometerSampleId, MaterialTypeId, ProductSize)
	)
	
	DECLARE @OutputTonnes TABLE
	(
		CalendarDate DATETIME,
		DateFrom DATETIME,
		DateTo DATETIME,
		LocationId INTEGER,
		MaterialTypeId INTEGER,
		ProductSize VARCHAR(5),
		Tonnes FLOAT
	)
	
	DECLARE @OutputGrades TABLE
	(
		CalendarDate DATETIME,
		DateFrom DATETIME,
		DateTo DATETIME,
		LocationId INTEGER,
		MaterialTypeId INTEGER,
		ProductSize VARCHAR(5),
		GradeId INTEGER,
		GradeValue FLOAT,
		Tonnes FLOAT
	)
	
	DECLARE @BeneProductMaterialTypeId INT
	DECLARE @ProductSizeField VARCHAR(31)

	SET @ProductSizeField = 'ProductSize'
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioReportDataActualBeneProduct',
		@TransactionCount = @@TranCount 

	-- if there are no transactions available then start a new one
	-- if there is already a transaction then only mark a savepoint
	IF @TransactionCount = 0
	BEGIN
		SET TRANSACTION ISOLATION LEVEL REPEATABLE READ 
		BEGIN TRANSACTION
	END
	ELSE
	BEGIN
		SAVE TRANSACTION @TransactionName
	END
  
	BEGIN TRY
		-- collect the location subtree
		INSERT INTO @Location
			(LocationId, ParentLocationId, IncludeStart, IncludeEnd)
		SELECT LocationId, ParentLocationId, IncludeStart, IncludeEnd
		FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, @iChildLocations, NULL, @iDateFrom, @iDateTo)

		IF @iIncludeLiveData = 1
		BEGIN
			-- determine the return material type
			SELECT @BeneProductMaterialTypeId = Material_Type_Id
			FROM dbo.MaterialType
			WHERE Material_Category_Id = 'Designation'
				AND Abbreviation = 'Bene Product'
				
			IF @BeneProductMaterialTypeId IS NULL
			BEGIN
				RAISERROR('Bene Product material type is required, but is missing.', 16, 1)
			END

			INSERT INTO @ProductRecord
			(
				CalendarDate, WeightometerSampleId, EffectiveTonnes, MaterialTypeId, ProductSize, DateFrom, DateTo, ParentLocationId
			)
			SELECT b.CalendarDate, ws.Weightometer_Sample_Id, 
				ISNULL(ISNULL(defaultlf.[Percent], 1) * ws.Corrected_Tonnes, ISNULL(defaultlf.[Percent], 1) * ws.Tonnes),
				@BeneProductMaterialTypeId, 
				ISNULL(wsn.Notes, defaultlf.ProductSize), b.DateFrom, b.DateTo, 
				l.ParentLocationId
			FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS b
				INNER JOIN dbo.WeightometerSample AS ws
					ON (ws.Weightometer_Sample_Date BETWEEN b.DateFrom AND b.DateTo)
				INNER JOIN
					(
						SELECT DISTINCT dttf.Weightometer_Sample_Id, ml.Location_Id
						FROM dbo.DataTransactionTonnesFlow AS dttf
							-- sourced from a mill
							INNER JOIN dbo.Mill AS m
								ON (m.Stockpile_Id = dttf.Source_Stockpile_Id)
							INNER JOIN dbo.MillLocation AS ml
								ON (m.Mill_Id = ml.Mill_Id)
							-- delivered to a post crusher stockpile
							INNER JOIN dbo.StockpileGroupStockpile AS sgs
								ON (dttf.Destination_Stockpile_Id = sgs.Stockpile_Id)
							LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('BeneProduct') xs
								ON xs.StockpileId = dttf.Source_Stockpile_Id
								OR xs.StockpileId = dttf.Destination_Stockpile_Id
						WHERE sgs.Stockpile_Group_Id IN ('Post Crusher', 'High Grade')
							AND xs.StockpileId IS NULL -- No movements to or from excluded groups.
					) AS dttf
					ON (dttf.Weightometer_Sample_Id = ws.Weightometer_Sample_Id)
				INNER JOIN @Location AS l
					ON (l.LocationId = dttf.Location_Id)
					AND (ws.Weightometer_Sample_Date BETWEEN l.IncludeStart AND l.IncludeEnd)
				LEFT JOIN dbo.WeightometerSampleNotes wsn
					ON (ws.Weightometer_Sample_Id = wsn.Weightometer_Sample_Id
						AND wsn.Weightometer_Sample_Field_Id = @ProductSizeField)
				LEFT JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf
					ON wsn.Notes IS NULL
					AND l.LocationId = defaultlf.LocationId
					AND ws.Weightometer_Sample_Date BETWEEN defaultlf.StartDate AND defaultlf.EndDate					
				LEFT JOIN dbo.BhpbioApprovalData bad
					ON bad.LocationId IN (l.ParentLocationId, l.LocationId)
					AND bad.TagId = 'F2MineProductionActuals'
					AND bad.ApprovedMonth = dbo.GetDateMonth(b.CalendarDate)
					AND bad.ApprovedMonth BETWEEN l.IncludeStart AND l.IncludeEnd
					AND @iIncludeApprovedData = 1
			WHERE bad.LocationId IS NULL
			AND	(ISNULL(defaultlf.[Percent], 1) > 0)
			
			-- return tonnes 
			INSERT INTO  @OutputTonnes
			(
				CalendarDate,
				DateFrom,
				DateTo,
				LocationId,
				MaterialTypeId,
				ProductSize,
				Tonnes
			)
			-- get the lump and fines
			SELECT CalendarDate, DateFrom, DateTo, ParentLocationId, MaterialTypeId, ProductSize, 
				SUM(EffectiveTonnes) AS Tonnes
			FROM @ProductRecord AS p
			GROUP BY CalendarDate, ParentLocationId, DateFrom, DateTo, MaterialTypeId, ProductSize
			UNION ALL 
			-- plus rolled up total
			SELECT CalendarDate, DateFrom, DateTo, ParentLocationId, MaterialTypeId, 'TOTAL',
				SUM(EffectiveTonnes) AS Tonnes
			FROM @ProductRecord AS p
			GROUP BY CalendarDate, ParentLocationId, DateFrom, DateTo, MaterialTypeId
			
			-- return Grades
			INSERT INTO @OutputGrades
			(
				CalendarDate,
				DateFrom,
				DateTo,
				LocationId,
				MaterialTypeId,
				ProductSize,
				GradeId,
				GradeValue,
				Tonnes
			)
			-- get separate lump and fines
			SELECT p.CalendarDate, p.DateFrom, p.DateTo, p.ParentLocationId, p.MaterialTypeId, ProductSize, wsg.Grade_Id, 
				SUM(p.EffectiveTonnes * wsg.Grade_Value) / SUM(p.EffectiveTonnes) AS GradeValue,
				SUM(p.EffectiveTonnes)
			FROM @ProductRecord AS p
				INNER JOIN dbo.WeightometerSampleGrade AS wsg
					ON wsg.Weightometer_Sample_Id = p.WeightometerSampleId 
			GROUP BY p.CalendarDate, p.DateFrom, p.DateTo, p.ParentLocationId, p.MaterialTypeId, p.ProductSize, wsg.Grade_Id
			UNION ALL
			-- plus rolled up weighted average
			SELECT p.CalendarDate, p.DateFrom, p.DateTo, p.ParentLocationId, p.MaterialTypeId, 'TOTAL', wsg.Grade_Id, 
				SUM(p.EffectiveTonnes * wsg.Grade_Value) / SUM(p.EffectiveTonnes) AS GradeValue,
				SUM(p.EffectiveTonnes)
			FROM @ProductRecord AS p
				INNER JOIN dbo.WeightometerSampleGrade AS wsg
					ON wsg.Weightometer_Sample_Id = p.WeightometerSampleId 
			GROUP BY p.CalendarDate, p.DateFrom, p.DateTo, p.ParentLocationId, p.MaterialTypeId, wsg.Grade_Id
		END
		
		IF @iIncludeApprovedData = 1
		BEGIN
			DECLARE @summaryEntryType VARCHAR(24)
			SET @summaryEntryType = 'ActualBeneProduct'
			
			-- Retrieve Tonnes
			INSERT INTO  @OutputTonnes
			(
				CalendarDate,
				DateFrom,
				DateTo,
				LocationId,
				MaterialTypeId,
				ProductSize,
				Tonnes
			)
			SELECT s.CalendarDate, s.DateFrom, s.DateTo, l.ParentLocationId, s.MaterialTypeId, s.ProductSize, s.Tonnes
			FROM dbo.GetBhpbioSummaryTonnesBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryType, 0) s
				INNER JOIN @Location l
					ON l.LocationId = s.LocationId
					AND s.CalendarDate BETWEEN l.IncludeStart AND l.IncludeEnd
					
			-- Retrieve Grades
			INSERT INTO @OutputGrades
			(
				CalendarDate,
				DateFrom,
				DateTo,
				LocationId,
				MaterialTypeId,
				ProductSize,
				GradeId,
				GradeValue,
				Tonnes
			)
			SELECT s.CalendarDate, s.DateFrom, s.DateTo,  l.ParentLocationId, s.MaterialTypeId, s.ProductSize, s.GradeId,  s.GradeValue, s.Tonnes
			FROM dbo.GetBhpbioSummaryGradeBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryType, 0, 1, 0) s
				INNER JOIN @Location l
					ON l.LocationId = s.LocationId
					AND s.CalendarDate BETWEEN l.IncludeStart AND l.IncludeEnd
		END
		
		SELECT o.CalendarDate, o.LocationId AS ParentLocationId, o.DateFrom, o.DateTo, o.MaterialTypeId, o.ProductSize, SUM(o.Tonnes) AS Tonnes
		FROM @OutputTonnes o
		GROUP BY o.CalendarDate, o.LocationId, o.DateFrom, o.DateTo, o.MaterialTypeId, o.ProductSize
				
		-- return Grades
		SELECT o.CalendarDate, o.LocationId AS ParentLocationId, o.MaterialTypeId, o.ProductSize, g.Grade_Id, g.Grade_Name AS GradeName,
			SUM(o.Tonnes * o.GradeValue) / SUM(o.Tonnes) AS GradeValue
		FROM @OutputGrades o
			INNER JOIN dbo.Grade AS g
				ON g.Grade_Id = o.GradeId
		GROUP BY o.CalendarDate, o.LocationId, o.DateFrom, o.DateTo, o.MaterialTypeId, g.Grade_Id, g.Grade_Name, o.ProductSize

		-- if we started a new transaction that is still valid then commit the changes
		IF (@TransactionCount = 0) AND (XAct_State() = 1)
		BEGIN
			COMMIT TRANSACTION
		END
	END TRY
	BEGIN CATCH
		-- if we started a transaction then roll it back
		IF (@TransactionCount = 0)
		BEGIN
			ROLLBACK TRANSACTION
		END
		-- if we are part of an existing transaction and 
		ELSE IF (XAct_State() = 1) AND (@TransactionCount > 0)
		BEGIN
			ROLLBACK TRANSACTION @TransactionName
		END

		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON dbo.GetBhpbioReportDataActualBeneProduct TO BhpbioGenericManager
GO
