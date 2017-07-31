IF OBJECT_ID('dbo.GetBhpbioApprovalDigblockListApprovedData') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioApprovalDigblockListApprovedData
GO 
  
CREATE PROCEDURE dbo.GetBhpbioApprovalDigblockListApprovedData
(
	@iLocationId INT,
	@iMonthFilter DATETIME
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
		ParentLocationID INT,
		IncludeStart DATETIME,
		IncludeEnd DATETIME,
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
		
		INSERT INTO @Location
		SELECT LocationId, ParentLocationID, IncludeStart,IncludeEnd
		--FROM dbo.GetBhpbioReportLocation(@iLocationId)
		FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId,0,NULL,@startOfMonth,@endOfMonth)
		
		SELECT d.Digblock_Id, 
		 d.Material_Type_Id,
		 mm.Tonnes as MiningTonnes,
		 gm.Tonnes as GeologyTonnes,
		 gcm.Tonnes as GradeControlTonnes,
		 mh.Tonnes As MonthlyHauledTonnes,
		 s.Tonnes AS SurveyedTonnes,
		 mb.Tonnes As MonthlyBestTonnes,
		 tgc.Tonnes - cumulative.Tonnes As RemainingTonnes
		FROM @Location l
			INNER JOIN dbo.DigBlockLocation dl
				ON dl.Location_Id = l.LocationId
			INNER JOIN dbo.Digblock d
				ON d.Digblock_Id =  dl.Digblock_Id
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
		WHERE gm.Tonnes IS NOT NULL
		 OR gcm.Tonnes IS NOT NULL
		 OR mm.Tonnes IS NOT NULL
		 OR mb.Tonnes IS NOT NULL
		 OR mh.Tonnes IS NOT NULL
		 OR s.Tonnes IS NOT NULL
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