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
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		ParentLocationId INT NULL,
		PRIMARY KEY (CalendarDate, WeightometerSampleId, MaterialTypeId)
	)
	
	DECLARE @OutputTonnes TABLE
	(
		CalendarDate DATETIME,
		DateFrom DATETIME,
		DateTo DATETIME,
		LocationId INTEGER,
		MaterialTypeId INTEGER,
		Tonnes FLOAT
	)
	
	DECLARE @OutputGrades TABLE
	(
		CalendarDate DATETIME,
		DateFrom DATETIME,
		DateTo DATETIME,
		LocationId INTEGER,
		MaterialTypeId INTEGER,
		GradeId INTEGER,
		GradeValue FLOAT,
		Tonnes FLOAT
	)
	
	DECLARE @BeneProductMaterialTypeId INT
	
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
			SET @BeneProductMaterialTypeId =
				(
					SELECT Material_Type_Id
					FROM dbo.MaterialType
					WHERE Material_Category_Id = 'Designation'
						AND Abbreviation = 'Bene Product'
				)

			INSERT INTO @ProductRecord
			(
				CalendarDate, WeightometerSampleId, EffectiveTonnes,
				MaterialTypeId, DateFrom, DateTo, ParentLocationId
			)
			SELECT b.CalendarDate, ws.Weightometer_Sample_Id, ISNULL(ws.Corrected_Tonnes, ws.Tonnes),
				@BeneProductMaterialTypeId, b.DateFrom, b.DateTo, l.ParentLocationId
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
						WHERE sgs.Stockpile_Group_Id IN ('Post Crusher', 'High Grade')
					) AS dttf
					ON (dttf.Weightometer_Sample_Id = ws.Weightometer_Sample_Id)
				INNER JOIN @Location AS l
					ON (l.LocationId = dttf.Location_Id)
					AND (ws.Weightometer_Sample_Date BETWEEN l.IncludeStart AND l.IncludeEnd)
				LEFT JOIN dbo.BhpbioApprovalData bad
					ON bad.LocationId IN (l.ParentLocationId, l.LocationId)
					AND bad.TagId = 'F2MineProductionActuals'
					AND bad.ApprovedMonth = dbo.GetDateMonth(b.CalendarDate)
					AND bad.ApprovedMonth BETWEEN l.IncludeStart AND l.IncludeEnd
					AND @iIncludeApprovedData = 1
			WHERE bad.LocationId IS NULL
			
			-- return Tonnes
			INSERT INTO  @OutputTonnes
			(
				CalendarDate,
				DateFrom,
				DateTo,
				LocationId,
				MaterialTypeId,
				Tonnes
			)
			SELECT CalendarDate, DateFrom, DateTo, ParentLocationId, MaterialTypeId, SUM(EffectiveTonnes) AS Tonnes
			FROM @ProductRecord
			GROUP BY CalendarDate, ParentLocationId, DateFrom, DateTo, MaterialTypeId
				
			-- return Grades
			INSERT INTO @OutputGrades
			(
				CalendarDate,
				DateFrom,
				DateTo,
				LocationId,
				MaterialTypeId,
				GradeId,
				GradeValue,
				Tonnes
			)
			SELECT p.CalendarDate, p.DateFrom, p.DateTo, p.ParentLocationId, p.MaterialTypeId, wsg.Grade_Id, 
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
				Tonnes
			)
			SELECT s.CalendarDate, s.DateFrom, s.DateTo, l.ParentLocationId, s.MaterialTypeId, s.Tonnes
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
				GradeId,
				GradeValue,
				Tonnes
			)
			SELECT s.CalendarDate, s.DateFrom, s.DateTo,  l.ParentLocationId, s.MaterialTypeId, s.GradeId,  s.GradeValue, s.Tonnes
			FROM dbo.GetBhpbioSummaryGradeBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryType, 0, 1, 0) s
				INNER JOIN @Location l
					ON l.LocationId = s.LocationId
					AND s.CalendarDate BETWEEN l.IncludeStart AND l.IncludeEnd
		END
		
		SELECT o.CalendarDate, o.LocationId AS ParentLocationId, o.DateFrom, o.DateTo, o.MaterialTypeId, SUM(o.Tonnes) AS Tonnes
		FROM @OutputTonnes o
		GROUP BY o.CalendarDate, o.LocationId, o.DateFrom, o.DateTo, o.MaterialTypeId
				
		-- return Grades
		SELECT o.CalendarDate, o.LocationId AS ParentLocationId, o.MaterialTypeId, g.Grade_Id, g.Grade_Name AS GradeName,
			SUM(o.Tonnes * o.GradeValue) / SUM(o.Tonnes) AS GradeValue
		FROM @OutputGrades o
			INNER JOIN dbo.Grade AS g
				ON g.Grade_Id = o.GradeId
		GROUP BY o.CalendarDate, o.LocationId, o.DateFrom, o.DateTo, o.MaterialTypeId, g.Grade_Id, g.Grade_Name

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

/* testing

EXEC dbo.GetBhpbioReportDataActualBeneProduct 
	@iDateFrom = '1-JUL-2012',
	@iDateTo = '31-JUL-2012',
	@iDateBreakdown = 'MONTH',
	@iLocationId = 8,
	@iChildLocations = 0,
	@iIncludeLiveData = 1,
	@iIncludeApprovedData = 1
*/
