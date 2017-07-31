IF OBJECT_ID('dbo.SummariseBhpbioOMHauledFromBlock') IS NOT NULL
     DROP PROCEDURE dbo.SummariseBhpbioOMHauledFromBlock 
GO 
    
CREATE PROCEDURE dbo.SummariseBhpbioOMHauledFromBlock
(
	@iSummaryMonth DATETIME,
	@iSummaryLocationId INTEGER,
	@iSpecificMaterialTypeId INTEGER
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'SummariseBhpbioOMHauledFromBlock',
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
		DECLARE @summaryEntryTypeId INTEGER
		DECLARE @DateFrom DATETIME
		DECLARE @DateTo DATETIME
	
		DECLARE @BhpbioSummaryEntryType TABLE
		(
			SummaryEntryTypeId INT NOT NULL,
			SummaryEntryTypeName VARCHAR(30) NOT NULL,
			PRIMARY KEY (SummaryEntryTypeId)
		)
		
		-- the first step is to remove previously summarised data for the same filtering criteria that the current summary is running on
		exec dbo.DeleteBhpbioSummaryOMHauledFromBlock @iSummaryMonth = @iSummaryMonth,
											@iSummaryLocationId = @iSummaryLocationId,
											@iSpecificMaterialTypeId = @iSpecificMaterialTypeId
		
		-- obtain the SummaryEntryTypeId
		INSERT INTO @BhpbioSummaryEntryType
		(
			SummaryEntryTypeId, SummaryEntryTypeName
		)
		SELECT bset.SummaryEntryTypeId, bset.Name
		FROM dbo.BhpbioSummaryEntryType bset
		WHERE bset.Name in ('HauledToNonOreStockpile', 'HauledToOreStockpile','HauledToCrusher')

		-- get the start of the summary month and the start of the following month
		-- this gives us a window of time to operate within
		SET @DateFrom = dbo.GetDateMonth(@iSummaryMonth)
		SET @DateTo = DateAdd(Day, -1, DateAdd(Month, 1, @DateFrom))
		
		-- get a Summary Id for the month (or create a new one if needed)
		EXEC dbo.GetBhpbioSummaryIdForMonth @iSummaryMonth = @DateFrom,
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
		DECLARE @HauledFromBlock TABLE
			(
				SummaryEntryTypeId INT NOT NULL,
				LocationId INT NULL,
				MaterialTypeId INT NOT NULL,
				Tonnes FLOAT NOT NULL,
				ProductSize VARCHAR(5) NOT NULL
			)
			
			
		-- -----------------------------------------------------------------------------------------------------------------------------------
		-- The queries used in this procedure are based on / taken from the original reporting implementation (on non-summarised data)
		-- -----------------------------------------------------------------------------------------------------------------------------------

		-- populate the table used to store details of relevant haulage rows
		-- to be only the haulage rows within the time window
		-- and for the appropriate material types
		INSERT INTO @HauledFromBlock
		(
			SummaryEntryTypeId, LocationId, MaterialTypeId, Tonnes, ProductSize
		)
		Select bset.SummaryEntryTypeId, @iSummaryLocationId, DesignationMaterialTypeId, Value, ProductSize
		From dbo.GetBhpbioReportHaulageBreakdown(@DateFrom, @DateTo, NULL, @iSummaryLocationId, 0, 1, 0) as hb
			Inner Join @BhpbioSummaryEntryType bset
				On hb.HaulageType = bset.SummaryEntryTypeName
		Where DesignationMaterialTypeId = @iSpecificMaterialTypeId

		-- insert main actual row using a Sum of Tonnes
		INSERT INTO dbo.BhpbioSummaryEntry (
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			Tonnes,
			ProductSize
		)
		SELECT  @summaryId,
				SummaryEntryTypeId,
				LocationId,
				MaterialTypeId,
				Sum(Tonnes) As Tonnes,
				ProductSize
		FROM @HauledFromBlock h
		GROUP BY SummaryEntryTypeId, LocationId, MaterialTypeId, ProductSize
		
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

GRANT EXECUTE ON dbo.SummariseBhpbioOMHauledFromBlock TO BhpbioGenericManager
GO

/*
-- A call like this is used for Other Movements related summarisation for a particular material type
exec dbo.SummariseBhpbioOMHauledFromBlock
	@iSummaryMonth = '2014-01-01',
	@iSummaryLocationId = 32272,
	@iSpecificMaterialTypeId = 3
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.SummariseBhpbioOMHauledFromBlock">
 <Procedure>
	Generates a set of summary Actual Other Movements to Stockpiles data based on supplied criteria.
	
	Pass: 
			@iSummaryMonth: the month for which summary data is to be deleted,
			@iSummaryLocationId: the location (typically a Pit),
			@iSpecificMaterialTypeId:
							when specified - only Data for the exact matching MaterialTypeId or for MaterialTypes related to the exact match is included
							when null - this criteria has no impact on filtering
 </Procedure>
</TAG>
*/	