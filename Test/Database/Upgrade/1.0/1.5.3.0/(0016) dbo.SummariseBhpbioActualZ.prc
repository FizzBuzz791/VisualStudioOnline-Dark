IF OBJECT_ID('dbo.SummariseBhpbioActualZ') IS NOT NULL
     DROP PROCEDURE dbo.SummariseBhpbioActualZ 
GO 
    
CREATE PROCEDURE dbo.SummariseBhpbioActualZ
(
	@iSummaryMonth DATETIME,
	@iSummaryLocationId INTEGER
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'SummariseBhpbioActualZ',
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
		DECLARE @summaryId INT
		DECLARE @startOfMonth DATETIME
		DECLARE @endOfMonth DATETIME
		DECLARE @startOfNextMonth DATETIME
		DECLARE @summaryEntryTypeId INTEGER
		
		-- obtain the Entry Type Id
		SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
		FROM dbo.BhpbioSummaryEntryType bset
		WHERE bset.Name = 'ActualZ'
		
		-- the first step is to remove previously summarised data for the same filtering criteria that the current summary is running on
		exec dbo.DeleteBhpbioSummaryEntry @iSummaryMonth = @iSummaryMonth,
											@iSummaryLocationId = @iSummaryLocationId,
											@iSummaryEntryTypeId = @summaryEntryTypeId
		

		-- get the start of the summary month and the start of the following month
		-- this gives us a window of time to operate within
		SELECT @startOfMonth = dbo.GetDateMonth(@iSummaryMonth)
		SELECT @startOfNextMonth = DATEADD(month,1,@iSummaryMonth)
		SELECT @endOfMonth = DATEADD(day,-1,@startOfNextMonth)

		-- get a Summary Id for the month (or create a new one if needed)
		EXEC dbo.GetBhpbioSummaryIdForMonth @iSummaryMonth = @startOfMonth,
											@oSummaryId = @summaryId OUTPUT

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
	
		DECLARE @Location TABLE
		(
			LocationId INT NOT NULL,
			IncludeStart DateTime NOT NULL,
			IncludeEnd DateTime NOT NULL,
			
			PRIMARY KEY (LocationId, IncludeStart, IncludeEnd)
		)
		
		INSERT INTO @Location
			(LocationId, IncludeStart, IncludeEnd)
		SELECT LocationId, IncludeStart, IncludeEnd
		FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iSummaryLocationId, 1, 'Pit', @startOfMonth, @endOfMonth)
		UNION 
		SELECT l.Location_Id, @startOfMonth, @endOfMonth
		FROM Location l
		WHERE l.Location_Id = @iSummaryLocationId
		
		DECLARE @SelectedHaulage TABLE
		(
			HaulageId INT NOT NULL,
			LocationId INT NULL,
			Tonnes FLOAT NOT NULL,
			MaterialTypeId INT NOT NULL,
			PRIMARY KEY (HaulageId)
		)
		
		-- -----------------------------------------------------------------------------------------------------------------------------------
		-- The queries used in this procedure are based on / taken from the original reporting implementation (on non-summarised data)
		-- -----------------------------------------------------------------------------------------------------------------------------------

		-- collect the haualge data that matches:
		-- 1. the date range specified
		-- 2. delivers to a crusher (which belongs to the location subtree specified)
		-- 3. sources from a designation stockpile group
		--
		-- for the Material Type, the following rule applies:
		-- If the Weightometer deliveres to a plant then it is BENE, otherwise it is High Grade.

		-- retrieve the list of Haulage Records to be used in the calculations
		INSERT INTO @SelectedHaulage
			(HaulageId, LocationId, Tonnes, MaterialTypeId)
		SELECT DISTINCT h.Haulage_Id, l.LocationId, h.Tonnes,
			CASE WHEN W.Weightometer_Id IS NOT NULL THEN @BeneFeedMaterialTypeId
					ELSE @HighGradeMaterialTypeId
			END
		FROM dbo.Haulage AS h
			INNER JOIN dbo.Crusher AS c
				ON (c.Crusher_Id = h.Destination_Crusher_Id)
			INNER JOIN dbo.GetBhpbioCrusherLocationWithOverride(@startOfMonth, @endOfMonth) AS cl
				ON (c.Crusher_Id = cl.Crusher_Id) 
				AND (h.Haulage_Date BETWEEN cl.IncludeStart AND cl.IncludeEnd)
			INNER JOIN @Location AS l
				ON (l.LocationId = cl.Location_Id)
				AND (h.Haulage_Date BETWEEN l.IncludeStart and l.IncludeEnd)
			INNER JOIN dbo.Stockpile AS s
				ON (s.Stockpile_Id = h.Source_Stockpile_Id)
			INNER JOIN dbo.StockpileGroupStockpile AS sgs
				ON (sgs.Stockpile_Id = s.Stockpile_Id)
			INNER JOIN dbo.BhpbioStockpileGroupDesignation AS sgd
				ON (sgd.StockpileGroupId = sgs.Stockpile_Group_Id)
			LEFT JOIN dbo.WeightometerFlowPeriodView AS WFPV
				ON (WFPV.Source_Crusher_Id = c.Crusher_Id
					AND WFPV.Destination_Mill_Id IS NOT NULL
					AND (@startOfMonth > WFPV.Start_Date Or WFPV.Start_Date IS NULL)
					AND (@startOfMonth < WFPV.End_Date Or WFPV.End_Date IS NULL))
			LEFT JOIN dbo.Weightometer AS W
				ON (W.Weightometer_Id = WFPV.Weightometer_Id)
		  LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('ActualZ') xs
			  ON xs.StockpileId = h.Source_Stockpile_Id
			  OR xs.StockpileId = h.Destination_Stockpile_Id
		WHERE 
			h.Haulage_State_Id IN ('N', 'A')
			AND h.Child_Haulage_Id IS NULL
			AND (W.Weightometer_Type_Id LIKE '%L1%' OR W.Weightometer_Type_Id IS NULL)
			AND h.Source_Stockpile_Id IS NOT NULL
			AND h.Haulage_Date >= @startOfMonth
			AND h.Haulage_Date < @startOfNextMonth
			AND xs.StockpileId IS NULL -- No movements to or from excluded groups.
			
		-- insert main actual row using a Sum of Tonnes
		INSERT INTO dbo.BhpbioSummaryEntry (
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			Tonnes
		)
		SELECT  @summaryId,
				@summaryEntryTypeId,
				h.LocationId,
				h.MaterialTypeId,
				Sum(h.Tonnes)
		FROM @SelectedHaulage h
		GROUP BY h.LocationId, h.MaterialTypeId

		-- insert the actual grades related to the selection of Haulage we are working with and the actual tonnes rows created above
		INSERT INTO dbo.BhpbioSummaryEntryGrade (
			SummaryEntryId,
			GradeId,
			GradeValue
		 )
		SELECT  bse.SummaryEntryId,
				hg.Grade_Id,
				-- weight-average the tonnes
				-- note that the AVG(bsa.Tonnes) could be any aggregate operation as there will only be one value per group
				-- as we are grouping on bse.SummaryEntryId
				SUM(h.Tonnes * hg.Grade_Value) / AVG(bse.Tonnes)
		FROM dbo.BhpbioSummaryEntry bse
			INNER JOIN @SelectedHaulage h 
				ON h.LocationId = bse.LocationId
				AND h.MaterialTypeId = bse.MaterialTypeId
			INNER JOIN dbo.HaulageGrade hg
				ON hg.Haulage_Id = h.HaulageId
		WHERE bse.SummaryId = @summaryId
			AND bse.SummaryEntryTypeId = @summaryEntryTypeId
			AND hg.Grade_Value IS NOT NULL
		GROUP BY bse.SummaryEntryId, hg.Grade_Id
		
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

GRANT EXECUTE ON dbo.SummariseBhpbioActualZ TO BhpbioGenericManager
GO

/*
exec dbo.SummariseBhpbioActualZ
	@iSummaryMonth = '2009-11-01',
	@iLocationId = 3,
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.SummariseBhpbioActualZ">
 <Procedure>
	Generates a set of summary ActualZ data based on supplied criteria.
			
	Pass: 
			@iSummaryMonth: the month for which summary data is to be generated,
			@iSummaryLocationId: the location (typically a Site) for which data will be summarised,
 </Procedure>
</TAG>
*/	