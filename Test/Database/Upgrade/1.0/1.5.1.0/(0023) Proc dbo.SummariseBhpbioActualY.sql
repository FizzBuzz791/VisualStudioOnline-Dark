IF OBJECT_ID('dbo.SummariseBhpbioActualY') IS NOT NULL
     DROP PROCEDURE dbo.SummariseBhpbioActualY 
GO 
    
CREATE PROCEDURE dbo.SummariseBhpbioActualY
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

	SELECT	@TransactionName = 'SummariseBhpbioActualY',
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
		DECLARE @startOfNextMonth DATETIME
		DECLARE @summaryEntryTypeId INTEGER
		
		-- the first step is to remove previously summarised data for the same filtering criteria that the current summary is running on
		exec dbo.DeleteBhpbioSummaryActualY @iSummaryMonth = @iSummaryMonth,
											@iSummaryLocationId = @iSummaryLocationId
		
		-- obtain the Actual Type Id for ActualY storage
		SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
		FROM dbo.BhpbioSummaryEntryType bset
		WHERE bset.Name = 'ActualY'

		-- get the start of the summary month and the start of the following month
		-- this gives us a window of time to operate within
		SELECT @startOfMonth = dbo.GetDateMonth(@iSummaryMonth)
		SELECT @startOfNextMonth = DATEADD(month,1,@iSummaryMonth)

		-- get a Summary Id for the month (or create a new one if needed)
		EXEC dbo.GetBhpbioSummaryIdForMonth @iSummaryMonth = @startOfMonth,
											@oSummaryId = @summaryId OUTPUT

		-- create and populate a table variable used to store Ids of relevant locations
		DECLARE @Location TABLE
		(
			LocationId INT NOT NULL,
			ParentLocationId INT NULL,
			PRIMARY KEY (LocationId)
		)

		INSERT INTO @Location(
			LocationId, 
			ParentLocationId)
		SELECT LocationId, ParentLocationId
		FROM dbo.GetBhpbioReportLocationBreakdown(@iSummaryLocationId, 1, NULL)

		-- create a table to store details of relevant haulage rows
		DECLARE @SelectedHaulage TABLE
			(
				HaulageId INT NOT NULL,
				LocationId INT NULL,
				Tonnes FLOAT NOT NULL,
				MaterialTypeId INT NOT NULL
			)
		
		-- -----------------------------------------------------------------------------------------------------------------------------------
		-- The queries used in this procedure are based on / taken from the original reporting implementation (on non-summarised data)
		-- -----------------------------------------------------------------------------------------------------------------------------------

		-- populate the table used to store details of relevant haulage rows
		-- to be only the haulage rows within the time window
		-- and for the appropriate material types
		INSERT INTO @SelectedHaulage(
						HaulageId, 
						LocationId, 
						Tonnes, 
						MaterialTypeId
						)
		SELECT DISTINCT h.Haulage_Id, l.LocationId, h.Tonnes, destinationStockpile.MaterialTypeId
		FROM dbo.Haulage AS h
			INNER JOIN dbo.DigblockLocation dl 
				ON (dl.Digblock_Id = h.Source_Digblock_Id)
			INNER JOIN @Location AS l
				ON (l.LocationId = dl.Location_Id)
			-- join to the destination stockpile
			-- this is a way of filtering for Actual Y (ie material from digblocks to stockpiles)
			INNER JOIN
				(
					SELECT sl2.Stockpile_Id, sgd2.MaterialTypeId
					FROM dbo.BhpbioStockpileGroupDesignation AS sgd2
					INNER JOIN dbo.StockpileGroupStockpile AS sgs2
						ON (sgs2.Stockpile_Group_Id = sgd2.StockpileGroupId)
					INNER JOIN dbo.StockpileLocation AS sl2
							ON (sl2.Stockpile_Id = sgs2.Stockpile_Id)
				) AS destinationStockpile
				ON (destinationStockpile.Stockpile_Id = h.Destination_Stockpile_Id)
			INNER JOIN dbo.GetBhpbioFilteredMaterialTypes(1,null) mt
				ON mt.MaterialTypeId = destinationStockpile.MaterialTypeId
			LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('ActualY') xs
				ON xs.StockpileId = h.Source_Stockpile_Id
				OR xs.StockpileId = h.Destination_Stockpile_Id
		WHERE h.Haulage_State_Id IN ('N', 'A')
			AND h.Child_Haulage_Id IS NULL
			AND h.Source_Digblock_Id IS NOT NULL
			AND h.Haulage_Date >= @startOfMonth 
			AND h.Haulage_Date < @startOfNextMonth
			AND h.Tonnes > 0
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
		FROM BhpbioSummaryEntry bse
			INNER JOIN @SelectedHaulage h 
				ON h.LocationId = bse.LocationId
				AND h.MaterialTypeId = bse.MaterialTypeId
			INNER JOIN dbo.HaulageGrade hg
				ON hg.Haulage_Id = h.HaulageId
		WHERE bse.SummaryId = @summaryId
			AND bse.SummaryEntryTypeId = @summaryEntryTypeId
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

GRANT EXECUTE ON dbo.SummariseBhpbioActualY TO BhpbioGenericManager
GO

/*
-- A call like this is used for F1 related summarisation
exec dbo.SummariseBhpbioActualY
	@iSummaryMonth = '2009-11-01',
	@iLocationId = 3,
	
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.SummariseBhpbioActualY">
 <Procedure>
	Generates a set of summary ActualY data based on supplied criteria.
	Haulage data is the key source for this summarisation
			
	Pass: 
			@iSummaryMonth: the month for which summary data is to be deleted,
			@iSummaryLocationId: the location (typically a Pit) within which child locations will have data removed,
 </Procedure>
</TAG>
*/	