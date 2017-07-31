IF OBJECT_ID('dbo.SummariseBhpbioShippingTransaction') IS NOT NULL
     DROP PROCEDURE dbo.SummariseBhpbioShippingTransaction 
GO 
    
CREATE PROCEDURE dbo.SummariseBhpbioShippingTransaction
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
	
	DECLARE @PortDelta TABLE
	(
		ParentLocationId INT NULL,
		LastBalanceDate DATETIME NULL,
		Tonnes FLOAT NULL,
		LastTonnes FLOAT NULL
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'SummariseBhpbioShippingTransaction',
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
		WHERE bset.Name = 'ShippingTransaction'
		
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
		
		-- -----------------------------------------------------------------------------------------------------------------------------------
		-- The queries used in this procedure are based on / taken from the original reporting implementation (on non-summarised data)
		-- -----------------------------------------------------------------------------------------------------------------------------------
		
		INSERT INTO @Location (LocationId, ParentLocationId)
		SELECT LocationId, ParentLocationId
		FROM dbo.GetBhpbioReportLocationBreakdown(@iSummaryLocationId, 1, 'SITE')
		UNION
		SELECT l.Location_Id, l.Parent_Location_Id
		FROM Location l
		WHERE l.Location_Id = @iSummaryLocationId
		
		---- Insert the tonnes
		INSERT INTO dbo.BhpbioSummaryEntry
		(
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			Tonnes
		)
		SELECT	@summaryId,
				@summaryEntryTypeId,
				L.LocationId, 
				NULL AS MaterialTypeId,
				SUM(S.Tonnes) AS Tonnes
		FROM dbo.BhpbioShippingTransactionNomination AS S
			INNER JOIN @Location AS L
				ON (S.HubLocationId = L.LocationId)
			LEFT JOIN GetBhpbioExcludeHubLocation('ShippingTransaction') HXF ON S.HubLocationId = HXF.LocationId
		WHERE S.OfficialFinishTime >= @startOfMonth
			AND S.OfficialFinishTime < @startOfNextMonth
			--AND S.HubLocationId NOT IN (SELECT LocationId FROM GetBhpbioExcludeHubLocation('ShippingTransaction'))
			AND HXF.LocationId IS NULL
		GROUP BY L.LocationId
		
		-- Insert the Shipping Grades
		INSERT INTO dbo.BhpbioSummaryEntryGrade
		(
			SummaryEntryId,
			GradeId,
			GradeValue
		)
		SELECT	bse.SummaryEntryId,
				SG.GradeId,
				SUM(SG.GradeValue * S.Tonnes) / SUM(S.Tonnes)
		FROM dbo.BhpbioShippingTransactionNomination AS S
			INNER JOIN @Location AS L
				ON (S.HubLocationId = L.LocationId)
			INNER JOIN dbo.BhpbioSummaryEntry bse
				ON bse.LocationId = L.LocationId
				AND bse.SummaryId = @summaryId
				AND bse.SummaryEntryTypeId = @summaryEntryTypeId
			INNER JOIN dbo.BhpbioShippingTransactionNominationGrade AS SG
				ON S.BhpbioShippingTransactionNominationId = SG.BhpbioShippingTransactionNominationId
			LEFT JOIN GetBhpbioExcludeHubLocation('ShippingTransaction') HXF ON S.HubLocationId = HXF.LocationId
		WHERE 
			S.OfficialFinishTime >= @startOfMonth
			AND S.OfficialFinishTime < @startOfNextMonth
			AND S.Tonnes > 0
			--AND S.HubLocationId NOT IN (SELECT LocationId FROM GetBhpbioExcludeHubLocation('ShippingTransaction'))
			AND HXF.LocationId IS NULL
		GROUP BY bse.SummaryEntryId, SG.GradeId
		
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

GRANT EXECUTE ON dbo.SummariseBhpbioShippingTransaction TO BhpbioGenericManager
GO

/*
exec dbo.SummariseBhpbioShippingTransaction
	@iSummaryMonth = '2009-11-01',
	@iSummaryLocationId = 3
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.SummariseBhpbioShippingTransaction">
 <Procedure>
	Generates a set of summary Shipping Transaction data based on supplied criteria.
			
	Pass: 
			@iSummaryMonth: the month for which summary data is to be generated,
			@iSummaryLocationId: the location (a Hub) for which data will be summarised

 </Procedure>
</TAG>
*/
