IF OBJECT_ID('dbo.DeleteBhpbioSummaryOMHauledFromBlock') IS NOT NULL
     DROP PROCEDURE dbo.DeleteBhpbioSummaryOMHauledFromBlock
GO 
    
CREATE PROCEDURE dbo.DeleteBhpbioSummaryOMHauledFromBlock
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

	SELECT @TransactionName = 'DeleteBhpbioSummaryOMHauledFromBlock',
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
		
		
		-- create a table variable to store the set of locations that we are interested in for this summarisation
		DECLARE @BhpbioSummaryEntryType TABLE
		(
			SummaryEntryTypeId INT NOT NULL
			PRIMARY KEY (SummaryEntryTypeId)
		)
		
		-- obtain the SummaryEntryTypeId
		-- this is required because the summary data is placed in a general summary storage table
		INSERT INTO @BhpbioSummaryEntryType
		SELECT bset.SummaryEntryTypeId
		FROM dbo.BhpbioSummaryEntryType bset
		WHERE bset.Name in ('HauledToNonOreStockpile', 'HauledToOreStockpile','HauledToCrusher')

		-- get the start of month (and start of the next month) based on the provided DateTime
		SELECT @startOfMonth = dbo.GetDateMonth(@iSummaryMonth)
		SELECT @startOfNextMonth = DATEADD(month,1,@iSummaryMonth)

		-- get an existing SummaryId or create a new one
		EXEC dbo.GetBhpbioSummaryIdForMonth @iSummaryMonth = @startOfMonth,
											@oSummaryId = @summaryId OUTPUT

		-- create a table variable to store the set of locations that we are interested in for this summarisation
		DECLARE @Location TABLE
		(
			LocationId INT NOT NULL,
			ParentLocationId INT NULL,
			PRIMARY KEY (LocationId)
		)

		-- populate the location table variable with all locations potentially relevant for this summary
		INSERT INTO @Location(
			LocationId, 
			ParentLocationId)
		SELECT LocationId, ParentLocationId
		FROM dbo.GetBhpbioReportLocationBreakdown(@iSummaryLocationId, 0, NULL)

		-- delete existing summary actual rows as appropriate based on the provided criteria
		-- this is any data that would be regenerated if the same criterial were sent to the equivalent Summarise procedure
		DELETE bse 
		FROM dbo.BhpbioSummaryEntry bse
			INNER JOIN dbo.GetBhpbioFilteredMaterialTypes(null,@iSpecificMaterialTypeId) mt
				ON mt.MaterialTypeId = bse.MaterialTypeId
			INNER JOIN @BhpbioSummaryEntryType bset
				ON bse.SummaryEntryTypeId = bset.SummaryEntryTypeId
		WHERE bse.SummaryId = @summaryId
			AND EXISTS (
						SELECT * 
						FROM @Location loc 
						WHERE loc.LocationId = bse.LocationId
						)
						
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

GRANT EXECUTE ON dbo.DeleteBhpbioSummaryOMHauledFromBlock TO BhpbioGenericManager
GO

/*
	
-- A call like this is used for Other Movements related summarisation for a particular material type
exec dbo.DeleteBhpbioSummaryOMHauledFromBlock
	@iSummaryMonth = '2009-11-01',
	@iLocationId = 3,
	@iSpecificMaterialTypeId = 6
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.DeleteBhpbioSummaryOMHauledFromBlock">
 <Procedure>
	Deletes a set of Actual Other Movements for Hauled data based on supplied criteria.
	The criteria is the same as which could be sent to the corresponding SummariseBhpbioOMHauledFromBlock procedure
	
	In the descriptions below the term Related Material Type means a MeterialType that is either
			- the Root for the specified type
			- a material type that has the specified type as its root
			
	Pass: 
			@iSummaryMonth: the month for which summary data is to be deleted,
			@iSummaryLocationId: the location (typically a Pit) within which child locations will have data removed,
			@iSpecificMaterialTypeId:
							when specified - only Data for the exact matching MaterialTypeId or for MaterialTypes related to the exact match is included
							when null - this criteria has no impact on filtering
 </Procedure>
</TAG>
*/	