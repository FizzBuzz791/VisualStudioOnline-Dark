IF Object_Id('dbo.GetBhpbioImportList') IS NOT NULL
	DROP PROCEDURE dbo.GetBhpbioImportList
GO

CREATE PROCEDURE dbo.GetBhpbioImportList
(
	@iValidationFromDate DATETIME,
	@iMonth INT,
	@iYear INT,
	@iLocationId INT,
	@iUseMonthLocation BIT = 0,
	@iActive BIT = 1
)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @iLocationName VARCHAR(50)
	DECLARE @iLocationType VARCHAR(50)

	SELECT @iLocationName = L.Name, @iLocationType = LT.Description 
	FROM LocationType LT 
	INNER JOIN Location L ON L.Location_Type_Id = LT.Location_Type_Id 
	WHERE L.Location_Id = @iLocationId

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

	SELECT I.ImportID, I.ImportName, I.ImportGroupID, I.ImportTypeId, I.Description, I.IsActive, I.DefaultKillTimeoutMinutes,
	  IG.Description AS ImportGroupDescription, IT.Description AS ImportTypeDescription, IT.ImportTypeName, 
	  COALESCE(Counts.ValidateCount, 0) AS ValidateCount, 
	  COALESCE(Counts.ConflictCount, 0) AS ConflictCount, 
	  COALESCE(Counts.CriticalErrorCount, 0) AS CriticalErrorCount
	FROM Import I
	INNER JOIN dbo.ImportType IT ON I.ImportTypeID = IT.ImportTypeID
	INNER JOIN dbo.ImportGroup IG ON IG.ImportGroupID = I.ImportGroupID
	-- Above is *all* the imports.
	-- Below is imports that have counts.
	LEFT JOIN (
		SELECT I.ImportID, I.ImportName, I.ImportGroupID, I.ImportTypeID, I.Description, I.IsActive, I.DefaultKillTimeoutMinutes,
			NULL AS ImportGroupDescription, NULL AS ImportTypeDescription, NULL AS ImportTypeName, 
			COUNT(ISV.ImportSyncValidateId) AS ValidateCount,
			COUNT(ISC.ImportSyncConflictId) AS ConflictCount, 
			COUNT(ISE.ImportSyncExceptionId) AS CriticalErrorCount
		FROM dbo.Import I
		LEFT JOIN dbo.ImportSyncQueue ISQ ON ISQ.ImportId = I.ImportId AND ISQ.IsPending = 1
		LEFT JOIN dbo.ImportSyncRow ISR ON ISR.ImportSyncRowId = ISQ.ImportSyncRowId
		-- we have to get the root row for this import item - the very first time it was imported
		-- this date is required so that we can filter the validation count by date for the imports page
		LEFT JOIN dbo.ImportSyncQueue ROOT_ISQ ON ROOT_ISQ.ImportSyncRowId = ISR.RootImportSyncRowId AND ROOT_ISQ.SyncAction = 'I'
		LEFT JOIN dbo.ImportSyncValidate ISV ON ISV.ImportSyncQueueId = ISQ.ImportSyncQueueId
		LEFT JOIN dbo.ImportSyncConflict ISC ON ISC.ImportSyncQueueId = ISQ.ImportSyncQueueId
		LEFT JOIN dbo.ImportSyncException ISE ON ISE.ImportSyncQueueId = ISQ.ImportSyncQueueId
		LEFT JOIN dbo.BhpbioImportSyncRowFilterData FD ON FD.ImportSyncRowId = ISR.ImportSyncRowId
		LEFT JOIN dbo.BhpbioImportReconciliationMovement RM ON RM.Site = FD.Site
															AND FD.Pit = RM.Pit
															AND FD.Bench = RM.Bench
															AND FD.PatternNumber = RM.PatternNumber
															AND FD.BlockName = RM.BlockName
															AND @iUseMonthLocation = 1
		WHERE I.IsActive = @iActive AND I.ImportId = 1 AND ((@iUseMonthLocation = 0 AND ROOT_ISQ.InitialComparedDateTime > @iValidationFromDate)
			OR (@iUseMonthLocation = 1 AND MONTH(RM.DateFrom) = @iMonth AND YEAR(RM.DateFrom) = @iYear AND (@iLocationId = 1 OR (@iLocationId <> 1
				AND ((@iLocationName = 'NJV' AND FD.Site IN ('Newman', 'OB18', 'OB23/25')) 
					OR (FD.Site = @siteName
   						AND FD.Pit = COALESCE(@pitName, FD.Pit)
						AND FD.Bench = COALESCE(@benchName, FD.Bench)
						AND FD.PatternNumber = COALESCE(@blastName, FD.PatternNumber)
						AND FD.BlockName = COALESCE(@blockName, FD.BlockName)
						)
					)
				))))
		GROUP BY I.ImportId, I.ImportName, I.Description, I.ImportGroupID, I.ImportTypeId, I.IsActive, I.DefaultKillTimeoutMinutes
		UNION ALL
		SELECT I.ImportID, I.ImportName, I.ImportGroupID, I.ImportTypeID, I.Description, I.IsActive, I.DefaultKillTimeoutMinutes,
			NULL AS ImportGroupDescription, NULL AS ImportTypeDescription, NULL AS ImportTypeName, 
			COUNT(ISV.ImportSyncValidateId) AS ValidateCount,
			COUNT(ISC.ImportSyncConflictId) AS ConflictCount, 
			COUNT(ISE.ImportSyncExceptionId) AS CriticalErrorCount
		FROM dbo.Import I
		LEFT JOIN dbo.ImportSyncQueue ISQ ON ISQ.ImportId = I.ImportId AND ISQ.IsPending = 1
		LEFT JOIN dbo.ImportSyncRow ISR ON ISR.ImportSyncRowId = ISQ.ImportSyncRowId
		-- we have to get the root row for this import item - the very first time it was imported
		-- this date is required so that we can filter the validation count by date for the imports page
		LEFT JOIN dbo.ImportSyncQueue ROOT_ISQ ON ROOT_ISQ.ImportSyncRowId = ISR.RootImportSyncRowId AND ROOT_ISQ.SyncAction = 'I'
		LEFT JOIN dbo.ImportSyncValidate ISV ON ISV.ImportSyncQueueId = ISQ.ImportSyncQueueId
		LEFT JOIN dbo.ImportSyncConflict ISC ON ISC.ImportSyncQueueId = ISQ.ImportSyncQueueId
		LEFT JOIN dbo.ImportSyncException ISE ON ISE.ImportSyncQueueId = ISQ.ImportSyncQueueId
		OUTER APPLY ISR.SourceRow.nodes('/HaulageSource') AS HSResult(HaulageSource)
		WHERE I.IsActive = @iActive AND I.ImportId = 4 AND ((@iUseMonthLocation = 0 AND ROOT_ISQ.InitialComparedDateTime > @iValidationFromDate)
			OR (@iUseMonthLocation = 1 
				AND ((MONTH(HSResult.HaulageSource.value('(Haulage/HaulageDate/text())[1]', 'DATE')) = @iMonth AND YEAR(HSResult.HaulageSource.value('(Haulage/HaulageDate/text())[1]', 'DATE')) = @iYear)
					OR (MONTH(HSResult.HaulageSource.value('(HaulageValue/HaulageDate/text())[1]', 'DATE')) = @iMonth AND YEAR(HSResult.HaulageSource.value('(HaulageValue/HaulageDate/text())[1]', 'DATE')) = @iYear)
					OR (MONTH(HSResult.HaulageSource.value('(HaulageNotes/HaulageDate/text())[1]', 'DATE')) = @iMonth AND YEAR(HSResult.HaulageSource.value('(HaulageNotes/HaulageDate/text())[1]', 'DATE')) = @iYear)
					OR (MONTH(HSResult.HaulageSource.value('(HaulageGrade/HaulageDate/text())[1]', 'DATE')) = @iMonth AND YEAR(HSResult.HaulageSource.value('(HaulageGrade/HaulageDate/text())[1]', 'DATE')) = @iYear))
				AND (@iLocationId = 1
					OR (@iLocationId <> 1
						AND ((SELECT dbo.GetParentLocationByLocationType((SELECT Location_ID FROM DigblockLocation DL
      							WHERE DL.Digblock_Id = HSResult.HaulageSource.value('(Haulage/Source/text())[1]', 'NVARCHAR(MAX)')),@iLocationType,@overrideDate)) = @iLocationId
							OR (SELECT dbo.GetParentLocationByLocationType((SELECT Location_ID FROM DigblockLocation DL
      							WHERE DL.Digblock_Id = HSResult.HaulageSource.value('(HaulageValue/Source/text())[1]', 'NVARCHAR(MAX)')),@iLocationType,@overrideDate)) = @iLocationId
							OR (SELECT dbo.GetParentLocationByLocationType((SELECT Location_ID FROM DigblockLocation DL
      							WHERE DL.Digblock_Id = HSResult.HaulageSource.value('(HaulageNotes/Source/text())[1]', 'NVARCHAR(MAX)')),@iLocationType,@overrideDate)) = @iLocationId
							OR (SELECT dbo.GetParentLocationByLocationType((SELECT Location_ID FROM DigblockLocation DL
      							WHERE DL.Digblock_Id = HSResult.HaulageSource.value('(HaulageGrade/Source/text())[1]', 'NVARCHAR(MAX)')),@iLocationType,@overrideDate)) = @iLocationId)))))
		GROUP BY I.ImportId, I.ImportName, I.Description, I.ImportGroupID, I.ImportTypeId, I.IsActive, I.DefaultKillTimeoutMinutes
		UNION ALL
		SELECT I.ImportID, I.ImportName, I.ImportGroupID, I.ImportTypeID, I.Description, I.IsActive, I.DefaultKillTimeoutMinutes,
			NULL AS ImportGroupDescription, NULL AS ImportTypeDescription, NULL AS ImportTypeName, 
			COUNT(ISV.ImportSyncValidateId) AS ValidateCount,
			COUNT(ISC.ImportSyncConflictId) AS ConflictCount, 
			COUNT(ISE.ImportSyncExceptionId) AS CriticalErrorCount
		FROM dbo.Import I
		LEFT JOIN dbo.ImportSyncQueue ISQ ON ISQ.ImportId = I.ImportId AND ISQ.IsPending = 1
		LEFT JOIN dbo.ImportSyncRow ISR ON ISR.ImportSyncRowId = ISQ.ImportSyncRowId
		-- we have to get the root row for this import item - the very first time it was imported
		-- this date is required so that we can filter the validation count by date for the imports page
		LEFT JOIN dbo.ImportSyncQueue ROOT_ISQ ON ROOT_ISQ.ImportSyncRowId = ISR.RootImportSyncRowId AND ROOT_ISQ.SyncAction = 'I'
		LEFT JOIN dbo.ImportSyncValidate ISV ON ISV.ImportSyncQueueId = ISQ.ImportSyncQueueId
		LEFT JOIN dbo.ImportSyncConflict ISC ON ISC.ImportSyncQueueId = ISQ.ImportSyncQueueId
		LEFT JOIN dbo.ImportSyncException ISE ON ISE.ImportSyncQueueId = ISQ.ImportSyncQueueId
		OUTER APPLY ISR.SourceRow.nodes('/ProductionSource/Transaction') AS PSResult(ProductionSource)
		WHERE I.IsActive = @iActive AND I.ImportId = 5 
			AND (
					(@iUseMonthLocation = 0 AND ROOT_ISQ.InitialComparedDateTime > @iValidationFromDate)
					OR (@iUseMonthLocation = 1 
					AND MONTH(PSResult.ProductionSource.value('(TransactionDate/text())[1]', 'DATE')) = @iMonth 
					AND YEAR(PSResult.ProductionSource.value('(TransactionDate/text())[1]', 'DATE')) = @iYear
					AND (@iLocationId = 1 
						OR (@iLocationId <> 1 
							AND (dbo.GetParentLocationByLocationType(dbo.ConvertMQ2ToLocationId(PSResult.ProductionSource.value('(SourceMineSite/text())[1]', 'NVARCHAR(MAX)')), @iLocationType, @overrideDate) = @iLocationId)
							)
						)
					)
				)
		GROUP BY I.ImportId, I.ImportName, I.Description, I.ImportGroupID, I.ImportTypeId, I.IsActive, I.DefaultKillTimeoutMinutes
		UNION ALL
		SELECT I.ImportID, I.ImportName, I.ImportGroupID, I.ImportTypeID, I.Description, I.IsActive, I.DefaultKillTimeoutMinutes,
			NULL AS ImportGroupDescription, NULL AS ImportTypeDescription, NULL AS ImportTypeName, 
			COUNT(ILRM.ImportLoadRowId) AS ValidateCount,
			COUNT(ISC.ImportSyncConflictId) AS ConflictCount, 
			COUNT(ISE.ImportSyncExceptionId) AS CriticalErrorCount
		FROM dbo.Import I
		LEFT JOIN dbo.ImportSyncQueue ISQ ON ISQ.ImportId = I.ImportId AND ISQ.IsPending = 1
		LEFT JOIN dbo.ImportSyncRow ISR ON ISR.ImportSyncRowId = ISQ.ImportSyncRowId
		-- we have to get the root row for this import item - the very first time it was imported
		-- this date is required so that we can filter the validation count by date for the imports page
		LEFT JOIN dbo.ImportSyncQueue ROOT_ISQ ON ROOT_ISQ.ImportSyncRowId = ISR.RootImportSyncRowId AND ROOT_ISQ.SyncAction = 'I'
		LEFT JOIN dbo.ImportSyncConflict ISC ON ISC.ImportSyncQueueId = ISQ.ImportSyncQueueId 
		LEFT JOIN dbo.ImportSyncException ISE ON ISE.ImportSyncQueueId = ISQ.ImportSyncQueueId 
		LEFT JOIN dbo.ImportLoadRow ILR ON ILR.ImportId = I.ImportId
		LEFT JOIN dbo.ImportLoadRowMessages ILRM ON ILRM.ImportLoadRowId = ILR.ImportLoadRowId
		WHERE I.IsActive = @iActive AND I.ImportId IN (9, 13)
		AND ((@iUseMonthLocation = 0 AND ROOT_ISQ.InitialComparedDateTime > @iValidationFromDate) 
		  OR (@iUseMonthLocation = 1 AND @iLocationId = 1 AND MONTH(ROOT_ISQ.InitialComparedDateTime) = @iMonth AND YEAR(ROOT_ISQ.InitialComparedDateTime) = @iYear))
		GROUP BY I.ImportId, I.ImportName, I.Description, I.ImportGroupID, I.ImportTypeId, I.IsActive, I.DefaultKillTimeoutMinutes
		UNION ALL
		SELECT I.ImportID, I.ImportName, I.ImportGroupID, I.ImportTypeID, I.Description, I.IsActive, I.DefaultKillTimeoutMinutes,
			NULL AS ImportGroupDescription, NULL AS ImportTypeDescription, NULL AS ImportTypeName, 
			COUNT(ISV.ImportSyncValidateId) AS ValidateCount,
			COUNT(ISC.ImportSyncConflictId) AS ConflictCount, 
			COUNT(ISE.ImportSyncExceptionId) AS CriticalErrorCount
		FROM dbo.Import I
		LEFT JOIN dbo.ImportSyncQueue ISQ ON ISQ.ImportId = I.ImportId AND ISQ.IsPending = 1
		LEFT JOIN dbo.ImportSyncRow ISR ON ISR.ImportSyncRowId = ISQ.ImportSyncRowId
		-- we have to get the root row for this import item - the very first time it was imported
		-- this date is required so that we can filter the validation count by date for the imports page
		LEFT JOIN dbo.ImportSyncQueue ROOT_ISQ ON ROOT_ISQ.ImportSyncRowId = ISR.RootImportSyncRowId AND ROOT_ISQ.SyncAction = 'I'
		LEFT JOIN dbo.ImportSyncValidate ISV ON ISV.ImportSyncQueueId = ISQ.ImportSyncQueueId
		LEFT JOIN dbo.ImportSyncConflict ISC ON ISC.ImportSyncQueueId = ISQ.ImportSyncQueueId
		LEFT JOIN dbo.ImportSyncException ISE ON ISE.ImportSyncQueueId = ISQ.ImportSyncQueueId
		OUTER APPLY ISR.SourceRow.nodes('/MetBalancingSource/MetBalancing') AS MBSResult(MetBalancingSource)
		WHERE I.IsActive = @iActive AND I.ImportId = 6 
		AND ((@iUseMonthLocation = 0 AND ROOT_ISQ.InitialComparedDateTime > @iValidationFromDate) 
		  OR (@iUseMonthLocation = 1 AND @iLocationId = 1 AND MONTH(MBSResult.MetBalancingSource.value('(CalendarDate/text())[1]', 'DATE')) = @iMonth AND YEAR(MBSResult.MetBalancingSource.value('(CalendarDate/text())[1]', 'DATE')) = @iYear))
		GROUP BY I.ImportId, I.ImportName, I.Description, I.ImportGroupID, I.ImportTypeId, I.IsActive, I.DefaultKillTimeoutMinutes
		UNION ALL
		SELECT I.ImportID, I.ImportName, I.ImportGroupID, I.ImportTypeID, I.Description, I.IsActive, I.DefaultKillTimeoutMinutes,
			NULL AS ImportGroupDescription, NULL AS ImportTypeDescription, NULL AS ImportTypeName, 
			COUNT(ISV.ImportSyncValidateId) AS ValidateCount,
			COUNT(ISC.ImportSyncConflictId) AS ConflictCount, 
			COUNT(ISE.ImportSyncExceptionId) AS CriticalErrorCount
		FROM dbo.Import I
		LEFT JOIN dbo.ImportSyncQueue ISQ ON ISQ.ImportId = I.ImportId AND ISQ.IsPending = 1
		LEFT JOIN dbo.ImportSyncRow ISR ON ISR.ImportSyncRowId = ISQ.ImportSyncRowId
		-- we have to get the root row for this import item - the very first time it was imported
		-- this date is required so that we can filter the validation count by date for the imports page
		LEFT JOIN dbo.ImportSyncQueue ROOT_ISQ ON ROOT_ISQ.ImportSyncRowId = ISR.RootImportSyncRowId AND ROOT_ISQ.SyncAction = 'I'
		LEFT JOIN dbo.ImportSyncValidate ISV ON ISV.ImportSyncQueueId = ISQ.ImportSyncQueueId
		LEFT JOIN dbo.ImportSyncConflict ISC ON ISC.ImportSyncQueueId = ISQ.ImportSyncQueueId
		LEFT JOIN dbo.ImportSyncException ISE ON ISE.ImportSyncQueueId = ISQ.ImportSyncQueueId
		OUTER APPLY ISR.SourceRow.nodes('/ShippingSource/Nomination') AS SSResult(ShippingSource)
		WHERE I.IsActive = @iActive AND I.ImportId = 7 
		AND ((@iUseMonthLocation = 0 AND ROOT_ISQ.InitialComparedDateTime > @iValidationFromDate)
			-- No location filtering is possible, but we can month/year filter properly
		  OR (@iUseMonthLocation = 1 AND @iLocationID = 1 AND MONTH(SSResult.ShippingSource.value('(OfficialFinishTime/text())[1]', 'DATE')) = @iMonth AND YEAR(SSResult.ShippingSource.value('(OfficialFinishTime/text())[1]', 'DATE')) = @iYear))
		GROUP BY I.ImportId, I.ImportName, I.Description, I.ImportGroupID, I.ImportTypeId, I.IsActive, I.DefaultKillTimeoutMinutes
		UNION ALL
		SELECT I.ImportID, I.ImportName, I.ImportGroupID, I.ImportTypeID, I.Description, I.IsActive, I.DefaultKillTimeoutMinutes,
			NULL AS ImportGroupDescription, NULL AS ImportTypeDescription, NULL AS ImportTypeName, 
			COUNT(ISV.ImportSyncValidateId) AS ValidateCount,
			COUNT(ISC.ImportSyncConflictId) AS ConflictCount, 
			COUNT(ISE.ImportSyncExceptionId) AS CriticalErrorCount
		FROM dbo.Import I
		LEFT JOIN dbo.ImportSyncQueue ISQ ON ISQ.ImportId = I.ImportId AND ISQ.IsPending = 1
		LEFT JOIN dbo.ImportSyncRow ISR ON ISR.ImportSyncRowId = ISQ.ImportSyncRowId
		-- we have to get the root row for this import item - the very first time it was imported
		-- this date is required so that we can filter the validation count by date for the imports page
		LEFT JOIN dbo.ImportSyncQueue ROOT_ISQ ON ROOT_ISQ.ImportSyncRowId = ISR.RootImportSyncRowId AND ROOT_ISQ.SyncAction = 'I'
		LEFT JOIN dbo.ImportSyncValidate ISV ON ISV.ImportSyncQueueId = ISQ.ImportSyncQueueId
		LEFT JOIN dbo.ImportSyncConflict ISC ON ISC.ImportSyncQueueId = ISQ.ImportSyncQueueId
		LEFT JOIN dbo.ImportSyncException ISE ON ISE.ImportSyncQueueId = ISQ.ImportSyncQueueId
		OUTER APPLY ISR.SourceRow.nodes('/PortBalanceSource') AS PBResult(PortBalanceSource)
		WHERE I.IsActive = @iActive AND I.ImportId = 11 AND ((@iUseMonthLocation = 0 AND ROOT_ISQ.InitialComparedDateTime > @iValidationFromDate)
			-- No location filtering is possible, but we can month/year filter properly
			OR (@iUseMonthLocation = 1 
				AND (@iLocationId = 1 
					OR (@iLocationId <> 1 
						AND ((dbo.ConvertMESToLocationId(PBResult.PortBalanceSource.value('(PortBalanceGrade/Hub/text())[1]', 'VARCHAR(3)')) = @iLocationId) 
							OR (dbo.ConvertMESToLocationId(PBResult.PortBalanceSource.value('(PortBalance/Hub/text())[1]', 'VARCHAR(3)')) = @iLocationId)))) 
				AND ((MONTH(PBResult.PortBalanceSource.value('(PortBalanceGrade/BalanceDate/text())[1]', 'DATE')) = @iMonth AND YEAR(PBResult.PortBalanceSource.value('(PortBalanceGrade/BalanceDate/text())[1]', 'DATE')) = @iYear) 
					OR (MONTH(PBResult.PortBalanceSource.value('(PortBalance/BalanceDate/text())[1]', 'DATE')) = @iMonth AND YEAR(PBResult.PortBalanceSource.value('(PortBalance/BalanceDate/text())[1]', 'DATE')) = @iYear))))
		GROUP BY I.ImportId, I.ImportName, I.Description, I.ImportGroupID, I.ImportTypeId, I.IsActive, I.DefaultKillTimeoutMinutes
		UNION ALL
		SELECT I.ImportID, I.ImportName, I.ImportGroupID, I.ImportTypeID, I.Description, I.IsActive, I.DefaultKillTimeoutMinutes,
			NULL AS ImportGroupDescription, NULL AS ImportTypeDescription, NULL AS ImportTypeName, 
			COUNT(ISV.ImportSyncValidateId) AS ValidateCount,
			COUNT(ISC.ImportSyncConflictId) AS ConflictCount, 
			COUNT(ISE.ImportSyncExceptionId) AS CriticalErrorCount
		FROM dbo.Import I
		LEFT JOIN dbo.ImportSyncQueue ISQ ON ISQ.ImportId = I.ImportId AND ISQ.IsPending = 1
		LEFT JOIN dbo.ImportSyncRow ISR ON ISR.ImportSyncRowId = ISQ.ImportSyncRowId
		-- we have to get the root row for this import item - the very first time it was imported
		-- this date is required so that we can filter the validation count by date for the imports page
		LEFT JOIN dbo.ImportSyncQueue ROOT_ISQ ON ROOT_ISQ.ImportSyncRowId = ISR.RootImportSyncRowId AND ROOT_ISQ.SyncAction = 'I'
		LEFT JOIN dbo.ImportSyncValidate ISV ON ISV.ImportSyncQueueId = ISQ.ImportSyncQueueId
		LEFT JOIN dbo.ImportSyncConflict ISC ON ISC.ImportSyncQueueId = ISQ.ImportSyncQueueId
		LEFT JOIN dbo.ImportSyncException ISE ON ISE.ImportSyncQueueId = ISQ.ImportSyncQueueId
		OUTER APPLY ISR.SourceRow.nodes('/PortBlendingSource') AS PBResult(PortBlendingSource)
		WHERE I.IsActive = @iActive AND I.ImportId = 12 AND ((@iUseMonthLocation = 0 AND ROOT_ISQ.InitialComparedDateTime > @iValidationFromDate)
			-- No location filtering is possible, but we can month/year filter properly
			OR (@iUseMonthLocation = 1 
				AND (@iLocationId = 1
					OR (@iLocationId <> 1
						AND (dbo.ConvertMESToLocationId(PBResult.PortBlendingSource.value('(PortBlending/RakeHub/text())[1]', 'VARCHAR(3)')) = @iLocationId) 
							OR (dbo.ConvertMESToLocationId(PBResult.PortBlendingSource.value('(PortBlending/Source/text())[1]', 'VARCHAR(3)')) = @iLocationId) 
							OR (dbo.ConvertMESToLocationId(PBResult.PortBlendingSource.value('(PortBlendingGrade/RakeHub/text())[1]', 'VARCHAR(3)')) = @iLocationId) 
							OR (dbo.ConvertMESToLocationId(PBResult.PortBlendingSource.value('(PortBlendingGrade/SourceHub/text())[1]', 'VARCHAR(3)')) = @iLocationId)))
				AND ((MONTH(PBResult.PortBlendingSource.value('(PortBlending/StartDate/text())[1]', 'DATE')) = @iMonth AND YEAR(PBResult.PortBlendingSource.value('(PortBlendingStartDate/text())[1]', 'DATE')) = @iYear)
					OR (MONTH(PBResult.PortBlendingSource.value('(PortBlendingGrade/StartDate/text())[1]', 'DATE')) = @iMonth AND YEAR(PBResult.PortBlendingSource.value('(PortBlendingGrade/StartDate/text())[1]', 'DATE')) = @iYear))))
		GROUP BY I.ImportId, I.ImportName, I.Description, I.ImportGroupID, I.ImportTypeId, I.IsActive, I.DefaultKillTimeoutMinutes
		UNION ALL
		SELECT I.ImportID, I.ImportName, I.ImportGroupID, I.ImportTypeID, I.Description, I.IsActive, I.DefaultKillTimeoutMinutes,
			NULL AS ImportGroupDescription, NULL AS ImportTypeDescription, NULL AS ImportTypeName, 
			COUNT(ISV.ImportSyncValidateId) AS ValidateCount,
			COUNT(ISC.ImportSyncConflictId) AS ConflictCount, 
			COUNT(ISE.ImportSyncExceptionId) AS CriticalErrorCount
		FROM dbo.Import I
		LEFT JOIN dbo.ImportSyncQueue ISQ ON ISQ.ImportId = I.ImportId AND ISQ.IsPending = 1
		LEFT JOIN dbo.ImportSyncRow ISR ON ISR.ImportSyncRowId = ISQ.ImportSyncRowId
		-- we have to get the root row for this import item - the very first time it was imported
		-- this date is required so that we can filter the validation count by date for the imports page
		LEFT JOIN dbo.ImportSyncQueue ROOT_ISQ ON ROOT_ISQ.ImportSyncRowId = ISR.RootImportSyncRowId AND ROOT_ISQ.SyncAction = 'I'
		LEFT JOIN dbo.ImportSyncValidate ISV ON ISV.ImportSyncQueueId = ISQ.ImportSyncQueueId
		LEFT JOIN dbo.ImportSyncConflict ISC ON ISC.ImportSyncQueueId = ISQ.ImportSyncQueueId
		LEFT JOIN dbo.ImportSyncException ISE ON ISE.ImportSyncQueueId = ISQ.ImportSyncQueueId
		OUTER APPLY ISR.SourceRow.nodes('/StockpileAdjustmentSource') AS SASResult(StockpileAdjustmentSource)
		WHERE I.IsActive = @iActive AND I.ImportId = 8 AND ((@iUseMonthLocation = 0 AND ROOT_ISQ.InitialComparedDateTime > @iValidationFromDate)
			OR (@iUseMonthLocation = 1 
				AND ((MONTH(SASResult.StockpileAdjustmentSource.value('(StockpileAdjustment/StockpileAdjustmentDate/text())[1]', 'DATE')) = @iMonth AND YEAR(SASResult.StockpileAdjustmentSource.value('(StockpileAdjustment/StockpileAdjustmentDate/text())[1]', 'DATE')) = @iYear) 
					OR (MONTH(SASResult.StockpileAdjustmentSource.value('(StockpileAdjustmentGrade/StockpileAdjustmentDate/text())[1]', 'DATE')) = @iMonth AND YEAR(SASResult.StockpileAdjustmentSource.value('(StockpileAdjustmentGrade/StockpileAdjustmentDate/text())[1]', 'DATE')) = @iYear))
				AND (@iLocationId = 1 OR (@iLocationId <> 1 
					AND (dbo.GetParentLocationByLocationType(dbo.ConvertMQ2ToLocationId(SASResult.StockpileAdjustmentSource.value('(StockpileAdjustment/Mine/text())[1]', 'NVARCHAR(MAX)')), @iLocationType, @overrideDate) = @iLocationId
						OR dbo.GetParentLocationByLocationType(dbo.ConvertMQ2ToLocationId(SASResult.StockpileAdjustmentSource.value('(StockpileAdjustmentGrade/Mine/text())[1]', 'NVARCHAR(MAX)')), @iLocationType, @overrideDate) = @iLocationId)))))
		GROUP BY I.ImportId, I.ImportName, I.Description, I.ImportGroupID, I.ImportTypeId, I.IsActive, I.DefaultKillTimeoutMinutes
		UNION ALL
		SELECT I.ImportID, I.ImportName, I.ImportGroupID, I.ImportTypeID, I.Description, I.IsActive, I.DefaultKillTimeoutMinutes,
			NULL AS ImportGroupDescription, NULL AS ImportTypeDescription, NULL AS ImportTypeName, 
			COUNT(ISV.ImportSyncValidateId) AS ValidateCount,
			COUNT(ISC.ImportSyncConflictId) AS ConflictCount, 
			COUNT(ISE.ImportSyncExceptionId) AS CriticalErrorCount
		FROM dbo.Import I
		LEFT JOIN dbo.ImportSyncQueue ISQ ON ISQ.ImportId = I.ImportId AND ISQ.IsPending = 1
		LEFT JOIN dbo.ImportSyncRow ISR ON ISR.ImportSyncRowId = ISQ.ImportSyncRowId
		-- we have to get the root row for this import item - the very first time it was imported
		-- this date is required so that we can filter the validation count by date for the imports page
		LEFT JOIN dbo.ImportSyncQueue ROOT_ISQ ON ROOT_ISQ.ImportSyncRowId = ISR.RootImportSyncRowId AND ROOT_ISQ.SyncAction = 'I'
		LEFT JOIN dbo.ImportSyncValidate ISV ON ISV.ImportSyncQueueId = ISQ.ImportSyncQueueId
		LEFT JOIN dbo.ImportSyncConflict ISC ON ISC.ImportSyncQueueId = ISQ.ImportSyncQueueId
		LEFT JOIN dbo.ImportSyncException ISE ON ISE.ImportSyncQueueId = ISQ.ImportSyncQueueId
		OUTER APPLY ISR.SourceRow.nodes('/StockpileSource/Stockpile') AS SSResult(StockpileSource)
		WHERE I.IsActive = @iActive AND I.ImportId = 10 AND ((@iUseMonthLocation = 0 AND ROOT_ISQ.InitialComparedDateTime > @iValidationFromDate)
			OR (@iUseMonthLocation = 1 
				AND MONTH(SSResult.StockpileSource.value('(StartDate/text())[1]', 'DATE')) = @iMonth AND YEAR(SSResult.StockpileSource.value('(StartDate/text())[1]', 'DATE')) = @iYear
				AND (@iLocationId = 1 OR (@iLocationId <> 1
					AND (dbo.GetParentLocationByLocationType(dbo.ConvertMQ2ToLocationId(SSResult.StockpileSource.value('(Mine/text())[1]', 'NVARCHAR(MAX)')), @iLocationType, @overrideDate) = @iLocationId)))))
		GROUP BY I.ImportId, I.ImportName, I.Description, I.ImportGroupID, I.ImportTypeId, I.IsActive, I.DefaultKillTimeoutMinutes) AS Counts ON Counts.ImportId = I.ImportId
	WHERE I.IsActive = @iActive
	ORDER BY I.ImportId
END
GO

GRANT EXECUTE ON dbo.GetBhpbioImportList TO CommonImportManager
GO
