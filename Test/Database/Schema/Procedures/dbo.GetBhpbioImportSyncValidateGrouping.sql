IF Object_Id('dbo.GetBhpbioImportSyncValidateGrouping') Is Not Null 
     DROP PROCEDURE dbo.GetBhpbioImportSyncValidateGrouping
GO
  
CREATE PROCEDURE dbo.GetBhpbioImportSyncValidateGrouping
(
	@iImportId SMALLINT,
	@iMonth INT,
	@iYear INT,
	@iLocationId INT,
	@iLocationName NVARCHAR(MAX),
	@iLocationType NVARCHAR(MAX),
	@iUseMonthLocation BIT = 0,
	@iValidationFromDate DATETIME = NULL
)
WITH ENCRYPTION
AS
BEGIN

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

	IF @iUseMonthLocation = 1
	  SELECT ISV.UserMessage, Count(1) AS Occurrence
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
		WHERE ISQ.ImportId = @iImportId AND ISQ.IsPending = 1 
			AND MONTH(RM.DateFrom) = @iMonth AND YEAR(RM.DateFrom) = @iYear
			AND ((@iLocationName = 'NJV' AND FD.Site IN ('Newman', 'OB18', 'OB23/25'))
				OR (FD.Site = @siteName
		 			AND FD.Pit = COALESCE(@pitName, FD.Pit)
					AND FD.Bench = COALESCE(@benchName, FD.Bench)
					AND FD.PatternNumber = COALESCE(@blastName, FD.PatternNumber)
					AND FD.BlockName = COALESCE(@blockName, FD.BlockName))
				OR @iLocationId = 1)
			AND FD.ImportSyncRowId IS NOT NULL
		GROUP BY ISV.UserMessage
	  UNION ALL
	  SELECT ISV.UserMessage, Count(1) AS Occurrence
	  FROM dbo.ImportSyncValidate ISV
	  INNER JOIN dbo.ImportSyncQueue ISQ ON ISQ.ImportSyncQueueId = ISV.ImportSyncQueueId
	  INNER JOIN dbo.ImportSyncRow ISR ON ISR.ImportSyncRowId = ISQ.ImportSyncRowId
	  INNER JOIN dbo.ImportSyncQueue ROOT_ISQ ON ROOT_ISQ.ImportSyncRowId = ISR.RootImportSyncRowId AND ROOT_ISQ.SyncAction = 'I'
	  OUTER APPLY ISR.SourceRow.nodes('/HaulageSource') AS HSResult(HaulageSource)
	  WHERE ISQ.ImportId = @iImportId AND ISQ.IsPending = 1 
		AND ((MONTH(HSResult.HaulageSource.value('(Haulage/HaulageDate/text())[1]', 'DATE')) = @iMonth AND YEAR(HSResult.HaulageSource.value('(Haulage/HaulageDate/text())[1]', 'DATE')) = @iYear)
			OR (MONTH(HSResult.HaulageSource.value('(HaulageValue/HaulageDate/text())[1]', 'DATE')) = @iMonth AND YEAR(HSResult.HaulageSource.value('(HaulageValue/HaulageDate/text())[1]', 'DATE')) = @iYear)
			OR (MONTH(HSResult.HaulageSource.value('(HaulageNotes/HaulageDate/text())[1]', 'DATE')) = @iMonth AND YEAR(HSResult.HaulageSource.value('(HaulageNotes/HaulageDate/text())[1]', 'DATE')) = @iYear)
			OR (MONTH(HSResult.HaulageSource.value('(HaulageGrade/HaulageDate/text())[1]', 'DATE')) = @iMonth AND YEAR(HSResult.HaulageSource.value('(HaulageGrade/HaulageDate/text())[1]', 'DATE')) = @iYear))
  		AND ((SELECT dbo.GetParentLocationByLocationType((SELECT Location_ID FROM DigblockLocation DL
        		WHERE DL.Digblock_Id = HSResult.HaulageSource.value('(Haulage/Source/text())[1]', 'NVARCHAR(MAX)')),@iLocationType,@overrideDate)) = @iLocationId
  			OR (SELECT dbo.GetParentLocationByLocationType((SELECT Location_ID FROM DigblockLocation DL
       			WHERE DL.Digblock_Id = HSResult.HaulageSource.value('(HaulageValue/Source/text())[1]', 'NVARCHAR(MAX)')),@iLocationType,@overrideDate)) = @iLocationId
  			OR (SELECT dbo.GetParentLocationByLocationType((SELECT Location_ID FROM DigblockLocation DL
        		WHERE DL.Digblock_Id = HSResult.HaulageSource.value('(HaulageNotes/Source/text())[1]', 'NVARCHAR(MAX)')),@iLocationType,@overrideDate)) = @iLocationId
  			OR (SELECT dbo.GetParentLocationByLocationType((SELECT Location_ID FROM DigblockLocation DL
        		WHERE DL.Digblock_Id = HSResult.HaulageSource.value('(HaulageGrade/Source/text())[1]', 'NVARCHAR(MAX)')),@iLocationType,@overrideDate)) = @iLocationId)
  		AND HSResult.HaulageSource.value('(Haulage/Source/text())[1]', 'NVARCHAR(MAX)') IS NOT NULL
	  GROUP BY ISV.UserMessage
	  UNION ALL
	  SELECT ISV.UserMessage, Count(1) AS Occurrence
	  FROM dbo.ImportSyncValidate ISV
	  INNER JOIN dbo.ImportSyncQueue ISQ ON ISQ.ImportSyncQueueId = ISV.ImportSyncQueueId
	  INNER JOIN dbo.ImportSyncRow ISR ON ISR.ImportSyncRowId = ISQ.ImportSyncRowId
	  INNER JOIN dbo.ImportSyncQueue ROOT_ISQ ON ROOT_ISQ.ImportSyncRowId = ISR.RootImportSyncRowId AND ROOT_ISQ.SyncAction = 'I'
	  OUTER APPLY ISR.SourceRow.nodes('/ProductionSource/Transaction') AS PSResult(ProductionSource)
	  WHERE ISQ.ImportId = @iImportId AND ISQ.IsPending = 1 
		AND MONTH(PSResult.ProductionSource.value('(TransactionDate/text())[1]', 'DATE')) = @iMonth AND YEAR(PSResult.ProductionSource.value('(TransactionDate/text())[1]', 'DATE')) = @iYear
  		AND ((dbo.GetParentLocationByLocationType(dbo.ConvertMQ2ToLocationId(PSResult.ProductionSource.value('(SourceMineSite/text())[1]', 'NVARCHAR(MAX)')), @iLocationType, @overrideDate) = @iLocationId)
      		OR (ISR.ImportId = 6 AND dbo.GetParentLocationByLocationType(dbo.ConvertMQ2ToLocationId('WB'), @iLocationType, @overrideDate) = @iLocationId))
  		AND PSResult.ProductionSource.value('(SourceMineSite/text())[1]', 'NVARCHAR(MAX)') IS NOT NULL
	  GROUP BY ISV.UserMessage
	  UNION ALL
	  SELECT ISV.UserMessage, Count(1) AS Occurrence
	  FROM dbo.ImportSyncValidate ISV
	  INNER JOIN dbo.ImportSyncQueue ISQ ON ISQ.ImportSyncQueueId = ISV.ImportSyncQueueId
	  INNER JOIN dbo.ImportSyncRow ISR ON ISR.ImportSyncRowId = ISQ.ImportSyncRowId
	  INNER JOIN dbo.ImportSyncQueue ROOT_ISQ ON ROOT_ISQ.ImportSyncRowId = ISR.RootImportSyncRowId AND ROOT_ISQ.SyncAction = 'I'
	  OUTER APPLY ISR.SourceRow.nodes('/StockpileAdjustmentSource') AS SASResult(StockpileAdjustmentSource)
	  WHERE ISQ.ImportId = @iImportId AND ISQ.IsPending = 1 
		AND ((MONTH(SASResult.StockpileAdjustmentSource.value('(StockpileAdjustment/StockpileAdjustmentDate/text())[1]', 'DATE')) = @iMonth AND YEAR(SASResult.StockpileAdjustmentSource.value('(StockpileAdjustment/StockpileAdjustmentDate/text())[1]', 'DATE')) = @iYear) 
			OR (MONTH(SASResult.StockpileAdjustmentSource.value('(StockpileAdjustmentGrade/StockpileAdjustmentDate/text())[1]', 'DATE')) = @iMonth AND YEAR(SASResult.StockpileAdjustmentSource.value('(StockpileAdjustmentGrade/StockpileAdjustmentDate/text())[1]', 'DATE')) = @iYear))
  		AND ((dbo.GetParentLocationByLocationType(dbo.ConvertMQ2ToLocationId(SASResult.StockpileAdjustmentSource.value('(StockpileAdjustment/Mine/text())[1]', 'NVARCHAR(MAX)')), @iLocationType, @overrideDate) = @iLocationId
  			OR dbo.GetParentLocationByLocationType(dbo.ConvertMQ2ToLocationId(SASResult.StockpileAdjustmentSource.value('(StockpileAdjustmentGrade/Mine/text())[1]', 'NVARCHAR(MAX)')), @iLocationType, @overrideDate) = @iLocationId))
  		AND SASResult.StockpileAdjustmentSource.value('(*/Mine/text())[1]', 'NVARCHAR(MAX)') IS NOT NULL
	  GROUP BY ISV.UserMessage
	  UNION ALL
	  SELECT ISV.UserMessage, Count(1) AS Occurrence
	  FROM dbo.ImportSyncValidate ISV
	  INNER JOIN dbo.ImportSyncQueue ISQ ON ISQ.ImportSyncQueueId = ISV.ImportSyncQueueId
	  INNER JOIN dbo.ImportSyncRow ISR ON ISR.ImportSyncRowId = ISQ.ImportSyncRowId
	  INNER JOIN dbo.ImportSyncQueue ROOT_ISQ ON ROOT_ISQ.ImportSyncRowId = ISR.RootImportSyncRowId AND ROOT_ISQ.SyncAction = 'I'
	  OUTER APPLY ISR.SourceRow.nodes('/StockpileSource/Stockpile') AS SSResult(StockpileSource)
	  WHERE ISQ.ImportId = @iImportId AND ISQ.IsPending = 1 
		AND MONTH(SSResult.StockpileSource.value('(StartDate/text())[1]', 'DATE')) = @iMonth AND YEAR(SSResult.StockpileSource.value('(StartDate/text())[1]', 'DATE')) = @iYear
  		AND ((dbo.GetParentLocationByLocationType(dbo.ConvertMQ2ToLocationId(SSResult.StockpileSource.value('(Mine/text())[1]', 'NVARCHAR(MAX)')), @iLocationType, @overrideDate) = @iLocationId))
		AND SSResult.StockpileSource.value('(Mine/text())[1]', 'NVARCHAR(MAX)') IS NOT NULL
	  GROUP BY ISV.UserMessage
	  UNION ALL
	  SELECT ISV.UserMessage, Count(1) AS Occurrence
	  FROM dbo.ImportSyncValidate ISV
	  INNER JOIN dbo.ImportSyncQueue ISQ ON ISQ.ImportSyncQueueId = ISV.ImportSyncQueueId
	  INNER JOIN dbo.ImportSyncRow ISR ON ISR.ImportSyncRowId = ISQ.ImportSyncRowId
	  INNER JOIN dbo.ImportSyncQueue ROOT_ISQ ON ROOT_ISQ.ImportSyncRowId = ISR.RootImportSyncRowId AND ROOT_ISQ.SyncAction = 'I'
	  OUTER APPLY ISR.SourceRow.nodes('/MetBalancingSource/MetBalancing') AS MBResult(MetBalancingSource)
	  WHERE ISQ.ImportId = @iImportId AND ISQ.IsPending = 1 AND @iLocationId = 1
		AND MONTH(MBResult.MetBalancingSource.value('(CalendarDate/text())[1]', 'DATE')) = @iMonth AND YEAR(MBResult.MetBalancingSource.value('(CalendarDate/text())[1]', 'DATE')) = @iYear
		AND MBResult.MetBalancingSource.value('(CalendarDate/text())[1]', 'NVARCHAR(MAX)') IS NOT NULL
	  GROUP BY ISV.UserMessage
	  UNION ALL
	  SELECT ISV.UserMessage, Count(1) AS Occurrence
	  FROM dbo.ImportSyncValidate ISV
	  INNER JOIN dbo.ImportSyncQueue ISQ ON ISQ.ImportSyncQueueId = ISV.ImportSyncQueueId
	  INNER JOIN dbo.ImportSyncRow ISR ON ISR.ImportSyncRowId = ISQ.ImportSyncRowId
	  INNER JOIN dbo.ImportSyncQueue ROOT_ISQ ON ROOT_ISQ.ImportSyncRowId = ISR.RootImportSyncRowId AND ROOT_ISQ.SyncAction = 'I'
	  OUTER APPLY ISR.SourceRow.nodes('/ShippingSource/Nomination') AS SSResult(ShippingSource)
	  WHERE ISQ.ImportId = @iImportId AND ISQ.IsPending = 1  AND @iLocationId = 1
		AND MONTH(SSResult.ShippingSource.value('(OfficialFinishTime/text())[1]', 'DATE')) = @iMonth AND YEAR(SSResult.ShippingSource.value('(OfficialFinishTime/text())[1]', 'DATE')) = @iYear
		AND SSResult.ShippingSource.value('(OfficialFinishTime/text())[1]', 'NVARCHAR(MAX)') IS NOT NULL
	  GROUP BY ISV.UserMessage
	  UNION ALL
	  SELECT ISV.UserMessage, Count(1) AS Occurrence
	  FROM dbo.ImportSyncValidate ISV
	  INNER JOIN dbo.ImportSyncQueue ISQ ON ISQ.ImportSyncQueueId = ISV.ImportSyncQueueId
	  INNER JOIN dbo.ImportSyncRow ISR ON ISR.ImportSyncRowId = ISQ.ImportSyncRowId
	  INNER JOIN dbo.ImportSyncQueue ROOT_ISQ ON ROOT_ISQ.ImportSyncRowId = ISR.RootImportSyncRowId AND ROOT_ISQ.SyncAction = 'I'
	  OUTER APPLY ISR.SourceRow.nodes('/PortBalanceSource') AS PBResult(PortBalanceSource)
	  WHERE ISQ.ImportId = @iImportId 
		AND ISQ.IsPending = 1 
		AND (@iLocationId = 1 
			OR (@iLocationId <> 1 
				AND ((dbo.ConvertMESToLocationId(PBResult.PortBalanceSource.value('(PortBalanceGrade/Hub/text())[1]', 'VARCHAR(3)')) = @iLocationId) 
					OR (dbo.ConvertMESToLocationId(PBResult.PortBalanceSource.value('(PortBalance/Hub/text())[1]', 'VARCHAR(3)')) = @iLocationId)))) 
		AND ((MONTH(PBResult.PortBalanceSource.value('(PortBalance/BalanceDate/text())[1]', 'DATE')) = @iMonth AND YEAR(PBResult.PortBalanceSource.value('(PortBalance/BalanceDate/text())[1]', 'DATE')) = @iYear) 
			OR (MONTH(PBResult.PortBalanceSource.value('(PortBalanceGrade/BalanceDate/text())[1]', 'DATE')) = @iMonth AND YEAR(PBResult.PortBalanceSource.value('(PortBalanceGrade/BalanceDate/text())[1]', 'DATE')) = @iYear))
		AND PBResult.PortBalanceSource.value('(*/BalanceDate/text())[1]', 'NVARCHAR(MAX)') IS NOT NULL
	  GROUP BY ISV.UserMessage
	  UNION ALL
	  SELECT ISV.UserMessage, Count(1) AS Occurrence
	  FROM dbo.ImportSyncValidate ISV
	  INNER JOIN dbo.ImportSyncQueue ISQ ON ISQ.ImportSyncQueueId = ISV.ImportSyncQueueId
	  INNER JOIN dbo.ImportSyncRow ISR ON ISR.ImportSyncRowId = ISQ.ImportSyncRowId
	  INNER JOIN dbo.ImportSyncQueue ROOT_ISQ ON ROOT_ISQ.ImportSyncRowId = ISR.RootImportSyncRowId AND ROOT_ISQ.SyncAction = 'I'
	  OUTER APPLY ISR.SourceRow.nodes('/PortBlendingSource') AS PBResult(PortBlendingSource)
	  WHERE ISQ.ImportId = @iImportId 
		AND ISQ.IsPending = 1 
		AND (@iLocationId = 1
			OR (@iLocationId <> 1
				AND (dbo.ConvertMESToLocationId(PBResult.PortBlendingSource.value('(PortBlending/RakeHub/text())[1]', 'VARCHAR(3)')) = @iLocationId) 
					OR (dbo.ConvertMESToLocationId(PBResult.PortBlendingSource.value('(PortBlending/Source/text())[1]', 'VARCHAR(3)')) = @iLocationId) 
					OR (dbo.ConvertMESToLocationId(PBResult.PortBlendingSource.value('(PortBlendingGrade/RakeHub/text())[1]', 'VARCHAR(3)')) = @iLocationId) 
					OR (dbo.ConvertMESToLocationId(PBResult.PortBlendingSource.value('(PortBlendingGrade/SourceHub/text())[1]', 'VARCHAR(3)')) = @iLocationId)))
		AND ((MONTH(PBResult.PortBlendingSource.value('(PortBlending/BalanceDate/text())[1]', 'DATE')) = @iMonth AND YEAR(PBResult.PortBlendingSource.value('(PortBlending/BalanceDate/text())[1]', 'DATE')) = @iYear)
			OR (MONTH(PBResult.PortBlendingSource.value('(PortBlendingGrade/BalanceDate/text())[1]', 'DATE')) = @iMonth AND YEAR(PBResult.PortBlendingSource.value('(PortBlendingGrade/BalanceDate/text())[1]', 'DATE')) = @iYear))
		AND PBResult.PortBlendingSource.value('(PortBlending/BalaceDate/text())[1]', 'NVARCHAR(MAX)') IS NOT NULL
	  GROUP BY ISV.UserMessage
	  UNION ALL
	  -- Import 9 & 13
	  SELECT ILRM.ValidationMessage AS UserMessage, COUNT(1) AS Occurrence
	  FROM dbo.ImportLoadRowMessages ILRM
	  INNER JOIN dbo.ImportLoadRow ILR ON ILR.ImportLoadRowId = ILRM.ImportLoadRowId
	  WHERE ILR.ImportId = @iImportId
	  GROUP BY ILRM.ValidationMessage
	ELSE
	  SELECT ISV.UserMessage, Count(1) AS Occurrence
	  FROM dbo.ImportSyncValidate ISV
	  INNER JOIN dbo.ImportSyncQueue ISQ ON ISQ.ImportSyncQueueId = ISV.ImportSyncQueueId
	  INNER JOIN dbo.ImportSyncRow ISR ON ISR.ImportSyncRowId = ISQ.ImportSyncRowId
	  INNER JOIN dbo.ImportSyncQueue ROOT_ISQ ON ROOT_ISQ.ImportSyncRowId = ISR.RootImportSyncRowId AND ROOT_ISQ.SyncAction = 'I'
	  WHERE ISQ.ImportId = @iImportId AND ISQ.IsPending = 1 AND ROOT_ISQ.InitialComparedDateTime > @iValidationFromDate
	  GROUP BY ISV.UserMessage
	  UNION ALL
	  SELECT ILRM.ValidationMessage AS UserMessage, COUNT(1) AS Occurrence
	  FROM dbo.ImportLoadRowMessages ILRM
	  INNER JOIN dbo.ImportLoadRow ILR ON ILR.ImportLoadRowId = ILRM.ImportLoadRowId
	  WHERE ILR.ImportId = @iImportId
	  GROUP BY ILRM.ValidationMessage
END
GO	

GRANT EXECUTE ON dbo.GetBhpbioImportSyncValidateGrouping TO CommonImportManager
GO