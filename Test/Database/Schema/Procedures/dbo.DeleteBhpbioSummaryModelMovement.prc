IF OBJECT_ID('dbo.DeleteBhpbioSummaryModelMovement') IS NOT NULL
     DROP PROCEDURE dbo.DeleteBhpbioSummaryModelMovement
GO 

CREATE PROCEDURE dbo.DeleteBhpbioSummaryModelMovement
(
	@iSummaryMonth DATETIME,
	@iSummaryLocationId INTEGER,
	@iIsHighGrade BIT,
	@iSpecificMaterialTypeId INTEGER,
	@iModelName VARCHAR(255)
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	DECLARE @summaryEntryTypeId INTEGER
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'DeleteBhpbioSummaryModelMovement',
		@TransactionCount = @@TranCount 
		
	SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
	FROM dbo.BhpbioSummaryEntryType bset
	WHERE bset.Name like REPLACE(@iModelName,' ','') + 'ModelMovement'

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

		-- determine the start of the summary month and the start of the following month
		-- this gives us a window of time to operate within
		SELECT @startOfMonth = dbo.GetDateMonth(@iSummaryMonth)
		SELECT @startOfNextMonth = DATEADD(month,1,@iSummaryMonth)

		-- determine the appropriate Summary Id the data calculated here is to be appended with
		EXEC dbo.GetBhpbioSummaryIdForMonth @iSummaryMonth = @startOfMonth,
											@oSummaryId = @summaryId OUTPUT

		-- create a local table variable for storing identifiers for locations
		-- that are relevant to this operation
		DECLARE @Location TABLE
		(
			LocationId INT NOT NULL,
			ParentLocationId INT NULL,
			PRIMARY KEY (LocationId)
		)
		
		-- populate the relevant locations table variable: @Location
		INSERT INTO @Location(
			LocationId, 
			ParentLocationId)
		SELECT LocationId, ParentLocationId
		FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iSummaryLocationId, 1, NULL, @startOfMonth, DATEADD(DAY, -1, @startOfNextMonth))
		
		-- delete summary data for the related locations as appropriate based on the criteria provided
		DELETE bse
		FROM dbo.BhpbioSummaryEntry bse
		INNER JOIN dbo.GetBhpbioFilteredMaterialTypes(@iIsHighGrade,@iSpecificMaterialTypeId) mt
				ON mt.MaterialTypeId = bse.MaterialTypeId
		INNER JOIN @Location loc
				ON loc.LocationId = bse.LocationId
		WHERE bse.SummaryId = @summaryId
		AND bse.SummaryEntryTypeId = @summaryEntryTypeId
		
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

GRANT EXECUTE ON dbo.DeleteBhpbioSummaryModelMovement TO BhpbioGenericManager
GO

/*
-- A call like this is used for F1 related summarisation for a model
exec dbo.DeleteBhpbioSummaryModelMovement
	@iSummaryMonth = '2009-11-01',
	@@iSummaryLocationId = 3,
	@iIsHighGrade = 1,
	@iSpecificMaterialTypeId = null,
	@iModelName = 'Geology'
	
-- A call like this is used for Other Movements related summarisation for a particular material type
exec dbo.DeleteBhpbioSummaryModelMovement
	@iSummaryMonth = '2009-11-01',
	@iLocationId = 3,
	@iIsHighGrade = null,
	@iSpecificMaterialTypeId = 6,
	@iModelName = 'Grade Control'
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.DeleteBhpbioSummaryModelMovement">
 <Procedure>
	Deletes a set of summary Model Movement data based on supplied criteria.
	The criteria is the same as which could be sent to the corresponding SummariseBhpModelMovement procedure
	
	In the descriptions below the term Related Material Type means a MeterialType that is either
			- the Root for the specified type
			- a material type that has the specified type as its root
	In the descriptions below the phrase High Grade Related type means a type that is:
			- returned by the dbo.GetBhpbioReportHighGrade() function
			
	Pass: 
			@iSummaryMonth: the month for which summary data is to be removed,
			@iSummaryLocationId: the location (typically a Pit) used to filter the movements to have summary data generated,
			@iIsHighGrade : 
							when 0 - Data for High grade related types is excluded
							when 1 - Only data for high grade related types is included
							when null - this criteria has no impact on filtering
			@iSpecificMaterialTypeId:
							when specified - only Data for the exact matching MaterialTypeId or for MaterialTypes related to the exact match is included
							when null - this criteria has no impact on filtering
			@iModelName: Specifies the BlockModel whose summary movements are to be cleared
 </Procedure>
</TAG>
*/