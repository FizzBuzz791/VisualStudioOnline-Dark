IF OBJECT_ID('dbo.GetBhpbioApprovalDigblockListApprovedData') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioApprovalDigblockListApprovedData
GO 
 
-- when @iIncludeDepletions is true, then an approved block will be included, even if it doesn't have any
-- depletion tonnes against it.
CREATE PROCEDURE dbo.GetBhpbioApprovalDigblockListApprovedData
(
	@iLocationId INT,
	@iMonthFilter DATETIME,
	@iIncludeDepletions BIT = 0
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	
	DECLARE @summaryId INTEGER
	
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		DigblockId VARCHAR(31),
		MaterialTypeId INT,
		PRIMARY KEY (LocationId)
	)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioApprovalDigblockListApprovedData',
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
		DECLARE @startOfMonth DATETIME
		SET @startOfMonth = @iMonthFilter
		
		DECLARE @startOfNextMonth DATETIME
		SET @startOfNextMonth = DateAdd(Month,1, @startOfMonth)

		DECLARE @endOfMonth DATETIME
		SET @endOfMonth = DateAdd(Day, -1, DateAdd(Month, 1, @startOfMonth))
		
		EXEC dbo.GetBhpbioSummaryIdForMonth @iSummaryMonth = @startOfMonth,
											@oSummaryId = @summaryId OUTPUT
		
		INSERT INTO @Location (LocationId, DigblockId, MaterialTypeId)
		SELECT dl.Location_Id, d.digblock_id, d.material_type_id
		FROM dbo.Digblock d
			INNER JOIN dbo.DigblockLocation dl ON d.Digblock_Id =  dl.Digblock_Id
			INNER JOIN BhpbioLocationDate block 
				ON block.Location_Id = dl.Location_Id
				AND (@startOfMonth BETWEEN block.Start_Date AND block.End_Date)
			INNER JOIN BhpbioLocationDate blast 
				ON block.Parent_Location_Id = blast.Location_Id
				AND (@startOfMonth BETWEEN blast.Start_Date AND blast.End_Date)
			INNER JOIN BhpbioLocationDate bench 
				ON blast.Parent_Location_Id = bench.Location_Id
				AND (@startOfMonth BETWEEN bench.Start_Date AND bench.End_Date)
			INNER JOIN dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId,0,'PIT',@startOfMonth,@endOfMonth) l
				ON bench.Parent_Location_Id = l.LocationId
				AND (@startOfMonth BETWEEN l.IncludeStart AND l.IncludeEnd)

		SELECT l.DigblockId, 
			l.MaterialTypeId,
			gm.Tonnes as GeologyTonnes,
			mm.Tonnes as MiningTonnes,
			stgm.Tonnes as ShortTermGeologyTonnes,
			gcm.Tonnes as GradeControlTonnes,
			gm.Volume as GeologyVolume,
			mm.Volume as MiningVolume,
			stgm.Volume as ShortTermGeologyVolume,
			gcm.Volume as GradeControlVolume,
			mh.Tonnes As MonthlyHauledTonnes,
			s.Tonnes AS SurveyedTonnes,
			mb.Tonnes As MonthlyBestTonnes,
			tgc.Tonnes - COALESCE(cumulative.Tonnes, 0) As RemainingTonnes,
			gm.ModelFilename As GeologyModelFilename,
			mm.ModelFilename As MiningModelFilename,
			stgm.ModelFilename As ShortTermGeologyModelFilename,
			gcm.ModelFilename As GradeControlModelFilename
		FROM @Location l
			LEFT JOIN dbo.BhpbioApprovalDigblock ad
				ON ad.DigblockId = l.DigblockId AND ad.ApprovedMonth = @startOfMonth
			LEFT JOIN dbo.GetBhpbioSummaryTonnesByLocation(@summaryId,'GradeControlModelMovement',NULL) gcm
				ON gcm.LocationId = l.LocationId
			LEFT JOIN dbo.GetBhpbioSummaryTonnesByLocation(@summaryId,'MiningModelMovement',NULL) mm
				ON mm.LocationId = l.LocationId
			LEFT JOIN dbo.GetBhpbioSummaryTonnesByLocation(@summaryId,'GeologyModelMovement',NULL) gm
				ON gm.LocationId = l.LocationId
			LEFT JOIN dbo.GetBhpbioSummaryTonnesByLocation(@summaryId,'BlastBlockMonthlyBest',NULL) mb
				ON mb.LocationId = l.LocationId
			LEFT JOIN dbo.GetBhpbioSummaryTonnesByLocation(@summaryId,'BlastBlockMonthlyHauled',NULL) mh
				ON mh.LocationId = l.LocationId
			LEFT JOIN dbo.GetBhpbioSummaryTonnesByLocation(@summaryId,'BlastBlockSurvey',NULL) s
				ON s.LocationId = l.LocationId
			LEFT JOIN dbo.GetBhpbioSummaryTonnesByLocation(@summaryId,'BlastBlockCumulativeHauled',NULL) cumulative
				ON cumulative.LocationId = l.LocationId
			LEFT JOIN dbo.GetBhpbioSummaryTonnesByLocation(@summaryId,'BlastBlockTotalGradeControl',NULL) tgc
				ON tgc.LocationId = l.LocationId
			LEFT JOIN dbo.GetBhpbioSummaryTonnesByLocation(@summaryId,'ShortTermGeologyModelMovement',NULL) stgm
				ON stgm.LocationId = l.LocationId
		WHERE (ad.DigblockId IS NOT NULL AND @iIncludeDepletions = 1)
		 OR gm.Tonnes IS NOT NULL
		 OR gcm.Tonnes IS NOT NULL
		 OR mm.Tonnes IS NOT NULL
		 OR mb.Tonnes IS NOT NULL
		 OR mh.Tonnes IS NOT NULL
		 OR s.Tonnes IS NOT NULL
		 OR stgm.Tonnes IS NOT NULL
		ORDER BY 1

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

GRANT EXECUTE ON dbo.GetBhpbioApprovalDigblockListApprovedData TO BhpbioGenericManager
GO

--EXEC dbo.GetBhpbioApprovalDigblockListApprovedData  4, '1-SEP-2008', NULL

/*
<TAG Name="Data Dictionary" FunctionName="dbo.GetBhpbioApprovalDigblockListApprovedData">
 <Function>
	Retrieves a set of digblock approval listing data based on Approved Summary data only.
	Note: This is combined with Live results by the dbo.GetBhpbioApprovalDigblockList procedure
	
			
	Pass: 
			@iLocationId : Identifies the Location within which to select digblocks
			@iMonthFilter: The month to return data for
			@iRecordLimit: An optional Record Limit
	
	Returns: Set of digblock approval data
 </Function>
</TAG>
*/	