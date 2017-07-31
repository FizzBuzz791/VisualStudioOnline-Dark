IF OBJECT_ID('dbo.SummariseBhpbioShippingTransaction_UF_ONLY') IS NOT NULL
     DROP PROCEDURE dbo.SummariseBhpbioShippingTransaction_UF_ONLY 
GO 
    
CREATE PROCEDURE dbo.SummariseBhpbioShippingTransaction_UF_ONLY
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
	
	DECLARE @ShippingItem TABLE
	(
		BhpbioShippingNominationItemParcelId INT NOT NULL,
		ProductSize VARCHAR(5) NOT NULL,
		Tonnes FLOAT NULL,
		
		PRIMARY KEY (BhpbioShippingNominationItemParcelId, ProductSize)
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
		
		-- obtain the Actual Type Id for Shipping storage
		SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
		FROM dbo.BhpbioSummaryEntryType bset
		WHERE bset.Name = 'ShippingTransaction'
		
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
		
		INSERT INTO @ShippingItem
		(
			BhpbioShippingNominationItemParcelId,
			ProductSize,
			Tonnes
		)
		SELECT	SP.BhpbioShippingNominationItemParcelId, 
				ISNULL(S.ShippedProductSize, defaultlf.ProductSize),
				ISNULL(defaultlf.[Percent], 1) * SP.Tonnes AS Tonnes
		FROM dbo.BhpbioShippingNominationItem AS S
			INNER JOIN dbo.BhpbioShippingNominationItemParcel SP
				ON (S.BhpbioShippingNominationItemId = SP.BhpbioShippingNominationItemId)
			INNER JOIN @Location AS L
				ON (SP.HubLocationId = L.LocationId)
			LEFT JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf
				ON S.ShippedProductSize IS NULL
				AND SP.HubLocationId = defaultlf.LocationId
				AND S.OfficialFinishTime BETWEEN defaultlf.StartDate AND defaultlf.EndDate
			LEFT JOIN GetBhpbioExcludeHubLocation('ShippingTransaction') HXF ON SP.HubLocationId = HXF.LocationId
		WHERE S.OfficialFinishTime >= @startOfMonth
			AND S.OfficialFinishTime < @startOfNextMonth
			AND HXF.LocationId IS NULL
			AND	(ISNULL(defaultlf.[Percent], 1) > 0)
		
	
		Declare @UltraFinesGradeId Int
		Select @UltraFinesGradeId = Grade_Id
		From Grade
		Where Grade_Name = 'Ultrafines'

		Delete seg
		FROM @ShippingItem SI 
		INNER JOIN BhpbioShippingNominationItemParcel SP 
			ON SP.BhpbioShippingNominationItemParcelId = SI.BhpbioShippingNominationItemParcelId
		INNER JOIN dbo.BhpbioShippingNominationItem S 
			ON S.BhpbioShippingNominationItemId = SP.BhpbioShippingNominationItemId
		INNER JOIN dbo.BhpbioSummaryEntry bse 
			ON bse.LocationId = SP.HubLocationId AND bse.SummaryId = @summaryId 
				AND bse.SummaryEntryTypeId = @summaryEntryTypeId 
				AND (bse.ProductSize = SI.ProductSize OR bse.ProductSize = 'TOTAL')
		INNER JOIN dbo.BhpbioSummaryEntryGrade seg
			on seg.SummaryEntryId = bse.SummaryEntryId
				and seg.GradeId = @UltraFinesGradeId

		INSERT INTO dbo.BhpbioSummaryEntryGrade
		(
			SummaryEntryId,
			GradeId,
			GradeValue
		)
		SELECT	bse.SummaryEntryId,
				@UltraFinesGradeId as GradeId,
				sum(CASE 
					WHEN SI.ProductSize = 'LUMP' THEN 0
					ELSE Undersize * SI.tonnes
				END) / sum(SI.tonnes) As Tonnes
		FROM @ShippingItem SI 
			INNER JOIN BhpbioShippingNominationItemParcel SP 
				ON SP.BhpbioShippingNominationItemParcelId = SI.BhpbioShippingNominationItemParcelId
			INNER JOIN dbo.BhpbioShippingNominationItem S 
				ON S.BhpbioShippingNominationItemId = SP.BhpbioShippingNominationItemId
			INNER JOIN dbo.BhpbioSummaryEntry bse 
				ON bse.LocationId = SP.HubLocationId AND bse.SummaryId = @summaryId 
					AND bse.SummaryEntryTypeId = @summaryEntryTypeId 
					AND (bse.ProductSize = SI.ProductSize OR bse.ProductSize = 'TOTAL')
		Where SI.ProductSize = 'LUMP' OR ((SI.tonnes is not null) AND (Undersize IS NOT NULL))
		GROUP BY bse.SummaryEntryId, bse.ProductSize
		
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

GRANT EXECUTE ON dbo.SummariseBhpbioShippingTransaction_UF_ONLY TO BhpbioGenericManager
GO
