IF OBJECT_ID('dbo.SummariseBhpbioPortStockpileDelta') IS NOT NULL
     DROP PROCEDURE dbo.SummariseBhpbioPortStockpileDelta 
GO 
    
CREATE PROCEDURE dbo.SummariseBhpbioPortStockpileDelta
(
	@iSummaryMonth DATETIME,
	@iSummaryLocationId INTEGER
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
	
	DECLARE @PortBalance TABLE
	(
		HubLocationId INT NOT NULL,
		BalanceDate DATETIME NOT NULL,
		Tonnes FLOAT,
		ProductSize VARCHAR(5)

		PRIMARY KEY (HubLocationId, BalanceDate, ProductSize)
	)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'SummariseBhpbioPortStockpileDelta',
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
		
		-- obtain the Actual Type Id for ActualY storage
		SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
		FROM dbo.BhpbioSummaryEntryType bset
		WHERE bset.Name = 'PortStockpileDelta'
		
		-- the first step is to remove previously summarised data for the same filtering criteria that the current summary is running on
		exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iSummaryMonth,
											@iSummaryLocationId = @iSummaryLocationId,
											@iSummaryEntryTypeId = @summaryEntryTypeId
		
		-- get the start of the summary month and the start of the following month
		-- this gives us a window of time to operate within
		SELECT @startOfMonth = dbo.GetDateMonth(@iSummaryMonth)
		SELECT @startOfNextMonth = DATEADD(month,1,@iSummaryMonth)

		-- get a Summary Id for the month (or create a new one if needed)
		EXEC dbo.GetBhpbioSummaryIdForMonth @iSummaryMonth = @startOfMonth,
											@oSummaryId = @summaryId OUTPUT
		
		INSERT INTO @Location (LocationId, ParentLocationId)
		SELECT LocationId, ParentLocationId
		FROM dbo.GetBhpbioReportLocationBreakdown(@iSummaryLocationId, 1, 'SITE')
		UNION
		SELECT l.Location_Id, l.Parent_Location_Id
		FROM Location l
		WHERE l.Location_Id = @iSummaryLocationId
		
		INSERT INTO @PortBalance (HubLocationId, BalanceDate, ProductSize, Tonnes)
		SELECT HubLocationId, BalanceDate, 
			CASE 
				WHEN ProductSize IS NULL THEN 'ROM'
				WHEN ProductSize NOT IN ('LUMP', 'FINES') THEN 'ROM' 
				ELSE ProductSize 
			END,
			SUM(Tonnes)
		FROM BhpbioPortBalance
		GROUP BY HubLocationId, BalanceDate, 
			CASE 
				WHEN ProductSize IS NULL THEN 'ROM'
				WHEN ProductSize NOT IN ('LUMP', 'FINES') THEN 'ROM' 
				ELSE ProductSize 
			END
			
		-- -----------------------------------------------------------------------------------------------------------------------------------
		-- The queries used in this procedure are based on / taken from the original reporting implementation (on non-summarised data)
		-- -----------------------------------------------------------------------------------------------------------------------------------
		
		---- Insert the tonnes
		INSERT INTO dbo.BhpbioSummaryEntry
		(
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			ProductSize,
			Tonnes
		)
		SELECT @summaryId,
			   @summaryEntryTypeId,
			   L.LocationId,
			   NULL,
			   CASE WHEN BPB.ProductSize = 'ROM' THEN defaultlf.ProductSize ELSE BPB.ProductSize END,
			   COALESCE(Sum(ISNULL(defaultlf.[Percent], 1) * BPB.Tonnes) - Sum(ISNULL(defaultlf.[Percent], 1) * BPBPREV.Tonnes), 0)
		FROM @PortBalance AS BPB
			INNER JOIN @Location AS L
				ON (BPB.HubLocationId = L.LocationId)
			LEFT JOIN @PortBalance AS BPBPREV
				ON BPBPREV.BalanceDate = DateAdd(Day, -1, @startOfMonth)
				AND BPB.HubLocationId = BPBPREV.HubLocationId
				AND BPB.ProductSize = BPBPREV.ProductSize
			LEFT JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf
				ON BPB.ProductSize = 'ROM'
				AND BPB.HubLocationId = defaultlf.LocationId
				AND BPB.BalanceDate BETWEEN defaultlf.StartDate AND defaultlf.EndDate
			LEFT JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlfprev
				ON BPBPREV.ProductSize = 'ROM'
				AND BPBPREV.HubLocationId = defaultlfprev.LocationId
				AND BPBPREV.BalanceDate BETWEEN defaultlfprev.StartDate AND defaultlfprev.EndDate
				AND defaultlf.ProductSize = defaultlfprev.ProductSize
			LEFT JOIN GetBhpbioExcludeHubLocation('PortBalance') AS HXF ON BPB.HubLocationId = HXF.LocationId
		WHERE BPB.BalanceDate = DateAdd(Day, -1, @startOfNextMonth)
		AND   HXF.LocationId IS NULL
		AND	(ISNULL(defaultlf.[Percent], 1) > 0)
		GROUP BY L.LocationId, CASE WHEN BPB.ProductSize = 'ROM' THEN defaultlf.ProductSize ELSE BPB.ProductSize END
		
		-- insert lump/fines roll up for total
		INSERT INTO dbo.BhpbioSummaryEntry
		(
			SummaryId,
			SummaryEntryTypeId,
			BSE.LocationId,
			MaterialTypeId,
			ProductSize,
			Tonnes
		)
		SELECT @summaryId, @summaryEntryTypeId, BSE.LocationId, NULL, 'TOTAL', SUM(BSE.Tonnes)
		FROM dbo.BhpbioSummaryEntry BSE
			INNER JOIN @Location AS L
				ON (BSE.LocationId = L.LocationId)
		WHERE BSE.SummaryId = @summaryId
		AND BSE.SummaryEntryTypeId = @summaryEntryTypeId
		GROUP BY BSE.LocationId 
		
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

GRANT EXECUTE ON dbo.SummariseBhpbioPortStockpileDelta TO BhpbioGenericManager
GO

/*
exec dbo.SummariseBhpbioPortStockpileDelta
	@iSummaryMonth = '2012-11-01',
	@iSummaryLocationId = 6
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.SummariseBhpbioPortStockpileDelta">
 <Procedure>
	Generates a set of summary Port Stockpile Delta data based on supplied criteria.
	
	Delta refers to the difference between additions and reclaims
			
	Pass: 
			@iSummaryMonth: the month for which summary data is to be generated,
			@iSummaryLocationId: the location (a Hub) for which data will be summarised

 </Procedure>
</TAG>
*/