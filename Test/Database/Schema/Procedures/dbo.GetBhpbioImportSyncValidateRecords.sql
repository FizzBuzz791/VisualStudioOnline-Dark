IF OBJECT_ID('dbo.GetBhpbioImportSyncValidateRecords') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioImportSyncValidateRecords
GO

CREATE PROCEDURE dbo.GetBhpbioImportSyncValidateRecords
(
	@iUserMessage VARCHAR(MAX),
	@iImportId SMALLINT,
	@iPage INT,
	@iPageSize INT,
	@iValidationFromDate DATETIME = Null,
	@iMonth INT,
	@iYear INT,
	@iLocationId INT,
	@iLocationName NVARCHAR(MAX),
	@iLocationType NVARCHAR(MAX),
	@iUseMonthLocation BIT
)
WITH ENCRYPTION
AS
BEGIN
	-- note: PageSize can be NULL to allow full exports

	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	
	DECLARE @Result TABLE
	(
		ImportSyncValidateId BIGINT NOT NULL,
		ImportSyncRowId BIGINT NOT NULL,
		SourceRow XML NOT NULL,
		Page INT NULL,
		PRIMARY KEY CLUSTERED (ImportSyncValidateId)
	)

	IF @iLocationName = 'Eastern Ridge'
		Set @iLocationName = 'OB23/25'

	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetImportSyncValidateRecords',
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
		DECLARE @locHierarchy TABLE (
			Location_Id INT NOT NULL,
			Location_Type_Id TINYINT NOT NULL,
			Name VARCHAR(31) NOT NULL,
			Location_Type_Description VARCHAR(255) NOT NULL,
			Order_No INT NOT NULL,
			PRIMARY KEY (Name, Location_Type_Id)
		)

		DECLARE @toDate DATETIME = GETDATE()
		INSERT INTO @locHierarchy EXEC dbo.GetBhpbioLocationParentHeirarchyWithOverride @iLocationId, @iValidationFromDate, @toDate, 'BLOCK'

		DECLARE @siteName VARCHAR(31)
		DECLARE @pitName VARCHAR(31)
		DECLARE @benchName VARCHAR(31)
		DECLARE @blastName VARCHAR(31)
		DECLARE @blockName VARCHAR(31)

		SELECT @siteName = Name FROM @locHierarchy WHERE Location_Type_Id = 3
		SELECT @pitName = Name FROM @locHierarchy WHERE Location_Type_Id = 4
		SELECT @benchName = Name FROM @locHierarchy WHERE Location_Type_Id = 5
		SELECT @blastName = Name FROM @locHierarchy WHERE Location_Type_Id = 6
		SELECT @blockName = Name FROM @locHierarchy WHERE Location_Type_Id = 7

		-- Hub -> Site is 1:1 except for NJV
		IF @iLocationType = 'HUB' AND @iLocationName <> 'NJV'
			SELECT @siteName = L.Name
			FROM Location L
			INNER JOIN LocationType LT ON LT.Location_Type_Id = L.Location_Type_Id
			WHERE L.Parent_Location_Id = @iLocationId

		IF @iLocationName = 'Eastern Ridge'
			SET @iLocationName = 'OB23/25'

		IF @siteName = 'Eastern Ridge'
			SET @siteName = 'OB23/25'

		DECLARE @overrideDate DATETIME = DATEADD(MM, (@iYear - 1900) * 12 + @iMonth - 1, 0)

		INSERT INTO @Result (ImportSyncValidateId, ImportSyncRowId, SourceRow, Page)
		SELECT ISV.ImportSyncValidateId, ISR.ImportSyncRowId, ISR.SourceRow, (ROW_NUMBER() OVER (ORDER BY ImportSyncValidateId ASC) - 1) / @iPageSize AS Page
		FROM dbo.ImportSyncValidate ISV
		INNER JOIN dbo.ImportSyncQueue ISQ ON ISQ.ImportSyncQueueId = ISV.ImportSyncQueueId
		INNER JOIN dbo.ImportSyncRow ISR ON ISR.ImportSyncRowId = ISQ.ImportSyncRowId
		INNER JOIN dbo.ImportSyncQueue ROOT_ISQ ON ROOT_ISQ.ImportSyncRowId = ISR.RootImportSyncRowId AND ROOT_ISQ.SyncAction = 'I'
		LEFT JOIN dbo.BhpbioImportSyncRowFilterData FD ON FD.ImportSyncRowId = ISR.ImportSyncRowId
		LEFT JOIN dbo.BhpbioImportReconciliationMovement RM ON RM.Site = FD.Site 
																AND FD.Pit = RM.Pit
																AND FD.Bench = RM.Bench
																AND FD.PatternNumber = RM.PatternNumber
																AND FD.BlockName = RM.BlockName
																AND @iUseMonthLocation = 1
		OUTER APPLY ISR.SourceRow.nodes('/HaulageSource') AS HSResult(HaulageSource)
		OUTER APPLY ISR.SourceRow.nodes('/ProductionSource/Transaction') AS PSResult(ProductionSource)
		OUTER APPLY ISR.SourceRow.nodes('/MetBalancingSource/MetBalancing') AS MBResult(MetBalancingSource)
		OUTER APPLY ISR.SourceRow.nodes('/ShippingSource/Nomination') AS ShSResult(ShippingSource)
		OUTER APPLY ISR.SourceRow.nodes('/StockpileAdjustmentSource') AS SASResult(StockpileAdjustmentSource)
		OUTER APPLY ISR.SourceRow.nodes('/StockpileSource/Stockpile') AS StSResult(StockpileSource)
		OUTER APPLY ISR.SourceRow.nodes('/PortBalanceSource') AS PBaResult(PortBalanceSource)
		OUTER APPLY ISR.SourceRow.nodes('/PortBlendingSource') AS PBlResult(PortBlendingSource)
		WHERE ISV.UserMessage = @iUserMessage AND ISQ.ImportId = @iImportId AND ISQ.IsPending = 1 
			AND ((@iUseMonthLocation = 0 AND ROOT_ISQ.InitialComparedDateTime > @iValidationFromDate)
				OR ((@iUseMonthLocation = 1 
					AND ((MONTH(RM.DateFrom) = @iMonth AND YEAR(RM.DateFrom) = @iYear AND @iImportId = 1)
						OR (MONTH(HSResult.HaulageSource.value('(Haulage/HaulageDate/text())[1]', 'DATE')) = @iMonth AND YEAR(HSResult.HaulageSource.value('(Haulage/HaulageDate/text())[1]', 'DATE')) = @iYear AND @iImportId = 4)
						OR (MONTH(HSResult.HaulageSource.value('(HaulageValue/HaulageDate/text())[1]', 'DATE')) = @iMonth AND YEAR(HSResult.HaulageSource.value('(HaulageValue/HaulageDate/text())[1]', 'DATE')) = @iYear AND @iImportId = 4)
						OR (MONTH(HSResult.HaulageSource.value('(HaulageNotes/HaulageDate/text())[1]', 'DATE')) = @iMonth AND YEAR(HSResult.HaulageSource.value('(HaulageNotes/HaulageDate/text())[1]', 'DATE')) = @iYear AND @iImportId = 4)
						OR (MONTH(HSResult.HaulageSource.value('(HaulageGrade/HaulageDate/text())[1]', 'DATE')) = @iMonth AND YEAR(HSResult.HaulageSource.value('(HaulageGrade/HaulageDate/text())[1]', 'DATE')) = @iYear AND @iImportId = 4)
						OR (MONTH(PSResult.ProductionSource.value('(TransactionDate/text())[1]', 'DATE')) = @iMonth AND YEAR(PSResult.ProductionSource.value('(TransactionDate/text())[1]', 'DATE')) = @iYear AND @iImportId = 5)
						OR (MONTH(MBResult.MetBalancingSource.value('(CalendarDate/text())[1]', 'DATE')) = @iMonth AND YEAR(MBResult.MetBalancingSource.value('(CalendarDate/text())[1]', 'DATE')) = @iYear AND @iImportId = 6)
						OR (MONTH(ShSResult.ShippingSource.value('(OfficialFinishTime/text())[1]', 'DATE')) = @iMonth AND YEAR(ShSResult.ShippingSource.value('(OfficialFinishTime/text())[1]', 'DATE')) = @iYear AND @iImportId = 7)
						OR (MONTH(SASResult.StockpileAdjustmentSource.value('(StockpileAdjustment/StockpileAdjustmentDate/text())[1]', 'DATE')) = @iMonth AND YEAR(SASResult.StockpileAdjustmentSource.value('(StockpileAdjustment/StockpileAdjustmentDate/text())[1]', 'DATE')) = @iYear AND @iImportId = 8)
						OR (MONTH(SASResult.StockpileAdjustmentSource.value('(StockpileAdjustmentGrade/StockpileAdjustmentDate/text())[1]', 'DATE')) = @iMonth AND YEAR(SASResult.StockpileAdjustmentSource.value('(StockpileAdjustmentGrade/StockpileAdjustmentDate/text())[1]', 'DATE')) = @iYear AND @iImportId = 8)
						OR (MONTH(StSResult.StockpileSource.value('(StartDate/text())[1]', 'DATE')) = @iMonth AND YEAR(StSResult.StockpileSource.value('(StartDate/text())[1]', 'DATE')) = @iYear AND @iImportId = 10)
						OR (MONTH(PBaResult.PortBalanceSource.value('(PortBalance/BalanceDate/text())[1]', 'DATE')) = @iMonth AND YEAR(PBaResult.PortBalanceSource.value('(PortBalance/BalanceDate/text())[1]', 'DATE')) = @iYear AND @iImportId = 11)
						OR (MONTH(PBaResult.PortBalanceSource.value('(PortBalanceGrade/BalanceDate/text())[1]', 'DATE')) = @iMonth AND YEAR(PBaResult.PortBalanceSource.value('(PortBalanceGrade/BalanceDate/text())[1]', 'DATE')) = @iYear AND @iImportId = 11)
						OR (MONTH(PBlResult.PortBlendingSource.value('(PortBlending/StartDate/text())[1]', 'DATE')) = @iMonth AND YEAR(PBlResult.PortBlendingSource.value('(PortBlending/StartDate/text())[1]', 'DATE')) = @iYear AND @iImportId = 12)
						OR (MONTH(PBlResult.PortBlendingSource.value('(PortBlendingGrade/StartDate/text())[1]', 'DATE')) = @iMonth AND YEAR(PBlResult.PortBlendingSource.value('(PortBlendingGrade/StartDate/text())[1]', 'DATE')) = @iYear AND @iImportId = 12)))
					AND ((@iLocationName = 'NJV' AND FD.Site IN ('Newman', 'OB18', 'OB23/25'))
						OR (FD.Site = @siteName
    						AND FD.Pit = COALESCE(@pitName, FD.Pit)
							AND FD.Bench = COALESCE(@benchName, FD.Bench)
							AND FD.PatternNumber = COALESCE(@blastName, FD.PatternNumber)
							AND FD.BlockName = COALESCE(@blockName, FD.BlockName))
						OR @iLocationId = 1
						OR (SELECT dbo.GetParentLocationByLocationType((SELECT Location_ID FROM DigblockLocation DL
      							WHERE DL.Digblock_Id = HSResult.HaulageSource.value('(Haulage/Source/text())[1]', 'nvarchar(max)')),@iLocationType,@overrideDate)) = @iLocationId
						OR (SELECT dbo.GetParentLocationByLocationType((SELECT Location_ID FROM DigblockLocation DL
      							WHERE DL.Digblock_Id = HSResult.HaulageSource.value('(HaulageValue/Source/text())[1]', 'nvarchar(max)')),@iLocationType,@overrideDate)) = @iLocationId
						OR (SELECT dbo.GetParentLocationByLocationType((SELECT Location_ID FROM DigblockLocation DL
      							WHERE DL.Digblock_Id = HSResult.HaulageSource.value('(HaulageNotes/Source/text())[1]', 'nvarchar(max)')),@iLocationType,@overrideDate)) = @iLocationId
						OR (SELECT dbo.GetParentLocationByLocationType((SELECT Location_ID FROM DigblockLocation DL
      							WHERE DL.Digblock_Id = HSResult.HaulageSource.value('(HaulageGrade/Source/text())[1]', 'nvarchar(max)')),@iLocationType,@overrideDate)) = @iLocationId
						OR dbo.GetParentLocationByLocationType(dbo.ConvertMQ2ToLocationId(PSResult.ProductionSource.value('(SourceMineSite/text())[1]', 'nvarchar(max)')), @iLocationType, @overrideDate) = @iLocationId
						OR dbo.GetParentLocationByLocationType(dbo.ConvertMQ2ToLocationId(SASResult.StockpileAdjustmentSource.value('(StockpileAdjustment/Mine/text())[1]', 'nvarchar(max)')), @iLocationType, @overrideDate) = @iLocationId
						OR dbo.GetParentLocationByLocationType(dbo.ConvertMQ2ToLocationId(SASResult.StockpileAdjustmentSource.value('(StockpileAdjustmentGrade/Mine/text())[1]', 'nvarchar(max)')), @iLocationType, @overrideDate) = @iLocationId
						OR dbo.GetParentLocationByLocationType(dbo.ConvertMQ2ToLocationId(StSResult.StockpileSource.value('(Mine/text())[1]', 'nvarchar(max)')), @iLocationType, @overrideDate) = @iLocationId
						OR dbo.ConvertMESToLocationId(PBaResult.PortBalanceSource.value('(PortBalance/Hub/text())[1]','VARCHAR(3)')) = @iLocationId
						OR dbo.ConvertMESToLocationId(PBaResult.PortBalanceSource.value('(PortBalanceGrade/Hub/text())[1]','VARCHAR(3)')) = @iLocationId
						OR dbo.ConvertMESToLocationId(PBlResult.PortBlendingSource.value('(PortBlending/RakeHub/text())[1]','VARCHAR(3)')) = @iLocationId
						OR dbo.ConvertMESToLocationId(PBlResult.PortBlendingSource.value('(PortBlending/SourceHub/text())[1]','VARCHAR(3)')) = @iLocationId
						OR dbo.ConvertMESToLocationId(PBlResult.PortBlendingSource.value('(PortBlendingGrade/RakeHub/text())[1]','VARCHAR(3)')) = @iLocationId
						OR dbo.ConvertMESToLocationId(PBlResult.PortBlendingSource.value('(PortBlendingGrade/SourceHub/text())[1]','VARCHAR(3)')) = @iLocationId)))
		UNION ALL
		SELECT ILRM.ImportLoadRowMessagesId, ILR.ImportLoadRowId, ILR.ImportRow, (ROW_NUMBER() OVER (ORDER BY ImportLoadRowMessagesId ASC) - 1) / @iPageSize AS Page
		FROM dbo.ImportLoadRow ILR
		INNER JOIN dbo.ImportLoadRowMessages ILRM ON ILRM.ImportLoadRowId = ILR.ImportLoadRowId
		WHERE ILRM.ValidationMessage = @iUserMessage AND ILR.ImportId = @iImportId

		-- return the results for the requested page number
		SELECT ImportSyncValidateId, ImportSyncRowId, SourceRow, Page
		FROM @Result
		WHERE (@iPageSize IS NULL) OR (Page = @iPage)

		-- return the results for the number of pages that are in the database
		SELECT MAX(Page) AS LastPage
		FROM @Result
		
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

GRANT EXECUTE ON dbo.GetBhpbioImportSyncValidateRecords TO CommonImportManager
GO