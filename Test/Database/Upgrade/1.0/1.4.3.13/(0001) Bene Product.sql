IF OBJECT_ID('dbo.GetBhpbioReportDataActualBeneProduct') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportDataActualBeneProduct
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReportDataActualBeneProduct
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iChildLocations BIT
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
		PRIMARY KEY (LocationId)
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
			(LocationId, ParentLocationId)
		SELECT LocationId, ParentLocationId
		FROM dbo.GetBhpbioReportLocationBreakdown(@iLocationId, @iChildLocations, NULL)

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
		
		-- return Tonnes
		SELECT CalendarDate, ParentLocationId, DateFrom, DateTo, MaterialTypeId, SUM(EffectiveTonnes) AS Tonnes
		FROM @ProductRecord
		GROUP BY CalendarDate, ParentLocationId, DateFrom, DateTo, MaterialTypeId
			
		-- return Grades
		SELECT p.CalendarDate, p.ParentLocationId, p.MaterialTypeId, g.Grade_Id, g.Grade_Name AS GradeName,
			SUM(p.EffectiveTonnes * wsg.Grade_Value) / SUM(p.EffectiveTonnes) AS GradeValue
		FROM @ProductRecord AS p
			CROSS JOIN dbo.Grade AS g
			LEFT OUTER JOIN dbo.WeightometerSampleGrade AS wsg
				ON (wsg.Grade_Id = g.Grade_Id
					AND wsg.Weightometer_Sample_Id = p.WeightometerSampleId) 
		GROUP BY p.CalendarDate, p.ParentLocationId, p.DateFrom, p.DateTo, p.MaterialTypeId, g.Grade_Id, g.Grade_Name

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
	@iDateFrom = '1-apr-2008',
	@iDateTo = '30-apr-2008',
	@iDateBreakdown = 'MONTH',
	@iLocationId = 6,
	@iChildLocations = 1
*/



/* MOVE WB_BPF0 STOCKPILE TO BENE FINES GROUP */

delete stockpilegroupstockpile
where stockpile_id = 
	(select stockpile_id from stockpile where stockpile_name = 'WB-BPF0')

insert into stockpilegroupstockpile (stockpile_group_id, stockpile_id) 
select 'Bene Fines', stockpile_id from stockpile where stockpile_name = 'WB-BPF0'