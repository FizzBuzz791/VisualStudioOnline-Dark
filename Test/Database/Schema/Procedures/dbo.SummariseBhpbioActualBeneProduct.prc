IF OBJECT_ID('dbo.SummariseBhpbioActualBeneProduct') IS NOT NULL
     DROP PROCEDURE dbo.SummariseBhpbioActualBeneProduct 
GO 
    
CREATE PROCEDURE dbo.SummariseBhpbioActualBeneProduct
(
	@iSummaryMonth DATETIME,
	@iSummaryLocationId INTEGER
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	DECLARE @ProductSizeField VARCHAR(31)

	SET @ProductSizeField = 'ProductSize'

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
		ProductSize VARCHAR(5) NOT NULL,
		ParentLocationId INT NULL,
		PRIMARY KEY (CalendarDate, WeightometerSampleId, MaterialTypeId, ProductSize)
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'SummariseBhpbioActualBeneProduct',
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
		DECLARE @SummaryId INT
		DECLARE @StartOfMonth DATETIME
		DECLARE @StartOfNextMonth DATETIME
		DECLARE @BeneProductSummaryEntryTypeId INTEGER
		DECLARE @BeneProductMaterialTypeId INTEGER
		
		-- obtain the Actual Type Id for ActualC storage
		SELECT @BeneProductSummaryEntryTypeId = bset.SummaryEntryTypeId
		FROM dbo.BhpbioSummaryEntryType bset
		WHERE bset.Name = 'ActualBeneProduct'
		
		-- the first step is to remove previously summarised data for the same filtering criteria that the current summary is running on
		exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iSummaryMonth,
											@iSummaryLocationId = @iSummaryLocationId,
											@iSummaryEntryTypeId = @BeneProductSummaryEntryTypeId
		
		-- get the start of the summary month and the start of the following month
		-- this gives us a window of time to operate within
		SELECT @StartOfMonth = dbo.GetDateMonth(@iSummaryMonth)
		SELECT @StartOfNextMonth = DATEADD(month,1,@iSummaryMonth)

		-- get a Summary Id for the month (or create a new one if needed)
		EXEC dbo.GetBhpbioSummaryIdForMonth @iSummaryMonth = @StartOfMonth,
											@oSummaryId = @SummaryId OUTPUT
											
		-- collect the location subtree
		INSERT INTO @Location
			(LocationId, ParentLocationId)
		SELECT LocationId, ParentLocationId
		FROM dbo.GetBhpbioReportLocationBreakdown(@iSummaryLocationId, 0, NULL)

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
			CalendarDate,
			WeightometerSampleId,
			EffectiveTonnes,
			MaterialTypeId, 
			ProductSize,
			ParentLocationId
		)
		SELECT @StartOfMonth, ws.Weightometer_Sample_Id, 
			ISNULL(ISNULL(defaultlf.[Percent], 1) * ws.Corrected_Tonnes, ISNULL(defaultlf.[Percent], 1) * ws.Tonnes),
			@BeneProductMaterialTypeId, 
			ISNULL(wsn.Notes, defaultlf.ProductSize), 
			CASE WHEN l.ParentLocationId IS NULL
				THEN l.LocationId
				ELSE l.ParentLocationId
			END
		FROM dbo.WeightometerSample AS ws
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
			LEFT JOIN dbo.WeightometerSampleNotes wsn
				ON (ws.Weightometer_Sample_Id = wsn.Weightometer_Sample_Id
					AND wsn.Weightometer_Sample_Field_Id = @ProductSizeField)
			LEFT JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf
				ON wsn.Notes IS NULL
				AND l.LocationId = defaultlf.LocationId
				AND ws.Weightometer_Sample_Date BETWEEN defaultlf.StartDate AND defaultlf.EndDate					
				
		WHERE ws.Weightometer_Sample_Date >= @StartOfMonth
			AND ws.Weightometer_Sample_Date < @StartOfNextMonth
			AND	(ISNULL(defaultlf.[Percent], 1) > 0)
		
		-- insert main actual row using a Sum of Tonnes
		INSERT INTO dbo.BhpbioSummaryEntry
		(
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			ProductSize,
			Tonnes
		)
		-- get the lump and fines
		SELECT	@summaryId,
				@BeneProductSummaryEntryTypeId,
				ParentLocationId, 
				MaterialTypeId, 
				ProductSize, 
				SUM(EffectiveTonnes) AS Tonnes
		FROM @ProductRecord AS p
		GROUP BY CalendarDate, ParentLocationId, MaterialTypeId, ProductSize
		UNION ALL 
		-- plus rolled up total
		SELECT	@summaryId,
				@BeneProductSummaryEntryTypeId,
				ParentLocationId, 
				MaterialTypeId, 
				'TOTAL', 
				SUM(EffectiveTonnes) AS Tonnes
		FROM @ProductRecord AS p
		GROUP BY CalendarDate, ParentLocationId, MaterialTypeId
			
		-- insert the summary grades
		INSERT INTO dbo.BhpbioSummaryEntryGrade
		(
			SummaryEntryId,
			GradeId,
			GradeValue
		)
		-- get separate lump and fines
		SELECT bse.SummaryEntryId,
			wsg.Grade_Id, 
			SUM(p.EffectiveTonnes * wsg.Grade_Value) / NULLIF(SUM(p.EffectiveTonnes), 0) AS GradeValue
		FROM @ProductRecord AS p
			INNER JOIN dbo.BhpbioSummaryEntry bse
				ON bse.LocationId = p.ParentLocationId
				AND bse.MaterialTypeId = p.MaterialTypeId
				AND (p.ProductSize = bse.ProductSize OR bse.ProductSize = 'TOTAL')
				AND bse.SummaryId = @SummaryId
				AND bse.SummaryEntryTypeId = @BeneProductSummaryEntryTypeId
			INNER JOIN dbo.WeightometerSampleGrade AS wsg
				ON wsg.Weightometer_Sample_Id = p.WeightometerSampleId 
		GROUP BY SummaryEntryId, Grade_Id
		
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

GRANT EXECUTE ON dbo.SummariseBhpbioActualBeneProduct TO BhpbioGenericManager
GO

/*
exec dbo.SummariseBhpbioActualBeneProduct
	@iSummaryMonth = '2009-11-01',
	@iLocationId = 3
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.SummariseBhpbioActualBeneProduct">
 <Procedure>
	Generates a set of summary Actual Bene Product data based on supplied criteria.
			
	Pass: 
			@iSummaryMonth: the month for which summary data is to be generated,
			@iSummaryLocationId: the location (typically a Site) for which data will be summarised
 </Procedure>
</TAG>
*/	
