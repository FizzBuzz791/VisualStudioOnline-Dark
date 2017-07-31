IF OBJECT_ID('dbo.AddBhpbioPurgeRequest') IS NOT NULL
     DROP PROCEDURE dbo.AddBhpbioPurgeRequest
GO 

CREATE PROC dbo.AddBhpbioPurgeRequest
(
	@iMonth DATETIME,
	@iRequestingUserId INT,
	@oPurgeRequestId INT OUTPUT
)
WITH ENCRYPTION
AS
BEGIN
	SET @iMonth = CASE WHEN @iMonth IS NOT NULL THEN convert(varchar,datepart(yyyy,@iMonth)) + '-' + convert(varchar,datepart(mm,@iMonth)) + '-01' END
	
	INSERT dbo.BhpbioPurgeRequest
	(
		PurgeMonth, PurgeRequestStatusId, RequestingUserId, LastStatusChangeDateTime
	)
	SELECT @iMonth, 1, @iRequestingUserId, GETDATE()
	WHERE @iMonth IS NOT NULL 
		AND @iRequestingUserId IS NOT NULL
		AND NOT EXISTS (SELECT * 
						FROM dbo.BhpbioPurgeRequest pr
							INNER JOIN dbo.BhpbioPurgeRequestStatus prs ON prs.PurgeRequestStatusId = pr.PurgeRequestStatusId
						WHERE YEAR(pr.PurgeMonth) = YEAR(@iMonth)
							AND MONTH(pr.PurgeMonth) = MONTH(@iMonth)
							-- and not finalised
							AND (prs.IsFinalStatePositive = 0 AND prs.IsFinalStateNegative = 0)
						)
	SET @oPurgeRequestId = CONVERT(INT,SCOPE_IDENTITY())
END
GO

GRANT EXECUTE ON dbo.AddBhpbioPurgeRequest TO BhpbioGenericManager
GO

IF OBJECT_ID('dbo.ApproveBhpbioApprovalData') IS NOT NULL
     DROP PROCEDURE dbo.ApproveBhpbioApprovalData 
GO 
  
CREATE PROCEDURE dbo.ApproveBhpbioApprovalData
(
	@iTagId VARCHAR(31),
	@iLocationId INT,
	@iApprovalMonth DATETIME,
	@iUserId INT
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'ApproveBhpbioApprovalData',
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
		IF NOT EXISTS (SELECT 1 FROM dbo.BhpbioReportDataTags WHERE TagId = @iTagId)
		BEGIN
			RAISERROR('The tag does not exist', 16, 1)
		END
		
		IF NOT EXISTS (SELECT 1 FROM dbo.Location WHERE Location_Id = @iLocationId)
		BEGIN
			RAISERROR('The location does not exist', 16, 1)
		END
	
		IF @iApprovalMonth <> dbo.GetDateMonth(@iApprovalMonth)
		BEGIN
			RAISERROR('The date supplied is not the start of a month', 16, 1)
		END
	
		IF NOT EXISTS (SELECT 1 FROM dbo.SecurityUser WHERE UserId = @iUserId)
		BEGIN
			RAISERROR('The user id does not exist', 16, 1)
		END
		
		-- Determine the latest month that was purged
		-- and ensure that the user is not attempting an approval in a month that has already been purged
		DECLARE @latestPurgedMonth DATETIME
		exec dbo.GetBhpbioLatestPurgedMonth @oLatestPurgedMonth = @latestPurgedMonth OUTPUT
		
		IF @latestPurgedMonth IS NOT NULL AND @latestPurgedMonth >= @iApprovalMonth
		BEGIN
			RAISERROR('It is not possible to approve data in this period as the period has been purged', 16, 1)
		END
		
		IF EXISTS	(
						SELECT 1 
						FROM dbo.BhpbioApprovalData 
						WHERE TagId = @iTagId 
							AND ApprovedMonth = @iApprovalMonth 
							AND LocationID = @iLocationId
					)
		BEGIN
			RAISERROR('The calculation and month provided has already been approved.', 16, 1)
		END
		
		IF NOT EXISTS	(
						SELECT TOP 1 1 
						FROM dbo.BhpbioReportDataTags AS T
							LEFT JOIN dbo.Location AS L
								ON (T.TagGroupLocationTypeId = L.Location_Type_Id
									OR T.TagGroupLocationTypeId IS NULL)
						WHERE TagId = @iTagId
							AND L.Location_ID = @iLocationId
					)
		BEGIN
			RAISERROR('The calculation cannot be approved at this location type.', 16, 1)
		END
		
		INSERT INTO dbo.BhpbioApprovalData
			(TagId, LocationId, ApprovedMonth, UserId, SignoffDate)
		SELECT @iTagId, @iLocationId, @iApprovalMonth, @iUserId, GetDate()
		
		-- Here we plug-in data summarisation steps as appropriate for the approval
		exec dbo.SummariseBhpbioDataRelatedToApproval	@iTagId = @iTagId,
														@iLocationId = @iLocationId,
														@iApprovalMonth = @iApprovalMonth,
														@iUserId = @iUserId
		
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

GRANT EXECUTE ON dbo.ApproveBhpbioApprovalData TO BhpbioGenericManager
GO

/*
BEGIN TRAN
exec dbo.ApproveBhpbioApprovalData
	@iTagId = 'F2Factor',
	@iLocationId = 3,
	@iApprovalMonth = '1-apr-2008',
	@iUserId = 1

Select * from dbo.BhpbioApprovalData where TagId = 'F2Factor'
	
ROLLBACK TRAN
*/
IF OBJECT_ID('dbo.PurgeBhpbioData') IS NOT NULL
     DROP PROC dbo.PurgeBhpbioData
GO 

CREATE PROC dbo.PurgeBhpbioData
(
	@iRequest INT
)
WITH ENCRYPTION
AS
BEGIN
SET NOCOUNT ON
DECLARE 
	@Message VARCHAR(100),
	@Compare VARCHAR(6),
	@LastDayOfPurgeMonth DATETIME,
	@FirstDayAfterPurge DATETIME
	
	SELECT @Compare = CONVERT(VARCHAR(6),PurgeMonth,112)
	FROM dbo.BhpbioPurgeRequest WITH (NOLOCK) 
	WHERE PurgeRequestId = @iRequest
		AND PurgeRequestStatusId = 5
	
	SET @FirstDayAfterPurge = DATEADD(m,1,@Compare + '01')
	SET @LastDayOfPurgeMonth = DATEADD(d,-1,@FirstDayAfterPurge)
	
	IF (@Compare IS NULL)
	BEGIN
		SET @Message = 'The Purge Request ' + convert(varchar,@iRequest) + ' has not been initiated'
		RAISERROR(@Message, 16,1)
	END

	IF EXISTS (
			SELECT * 
			FROM dbo.BhpbioApprovalStatusByMonth sbm
			WHERE sbm.Month < @FirstDayAfterPurge AND Approved = 0
		)
	BEGIN
		SET @Message = 'The Purge Request ' + convert(varchar,@iRequest) + ' cannot be performed as there are missing approvals'
		RAISERROR(@Message, 16,1)
	END

	-- Haulage
	DELETE hg
	FROM dbo.HaulageGrade AS hg 
		INNER JOIN dbo.Haulage AS h WITH (NOLOCK)
			ON hg.Haulage_Id = h.Haulage_Id
	WHERE CONVERT(VARCHAR(6),h.Haulage_Date,112) <= @Compare
	
	DELETE hn
	FROM dbo.HaulageNotes AS hn
		INNER JOIN dbo.Haulage AS h WITH (NOLOCK)
			ON hn.Haulage_Id = h.Haulage_Id
	WHERE CONVERT(VARCHAR(6),h.Haulage_Date,112) <= @Compare
	
	DELETE hv
	FROM dbo.HaulageValue AS hv
		INNER JOIN dbo.Haulage AS h WITH (NOLOCK)
			ON hv.Haulage_Id = h.Haulage_Id
	WHERE CONVERT(VARCHAR(6),h.Haulage_Date,112) <= @Compare
	
	DELETE dbo.Haulage
	WHERE CONVERT(VARCHAR(6),Haulage_Date,112) <= @Compare
	
	-- Haulage Raw
	DELETE hg
	FROM dbo.HaulageRawGrade AS hg 
		INNER JOIN dbo.HaulageRaw AS h WITH (NOLOCK)
			ON hg.Haulage_Raw_Id = h.Haulage_Raw_Id
	WHERE CONVERT(VARCHAR(6),h.Haulage_Date,112) <= @Compare
	
	DELETE hv
	FROM dbo.HaulageRawValue AS hv
		INNER JOIN dbo.HaulageRaw AS h WITH (NOLOCK)
			ON hv.Haulage_Raw_Id = h.Haulage_Raw_Id
	WHERE CONVERT(VARCHAR(6),h.Haulage_Date,112) <= @Compare
	
	DELETE hl
	FROM dbo.HaulageRawLocation AS hl
		INNER JOIN dbo.HaulageRaw AS h WITH (NOLOCK)
			ON hl.HaulageRawId = h.Haulage_Raw_Id
	WHERE CONVERT(VARCHAR(6),h.Haulage_Date,112) <= @Compare
	
	DELETE hn
	FROM dbo.HaulageRawNotes AS hn
		INNER JOIN dbo.HaulageRaw AS h WITH (NOLOCK)
			ON hn.Haulage_Raw_Id = h.Haulage_Raw_Id
	WHERE CONVERT(VARCHAR(6),h.Haulage_Date,112) <= @Compare
	
	DELETE dbo.HaulageRaw
	WHERE CONVERT(VARCHAR(6),Haulage_Date,112) <= @Compare
	
	-- WeightometerSample
	DELETE wsv
	FROM dbo.WeightometerSampleValue wsv 
		INNER JOIN dbo.WeightometerSample ws WITH (NOLOCK)
			ON wsv.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
	WHERE CONVERT(VARCHAR(6),ws.Weightometer_Sample_Date,112) <= @Compare 
	
	DELETE wsn
	FROM dbo.WeightometerSampleNotes wsn 
		INNER JOIN dbo.WeightometerSample ws WITH (NOLOCK)
			ON wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
	WHERE CONVERT(VARCHAR(6),ws.Weightometer_Sample_Date,112) <= @Compare 
	
	DELETE wsg
	FROM dbo.WeightometerSampleGrade wsg 
		INNER JOIN dbo.WeightometerSample ws WITH (NOLOCK)
			ON wsg.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
	WHERE CONVERT(VARCHAR(6),ws.Weightometer_Sample_Date,112) <= @Compare 
	
	DELETE dbo.WeightometerSample
	WHERE CONVERT(VARCHAR(6),Weightometer_Sample_Date,112) <= @Compare 
	
	-- BhpbioImportReconciliationMovement
	DELETE dbo.BhpbioImportReconciliationMovement
	WHERE CONVERT(VARCHAR(6),DateTo,112) <= @Compare
	
	-- BhpbioPortBlending
	DELETE g
	FROM dbo.BhpbioPortBlendingGrade g 
		INNER JOIN dbo.BhpbioPortBlending b WITH (NOLOCK)
			ON g.BhpbioPortBlendingId = b.BhpbioPortBlendingId
	WHERE CONVERT(VARCHAR(6),b.EndDate,112) <= @Compare	
	
	DELETE dbo.BhpbioPortBlending
	WHERE CONVERT(VARCHAR(6),EndDate,112) <= @Compare	
	
	-- BhpbioShippingTransactionNomination
	DELETE g
	FROM dbo.BhpbioShippingTransactionNominationGrade g 
		INNER JOIN dbo.BhpbioShippingTransactionNomination n WITH (NOLOCK)
			ON g.BhpbioShippingTransactionNominationId = n.BhpbioShippingTransactionNominationId
	WHERE CONVERT(VARCHAR(6),n.OfficialFinishTime,112) <= @Compare
	
	DELETE dbo.BhpbioShippingTransactionNomination
	WHERE CONVERT(VARCHAR(6),OfficialFinishTime,112) <= @Compare
	
	-- BhpbioPortBalance
	DELETE dbo.BhpbioPortBalance
	WHERE CONVERT(VARCHAR(6),BalanceDate,112) <= @Compare
	
	-- DataTransactionTonnes
	DELETE f
	FROM dbo.DataTransactionTonnesFlow f
		INNER JOIN dbo.DataTransactionTonnes t WITH (NOLOCK)
			ON f.Data_Transaction_Tonnes_Id = t.Data_Transaction_Tonnes_Id
	WHERE CONVERT(VARCHAR(6),t.Data_Transaction_Tonnes_Date,112) <= @Compare
	
	DELETE g
	FROM dbo.DataTransactionTonnesGrade g 
		INNER JOIN dbo.DataTransactionTonnes t WITH (NOLOCK)
			ON g.Data_Transaction_Tonnes_Id = t.Data_Transaction_Tonnes_Id
	WHERE CONVERT(VARCHAR(6),t.Data_Transaction_Tonnes_Date,112) <= @Compare
	
	DELETE dbo.DataTransactionTonnes
	WHERE CONVERT(VARCHAR(6),Data_Transaction_Tonnes_Date,112) <= @Compare
	
	-- DataProcessTransaction
	DELETE dbo.DataProcessTransaction
	WHERE CONVERT(VARCHAR(6),Data_Process_Transaction_Date,112) <= @Compare
	
	-- DataProcessTransactionLeft
	DELETE g
	FROM dbo.DataProcessTransactionLeftGrade g
		INNER JOIN dbo.DataProcessTransactionLeft t WITH (NOLOCK)
			ON g.Data_Process_Transaction_Left_Id = t.Data_Process_Transaction_Left_Id
	WHERE CONVERT(VARCHAR(6),t.Data_Process_Transaction_Left_Date,112) <= @Compare
	
	DELETE dbo.DataProcessTransactionLeft
	WHERE CONVERT(VARCHAR(6),Data_Process_Transaction_Left_Date,112) <= @Compare
	
	-- DataProcessStockpileBalance
	-- We need to keep the last day of the purged month in order for RECALC
	-- to be able to calculate the opening balance for the first day of the next month
	DELETE g
	FROM dbo.DataProcessStockpileBalanceGrade g
		INNER JOIN dbo.DataProcessStockpileBalance s WITH (NOLOCK)
			ON g.Data_Process_Stockpile_Balance_Id = s.Data_Process_Stockpile_Balance_Id
	WHERE s.Data_Process_Stockpile_Balance_Date < @LastDayOfPurgeMonth
	
	DELETE dbo.DataProcessStockpileBalance
	WHERE Data_Process_Stockpile_Balance_Date < @LastDayOfPurgeMonth
	
	-- AuditHistory
	DELETE h
	FROM dbo.AuditHistory h 
		INNER JOIN dbo.AuditType t WITH (NOLOCK)
			ON h.Audit_Type_Id = t.Audit_Type_Id
	WHERE (NOT t.Audit_Type_Group_Id = 6) -- ie not Purge
		AND CONVERT(VARCHAR(6),h.Audit_History_Datetime,112) <= @Compare
		
	-- RecalcHistory
	DELETE dbo.RecalcHistory
	WHERE CONVERT(VARCHAR(6),End_Date,112) <= @Compare
	
	-- ImportHistory
	DELETE s
	FROM dbo.ImportHistorySync s
		INNER JOIN dbo.ImportHistory h WITH (NOLOCK)
			ON s.ImportHistoryId = h.ImportHistoryId
	WHERE CONVERT(VARCHAR(6),h.JobDateStarted,112) <= @Compare
	
	DELETE l
	FROM dbo.ImportHistoryLoad l
		INNER JOIN dbo.ImportHistory h WITH (NOLOCK)
			ON l.ImportHistoryId = h.ImportHistoryId
	WHERE CONVERT(VARCHAR(6),h.JobDateStarted,112) <= @Compare
	
	DELETE dbo.ImportHistory
	WHERE CONVERT(VARCHAR(6),JobDateStarted,112) <= @Compare
	
	-- SupportLog
	DELETE dbo.SupportLog
	WHERE CONVERT(VARCHAR(6),Added,112) <= @Compare
	
	IF OBJECT_ID('tempdb.dbo.#BhpbioPurgeBhpbioDataSyncRowsToDelete') IS NOT NULL
	BEGIN
		DROP TABLE #BhpbioPurgeBhpbioDataSyncRowsToDelete
	END

	-- Identify the sync rows to delete
	CREATE TABLE #BhpbioPurgeBhpbioDataSyncRowsToDelete (
		ImportSyncRowId BIGINT NOT NULL,
		
		CONSTRAINT PK_BhpbioPurgeBhpbioDataSyncRowsToDelete
			PRIMARY KEY (ImportSyncRowId)
	)
	
	-- the sync rows to delete are thoses with queue data of the appropriate age
	INSERT INTO #BhpbioPurgeBhpbioDataSyncRowsToDelete(ImportSyncRowId)
	SELECT DISTINCT isq.ImportSyncRowId
	FROM dbo.ImportSyncQueue isq
		INNER JOIN dbo.ImportSyncTable ist ON ist.ImportSyncTableId = isq.ImportSyncTableId
	WHERE ist.Name IN ('Haulage','HaulageNotes','HaulageValue','HaulageGrade','Transaction','TransactionNomination','TransactionNominationGrade','PortBalance','PortBlending','PortBlendingGrade')
		AND isq.LastProcessedDateTime < @FirstDayAfterPurge
	
	-- and also any orphaned entries	
	INSERT INTO #BhpbioPurgeBhpbioDataSyncRowsToDelete(ImportSyncRowId)
	SELECT r.ImportSyncRowId
	FROM dbo.ImportSyncRow r
		LEFT JOIN dbo.ImportSyncQueue q
			ON (q.ImportSyncRowId = r.ImportSyncRowId) 
	WHERE q.ImportSyncRowId IS NULL

	-- delete the exceptions associated with sync rows about to be deleted
	DELETE e
	FROM dbo.ImportSyncRow r
		INNER JOIN #BhpbioPurgeBhpbioDataSyncRowsToDelete rtd ON r.ImportSyncRowId = rtd.ImportSyncRowId
		INNER JOIN dbo.ImportSyncQueue q
			ON (r.ImportSyncRowId = q.ImportSyncRowId)      
		INNER JOIN dbo.ImportSyncException e
			ON (e.ImportSyncQueueId = q.ImportSyncQueueId)

	-- delete the validation fields associated with sync rows about to be deleteed
	DELETE vf
	FROM dbo.ImportSyncRow r
		INNER JOIN #BhpbioPurgeBhpbioDataSyncRowsToDelete rtd ON r.ImportSyncRowId = rtd.ImportSyncRowId
		INNER JOIN dbo.ImportSyncQueue q
			ON (r.ImportSyncRowId = q.ImportSyncRowId)
		INNER JOIN dbo.ImportSyncValidate v
			ON (v.ImportSyncQueueId = q.ImportSyncQueueId)
		INNER JOIN dbo.ImportSyncValidateField vf
			ON (v.ImportSyncValidateId = vf.ImportSyncValidateId)

	-- delete the validate entries associated with sync rows about to be deleted
	DELETE v
	FROM dbo.ImportSyncRow r
		INNER JOIN #BhpbioPurgeBhpbioDataSyncRowsToDelete rtd ON r.ImportSyncRowId = rtd.ImportSyncRowId
		INNER JOIN dbo.ImportSyncQueue q
			ON (r.ImportSyncRowId = q.ImportSyncRowId)
		INNER JOIN dbo.ImportSyncValidate v
			ON (v.ImportSyncQueueId = q.ImportSyncQueueId)

	-- delete changed fields associated with import sync rows to about
	DELETE cf
	FROM dbo.ImportSyncRow r
		INNER JOIN #BhpbioPurgeBhpbioDataSyncRowsToDelete rtd ON r.ImportSyncRowId = rtd.ImportSyncRowId
		INNER JOIN dbo.ImportSyncQueue q
			ON (r.ImportSyncRowId = q.ImportSyncRowId)
		INNER JOIN importsyncChangedField cf
			ON (cf.ImportSyncQueueId = q.ImportSyncQueueId)

	-- delete the import sync queue entries associated with a sync row about to be deleted
	DELETE q
	FROM dbo.ImportSyncRow r
		INNER JOIN #BhpbioPurgeBhpbioDataSyncRowsToDelete rtd ON r.ImportSyncRowId = rtd.ImportSyncRowId
		INNER JOIN dbo.ImportSyncQueue q
			ON (r.ImportSyncRowId = q.ImportSyncRowId)

	-- delete the import sync relationships associated with a sync row about to be deleted
	DELETE q
	FROM dbo.ImportSyncRow r
		INNER JOIN #BhpbioPurgeBhpbioDataSyncRowsToDelete rtd ON r.ImportSyncRowId = rtd.ImportSyncRowId
		INNER JOIN dbo.ImportSyncRelationship q
			ON (r.ImportSyncRowId = q.ParentImportSyncRowId)

	DELETE q
	FROM dbo.ImportSyncRow r
		INNER JOIN #BhpbioPurgeBhpbioDataSyncRowsToDelete rtd ON r.ImportSyncRowId = rtd.ImportSyncRowId
		INNER JOIN dbo.ImportSyncRelationship q
			ON (r.ImportSyncRowId = q.ImportSyncRowId)

	-- delete the identified sync rows themselves
	DELETE r
	FROM dbo.ImportSyncRow r
		INNER JOIN #BhpbioPurgeBhpbioDataSyncRowsToDelete rtd ON r.ImportSyncRowId = rtd.ImportSyncRowId
		
	DROP TABLE #BhpbioPurgeBhpbioDataSyncRowsToDelete
END
GO

GRANT EXECUTE ON dbo.PurgeBhpbioData TO BhpbioGenericManager
GO

IF OBJECT_ID('dbo.DeleteBhpbioSummaryActualY') IS NOT NULL
     DROP PROCEDURE dbo.DeleteBhpbioSummaryActualY 
GO 
    
CREATE PROCEDURE dbo.DeleteBhpbioSummaryActualY
(
	@iSummaryMonth DATETIME,
	@iSummaryLocationId INTEGER
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'DeleteBhpbioSummaryActualY',
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
		
		-- obtain the Entry Type Id for ActualY storage
		-- this is required because the summary data for ActualY is placed in a general summary storage table
		SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
		FROM BhpbioSummaryEntryType bset
		WHERE bset.Name = 'ActualY'

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
		FROM dbo.GetBhpbioReportLocationBreakdown(@iSummaryLocationId, 1, NULL)

		-- delete existing summary actual rows as appropriate based on the provided criteria
		-- this is any data that would be regenerated if the same criterial were sent to the equivalent Summarise procedure
		DELETE bse 
		FROM dbo.BhpbioSummaryEntry bse
			INNER JOIN dbo.GetBhpbioFilteredMaterialTypes(1,null) mt
				ON mt.MaterialTypeId = bse.MaterialTypeId
		WHERE bse.SummaryId = @summaryId
			AND bse.SummaryEntryTypeId = @summaryEntryTypeId
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

GRANT EXECUTE ON dbo.DeleteBhpbioSummaryActualY TO BhpbioGenericManager
GO

/*
-- A call like this is used for F1 related summarisation of ActualY
exec dbo.DeleteBhpbioSummaryActualY
	@iSummaryMonth = '2009-11-01',
	@iLocationId = 3,
	
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.DeleteBhpbioSummaryActualY">
 <Procedure>
	Deletes a set of summary ActualY data based on supplied criteria.
	The criteria is the same as which could be sent to the corresponding SummariseBhpbioActualY procedure
	
	Pass: 
			@iSummaryMonth: the month for which summary data is to be deleted,
			@iSummaryLocationId: the location (typically a Pit) within which child locations will have data removed,
 </Procedure>
</TAG>
*/	
IF OBJECT_ID('dbo.DeleteBhpbioSummaryAdditionalHaulageRelated') IS NOT NULL
     DROP PROCEDURE dbo.DeleteBhpbioSummaryAdditionalHaulageRelated
GO 

CREATE PROCEDURE dbo.DeleteBhpbioSummaryAdditionalHaulageRelated
(
	@iSummaryMonth DATETIME,
	@iSummaryLocationId INTEGER,
	@iIsHighGrade BIT,
	@iSpecificMaterialTypeId INTEGER
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	DECLARE @summaryEntryTypeId INTEGER
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'DeleteBhpbioSummaryAdditionalHaulageRelated',
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
		FROM dbo.GetBhpbioReportLocationBreakdown(@iSummaryLocationId, 1, NULL)
		
		-- delete summary data for the related locations as appropriate based on the criteria provided
		DELETE bse
		FROM dbo.BhpbioSummaryEntry bse
			INNER JOIN dbo.GetBhpbioFilteredMaterialTypes(@iIsHighGrade,@iSpecificMaterialTypeId) mt
					ON mt.MaterialTypeId = bse.MaterialTypeId
			INNER JOIN dbo.BhpbioSummaryEntryType bset
					ON bset.SummaryEntryTypeId = bse.SummaryEntryTypeId
			INNER JOIN @Location loc
					ON loc.LocationId = bse.LocationId
		WHERE bse.SummaryId = @summaryId
			AND bset.Name IN ('BlastBlockMonthlyHauled', 'BlastBlockMonthlyBest', 'BlastBlockSurvey', 'BlastBlockCumulativeHauled', 'BlastBlockTotalGradeControl')
		
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

GRANT EXECUTE ON dbo.DeleteBhpbioSummaryAdditionalHaulageRelated TO BhpbioGenericManager
GO

/*
-- A call like this is used to delete additional haulage related data for HighGrade movements
exec dbo.DeleteBhpbioSummaryAdditionalHaulageRelated
	@iSummaryMonth = '2009-11-01',
	@@iSummaryLocationId = 3,
	@iIsHighGrade = 1,
	@iSpecificMaterialTypeId = null
	
-- A call like this is used to delete summary additional haulage related data for a specific material type
exec dbo.DeleteBhpbioSummaryAdditionalHaulageRelated
	@iSummaryMonth = '2009-11-01',
	@iLocationId = 3,
	@iIsHighGrade = null,
	@iSpecificMaterialTypeId = 6
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.DeleteBhpbioSummaryAdditionalHaulageRelated">
 <Procedure>
	Deletes summary data related to Haulage for either HighGrade movements OR for movements of a sepcific material type
	
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
 </Procedure>
</TAG>
*/
IF OBJECT_ID('dbo.DeleteBhpbioSummaryDataRelatedToApproval') IS NOT NULL
     DROP PROCEDURE dbo.DeleteBhpbioSummaryDataRelatedToApproval
GO 
  
CREATE PROCEDURE dbo.DeleteBhpbioSummaryDataRelatedToApproval
(
	@iTagId VARCHAR(31),
	@iLocationId INT,
	@iApprovalMonth DATETIME
)
WITH ENCRYPTION
AS 
BEGIN 
	SET NOCOUNT ON 
	
	DECLARE @TransactionName VARCHAR
	DECLARE @TransactionCount INTEGER
	
	SELECT @TransactionName = 'DeleteBhpbioSummaryDataRelatedToApproval',
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
	
		DECLARE @summaryEntryTypeId INTEGER
		
		-- Here we plug-in data summarisation clering steps as part of the approval
		-- based on the Tag Id supplied
		
		IF @iTagId = 'F1Factor'
		BEGIN
			-- clear summary for ActualY movements as part of the F1 process
			exec dbo.DeleteBhpbioSummaryActualY @iSummaryMonth = @iApprovalMonth, 
												@iSummaryLocationId = @iLocationId
												
			exec dbo.DeleteBhpbioSummaryAdditionalHaulageRelated	@iSummaryMonth = @iApprovalMonth, 
																	@iSummaryLocationId = @iLocationId,
																	@iIsHighGrade = 1,
																	@iSpecificMaterialTypeId = null
		END
		
		IF @iTagId = 'F1GeologyModel'
		BEGIN
			-- clear summary for  geology model movements
			exec dbo.DeleteBhpbioSummaryModelMovement	@iSummaryMonth = @iApprovalMonth, 
														@iSummaryLocationId = @iLocationId,
														@iIsHighGrade = 1,
														@iSpecificMaterialTypeId = null,
														@iModelName = 'Geology'
		END
		
		IF @iTagId = 'F1GradeControlModel'
		BEGIN
			-- clear summary for  grade control movements
			exec dbo.DeleteBhpbioSummaryModelMovement	@iSummaryMonth = @iApprovalMonth, 
														@iSummaryLocationId = @iLocationId,
														@iIsHighGrade = 1,
														@iSpecificMaterialTypeId = null,
														@iModelName = 'Grade Control'
		END
		
		IF @iTagId = 'F1MiningModel'
		BEGIN
			-- clear summary for  mining model movements
			exec dbo.DeleteBhpbioSummaryModelMovement	@iSummaryMonth = @iApprovalMonth, 
														@iSummaryLocationId = @iLocationId,
														@iIsHighGrade = 1,
														@iSpecificMaterialTypeId = null,
														@iModelName = 'Mining'
		END
		
		IF @iTagId like 'OtherMaterial%'
		BEGIN
			DECLARE @otherMaterialTypeId INTEGER
			
			SELECT @otherMaterialTypeId = rdt.OtherMaterialTypeId
			FROM dbo.BhpbioReportDataTags rdt
			WHERE rdt.TagId = @iTagId
			
			-- clear summary for movements using the 3 models
			-- for only the MaterialType related to the OtherMaterial% tag
			
			-- geology model
			exec dbo.DeleteBhpbioSummaryModelMovement	@iSummaryMonth = @iApprovalMonth, 
														@iSummaryLocationId = @iLocationId,
														@iIsHighGrade = null,
														@iSpecificMaterialTypeId = @otherMaterialTypeId,
														@iModelName = 'Geology'
			
			-- grade control model
			exec dbo.DeleteBhpbioSummaryModelMovement	@iSummaryMonth = @iApprovalMonth, 
														@iSummaryLocationId = @iLocationId,
														@iIsHighGrade = null,
														@iSpecificMaterialTypeId = @otherMaterialTypeId,
														@iModelName = 'Grade Control'

			-- mining model													
			exec dbo.DeleteBhpbioSummaryModelMovement	@iSummaryMonth = @iApprovalMonth, 
														@iSummaryLocationId = @iLocationId,
														@iIsHighGrade = null,
														@iSpecificMaterialTypeId = @otherMaterialTypeId,
														@iModelName = 'Mining'
														
			-- clear summary for Actual Other Movements to Stockpiles
			exec dbo.DeleteBhpbioSummaryOMToStockpile	@iSummaryMonth = @iApprovalMonth, 
														@iSummaryLocationId = @iLocationId,
														@iSpecificMaterialTypeId = @otherMaterialTypeId
			
			exec dbo.DeleteBhpbioSummaryAdditionalHaulageRelated	@iSummaryMonth = @iApprovalMonth, 
																	@iSummaryLocationId = @iLocationId,
																	@iIsHighGrade = null,
																	@iSpecificMaterialTypeId = @otherMaterialTypeId
		END
		
		IF @iTagId = 'F2MineProductionActuals'
		BEGIN
			-- obtain the Actual Type Id for ActualC storage
			SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
			FROM BhpbioSummaryEntryType bset
			WHERE bset.Name = 'ActualC'
		
			-- delete ActualC data for the site
			exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iApprovalMonth, 
												@iSummaryLocationId = @iLocationId,
												@iSummaryEntryTypeId = @summaryEntryTypeId
												
			SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
			FROM BhpbioSummaryEntryType bset
			WHERE bset.Name = 'ActualCSampleTonnes'
		
			-- delete ActualC data for the site
			exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iApprovalMonth, 
												@iSummaryLocationId = @iLocationId,
												@iSummaryEntryTypeId = @summaryEntryTypeId
			
			-- delete Bene Feed data									
			SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
			FROM BhpbioSummaryEntryType bset
			WHERE bset.Name = 'ActualBeneFeed'
		
			-- delete ActualC data for the site
			exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iApprovalMonth, 
												@iSummaryLocationId = @iLocationId,
												@iSummaryEntryTypeId = @summaryEntryTypeId
		END
		
		IF @iTagId = 'F2StockpileToCrusher'
		BEGIN
			-- obtain the Actual Type Id for ActualC storage
			SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
			FROM BhpbioSummaryEntryType bset
			WHERE bset.Name = 'ActualZ'
			
			-- delete ActualZ data for the site
			exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iApprovalMonth, 
												@iSummaryLocationId = @iLocationId,
												@iSummaryEntryTypeId = @summaryEntryTypeId
		END
		
		IF @iTagId = 'F3PostCrusherStockpileDelta'
		BEGIN
			-- summarise SitePostCrusherStockpileDelta data
			SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
			FROM BhpbioSummaryEntryType bset
			WHERE bset.Name = 'HubPostCrusherStockpileDelta'
			
			-- for Hub crushers
			exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iApprovalMonth, 
												@iSummaryLocationId = @iLocationId,
												@iSummaryEntryTypeId = @summaryEntryTypeId
			
			SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
			FROM BhpbioSummaryEntryType bset
			WHERE bset.Name = 'SitePostCrusherStockpileDelta'
			
			-- and Site crushers												  
			exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iApprovalMonth, 
												@iSummaryLocationId = @iLocationId,
												@iSummaryEntryTypeId = @summaryEntryTypeId
												
			SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
			FROM BhpbioSummaryEntryType bset
			WHERE bset.Name = 'HubPostCrusherSpDeltaGrades'
			
			-- Grades for Hub crushers
			exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iApprovalMonth, 
												@iSummaryLocationId = @iLocationId,
												@iSummaryEntryTypeId = @summaryEntryTypeId
			
			SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
			FROM BhpbioSummaryEntryType bset
			WHERE bset.Name = 'SitePostCrusherSpDeltaGrades'
			
			-- and Site crushers												  
			exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iApprovalMonth, 
												@iSummaryLocationId = @iLocationId,
												@iSummaryEntryTypeId = @summaryEntryTypeId
		END
		
		IF @iTagId = 'F3PortStockpileDelta'
		BEGIN
			SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
			FROM BhpbioSummaryEntryType bset
			WHERE bset.Name = 'PortStockpileDelta'
			
			exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iApprovalMonth, 
												@iSummaryLocationId = @iLocationId,
												@iSummaryEntryTypeId = @summaryEntryTypeId
		END
		
		IF @iTagId = 'F3PortBlendedAdjustment'
		BEGIN
			SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
			FROM BhpbioSummaryEntryType bset
			WHERE bset.Name = 'PortBlending'
			
			exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iApprovalMonth, 
												@iSummaryLocationId = @iLocationId,
												@iSummaryEntryTypeId = @summaryEntryTypeId
		END
		
		IF @iTagId = 'F3OreShipped'
		BEGIN
			SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
			FROM BhpbioSummaryEntryType bset
			WHERE bset.Name = 'ShippingTransaction'
			
			exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iApprovalMonth, 
												@iSummaryLocationId = @iLocationId,
												@iSummaryEntryTypeId = @summaryEntryTypeId
		END
		
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

GRANT EXECUTE ON dbo.DeleteBhpbioSummaryDataRelatedToApproval TO BhpbioGenericManager
GO

/*
exec dbo.DeleteBhpbioSummaryDataRelatedToApproval
	@iTagId = 'F2Factor',
	@iLocationId = 3,
	@iApprovalMonth = '2009-11-01'
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.DeleteBhpbioSummaryDataRelatedToApproval">
 <Procedure>
	Deletes a set of summary data based on supplied criteria.
	The criteria used is the same that would be passed to the corresponding UnApproval call
	
	Pass: 
			@iTagId: indicates the type of approval to remove summary information for
			@iLocationId: indicates a location related to the removal operation (for F1 approvals this would be a Pit and so on)
			@iApprovalMonth: the approval month to remove summary data for
							
 </Procedure>
</TAG>
*/	
IF OBJECT_ID('dbo.DeleteBhpbioSummaryEntry') IS NOT NULL
     DROP PROCEDURE dbo.DeleteBhpbioSummaryEntry 
GO 
    
CREATE PROCEDURE dbo.DeleteBhpbioSummaryEntry
(
	@iSummaryMonth DATETIME,
	@iSummaryLocationId INTEGER,
	@iSummaryEntryTypeId INTEGER
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'DeleteBhpbioSummaryEntry',
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
		
		-- get the start of month (and start of the next month) based on the provided DateTime
		SELECT @startOfMonth = dbo.GetDateMonth(@iSummaryMonth)

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
		FROM dbo.GetBhpbioReportLocationBreakdown(@iSummaryLocationId, 1, NULL)
		UNION 
		SELECT l.Location_Id, l.Parent_Location_Id
		FROM Location l
		WHERE l.Location_Id = @iSummaryLocationId
		
		-- delete existing summary entry rows as appropriate based on the provided criteria
		DELETE bse 
		FROM dbo.BhpbioSummaryEntry bse
		WHERE bse.SummaryId = @summaryId
			AND bse.SummaryEntryTypeId = @iSummaryEntryTypeId
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

GRANT EXECUTE ON dbo.DeleteBhpbioSummaryEntry TO BhpbioGenericManager
GO

/*
exec dbo.DeleteBhpbioSummaryEntry
	@iSummaryMonth = '2009-11-01',
	@iLocationId = 3,
	@iEntryTypeId = 1
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.DeleteBhpbioSummaryEntry">
 <Procedure>
	Deletes a set of summary data based on supplied criteria.
	
	Pass: 
			@iSummaryMonth: the month for which summary data is to be deleted,
			@iSummaryLocationId: the location within which child locations will have data removed
			@iSummaryEntryTypeId: the type of summary data to remove
			
 </Procedure>
</TAG>
*/	
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
		FROM dbo.GetBhpbioReportLocationBreakdown(@iSummaryLocationId, 1, NULL)
		
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
IF OBJECT_ID('dbo.DeleteBhpbioSummaryOMToStockpile') IS NOT NULL
     DROP PROCEDURE dbo.DeleteBhpbioSummaryOMToStockpile
GO 
    
CREATE PROCEDURE dbo.DeleteBhpbioSummaryOMToStockpile
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

	SELECT @TransactionName = 'DeleteBhpbioSummaryOMToStockpile',
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
		-- this is required because the summary data for ActualY is placed in a general summary storage table
		SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
		FROM dbo.BhpbioSummaryEntryType bset
		WHERE bset.Name = 'ActualOMToStockpile'

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
		FROM dbo.GetBhpbioReportLocationBreakdown(@iSummaryLocationId, 1, NULL)

		-- delete existing summary actual rows as appropriate based on the provided criteria
		-- this is any data that would be regenerated if the same criterial were sent to the equivalent Summarise procedure
		DELETE bse 
		FROM dbo.BhpbioSummaryEntry bse
			INNER JOIN dbo.GetBhpbioFilteredMaterialTypes(null,@iSpecificMaterialTypeId) mt
				ON mt.MaterialTypeId = bse.MaterialTypeId
		WHERE bse.SummaryId = @summaryId
			AND bse.SummaryEntryTypeId = @summaryEntryTypeId
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

GRANT EXECUTE ON dbo.DeleteBhpbioSummaryOMToStockpile TO BhpbioGenericManager
GO

/*
	
-- A call like this is used for Other Movements related summarisation for a particular material type
exec dbo.DeleteBhpbioSummaryOMToStockpile
	@iSummaryMonth = '2009-11-01',
	@iLocationId = 3,
	@iSpecificMaterialTypeId = 6
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.DeleteBhpbioSummaryOMToStockpile">
 <Procedure>
	Deletes a set of Actual Other Movements to Stockpile data based on supplied criteria.
	The criteria is the same as which could be sent to the corresponding SummariseBhpbioOMToStockpile procedure
	
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
IF OBJECT_ID('dbo.GetBhpbioApprovalDigblockList') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioApprovalDigblockList  
GO 
  
CREATE PROCEDURE dbo.GetBhpbioApprovalDigblockList
(
	@iLocationId INT,
	@iMonthFilter DATETIME,
	@iRecordLimit INT
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @LocationId INT
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	DECLARE @MonthDate DATETIME
	DECLARE @EndMonthDate DATETIME
	DECLARE @HauledFieldId VARCHAR(31)
	DECLARE @SurveyedFieldId VARCHAR(31)
	
	-- Create a table used to store Live Results
	DECLARE @LiveResults TABLE
	(
		DigblockId VARCHAR(31) COLLATE DATABASE_DEFAULT NULL,
		MaterialTypeId INTEGER,
		MiningTonnes FLOAT NULL,
		GeologyTonnes FLOAT NULL,
		GradeControlTonnes FLOAT NULL,
		HauledTonnes FLOAT NULL,
		SurveyedTonnes FLOAT NULL,
		BestTonnes FLOAT NULL,
		RemainingTonnes FLOAT NULL
	)
	
	-- Create a table used to store Approved Results
	DECLARE @ApprovedResults TABLE
	(
		DigblockId VARCHAR(31) COLLATE DATABASE_DEFAULT NULL,
		MaterialTypeId INTEGER,
		MiningTonnes FLOAT NULL,
		GeologyTonnes FLOAT NULL,
		GradeControlTonnes FLOAT NULL,
		HauledTonnes FLOAT NULL,
		SurveyedTonnes FLOAT NULL,
		BestTonnes FLOAT NULL,
		RemainingTonnes FLOAT NULL
	)
	
	-- Create a table used to store Distinct Digblock Ids
	DECLARE @DistinctDigblocks TABLE
	(
		DigblockId VARCHAR(31) COLLATE DATABASE_DEFAULT NULL
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioApprovalDigblockList',
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
		-- Get Live Data Results
		INSERT INTO @LiveResults
			(
				DigblockId, MaterialTypeId, MiningTonnes, GeologyTonnes, GradeControlTonnes, HauledTonnes,
				SurveyedTonnes, BestTonnes, RemainingTonnes
			)
		EXEC dbo.GetBhpbioApprovalDigblockListLiveData @iLocationId = @iLocationId,
														@iMonthFilter = @iMonthFilter,
														@iRecordLimit = @iRecordLimit
															
		-- Get Approved Data Results
		INSERT INTO @ApprovedResults
			(
				DigblockId, MaterialTypeId, MiningTonnes, GeologyTonnes, GradeControlTonnes, HauledTonnes,
				SurveyedTonnes, BestTonnes, RemainingTonnes
			)
		EXEC dbo.GetBhpbioApprovalDigblockListApprovedData @iLocationId = @iLocationId,
															@iMonthFilter = @iMonthFilter

		-- determine the distinct set of digblocks	
		INSERT INTO @DistinctDigblocks
		SELECT DISTINCT merged.DigblockId
		FROM (
				SELECT lr.DigblockId 
				FROM @LiveResults lr
				UNION
				SELECT ar.DigblockId 
				FROM @ApprovedResults ar
			) as merged
			
	
		-- Return the Results
		IF @iRecordLimit IS NOT NULL
		BEGIN
			SET ROWCOUNT @iRecordLimit
		END
		
		SELECT dd.DigblockId,
				CASE WHEN a.DigblockId IS NOT NULL THEN 1 ELSE 0 END AS Approved,
				CASE 
					WHEN u.UserId IS NOT NULL THEN u.FirstName + ' ' + u.LastName
					WHEN u.UserId IS NULL AND a.UserId IS NOT NULL THEN 'Unknown User'
					ELSE ''
				END AS SignoffUser,
			   mt.Description as MaterialTypeDescription,
			   COALESCE(ar.MiningTonnes, lr.MiningTonnes) as MiningTonnes,
			   COALESCE(ar.GeologyTonnes, lr.GeologyTonnes) as GeologyTonnes,
			   COALESCE(ar.GradeControlTonnes, lr.GradeControlTonnes) as GradeControlTonnes,
			   COALESCE(ar.HauledTonnes, lr.HauledTonnes) as HauledTonnes,
			   COALESCE(ar.SurveyedTonnes, lr.SurveyedTonnes) as SurveyedTonnes,
			   COALESCE(ar.BestTonnes, lr.BestTonnes) as BestTonnes,
			   COALESCE(ar.RemainingTonnes, lr.RemainingTonnes) as RemainingTonnes
		FROM @DistinctDigblocks dd
			INNER JOIN Digblock d
				ON d.Digblock_Id = dd.DigblockId
			INNER JOIN dbo.MaterialType mt
				ON mt.Material_Type_Id = d.Material_Type_Id
			LEFT JOIN @LiveResults lr 
				ON lr.DigblockId = dd.DigblockId
			LEFT JOIN @ApprovedResults ar
				ON ar.DigblockId = dd.DigblockId
			LEFT JOIN dbo.BhpbioApprovalDigblock a
				ON a.DigblockID = dd.DigblockId
				AND a.ApprovedMonth = @iMonthFilter
			LEFT JOIN dbo.SecurityUser u
				ON u.UserId = a.UserId
		ORDER BY 1, 2
		
		IF @iRecordLimit IS NOT NULL
		BEGIN
			SET ROWCOUNT 0
		END

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

GRANT EXECUTE ON dbo.GetBhpbioApprovalDigblockList TO BhpbioGenericManager
GO

--EXEC dbo.GetBhpbioApprovalDigblockList  4, '1-SEP-2008', NULL

/*
<TAG Name="Data Dictionary" FunctionName="dbo.GetBhpbioApprovalDigblockList">
 <Function>
	Retrieves a set of digblock listing data based on Live AND Approved Summary data.
	Note: This is done by calling the dbo.GetBhpbioApprovalDigblockListLive and dbo.GetBhpbioApprovalDigblockListApproved procedures respectively
			
	Pass: 
			@iLocationId : Identifies the Location within which to select digblocks
			@iMonthFilter: The month to return data for
			@iRecordLimit: An optional Record Limit
	
	Returns: Set of digblock approval data
 </Function>
</TAG>
*/	


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
		
		EXEC dbo.GetBhpbioSummaryIdForMonth @iSummaryMonth = @startOfMonth,
											@oSummaryId = @summaryId OUTPUT
		
		INSERT INTO @Location
		SELECT LocationId
		FROM dbo.GetBhpbioReportLocation(@iLocationId)
		
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

IF OBJECT_ID('dbo.GetBhpbioApprovalDigblockListLiveData') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioApprovalDigblockListLiveData
GO 
  
CREATE PROCEDURE dbo.GetBhpbioApprovalDigblockListLiveData
(
	@iLocationId INT,
	@iMonthFilter DATETIME,
	@iRecordLimit INT
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @LocationId INT
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	DECLARE @MonthDate DATETIME
	DECLARE @EndMonthDate DATETIME
	DECLARE @HauledFieldId VARCHAR(31)
	DECLARE @SurveyedFieldId VARCHAR(31)
	
	DECLARE @Results TABLE
	(
		DigblockId VARCHAR(31) COLLATE DATABASE_DEFAULT NULL,
		MaterialTypeId INTEGER,
		ApprovalMonth DATETIME NULL,
		MiningTonnes FLOAT NULL,
		GeologyTonnes FLOAT NULL,
		GradeControlTonnes FLOAT NULL,
		HauledTonnes FLOAT NULL,
		SurveyedTonnes FLOAT NULL,
		BestTonnes FLOAT NULL,
		CorrectedTonnes FLOAT NULL,
		RemainingTonnes FLOAT NULL,
		MinedPercent FLOAT NULL,
		BlockLocationId INT NULL
	)
	
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		PRIMARY KEY (LocationId)
	)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioApprovalDigblockListLiveData',
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
		DECLARE @MaterialCategory VARCHAR(31)
		SET @MaterialCategory = 'Designation'
		
		SET @HauledFieldId = 'HauledTonnes'
		SET @SurveyedFieldId = 'GroundSurveyTonnes'
		SET @MonthDate = dbo.GetDateMonth(@iMonthFilter)
		SET @EndMonthDate = DateAdd(Day, -1, DateAdd(Month, 1, @MonthDate))

		INSERT INTO @Location
		SELECT LocationId
		FROM dbo.GetBhpbioReportLocation(@iLocationId)
		
		SET @LocationId = @iLocationId
		IF @LocationId IS NOT NULL AND @LocationId < 0
		BEGIN
			SET @LocationId = NULL
		END
		
		-- Insert the inital data of a digblock id, and any approvals including the sign off person.
		INSERT INTO @Results
			(
				DigblockId, ApprovalMonth, MinedPercent, BlockLocationId, 
				CorrectedTonnes, BestTonnes, HauledTonnes, SurveyedTonnes, RemainingTonnes, 
				MaterialTypeId
			)
		SELECT d.Digblock_Id, 
			@iMonthFilter,
			RM.MinedPercentage, 
			DL.Location_Id,
			processed.Corrected,
			field.Best,
			field.Hauled,
			field.Survey,
			-cumlative.Best,
			D.Material_Type_Id
		FROM dbo.Digblock AS D
			INNER JOIN dbo.DigblockLocation AS DL
				ON (D.Digblock_Id = DL.Digblock_Id)
			INNER JOIN @Location AS L
				ON (L.LocationId = DL.Location_Id)
			LEFT JOIN dbo.BhpbioImportReconciliationMovement AS RM
				ON (RM.DateFrom >= @MonthDate
					AND RM.DateTo <= @EndMonthDate
					AND DL.Location_Id = RM.BlockLocationId)
			LEFT JOIN
				(
					SELECT DPT.Source_Digblock_Id As DigblockId,
						Coalesce(Sum(DPT.Tonnes), 0) As Corrected
					FROM dbo.DataProcessTransaction AS DPT
					WHERE DPT.Data_Process_Transaction_Date BETWEEN @MonthDate AND @EndMonthDate
					GROUP BY DPT.Source_Digblock_Id
				) AS processed
					ON D.Digblock_Id = processed.DigblockId
			LEFT JOIN
				(
					SELECT h.Source_Digblock_Id As DigblockId,
						Coalesce(Sum(h.Tonnes), 0) As Best,
						Coalesce(Sum(hauled.Field_Value), 0) As Hauled,
						Coalesce(Sum(survey.Field_Value), 0) As Survey
					FROM dbo.Haulage AS h
						LEFT JOIN dbo.HaulageValue AS hauled
							ON h.Haulage_Id = hauled.Haulage_Id
								AND hauled.Haulage_Field_Id = @HauledFieldId
						LEFT JOIN dbo.HaulageValue AS survey
							ON h.Haulage_Id = survey.Haulage_Id
								AND survey.Haulage_Field_Id = @SurveyedFieldId
					WHERE h.Haulage_Date BETWEEN @MonthDate AND @EndMonthDate
						AND h.Haulage_State_Id IN ('N', 'A')
						AND h.Child_Haulage_Id IS NULL
					GROUP BY h.Source_Digblock_Id	
				) AS field
					ON D.Digblock_Id = field.DigblockId
			LEFT JOIN
				(
					SELECT h.Source_Digblock_Id As DigblockId,
						Coalesce(Sum(h.Tonnes), 0) As Best
					FROM dbo.Haulage AS h
					WHERE h.Haulage_Date <= @EndMonthDate
						AND h.Haulage_State_Id IN ('N', 'A')
						AND h.Child_Haulage_Id IS NULL
					GROUP BY h.Source_Digblock_Id	
				) AS cumlative
					ON D.Digblock_Id = cumlative.DigblockId
		WHERE RM.MinedPercentage IS NOT NULL 
			OR field.Survey IS NOT NULL 
			OR field.Hauled IS NOT NULL 
			OR field.Best IS NOT NULL
			OR processed.Corrected IS NOT NULL

		-- Get the haulage and moved block tonnes
		UPDATE r
		SET MiningTonnes = model.Mining * r.MinedPercent,
			GradeControlTonnes = model.GradeControl * r.MinedPercent,
			GeologyTonnes = model.Geology * r.MinedPercent,
			RemainingTonnes = model.GradeControl + RemainingTonnes
		FROM @Results AS r
			LEFT JOIN 
				(
					SELECT r.DigblockId,
						Sum(CASE WHEN BM.Name = 'Mining' THEN MBP.Tonnes ELSE NULL END) AS Mining,
						Sum(CASE WHEN BM.Name = 'Grade Control' THEN MBP.Tonnes ELSE NULL END) As GradeControl,
						Sum(CASE WHEN BM.Name = 'Geology' THEN MBP.Tonnes ELSE NULL END) As Geology
					FROM @Results AS R
						INNER JOIN dbo.ModelBlockLocation AS MBL
							ON (R.BlockLocationId = MBL.Location_Id)
						INNER JOIN dbo.ModelBlock AS MB
							ON (MBL.Model_Block_Id = MB.Model_Block_Id)
						INNER JOIN dbo.BlockModel AS BM
							ON (BM.Block_Model_Id = MB.Block_Model_Id)
						INNER JOIN dbo.ModelBlockPartial AS MBP
							ON (MB.Model_Block_Id = MBP.Model_Block_Id)
						INNER JOIN dbo.GetMaterialsByCategory(@MaterialCategory) AS MC
							ON (MC.MaterialTypeId = MBP.Material_Type_Id)
						INNER JOIN dbo.MaterialType AS MT
							ON (MC.RootMaterialTypeId = MT.Material_Type_Id)
						--INNER JOIN dbo.GetBhpbioReportHighGrade() AS BRHG
						--	ON (BRHG.MaterialTypeId = MT.Material_Type_Id)
					GROUP BY R.DigblockId
				) AS model
					ON r.DigblockId = model.DigblockId

		IF @iRecordLimit IS NOT NULL
		BEGIN
			SET ROWCOUNT @iRecordLimit
		END
		
		-- Return the results					
		SELECT DigblockId, MaterialTypeId, MiningTonnes, GeologyTonnes, GradeControlTonnes, HauledTonnes,
				SurveyedTonnes, BestTonnes, RemainingTonnes
		FROM @Results
		ORDER BY DigblockId

		IF @iRecordLimit IS NOT NULL
		BEGIN
			SET ROWCOUNT 0
		END

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

GRANT EXECUTE ON dbo.GetBhpbioApprovalDigblockListLiveData TO BhpbioGenericManager
GO

--EXEC dbo.GetBhpbioApprovalDigblockListLiveData  4, '1-SEP-2008', NULL

--EXEC dbo.GetBhpbioApprovalDigblockListLiveData  4, '1-SEP-2008', NULL

/*
<TAG Name="Data Dictionary" FunctionName="dbo.GetBhpbioApprovalDigblockListLiveData">
 <Function>
	Retrieves a set of digblock approval listing data based on Live data only.
	Note: This is combined with Approved Summary results by the dbo.GetBhpbioApprovalDigblockList procedure
			
	Pass: 
			@iLocationId : Identifies the Location within which to select digblocks
			@iMonthFilter: The month to return data for
			@iRecordLimit: An optional Record Limit
	
	Returns: Set of digblock approval data
 </Function>
</TAG>
*/	
IF OBJECT_ID('dbo.GetBhpbioApprovalOtherMaterial') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioApprovalOtherMaterial  
GO 
  
CREATE PROCEDURE dbo.GetBhpbioApprovalOtherMaterial 
(
	@iMonthFilter DATETIME,
	@iLocationId INT,
	@iChildLocations BIT
)
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	
	DECLARE @ActualId INT
	SET @ActualId = 88
	DECLARE @ActualName VARCHAR(40)
	SET @ActualName = 'Actual'

	DECLARE @BlockModelXml VARCHAR(500)
	SET @BlockModelXml = ''
	
	DECLARE @MaterialCategoryId VARCHAR(31)
	SET @MaterialCategoryId = 'Designation'
	
	DECLARE @DateFrom DATETIME
	DECLARE @DateTo DATETIME
	SET @DateFrom = dbo.GetDateMonth(@iMonthFilter)
	SET @DateTo = DateAdd(Day, -1, DateAdd(Month, 1, @DateFrom))
		

	DECLARE @Tonnes TABLE
	(
		Type VARCHAR(255) COLLATE DATABASE_DEFAULT NOT NULL,
		LocationId INT NOT NULL,
		BlockModelId INT NULL,
		CalendarDate DATETIME NOT NULL,
		Material VARCHAR(65) COLLATE DATABASE_DEFAULT NULL,
		MaterialTypeId INT NOT NULL,
		Tonnes FLOAT,
		PRIMARY KEY CLUSTERED (CalendarDate, MaterialTypeId, Type, LocationId)
	)
	
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		ParentLocationId INT NULL,
		LocationType VARCHAR(255) NOT NULL,
		LocationName VARCHAR(31) NOT NULL,
		PRIMARY KEY (LocationId)
	)
	
		
	DECLARE @MaterialType TABLE
	(
		RootMaterialTypeId INT NOT NULL,
		RootAbbreviation VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialTypeId INT NOT NULL,
		PRIMARY KEY CLUSTERED (MaterialTypeId, RootMaterialTypeId)
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioApprovalOtherMaterial',
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
		-- Create Pivot Tables
		CREATE TABLE dbo.#Record
		(
			TagId VARCHAR(65) COLLATE DATABASE_DEFAULT NULL,
			LocationId INT NOT NULL,
			LocationType VARCHAR(255) NOT NULL,
			LocationName VARCHAR(31) NOT NULL,
			MaterialTypeId INT NULL,
			MaterialName VARCHAR(65) COLLATE DATABASE_DEFAULT NOT NULL,
			OrderNo INT NOT NULL,
			ParentMaterialTypeId INT NULL,
			Approved BIT NULL,
			SignOff VARCHAR(65) COLLATE DATABASE_DEFAULT NULL,
			PRIMARY KEY (MaterialName, LocationId)
		)

		CREATE TABLE dbo.#RecordTonnes
		(
			MaterialTypeId INT NULL,
			LocationId INT NOT NULL,
			MaterialName VARCHAR(65) COLLATE DATABASE_DEFAULT NULL,
			ModelName VARCHAR(500) COLLATE DATABASE_DEFAULT NULL,
			Tonnes FLOAT NULL,
			OrderNo INT NULL,
			RootNode INT NULL
		)
		
		-- load the material data
		INSERT INTO @MaterialType
			(RootMaterialTypeId, RootAbbreviation, MaterialTypeId)
		SELECT mc.RootMaterialTypeId, mt.Abbreviation, mc.MaterialTypeId
		FROM dbo.GetMaterialsByCategory('Designation') AS mc
			INNER JOIN dbo.MaterialType AS mt
				ON (mc.RootMaterialTypeId = mt.Material_Type_Id)
		WHERE mc.RootMaterialTypeId = mc.RootMaterialTypeId
		
		-- setup the Locations
		INSERT INTO @Location
			(LocationId, ParentLocationId, LocationName, LocationType)
		SELECT L.Location_Id, L.Parent_Location_Id, L.Name, LT.Description
		FROM dbo.Location AS L
			INNER JOIN dbo.LocationType as LT
				ON L.Location_Type_Id = LT.Location_Type_Id
		WHERE (@iChildLocations = 0 AND Location_Id = @iLocationId)
			OR (@iChildLocations = 1 AND Parent_Location_Id = @iLocationId)
		
		-- Taken from dbo.GetBhpbioReportBaseDataAsTonnes so children can be collected
		INSERT INTO @Tonnes
			(Type, CalendarDate, MaterialTypeId, Tonnes, LocationId)
		SELECT 'Actual', sub.CalendarDate, mc.RootMaterialTypeId, SUM(Coalesce(Tonnes, 0.0)), 
			CASE WHEN @iChildLocations = 0 THEN @iLocationId ELSE LocationId END AS LocationId
			FROM
				(	-- C - z + y
					-- '+C' - all crusher removals
					SELECT CalendarDate, DesignationMaterialTypeId, SUM(Value) AS Tonnes, LocationId
					FROM dbo.GetBhpbioReportActualC(@DateFrom, @DateTo, NULL, @iLocationId, @iChildLocations, 1, 1)
					WHERE Attribute = 0
					GROUP BY CalendarDate, DesignationMaterialTypeId, LocationId
					UNION ALL
					-- '-z' - pre crusher stockpiles to crusher
					SELECT CalendarDate, DesignationMaterialTypeId, -SUM(Value) AS Tonnes, LocationId
					FROM dbo.GetBhpbioReportActualZ(@DateFrom, @DateTo, NULL, @iLocationId, @iChildLocations, 1, 1)
					WHERE Attribute = 0
					GROUP BY CalendarDate, DesignationMaterialTypeId, LocationId
					UNION ALL
					-- '+y' - pit to pre-crusher stockpiles
					SELECT CalendarDate, DesignationMaterialTypeId, SUM(Value), LocationId
					FROM dbo.GetBhpbioReportActualY(@DateFrom, @DateTo, NULL, @iLocationId, @iChildLocations, 1, 1)
					WHERE Attribute = 0
					GROUP BY CalendarDate, DesignationMaterialTypeId, LocationId
				) AS sub
				INNER JOIN @MaterialType AS mc
					ON (mc.MaterialTypeId = sub.DesignationMaterialTypeId)
			GROUP BY sub.CalendarDate, mc.RootMaterialTypeId, CASE WHEN @iChildLocations = 0 THEN @iLocationId ELSE LocationId END

		-- Taken from dbo.GetBhpbioReportBaseDataAsTonnes so children can be collected
		INSERT INTO @Tonnes
			(Type, BlockModelId, CalendarDate, MaterialTypeId, Tonnes, LocationId)
		SELECT bm.Name, bm.Block_Model_Id, m.CalendarDate, mc.RootMaterialTypeId, SUM(m.Value),
			CASE WHEN @iChildLocations = 0 THEN @iLocationId ELSE LocationId END AS LocationId
		FROM dbo.GetBhpbioReportModel(@DateFrom, @DateTo, NULL, @iLocationId, @iChildLocations, 1, 1) AS m
			INNER JOIN dbo.BlockModel AS bm
				ON (m.BlockModelId = bm.Block_Model_Id)
			INNER JOIN @MaterialType AS mc
				ON (mc.MaterialTypeId = m.DesignationMaterialTypeId)
		WHERE m.Attribute = 0
		GROUP BY bm.Name, bm.Block_Model_Id, m.CalendarDate, mc.RootMaterialTypeId, CASE WHEN @iChildLocations = 0 THEN @iLocationId ELSE LocationId END

		-- Modified version from dbo.GetBhpbioReportBaseDataAsTonnes so children can be collected
		-- Put the block model tonnes in.
		INSERT INTO dbo.#RecordTonnes
			(MaterialName, ModelName, Tonnes, LocationId, OrderNo)
		SELECT mt.RootAbbreviation AS Material, t.Type, r.Tonnes, r.LocationId, Coalesce(T.BlockModelId, @ActualId)
		-- Get all types
		FROM ( SELECT DISTINCT t2.Type, t2.BlockModelId FROM @Tonnes as t2) AS t
		-- Cross joined with all material types
			CROSS JOIN
				(
					SELECT DISTINCT mt2.RootMaterialTypeId, mt2.RootAbbreviation, mt2.MaterialTypeId
					FROM @MaterialType AS mt2
						INNER JOIN @Tonnes AS r2
							ON (r2.MaterialTypeId = mt2.MaterialTypeId)
				) AS mt
		-- Joined on tonnes
		INNER JOIN @Tonnes AS r
			ON (r.MaterialTypeId = mt.MaterialTypeId
				AND r.Type = t.Type)
		WHERE mt.RootAbbreviation NOT IN (SELECT Description FROM dbo.GetBhpbioReportHighGrade()) 
			AND mt.RootAbbreviation IS NOT NULL

		-- Add up the total ore and total waste.
		INSERT INTO dbo.#RecordTonnes
			(MaterialTypeId, MaterialName, ModelName, Tonnes, LocationId, OrderNo, RootNode)
		SELECT CMT.Parent_Material_Type_Id, 'Total ' + MT.Description, 
			ModelName, Sum(Tonnes), RT.LocationId, RT.OrderNo, CMT.Parent_Material_Type_Id
		FROM dbo.#RecordTonnes AS RT
			INNER JOIN dbo.MaterialType AS CMT
				ON RT.MaterialName = CMT.Description
					AND CMT.Material_Category_Id = @MaterialCategoryId
			INNER JOIN dbo.MaterialType AS MT
				ON CMT.Parent_Material_Type_Id = MT.Material_Type_Id
		WHERE CMT.Parent_Material_Type_Id IS NOT NULL
		GROUP BY ModelName, CMT.Parent_Material_Type_Id, MT.Description, RT.OrderNo, RT.LocationId

		-- Insert the required unpivoted rows based on the rows.
		INSERT INTO dbo.#Record
			(TagId, MaterialTypeId, MaterialName, OrderNo, ParentMaterialTypeId, LocationId, LocationName, LocationType)
		SELECT 
			CASE WHEN Parent_Material_Type_Id IS NULL THEN 
				NULL 
			ELSE 
				'OtherMaterial_' + REPLACE(MT.Description, ' ', '_')
			END,
			Coalesce(Material_Type_Id, RT.MaterialTypeId), 
			CASE WHEN Parent_Material_Type_Id IS NULL THEN 
				'Total ' + MT.Description
			ELSE 
				MT.Description
			END,
			CASE WHEN Parent_Material_Type_Id IS NULL THEN 
				((MT.Material_Type_Id * 2) + 1) * 100
			ELSE 
				Coalesce(Parent_Material_Type_Id*2, RootNode*2 + 1) * 100 + Coalesce(Material_Type_Id, 0)
			END,
			Parent_Material_Type_Id, L.LocationId, L.LocationName, L.LocationType
		FROM dbo.MaterialType AS MT
			CROSS JOIN @Location AS L
			LEFT JOIN dbo.#RecordTonnes AS RT
				ON (MT.Material_Type_Id = RT.MaterialTypeId
					AND L.LocationId = RT.LocationId)
		WHERE MT.Material_Category_Id IN ('Designation', 'Classification')
			AND MT.Description NOT IN (SELECT Description FROM dbo.GetBhpbioReportHighGrade()) 
		GROUP BY Material_Type_Id, RT.MaterialName, MT.Description, Material_Type_Id, RT.MaterialTypeId, RootNode, 
			Parent_Material_Type_Id, L.LocationId, L.LocationName, L.LocationType

		-- Ensure all models/actual column show up.
		INSERT INTO dbo.#RecordTonnes
			(LocationId, ModelName, OrderNo)
		SELECT -1, Name, Block_Model_Id
		FROM dbo.BlockModel
		UNION
		SELECT -1, @ActualName, @ActualId
		
		
		-- Ensure all models/actual column values are not null.
		INSERT INTO dbo.#RecordTonnes
			(ModelName, LocationId, MaterialName, Tonnes, OrderNo)
		SELECT STUB.ModelName, L.LocationId, MT.MaterialName, 0, STUB.OrderNo--MUST INSERT SAME ORDER NO HERE
		--SELECT STUB.ModelName, RT.ModelName, L.LocationId, RT.LocationId, MT.MaterialName, RT.MaterialName, RT.*
		FROM (SELECT DISTINCT ModelName, OrderNo FROM dbo.#RecordTonnes WHERE MaterialName IS NULL) AS STUB
		CROSS JOIN @Location AS L
		CROSS JOIN (SELECT DISTINCT MaterialName FROM dbo.#Record) AS MT
		LEFT JOIN dbo.#RecordTonnes AS RT
			ON (RT.LocationId = L.LocationId
				AND RT.ModelName = STUB.ModelName
				AND RT.MaterialName = MT.MaterialName)
		WHERE RT.LocationId IS NULL
		--	and RT.ModelName = 'Grade Control'
		--	and RT.materialname = 'Pyritic Waste'
		order by L.LocationId
		
		
		-- Display zeros when a value is not present.
		UPDATE dbo.#RecordTonnes
		SET Tonnes = 0
		WHERE Tonnes IS NULL
		
				
		-- Pivot the blockmodel/actual tonnes into the material types
		EXEC dbo.PivotTable
			@iTargetTable = '#Record',
			@iPivotTable = '#RecordTonnes',
			@iJoinColumns = '#Record.MaterialName = #RecordTonnes.MaterialName AND #Record.LocationId = #RecordTonnes.LocationId',
			@iPivotColumn = 'ModelName',
			@iPivotValue = 'Tonnes',
			@iPivotType = 'FLOAT',
			@iPivotOrderColumn = 'OrderNo'
		
		SELECT TagId,
				LocationId,
				LocationType,
				LocationName,
				MaterialTypeId,
				MaterialName,
				OrderNo,
				ParentMaterialTypeId,
				Approved,
				SignOff,
				Geology,
				Mining,
				[Grade Control],
				Actual
		FROM dbo.#Record
		ORDER BY LocationName, OrderNo
		
		DROP TABLE dbo.#Record
		DROP TABLE dbo.#RecordTonnes

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

GRANT EXECUTE ON dbo.GetBhpbioApprovalOtherMaterial TO BhpbioGenericManager
GO

--exec dbo.GetBhpbioApprovalOtherMaterial '1-nov-2009', 8, 1
IF Object_Id('dbo.GetBhpbioGradeRecoveryReport') IS NOT NULL
	DROP PROCEDURE dbo.GetBhpbioGradeRecoveryReport
GO

CREATE PROCEDURE dbo.GetBhpbioGradeRecoveryReport
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iLocationId INT,
	@iIncludeBlockModels BIT,
	@iBlockModels XML,
	@iIncludeActuals BIT,
	@iDesignationMaterialTypeId	INT,
	@iTonnes BIT,
	@iGrades XML,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT
)
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @Tonnes TABLE
	(
		Type VARCHAR(255) COLLATE DATABASE_DEFAULT NOT NULL,
		BlockModelId INT NULL,
		CalendarDate DATETIME NOT NULL,
		Material VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialTypeId INT NOT NULL,
		Tonnes FLOAT,
		PRIMARY KEY CLUSTERED (CalendarDate, Material, Type)
	)

	DECLARE @Grade TABLE
	(
		Type VARCHAR(255) COLLATE DATABASE_DEFAULT NOT NULL,
		BlockModelId INT NULL,
		CalendarDate DATETIME NOT NULL,
		Material VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialTypeId INT NOT NULL,
		GradeName VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		GradeId SMALLINT NOT NULL,
		GradeValue REAL,
		GradePrecision INT,
		PRIMARY KEY CLUSTERED (CalendarDate, Material, GradeName, Type)
	)

	SET NOCOUNT ON

	SELECT @TransactionName = 'GetBhpbioGradeRecoveryReport',
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
		-- load the base data
		INSERT INTO @Tonnes
		(
			Type, BlockModelId, CalendarDate, Material, MaterialTypeId, Tonnes
		)
		EXEC dbo.GetBhpbioReportBaseDataAsTonnes
			@iDateFrom = @iDateFrom,
			@iDateTo = @iDateTo,
			@iDateBreakdown = NULL,
			@iLocationId = @iLocationId,
			@iIncludeBlockModels = @iIncludeBlockModels,
			@iBlockModels = @iBlockModels,
			@iIncludeActuals = @iIncludeActuals,
			@iMaterialCategoryId = 'Designation',
			@iRootMaterialTypeId = @iDesignationMaterialTypeId,
			@iIncludeLiveData = @iIncludeLiveData,
			@iIncludeApprovedData = @iIncludeApprovedData

		INSERT INTO @Grade
		(
			Type, BlockModelId, CalendarDate, Material, MaterialTypeId, GradeName, GradeId, GradeValue
		)
		EXEC dbo.GetBhpbioReportBaseDataAsGrades
			@iDateFrom = @iDateFrom,
			@iDateTo = @iDateTo,
			@iDateBreakdown = NULL,
			@iLocationId = @iLocationId,
			@iIncludeBlockModels = @iIncludeBlockModels,
			@iBlockModels = @iBlockModels,
			@iIncludeActuals = @iIncludeActuals,
			@iMaterialCategoryId = 'Designation',
			@iRootMaterialTypeId = @iDesignationMaterialTypeId,
			@iGrades = @iGrades,
			@iIncludeLiveData = @iIncludeLiveData,
			@iIncludeApprovedData = @iIncludeApprovedData

			
		UPDATE BG
		SET GradePrecision = G.Display_Precision
		FROM @Grade BG
			INNER JOIN Grade G
				ON (G.Grade_Id = BG.GradeId)

		-- create the summary table

		-- generate the ABSOLUTE DATA
		-- this has no recovery calculations applied

		SELECT 'Absolute' AS Section, 'Tonnes' AS TonnesGradesTag, Type AS Model, Material AS Designation,
			SUM(Tonnes) AS Value
		FROM @Tonnes
		GROUP BY Type, Material
		HAVING @iTonnes = 1

		UNION ALL

		SELECT 'Absolute', g.GradeName, g.Type, g.Material,
			SUM(g.GradeValue * t.Tonnes) / SUM(t.Tonnes)
		FROM @Grade AS g
			INNER JOIN @Tonnes AS t
				ON (g.Type = t.Type
					AND g.CalendarDate = t.CalendarDate
					AND g.Material = t.Material)
		GROUP BY g.GradeName, g.Type, g.Material

		UNION ALL

		-- generate the DIFFERENCES (RECOVERY) DATA
		-- this shows comparisons between all permutations
		-- this may need to be filtered out somewhere at some point!
		SELECT 'Difference', 'Tonnes', t1.Type + ' - ' + t2.Type, t1.Material,
			ROUND(SUM(t1.Tonnes), -3) - ROUND(SUM(t2.Tonnes), -3)
		FROM @Tonnes AS t1
			INNER JOIN @Tonnes AS t2
				ON (t1.CalendarDate = t2.CalendarDate
					AND t1.Material = t2.Material
					AND t1.Type <> t2.Type)
		WHERE (t1.Type = 'Actual' AND t2.Type = 'Mining')
			OR (t1.Type = 'Grade Control' AND t2.Type = 'Mining')
			OR (t1.Type = 'Actual' AND t2.Type = 'Grade Control')
		GROUP BY t1.Type, t2.Type, t1.Material

		UNION ALL

		SELECT 'Difference', g1.GradeName, g1.Type + ' - ' + g2.Type, g1.Material,
			ROUND(SUM(g1.GradeValue * t1.Tonnes)/SUM(t1.Tonnes), g1.GradePrecision) - ROUND(SUM(g2.GradeValue * t2.Tonnes) / SUM(t2.Tonnes), g2.GradePrecision)
		FROM @Grade AS g1
			INNER JOIN @Tonnes AS t1
				ON (t1.Type = g1.Type
					AND t1.CalendarDate = g1.CalendarDate
					AND t1.Material = g1.Material)
			INNER JOIN @Grade AS g2
				ON (g1.CalendarDate = g2.CalendarDate
					AND g1.Material = g2.Material
					AND g1.GradeName = g2.GradeName
					AND g1.Type <> g2.Type)
			INNER JOIN @Tonnes AS t2
				ON (t2.Type = g2.Type
					AND t2.CalendarDate = g2.CalendarDate
					AND t2.Material = g2.Material)
		WHERE (t1.Type = 'Actual' AND t2.Type = 'Mining')
			OR (t1.Type = 'Grade Control' AND t2.Type = 'Mining')
			OR (t1.Type = 'Actual' AND t2.Type = 'Grade Control')
		GROUP BY g1.Type, g2.Type, g1.Material, g1.GradeName, g1.GradePrecision, g2.GradePrecision

		-- supply the GRAPH data
		SELECT 'Tonnes' AS TonnesGradesTag, Type AS ModelTag, Material AS Designation,
			SUM(Tonnes) AS Value
		FROM @Tonnes
		GROUP BY Type, Material
		HAVING @iTonnes = 1

		UNION ALL

		SELECT g.GradeName, g.Type, g.Material,
			SUM(g.GradeValue * t.Tonnes) / SUM(t.Tonnes)
		FROM @Grade AS g
			INNER JOIN @Tonnes AS t
				ON (g.CalendarDate = t.CalendarDate
					AND g.Type = t.Type
					AND g.Material = t.Material)
		GROUP BY g.GradeName, g.Type, g.Material
					
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

GRANT EXECUTE ON dbo.GetBhpbioGradeRecoveryReport TO BhpbioGenericManager
GO

/*
testing

EXEC dbo.GetBhpbioGradeRecoveryReport
	@iDateFrom = '01-APR-2009',
	@iDateTo = '30-JUN-2009',
	@iLocationId = 1,
	@iIncludeBlockModels = 1,
	@iBlockModels = '<BlockModels><BlockModel id="1"></BlockModel><BlockModel id="2"></BlockModel><BlockModel id="3"></BlockModel></BlockModels>',
	@iIncludeActuals = 1,
	@iDesignationMaterialTypeId = NULL,
	@iTonnes = 1,
	@iGrades = '<Grades><Grade>1</Grade><Grade>2</Grade></Grades>',
	@iIncludeLiveData = 0,
	@iIncludeApprovedData = 1
*/

IF OBJECT_ID('dbo.GetBhpbioLatestPurgeableMonth') IS NOT NULL
     DROP PROC dbo.GetBhpbioLatestPurgeableMonth
GO 

CREATE PROC dbo.GetBhpbioLatestPurgeableMonth
(
	@oMonth DATETIME OUTPUT
)
WITH ENCRYPTION
AS
BEGIN
SET NOCOUNT ON;
WITH data
AS
(
	SELECT [Month], Approved 
	FROM dbo.BhpbioApprovalStatusByMonth WITH (NOLOCK)
), 
result AS 
(
	SELECT d.Month
	FROM data d
	WHERE Approved = 1
		AND NOT EXISTS(SELECT * FROM data e WHERE e.Month <= d.Month AND Approved = 0)

)

SELECT @oMonth = MAX(Month) FROM result
END
GO

GRANT EXECUTE ON dbo.GetBhpbioLatestPurgeableMonth TO BhpbioGenericManager
GO


IF OBJECT_ID('dbo.GetBhpbioLatestPurgedMonth') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioLatestPurgedMonth  
GO 
  
CREATE PROCEDURE dbo.GetBhpbioLatestPurgedMonth 
(
	@oLatestPurgedMonth DATETIME OUTPUT
)
WITH ENCRYPTION
AS 
BEGIN 
	SET NOCOUNT ON
	
	SELECT @oLatestPurgedMonth = MAX(pr.PurgeMonth)
	FROM dbo.BhpbioPurgeRequest pr WITH (NOLOCK)
		INNER JOIN dbo.BhpbioPurgeRequestStatus prs ON prs.PurgeRequestStatusId = pr.PurgeRequestStatusId
	WHERE prs.IsFinalStatePositive = 1
	
END 
GO

GRANT EXECUTE ON dbo.GetBhpbioLatestPurgedMonth TO BhpbioGenericManager
GO

/*
DECLARE @TestDate DATETIME
exec dbo.GetBhpbioLatestPurgedMonth @oLatestPurgedMonth = @TestDate OUTPUT
SELECT @TestDate
*/


/*
<TAG Name="Data Dictionary" FunctionName="dbo.GetBhpbioLatestPurgedMonth">
 <Function>
	Gets a DateTime that represents the latest month in the system that has been purged
	
	Parameters:	@oLatestPurgedMonth OUTPUT - the latest purged month (or NULL if no purging has occured)
 </Function>
</TAG>
*/	
IF Object_Id('dbo.GetBhpbioModelComparisonReport') IS NOT NULL
	DROP PROCEDURE dbo.GetBhpbioModelComparisonReport
GO

CREATE PROCEDURE dbo.GetBhpbioModelComparisonReport
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iIncludeBlockModels BIT,
	@iBlockModels XML,
	@iIncludeActuals BIT,
	@iDesignationMaterialTypeId INT,
	@iTonnes BIT,
	@iGrades XML,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT
)
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @Tonnes TABLE
	(
		Type VARCHAR(255) COLLATE DATABASE_DEFAULT NOT NULL,
		BlockModelId INT NULL,
		CalendarDate DATETIME NOT NULL,
		Material VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialTypeId INT NOT NULL,
		Tonnes FLOAT,
		PRIMARY KEY CLUSTERED (CalendarDate, Material, Type)
	)

	DECLARE @Grade TABLE
	(
		Type VARCHAR(255) COLLATE DATABASE_DEFAULT NOT NULL,
		BlockModelId INT NULL,
		CalendarDate DATETIME NOT NULL,
		Material VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialTypeId INT NOT NULL,
		GradeName VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		GradeId SMALLINT NOT NULL,
		GradeValue REAL,
		PRIMARY KEY CLUSTERED (CalendarDate, Material, GradeName, Type)
	)

	SET NOCOUNT ON

	SELECT @TransactionName = 'GetBhpbioModelComparisonReport',
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
		-- note: this has been split into two separate calls
		-- a new requirement (for crusher actuals) has made it such that we cannot aggregate any further beyond the base procs

		-- create the summary data
		INSERT INTO @Tonnes
		(
			Type, BlockModelId, CalendarDate, Material, MaterialTypeId, Tonnes
		)
		EXEC dbo.GetBhpbioReportBaseDataAsTonnes
			@iDateFrom = @iDateFrom,
			@iDateTo = @iDateTo,
			@iDateBreakdown = NULL,
			@iLocationId = @iLocationId,
			@iIncludeBlockModels = @iIncludeBlockModels,
			@iBlockModels = @iBlockModels,
			@iIncludeActuals = @iIncludeActuals,
			@iMaterialCategoryId = 'Designation',
			@iRootMaterialTypeId = @iDesignationMaterialTypeId,
			@iIncludeLiveData = @iIncludeLiveData,
			@iIncludeApprovedData = @iIncludeApprovedData

		INSERT INTO @Grade
		(
			Type, BlockModelId, CalendarDate, Material, MaterialTypeId, GradeName, GradeId, GradeValue
		)
		EXEC dbo.GetBhpbioReportBaseDataAsGrades
			@iDateFrom = @iDateFrom,
			@iDateTo = @iDateTo,
			@iDateBreakdown = NULL,
			@iLocationId = @iLocationId,
			@iIncludeBlockModels = @iIncludeBlockModels,
			@iBlockModels = @iBlockModels,
			@iIncludeActuals = @iIncludeActuals,
			@iMaterialCategoryId = 'Designation',
			@iRootMaterialTypeId = @iDesignationMaterialTypeId,
			@iGrades = @iGrades,
			@iIncludeLiveData = @iIncludeLiveData,
			@iIncludeApprovedData = @iIncludeApprovedData

		SELECT 'Tonnes' AS TonnesGradesTag, Type AS ModelTag, Material, Tonnes AS Value
		FROM @Tonnes
		UNION ALL
		SELECT g.GradeName, g.Type, g.Material, g.GradeValue
		FROM @Grade AS g
			INNER JOIN @Tonnes AS t
				ON (t.Type = g.Type
					AND t.CalendarDate = g.CalendarDate
					AND t.Material = g.Material)

		-- create the graph data
		DELETE FROM @Tonnes
		DELETE FROM @Grade

		INSERT INTO @Tonnes
		(
			Type, BlockModelId, CalendarDate, Material, MaterialTypeId, Tonnes
		)
		EXEC dbo.GetBhpbioReportBaseDataAsTonnes
			@iDateFrom = @iDateFrom,
			@iDateTo = @iDateTo,
			@iDateBreakdown = @iDateBreakdown,
			@iLocationId = @iLocationId,
			@iIncludeBlockModels = @iIncludeBlockModels,
			@iBlockModels = @iBlockModels,
			@iIncludeActuals = @iIncludeActuals,
			@iMaterialCategoryId = 'Designation',
			@iRootMaterialTypeId = @iDesignationMaterialTypeId,
			@iIncludeLiveData = @iIncludeLiveData,
			@iIncludeApprovedData = @iIncludeApprovedData

		INSERT INTO @Grade
		(
			Type, BlockModelId, CalendarDate, Material, MaterialTypeId, GradeName, GradeId, GradeValue
		)
		EXEC dbo.GetBhpbioReportBaseDataAsGrades
			@iDateFrom = @iDateFrom,
			@iDateTo = @iDateTo,
			@iDateBreakdown = @iDateBreakdown,
			@iLocationId = @iLocationId,
			@iIncludeBlockModels = @iIncludeBlockModels,
			@iBlockModels = @iBlockModels,
			@iIncludeActuals = @iIncludeActuals,
			@iMaterialCategoryId = 'Designation',
			@iRootMaterialTypeId = @iDesignationMaterialTypeId,
			@iGrades = @iGrades,
			@iIncludeLiveData = @iIncludeLiveData,
			@iIncludeApprovedData = @iIncludeApprovedData

		SELECT CalendarDate, 'Tonnes' AS TonnesGradesTag, Type AS ModelTag, Material, Tonnes AS Value
		FROM @Tonnes
		UNION ALL
		SELECT CalendarDate, GradeName, Type, Material, GradeValue
		FROM @Grade

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

GRANT EXECUTE ON dbo.GetBhpbioModelComparisonReport TO BhpbioGenericManager
GO

/*
testing

EXEC dbo.GetBhpbioModelComparisonReport
	@iDateFrom = '01-APR-2009',
	@iDateTo = '30-JUN-2009',
	@iDateBreakdown = 'MONTH',
	@iLocationId = 1,
	@iIncludeBlockModels = 1,
	@iBlockModels = '<BlockModels><BlockModel>1</BlockModel><BlockModel>2</BlockModel><BlockModel>3</BlockModel></BlockModels>',
	@iIncludeActuals = 1,
	@iDesignationMaterialTypeId = NULL,
	@iTonnes = 1,
	@iGrades = '<Grades><Grade>1</Grade><Grade>2</Grade></Grades>'
	@iIncludeLiveData = 0,
	@iIncludeApprovedData = 1

*/
IF Object_Id('dbo.GetBhpbioMovementRecoveryReport') IS NOT NULL
	DROP PROCEDURE dbo.GetBhpbioMovementRecoveryReport
GO

CREATE PROCEDURE dbo.GetBhpbioMovementRecoveryReport
(
	@iDateTo DATETIME,
	@iLocationId INT,
	@iComparison1IsActual BIT,
	@iComparison1BlockModelId INT,
	@iComparison2IsActual BIT,
	@iComparison2BlockModelId INT,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT
)
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @BlockModels XML
	DECLARE @IncludeActuals BIT
	DECLARE @IncludeBlockModels BIT

	DECLARE @Comparison TINYINT
	DECLARE @MaterialCategory VARCHAR(31)
	DECLARE @RollingPeriod TINYINT
	DECLARE @DateFrom DATETIME

	DECLARE @Tonnes TABLE
	(
		Compare1Or2 TINYINT NOT NULL,
		RollingPeriod TINYINT NOT NULL,
		MaterialCategory VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		CalendarDate DATETIME NOT NULL,
		Material VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialTypeId INT,
		Tonnes FLOAT,
		PRIMARY KEY CLUSTERED (CalendarDate, Material, Compare1Or2, RollingPeriod, MaterialCategory)
	)

	DECLARE @TempTonnes TABLE
	(
		Type VARCHAR(255) COLLATE DATABASE_DEFAULT NOT NULL,
		BlockModelId INT NULL,
		CalendarDate DATETIME NOT NULL,
		Material VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialTypeId INT NOT NULL,
		Tonnes FLOAT,
		PRIMARY KEY CLUSTERED (CalendarDate, Material, Type)
	)

	DECLARE @Material TABLE
	(
		MaterialCategory VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		Material VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialClassificationOrder VARCHAR(31) COLLATE DATABASE_DEFAULT,
		PRIMARY KEY CLUSTERED (MaterialCategory, Material)
	)

	SET NOCOUNT ON

	SELECT @TransactionName = 'GetBhpbioMovementRecoveryReport',
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
		-- loop on:
		-- Comparison1, Comparison2
		-- Designation, Classification
		-- 12 Month, 3 Month

		-- loop on Comparison1, Comparison2
		SET @Comparison = 1
		WHILE @Comparison IN (1, 2)
		BEGIN
			IF (@Comparison = 1 AND @iComparison1IsActual = 1)
				OR (@Comparison = 2 AND @iComparison2IsActual = 1)
			BEGIN	
				SET @IncludeActuals = 1
				SET @IncludeBlockModels = 0
			END
			ELSE
			BEGIN
				SET @IncludeActuals = 0
				SET @IncludeBlockModels = 1
			END

			SET @BlockModels =
				(
					SELECT [@id]
					FROM
						(
							SELECT @iComparison1BlockModelId AS [@id]
							WHERE @iComparison1IsActual = 0
								AND @Comparison = 1
							UNION ALL
							SELECT @iComparison2BlockModelId AS [@id]
							WHERE @iComparison2IsActual = 0
								AND @Comparison = 2
						) AS sub
					FOR XML PATH ('BlockModel'), ELEMENTS, ROOT('BlockModels')
				)

			-- loop on Designation, Classification
			SET @MaterialCategory = 'Designation'
			WHILE @MaterialCategory IS NOT NULL
			BEGIN
				-- loop on 12 Month, 3 Month
				SET @RollingPeriod = 12
				WHILE @RollingPeriod IN (12, 3)
				BEGIN
					SET @DateFrom =
						(
							CASE @RollingPeriod
								WHEN 3 THEN DateAdd(Month, -3, (@iDateTo + 1))
								WHEN 12 THEN DateAdd(Month, -12, (@iDateTo + 1))
								ELSE NULL
							END
						)

					INSERT INTO @TempTonnes
					(
						Type, BlockModelId, CalendarDate, Material, MaterialTypeId, Tonnes
					)
					EXEC dbo.GetBhpbioReportBaseDataAsTonnes
						@iDateFrom = @DateFrom,
						@iDateTo = @iDateTo,
						@iDateBreakdown = NULL,
						@iLocationId = @iLocationId,
						@iIncludeBlockModels = @IncludeBlockModels,
						@iBlockModels = @BlockModels,
						@iIncludeActuals = @IncludeActuals,
						@iMaterialCategoryId = @MaterialCategory,
						@iRootMaterialTypeId = NULL,
						@iIncludeLiveData = @iIncludeLiveData,
						@iIncludeApprovedData = @iIncludeApprovedData

					INSERT INTO @Tonnes
					(
						Compare1Or2, RollingPeriod, MaterialCategory, CalendarDate, Material, MaterialTypeId, Tonnes
					)
					SELECT @Comparison, @RollingPeriod, @MaterialCategory, CalendarDate, Material, MaterialTypeId, Sum(Tonnes)
					FROM @TempTonnes
					Group By CalendarDate, Material, MaterialTypeId

					DELETE
					FROM @TempTonnes

					-- load the next rolling period
					SET @RollingPeriod =
						(
							SELECT
								CASE @RollingPeriod
									WHEN 12 THEN 3
									WHEN 3 THEN NULL
									ELSE NULL
								END
						)
				END

				-- load the next material category
				SET @MaterialCategory = 
					(
						SELECT
							CASE @MaterialCategory
								WHEN 'Designation' THEN 'Classification'
								WHEN 'Classification' THEN NULL
								ELSE NULL
							END
					)
			END
					
			-- load the next comparison
			SET @Comparison = @Comparison + 1
		END

		-- load materials
		INSERT INTO @Material
		(MaterialCategory, Material, MaterialClassificationOrder)
		SELECT DISTINCT MaterialCategory, Material, MT.Order_No
		FROM @Tonnes T
			INNER JOIN dbo.MaterialType MT
				ON dbo.GetMaterialCategoryMaterialType(T.MaterialTypeId, 'Classification') = MT.Material_Type_Id

		-- create the summary table
		SELECT rp.RollingPeriod, c.Compare1Or2, sub.MaterialCategory, sub.Material, sub.MaterialClassificationOrder, sub.Tonnes
		FROM
			(
				SELECT 3 AS RollingPeriod
				UNION ALL
				SELECT 12
			) AS rp
			CROSS JOIN
			(
				SELECT 1 AS Compare1Or2
				UNION ALL
				SELECT 2
				UNION ALL
				SELECT 3  -- this is the total line
			) AS c
			LEFT OUTER JOIN
			(
				-- return the underlying data
				SELECT t.RollingPeriod, t.Compare1Or2, t.MaterialCategory, t.Material, MC.MaterialClassificationOrder, 
					SUM(Tonnes) AS Tonnes
				FROM @Tonnes t
					INNER JOIN @Material AS mc
						ON (mc.MaterialCategory = t.MaterialCategory
							AND MC.Material = t.Material)
				GROUP BY t.RollingPeriod, t.Compare1Or2, t.MaterialCategory, t.Material, MC.MaterialClassificationOrder

				UNION ALL

				-- return the total movement line
				SELECT t.RollingPeriod, t.Compare1Or2, 'Total Movement', NULL, MAX(MC.MaterialClassificationOrder) + 1,
					SUM(t.Tonnes) AS Tonnes
				FROM @Tonnes AS t
					INNER JOIN @Material AS mc
						ON (mc.MaterialCategory = t.MaterialCategory
							AND mc.Material = t.Material)
				WHERE t.MaterialCategory = 'Classification'
				GROUP BY t.RollingPeriod, t.Compare1Or2

				UNION ALL

				-- return the % variance line
				SELECT COALESCE(t1.RollingPeriod, t2.RollingPeriod),
					3, mc.MaterialCategory, mc.Material AS Material, MC.MaterialClassificationOrder, 
					CASE
						WHEN SUM(t2.Tonnes) <> 0 AND SUM(t1.Tonnes) <> 0
							THEN SUM(t1.Tonnes) / SUM(t2.Tonnes)
						ELSE NULL
					END AS Tonnes
				FROM @Material AS mc
					LEFT JOIN @Tonnes AS t1
						ON (mc.MaterialCategory = t1.MaterialCategory
							AND mc.Material = t1.Material
							AND t1.Compare1Or2 = 1)
					LEFT JOIN @Tonnes AS t2
						ON (mc.MaterialCategory = t2.MaterialCategory
							AND mc.Material = t2.Material
							AND t2.Compare1Or2 = 2
							AND t1.RollingPeriod = t2.RollingPeriod)
				WHERE (t2.CalendarDate = t1.CalendarDate
						OR t1.CalendarDate Is Null
						OR t2.CalendarDate Is Null)
				GROUP BY COALESCE(t1.RollingPeriod, t2.RollingPeriod),
					mc.MaterialCategory, mc.Material, mc.MaterialClassificationOrder

				UNION ALL

				SELECT COALESCE(t1.RollingPeriod, t2.RollingPeriod),
					3, 'Total Movement', NULL AS Material, Max(mc.MaterialClassificationOrder) + 1,
					CASE
						WHEN SUM(t2.Tonnes) <> 0 AND SUM(t1.Tonnes) <> 0
							THEN SUM(t1.Tonnes) / Sum(t2.Tonnes)
						ELSE NULL
					END AS Tonnes
				FROM @Material AS mc
					LEFT JOIN @Tonnes AS t1
						ON (mc.MaterialCategory = t1.MaterialCategory
							AND MC.Material = t1.Material
							AND t1.Compare1Or2 = 1)
					LEFT JOIN @Tonnes AS t2
						ON (mc.MaterialCategory = t2.MaterialCategory
							AND mc.Material = t2.Material
							AND t2.Compare1Or2 = 2
							AND t2.RollingPeriod = t1.RollingPeriod)
				WHERE (t2.CalendarDate = t1.CalendarDate
						Or t1.CalendarDate Is Null
						Or t2.CalendarDate Is Null)
					AND mc.MaterialCategory = 'Classification'
				GROUP BY COALESCE(t1.RollingPeriod, t2.RollingPeriod)
			) AS sub
			ON (rp.RollingPeriod = sub.RollingPeriod
				AND c.Compare1Or2 = sub.Compare1Or2)
		ORDER BY rp.RollingPeriod, c.Compare1Or2,
			CASE MaterialCategory
				WHEN 'Designation' THEN 1
				WHEN 'Classification' THEN 2
				ELSE 3 END,
			Material

		-- create the graph data
		SELECT rp.RollingPeriod, sub.MaterialCategory, sub.Material, sub.MaterialClassificationOrder, sub.Tonnes
		FROM
			(
				SELECT 3 AS RollingPeriod
				UNION ALL
				SELECT 12
			) AS rp
			LEFT OUTER JOIN
			(
				SELECT COALESCE(t1.RollingPeriod, t2.RollingPeriod) AS RollingPeriod,
					mc.MaterialCategory, mc.Material AS Material, mc.MaterialClassificationOrder, 
					CASE
						WHEN SUM(t2.Tonnes) <> 0 AND SUM(t1.Tonnes) <> 0
							THEN SUM(t1.Tonnes) / Sum(t2.Tonnes)
						ELSE NULL
					END AS Tonnes
				FROM @Material AS mc
					LEFT JOIN @Tonnes AS t1
						ON (mc.MaterialCategory = t1.MaterialCategory
							AND mc.Material = t1.Material
							AND t1.Compare1Or2 = 1)
					LEFT JOIN @Tonnes AS t2
						ON (mc.MaterialCategory = t2.MaterialCategory
							AND mc.Material = t2.Material
							AND t2.Compare1Or2 = 2
							AND t2.RollingPeriod = t1.RollingPeriod)
				WHERE (t2.CalendarDate = t1.CalendarDate
						OR t1.CalendarDate Is Null
						OR t2.CalendarDate Is Null)
				GROUP BY COALESCE(t1.RollingPeriod, t2.RollingPeriod),
					mc.MaterialCategory, mc.Material, mc.MaterialClassificationOrder

				UNION ALL

				SELECT COALESCE(t1.RollingPeriod, t2.RollingPeriod) AS RollingPeriod,
					'Total Movement', NULL AS Material, MAX(MC.MaterialClassificationOrder) + 1, 
					CASE
						WHEN SUM(t2.Tonnes) <> 0 AND SUM(t1.Tonnes) <> 0
							THEN SUM(t1.Tonnes) / Sum(t2.Tonnes)
						ELSE NULL
					END AS Tonnes
				FROM @Material AS mc
					LEFT JOIN @Tonnes AS t1
						ON (mc.MaterialCategory = t1.MaterialCategory
							AND mc.Material = t1.Material
							AND t1.Compare1Or2 = 1)
					LEFT JOIN @Tonnes AS t2
						ON (mc.MaterialCategory = t2.MaterialCategory
							AND mc.Material = t2.Material
							AND t2.Compare1Or2 = 2
							AND t2.RollingPeriod = t1.RollingPeriod)
				WHERE (t2.CalendarDate = t1.CalendarDate
						Or t1.CalendarDate Is Null
						Or t2.CalendarDate Is Null)
					AND mc.MaterialCategory = 'Classification'
				GROUP BY COALESCE(t1.RollingPeriod, t2.RollingPeriod)
			) AS sub
			ON (sub.RollingPeriod = rp.RollingPeriod)

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

GRANT EXECUTE ON dbo.GetBhpbioMovementRecoveryReport TO BhpbioGenericManager
GO

/* testing
EXEC dbo.GetBhpbioMovementRecoveryReport
	@iDateTo = '30-JUN-2009',
	@iLocationId = 1,
	@iComparison1IsActual = 0,
	@iComparison1BlockModelId = 1,
	@iComparison2IsActual = 0,
	@iComparison2BlockModelId = 2,
	@iIncludeLiveData = 0,
	@iIncludeApprovedData = 1
*/
IF OBJECT_ID('dbo.GetBhpbioPurgeRequests') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioPurgeRequests
GO 

CREATE PROC dbo.GetBhpbioPurgeRequests
(
	@iIsReadyForApproval BIT = NULL,
	@iIsReadyForPurging BIT = NULL,
	@iOnlyLatestForEachMonth BIT = 1
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @latestPerMonth TABLE (
		PurgeMonth DATETIME,
		LastStatusChangeDateTime DATETIME
	)
	
	-- find the latest request per month
	INSERT INTO @latestPerMonth
	SELECT pr.PurgeMonth, MAX(pr.LastStatusChangeDateTime)
	FROM dbo.BhpbioPurgeRequest pr
	GROUP BY pr.PurgeMonth
	
	SELECT
		R.PurgeRequestId AS Id,
		R.PurgeMonth As Month,
		S.PurgeRequestStatusId As Status,
		RU.UserId AS RequestingUserId,
		RU.FirstName AS RequestingUserFirstName,
		RU.LastName AS RequestingUserLastName,
		R.LastStatusChangeDateTime AS Timestamp,
		AU.UserId AS ApprovingUserId,
		AU.FirstName AS ApprovingUserFirstName,
		AU.LastName AS ApprovingUserLastName,
		S.IsReadyForApproval,
		S.IsReadyForPurging
	FROM dbo.BhpbioPurgeRequest AS R WITH (NOLOCK)
		INNER JOIN dbo.BhpbioPurgeRequestStatus AS S WITH (NOLOCK)
			ON (R.PurgeRequestStatusId = S.PurgeRequestStatusId)
		INNER JOIN dbo.SecurityUser AS RU WITH (NOLOCK)
			ON (R.RequestingUserId = RU.UserId)
		LEFT JOIN dbo.SecurityUser AS AU WITH (NOLOCK)
			ON (R.ApprovingUserId = AU.UserId)
		LEFT JOIN @latestPerMonth lpm
			ON lpm.PurgeMonth = R.PurgeMonth
			AND lpm.LastStatusChangeDateTime = R.LastStatusChangeDateTime
	WHERE (@iIsReadyForApproval IS NULL OR S.IsReadyForApproval = @iIsReadyForApproval)
		AND (@iIsReadyForPurging IS NULL OR S.IsReadyForPurging = @iIsReadyForPurging)
		-- and we are not restricting output to latest change request per month, or we are and this row is the latest for the month
		AND (NOT @iOnlyLatestForEachMonth = 1 OR lpm.PurgeMonth IS NOT NULL)
	ORDER BY R.PurgeMonth DESC
END
GO

GRANT EXECUTE ON dbo.GetBhpbioPurgeRequests TO BhpbioGenericManager
GO

IF Object_Id('dbo.GetBhpbioRecoveryAnalysisReport') IS NOT NULL
	DROP PROCEDURE dbo.GetBhpbioRecoveryAnalysisReport
GO

CREATE PROCEDURE dbo.GetBhpbioRecoveryAnalysisReport
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iIncludeBlockModels BIT,
	@iBlockModels XML,
	@iIncludeActuals BIT,
	@iDesignationMaterialTypeId INT,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT
)
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @Tonnes TABLE
	(
		MaterialCategory VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		Type VARCHAR(255) COLLATE DATABASE_DEFAULT NOT NULL,
		CalendarDate DATETIME NOT NULL,
		Material VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
		Tonnes FLOAT,
		PRIMARY KEY CLUSTERED (CalendarDate, Material, Type, MaterialCategory)
	)

	DECLARE @TempTonnes TABLE
	(
		Type VARCHAR(255) COLLATE DATABASE_DEFAULT NOT NULL,
		BlockModelId INT NULL,
		CalendarDate DATETIME NOT NULL,
		Material VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialTypeId INT NOT NULL,
		Tonnes FLOAT,
		PRIMARY KEY CLUSTERED (CalendarDate, Material, Type)
	)

	SET NOCOUNT ON

	SELECT @TransactionName = 'GetBhpbioRecoveryAnalysisReport',
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
		-- load DESIGNATION
		INSERT INTO @TempTonnes
		(
			Type, BlockModelId, CalendarDate, Material, MaterialTypeId, Tonnes
		)
		EXEC dbo.GetBhpbioReportBaseDataAsTonnes
			@iDateFrom = @iDateFrom,
			@iDateTo = @iDateTo,
			@iDateBreakdown = @iDateBreakdown,
			@iLocationId = @iLocationId,
			@iIncludeBlockModels = @iIncludeBlockModels,
			@iBlockModels = @iBlockModels,
			@iIncludeActuals = @iIncludeActuals,
			@iMaterialCategoryId = 'Designation',
			@iRootMaterialTypeId = @iDesignationMaterialTypeId,
			@iIncludeLiveData = @iIncludeLiveData,
			@iIncludeApprovedData = @iIncludeApprovedData

		INSERT INTO @Tonnes
		(
			MaterialCategory, Type, CalendarDate, Material, Tonnes
		)
		SELECT 'Designation', Type, CalendarDate, Material, Tonnes
		FROM @TempTonnes

		DELETE
		FROM @TempTonnes

		-- load CLASSIFICATION
		INSERT INTO @TempTonnes
		(
			Type, BlockModelId, CalendarDate, Material, MaterialTypeId, Tonnes
		)
		EXEC dbo.GetBhpbioReportBaseDataAsTonnes
			@iDateFrom = @iDateFrom,
			@iDateTo = @iDateTo,
			@iDateBreakdown = @iDateBreakdown,
			@iLocationId = @iLocationId,
			@iIncludeBlockModels = @iIncludeBlockModels,
			@iBlockModels = @iBlockModels,
			@iIncludeActuals = @iIncludeActuals,
			@iMaterialCategoryId = 'Classification',
			@iRootMaterialTypeId = NULL,
			@iIncludeLiveData = @iIncludeLiveData,
			@iIncludeApprovedData = @iIncludeApprovedData

		INSERT INTO @Tonnes
		(
			MaterialCategory, Type, CalendarDate, Material, Tonnes
		)
		SELECT 'Classification', Type, CalendarDate, Material, Tonnes
		FROM @TempTonnes

		DELETE
		FROM @TempTonnes

		-- create the summary table

		-- generate the DIFFERENCES (RECOVERY) DATA
		-- this shows comparisons between all permutations
		-- this may need to be filtered out somewhere at some point!
		SELECT t1.Type + ' - ' + t2.Type AS ComparisonType, t1.MaterialCategory, t1.Material,
			SUM(t1.Tonnes) / NULLIF(SUM(t2.Tonnes), 0.0) AS RecoveryPercent
		FROM @Tonnes AS t1
			INNER JOIN @Tonnes AS t2
				ON (t1.CalendarDate = t2.CalendarDate
					AND t1.Material = t2.Material
					AND t1.MaterialCategory = t2.MaterialCategory
					AND t1.Type <> t2.Type)
		WHERE (t1.Type = 'Mining' AND t2.Type = 'Geology')
			OR (t1.Type = 'Grade Control' AND t2.Type = 'Mining')
			OR (t1.Type = 'Actual' AND t2.Type = 'Mining')
			OR (t1.Type = 'Actual' AND t2.Type = 'Grade Control')
		GROUP BY t1.Type, t2.Type, t1.Material, t1.MaterialCategory

		-- supply the GRAPH data
		-- this is supposed to show recovery data but it doesn't make sense

		SELECT t1.Type + ' - ' + t2.Type AS ComparisonType, t1.Material AS Designation, t1.CalendarDate,
			SUM(t1.Tonnes) / NULLIF(SUM(t2.Tonnes), 0.0) AS RecoveryPercent
		FROM @Tonnes AS t1
			INNER JOIN @Tonnes AS t2
				ON (t1.CalendarDate = t2.CalendarDate
					AND t1.Material = t2.Material
					AND t1.MaterialCategory = t2.MaterialCategory
					AND t1.Type <> t2.Type)
		WHERE t1.MaterialCategory = 'Designation'
			AND
			(
				(t1.Type = 'Mining' AND t2.Type = 'Geology')
				OR (t1.Type = 'Grade Control' AND t2.Type = 'Mining')
				OR (t1.Type = 'Actual' AND t2.Type = 'Mining')
				OR (t1.Type = 'Actual' AND t2.Type = 'Grade Control')
			)
		GROUP BY t1.Type, t2.Type, t1.Material, t1.CalendarDate
					
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

GRANT EXECUTE ON dbo.GetBhpbioRecoveryAnalysisReport TO BhpbioGenericManager
GO

/*
testing

EXEC dbo.GetBhpbioRecoveryAnalysisReport
	@iDateFrom = '01-APR-2009',
	@iDateTo = '30-JUN-2009',
	@iDateBreakdown = 'MONTH',
	@iLocationId = 1,
	@iIncludeBlockModels = 1,
	@iBlockModels = '<BlockModels><BlockModel id="1"></BlockModel><BlockModel id="2"></BlockModel><BlockModel id="3"></BlockModel></BlockModels>',
	@iIncludeActuals = 1,
	@iDesignationMaterialTypeId = NULL,
	@iIncludeLiveData = 0,
	@iIncludeApprovedData = 1
	
*/
IF OBJECT_ID('dbo.GetBhpbioReportBaseDataAsGrades') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportBaseDataAsGrades
GO

CREATE PROCEDURE dbo.GetBhpbioReportBaseDataAsGrades
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iIncludeBlockModels BIT,
	@iBlockModels XML,
	@iIncludeActuals BIT,
	@iMaterialCategoryId VARCHAR(31),
	@iRootMaterialTypeId INT,
	@iGrades XML,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT
)
AS 
BEGIN
	-- for internal consumption only
	
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	DECLARE @HighGradeMaterialTypeId INT

	DECLARE @Grade TABLE
	(
		Type VARCHAR(255) COLLATE DATABASE_DEFAULT NOT NULL,
		CalendarDate DATETIME NOT NULL,
		MaterialTypeId INT NOT NULL,
		GradeId SMALLINT NOT NULL,
		GradeValue FLOAT NULL,
		Tonnes FLOAT NULL,
		PRIMARY KEY CLUSTERED (CalendarDate, MaterialTypeId, GradeId, Type)
	)
	
	DECLARE @Type TABLE
	(
		Type VARCHAR(255) COLLATE DATABASE_DEFAULT NOT NULL,
		BlockModelId INT NULL,
		PRIMARY KEY CLUSTERED (Type)
	)

	DECLARE @MaterialType TABLE
	(
		RootMaterialTypeId INT NOT NULL,
		RootAbbreviation VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialTypeId INT NOT NULL,
		PRIMARY KEY CLUSTERED (MaterialTypeId, RootMaterialTypeId)
	)

	DECLARE @Date TABLE
	(
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		CalendarDate DATETIME NOT NULL,
		PRIMARY KEY NONCLUSTERED (CalendarDate),
		UNIQUE CLUSTERED (DateFrom, DateTo, CalendarDate)
	)

	DECLARE @GradeLookup TABLE
	(
		GradeId SMALLINT NOT NULL,
		GradeName VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		OrderNo INT NOT NULL,
		PRIMARY KEY CLUSTERED (GradeId)
	)

	DECLARE @C TABLE
	(
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		DesignationMaterialTypeId INT NOT NULL,
		LocationId INT NULL,
		Attribute SMALLINT NULL,
		Value FLOAT NULL
	)

	DECLARE @Y TABLE
	(
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		DesignationMaterialTypeId INT NOT NULL,
		LocationId INT NULL,
		Attribute SMALLINT NULL,
		Value FLOAT NULL
	) 

	DECLARE @Z TABLE
	(
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		DesignationMaterialTypeId INT NOT NULL,
		LocationId INT NULL,
		Attribute SMALLINT NULL,
		Value FLOAT NULL
	)

	DECLARE @M TABLE
	(
		CalendarDate DATETIME NOT NULL,
		BlockModelId INT NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		DesignationMaterialTypeId INT NOT NULL,
		LocationId INT NULL,
		Attribute SMALLINT NULL,
		Value FLOAT NULL
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioReportBaseDataAsGrades',
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
		-- perform checks
		IF dbo.GetDateMonth(@iDateFrom) <> @iDateFrom
		BEGIN
			RAISERROR('The @iDateFrom parameter must be the first day of the month.', 16, 1)
		END

		IF (dbo.GetDateMonth(@iDateTo + 1) - 1) <> @iDateTo
		BEGIN
			RAISERROR('The @iDateTo parameter must be the last day of the month.', 16, 1)
		END

		IF NOT @iMaterialCategoryId IN ('Classification', 'Designation')
		BEGIN
			RAISERROR('The Material Category parameter can only be Classification/Designation.', 16, 1)
		END

		-- load Grades
		IF @iGrades IS NULL
		BEGIN
			INSERT INTO @GradeLookup
				(GradeId, GradeName, OrderNo)
			SELECT Grade_Id, Grade_Name, Order_No
			FROM dbo.Grade
		END
		ELSE
		BEGIN
			INSERT INTO @GradeLookup
				(GradeId, GradeName, OrderNo)
			SELECT g.Grade.value('./@id', 'SMALLINT'), g2.Grade_Name, g2.Order_No
			FROM @iGrades.nodes('/Grades/Grade') AS g(Grade)
				INNER JOIN dbo.Grade AS g2
					ON (g2.Grade_Id = g.Grade.value('./@id', 'SMALLINT'))
		END

		-- load Block Model
		IF @iIncludeActuals = 1
		BEGIN
			INSERT INTO @Type
				(Type, BlockModelId)
			VALUES
				('Actual', NULL)
		END

		IF (@iIncludeBlockModels = 1) AND (@iBlockModels IS NULL)
		BEGIN
			INSERT INTO @Type
				(Type, BlockModelId)
			SELECT Name, Block_Model_Id
			FROM dbo.BlockModel
		END
		ELSE IF (@iIncludeBlockModels = 1)
		BEGIN
			INSERT INTO @Type
				(Type, BlockModelId)
			SELECT bm.Name, b.BlockModel.value('./@id', 'INT')
			FROM @iBlockModels.nodes('/BlockModels/BlockModel') AS b(BlockModel)
				INNER JOIN dbo.BlockModel AS bm
					ON (bm.Block_Model_Id = b.BlockModel.value('./@id', 'INT'))
		END
		
		-- load the material data
		INSERT INTO @MaterialType
			(RootMaterialTypeId, RootAbbreviation, MaterialTypeId)
		SELECT mc.RootMaterialTypeId, mt.Abbreviation, mc.MaterialTypeId
		FROM dbo.GetMaterialsByCategory(@iMaterialCategoryId) AS mc
			INNER JOIN dbo.MaterialType AS mt
				ON (mc.RootMaterialTypeId = mt.Material_Type_Id)
		WHERE mc.RootMaterialTypeId = ISNULL(@iRootMaterialTypeId, mc.RootMaterialTypeId)

		-- load the date range
		INSERT INTO @Date
			(DateFrom, DateTo, CalendarDate)
		SELECT DateFrom, DateTo, CalendarDate
		FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1)

		-- generate the actual + model data
		IF @iIncludeActuals = 1
		BEGIN
			INSERT INTO @C
				(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value)
			SELECT CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value
			FROM dbo.GetBhpbioReportActualC(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, NULL, @iIncludeLiveData, @iIncludeApprovedData)

			INSERT INTO @Y
				(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value)
			SELECT CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value
			FROM dbo.GetBhpbioReportActualY(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, NULL, @iIncludeLiveData, @iIncludeApprovedData)

			INSERT INTO @Z
				(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value)
			SELECT CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value
			FROM dbo.GetBhpbioReportActualZ(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, NULL, @iIncludeLiveData, @iIncludeApprovedData)

			INSERT INTO @Grade
			(
				Type, CalendarDate, MaterialTypeId, GradeId, GradeValue, Tonnes
			)
			SELECT 'Actual', CalendarDate, RootMaterialTypeId, GradeId,
				SUM(Tonnes * GradeValue) / NULLIF(SUM(Tonnes), 0.0), SUM(Tonnes)
			FROM
				(
					-- High Grade = C - z(hg) + y(hg)
					-- All Grade  = y(non-hg)

					-- '+C' - all crusher removals
					SELECT g.CalendarDate, mc.RootMaterialTypeId,
						g.Attribute As GradeId, SUM(t.Value) AS Tonnes,
						-- the following value is only valid as the data is always returned at the Site level
						-- above this level (Hub/WAIO) the aggregation will properly perform real aggregations
						SUM(g.Value * NULLIF(t.Value, 0.0)) / NULLIF(SUM(t.Value), 0.0) As GradeValue
					FROM @C AS g
						INNER JOIN @C AS t
							ON (g.DesignationMaterialTypeId = t.DesignationMaterialTypeId)
						INNER JOIN @MaterialType AS mc
							ON (mc.MaterialTypeId = t.DesignationMaterialTypeId)
					WHERE g.Attribute > 0
						AND t.Attribute = 0
					GROUP BY g.CalendarDate, mc.RootMaterialTypeId, g.Attribute

					UNION ALL

					-- '-z(all)' - pre crusher stockpiles to crusher
					SELECT g.CalendarDate, mc.RootMaterialTypeId,
						g.Attribute As GradeId,
						-SUM(t.Value) AS Tonnes, SUM(g.Value * t.Value) / NULLIF(SUM(t.Value), 0.0) As GradeValue
					FROM @Z AS g
						INNER JOIN @Z AS t
							ON (g.DesignationMaterialTypeId = t.DesignationMaterialTypeId)
						INNER JOIN @MaterialType AS mc
							ON (mc.MaterialTypeId = t.DesignationMaterialTypeId)
					WHERE g.Attribute > 0
						AND t.Attribute = 0
					GROUP BY g.CalendarDate, mc.RootMaterialTypeId, g.Attribute

					UNION ALL

					-- '+y(hg)' - pit to pre-crusher stockpiles
					SELECT g.CalendarDate, mc.RootMaterialTypeId,
						g.Attribute As GradeId,
						SUM(t.Value) AS Tonnes, SUM(g.Value * t.Value) / NULLIF(SUM(t.Value), 0.0) As GradeValue
					FROM @Y AS g
						INNER JOIN @Y AS t
							ON (g.DesignationMaterialTypeId = t.DesignationMaterialTypeId)
						INNER JOIN @MaterialType AS mc
							ON (mc.MaterialTypeId = t.DesignationMaterialTypeId)
					WHERE g.Attribute > 0
						AND t.Attribute = 0
					GROUP BY g.CalendarDate, mc.RootMaterialTypeId, g.Attribute
				) AS sub
			GROUP BY CalendarDate, RootMaterialTypeId, GradeId
		END

		IF (@iIncludeBlockModels = 1)
		BEGIN
			INSERT INTO @M
				(CalendarDate, BlockModelId, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value)
			SELECT CalendarDate, BlockModelId, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value
			FROM dbo.GetBhpbioReportModel(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, NULL, @iIncludeLiveData, @iIncludeApprovedData)

			INSERT INTO @Grade
			(
				Type, CalendarDate, MaterialTypeId, GradeId, GradeValue, Tonnes
			)
			SELECT bm.Type, g.CalendarDate, mc.RootMaterialTypeId, g.Attribute,
				SUM(g.Value * t.Value) / SUM(t.Value), SUM(t.Value)
			FROM @M AS t
				INNER JOIN @M AS g
					ON (t.DesignationMaterialTypeId = g.DesignationMaterialTypeId
						AND t.BlockModelId = g.BlockModelId)
				INNER JOIN @MaterialType AS mc
					ON (mc.MaterialTypeId = t.DesignationMaterialTypeId)
				INNER JOIN @Type AS bm
					ON (t.BlockModelId = bm.BlockModelId)
			WHERE t.Attribute = 0
				AND g.Attribute > 0
			GROUP BY bm.Type, g.CalendarDate, mc.RootMaterialTypeId, g.Attribute
		END

		-- return the result	
		SELECT t.Type, t.BlockModelId, d.CalendarDate,
			mt.RootAbbreviation AS Material, mt.RootMaterialTypeId AS MaterialTypeId,
			g.GradeName, g.GradeId, SUM(r.GradeValue * r.Tonnes) / SUM(r.Tonnes) As GradeValue
		FROM
			-- display all dates
			@Date AS d
			-- display all elisted types (block models + actual)
			CROSS JOIN @Type AS t
			-- ensure material types are represented uniformly
			CROSS JOIN
				(
					SELECT DISTINCT mt2.RootMaterialTypeId, mt2.RootAbbreviation, mt2.MaterialTypeId
					FROM @MaterialType AS mt2
					INNER JOIN @Grade AS grade ON (grade.MaterialTypeId = mt2.MaterialTypeId)
				) AS mt
			-- ensure all grades are represented
			CROSS JOIN @GradeLookup AS g
			-- pivot in the results
			LEFT OUTER JOIN @Grade AS r
				ON (r.CalendarDate = d.CalendarDate
					AND r.MaterialTypeId = mt.MaterialTypeId
					AND r.Type = t.Type
					AND g.GradeId = r.GradeId)
		GROUP BY t.Type, t.BlockModelId, d.CalendarDate,
			mt.RootAbbreviation , mt.RootMaterialTypeId ,
			g.GradeName, g.GradeId, g.OrderNo
		ORDER BY d.CalendarDate, mt.RootAbbreviation, t.Type, g.OrderNo

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

/* testing

EXEC dbo.GetBhpbioReportBaseDataAsGrades
	@iDateFrom = '01-APR-2010',
	@iDateTo = '30-JUN-2010',
	@iDateBreakdown = 'QUARTER',
	@iLocationId = 4,
	@iIncludeBlockModels = 1,
	@iBlockModels = NULL,
	@iIncludeActuals = 1,
	@iMaterialCategoryId = 'Designation',
	@iRootMaterialTypeId = NULL,
	@iGrades = NULL,
	@iIncludeLiveData = 0,
	@iIncludeApprovedData = 1
	
*/ 
IF OBJECT_ID('dbo.GetBhpbioReportBaseDataAsTonnes') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportBaseDataAsTonnes
GO

CREATE PROCEDURE dbo.GetBhpbioReportBaseDataAsTonnes
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iIncludeBlockModels BIT,
	@iBlockModels XML,
	@iIncludeActuals BIT,
	@iMaterialCategoryId VARCHAR(31),
	@iRootMaterialTypeId INT,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT
)
AS 
BEGIN
	-- for internal consumption only

	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @Tonnes TABLE
	(
		Type VARCHAR(255) COLLATE DATABASE_DEFAULT NOT NULL,
		CalendarDate DATETIME NOT NULL,
		MaterialTypeId INT NOT NULL,
		Tonnes FLOAT,
		PRIMARY KEY CLUSTERED (CalendarDate, MaterialTypeId, Type)
	)
	
	DECLARE @Type TABLE
	(
		Type VARCHAR(255) COLLATE DATABASE_DEFAULT NOT NULL,
		BlockModelId INT NULL,
		PRIMARY KEY CLUSTERED (Type)
	)

	DECLARE @MaterialType TABLE
	(
		RootMaterialTypeId INT NOT NULL,
		RootAbbreviation VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialTypeId INT NOT NULL,
		PRIMARY KEY CLUSTERED (MaterialTypeId, RootMaterialTypeId)
	)

	DECLARE @Date TABLE
	(
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		CalendarDate DATETIME NOT NULL,
		PRIMARY KEY NONCLUSTERED (CalendarDate),
		UNIQUE CLUSTERED (DateFrom, DateTo, CalendarDate)
	)

	DECLARE @Location Table
	(
		LocationId INT NOT NULL,
		PRIMARY KEY CLUSTERED (LocationId)
	)

	DECLARE @Crusher Table
	(
		CrusherId VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		PRIMARY KEY CLUSTERED (CrusherId)
	)

	DECLARE @HighGradeMaterialTypeId INT
	DECLARE @BeneFeedMaterialTypeId INT

	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioReportBaseDataAsTonnes',
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
		-- perform checks
		IF dbo.GetDateMonth(@iDateFrom) <> @iDateFrom
		BEGIN
			RAISERROR('The @iDateFrom parameter must be the first day of the month.', 16, 1)
		END

		IF (dbo.GetDateMonth(@iDateTo + 1) - 1) <> @iDateTo
		BEGIN
			RAISERROR('The @iDateTo parameter must be the last day of the month.', 16, 1)
		END

		IF NOT @iMaterialCategoryId IN ('Classification', 'Designation')
		BEGIN
			RAISERROR('The Material Category parameter can only be Classification/Designation.', 16, 1)
		END

		IF @iMaterialCategoryId NOT IN ('Classification', 'Designation')
		BEGIN
			RAISERROR('Only "Classification" and "Designation" are supported as material categories.', 16, 1)
		END

		-- load Block Model
		IF @iIncludeActuals = 1
		BEGIN
			INSERT INTO @Type
				(Type, BlockModelId)
			VALUES
				('Actual', NULL)
		END

		IF (@iIncludeBlockModels = 1) AND (@iBlockModels IS NULL)
		BEGIN
			INSERT INTO @Type
				(Type, BlockModelId)
			SELECT Name, Block_Model_Id
			FROM dbo.BlockModel
		END
		ELSE IF (@iIncludeBlockModels = 1)
		BEGIN
			INSERT INTO @Type
				(Type, BlockModelId)
			SELECT bm.Name, b.BlockModel.value('./@id', 'INT')
			FROM @iBlockModels.nodes('/BlockModels/BlockModel') AS b(BlockModel)
				INNER JOIN dbo.BlockModel AS bm
					ON (bm.Block_Model_Id = b.BlockModel.value('./@id', 'INT'))
		END
		
		-- load the material data
		INSERT INTO @MaterialType
			(RootMaterialTypeId, RootAbbreviation, MaterialTypeId)
		SELECT mc.RootMaterialTypeId, mt.Abbreviation, mc.MaterialTypeId
		FROM dbo.GetMaterialsByCategory(@iMaterialCategoryId) AS mc
			INNER JOIN dbo.MaterialType AS mt
				ON (mc.RootMaterialTypeId = mt.Material_Type_Id)
		WHERE mc.RootMaterialTypeId = ISNULL(@iRootMaterialTypeId, mc.RootMaterialTypeId)

		-- load the date range
		INSERT INTO @Date
			(DateFrom, DateTo, CalendarDate)
		SELECT DateFrom, DateTo, CalendarDate
		FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1)


		-- generate the actual + model data
		IF @iIncludeActuals = 1
		BEGIN
			INSERT INTO @Tonnes
			(
				Type, CalendarDate, MaterialTypeId, Tonnes
			)
			SELECT 'Actual', sub.CalendarDate, mc.RootMaterialTypeId, SUM(NULLIF(Tonnes, 0.0))
			FROM
				(
					-- C - z + y

					-- '+C' - all crusher removals
					SELECT CalendarDate, DesignationMaterialTypeId, SUM(Value) AS Tonnes
					FROM dbo.GetBhpbioReportActualC(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, NULL, @iIncludeLiveData, @iIncludeApprovedData)
					WHERE Attribute = 0
					GROUP BY CalendarDate, DesignationMaterialTypeId
					
					UNION ALL

					-- '-z' - pre crusher stockpiles to crusher
					SELECT CalendarDate, DesignationMaterialTypeId, -SUM(Value) AS Tonnes
					FROM dbo.GetBhpbioReportActualZ(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, NULL, @iIncludeLiveData, @iIncludeApprovedData)
					WHERE Attribute = 0
					GROUP BY CalendarDate, DesignationMaterialTypeId

					UNION ALL

					-- '+y' - pit to pre-crusher stockpiles
					SELECT CalendarDate, DesignationMaterialTypeId, SUM(Value)
					FROM dbo.GetBhpbioReportActualY(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, NULL, @iIncludeLiveData, @iIncludeApprovedData)
					WHERE Attribute = 0
					GROUP BY CalendarDate, DesignationMaterialTypeId
				) AS sub
				INNER JOIN @MaterialType AS mc
					ON (mc.MaterialTypeId = sub.DesignationMaterialTypeId)
			GROUP BY sub.CalendarDate, mc.RootMaterialTypeId
		END

		IF (@iIncludeBlockModels = 1)
		BEGIN
			INSERT INTO @Tonnes
			(
				Type, CalendarDate, MaterialTypeId, Tonnes
			)
			SELECT bm.Type, m.CalendarDate, mc.RootMaterialTypeId, SUM(m.Value)
			FROM dbo.GetBhpbioReportModel(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, NULL, @iIncludeLiveData, @iIncludeApprovedData) AS m
				INNER JOIN @Type AS bm
					ON (m.BlockModelId = bm.BlockModelId)
				INNER JOIN @MaterialType AS mc
					ON (mc.MaterialTypeId = m.DesignationMaterialTypeId)
			WHERE m.Attribute = 0
			GROUP BY bm.Type, m.CalendarDate, mc.RootMaterialTypeId
		END

		-- return the result		
		SELECT t.Type, t.BlockModelId, d.CalendarDate,
			mt.RootAbbreviation AS Material, mt.RootMaterialTypeId AS MaterialTypeId,
			Sum(r.Tonnes) As Tonnes
		FROM
			-- display all dates
			@Date AS d
			-- display all elisted types (block models + actual)
			CROSS JOIN @Type AS t
			-- ensure material types are represented uniformly
			CROSS JOIN
				(
					SELECT DISTINCT mt2.RootMaterialTypeId, mt2.RootAbbreviation, mt2.MaterialTypeId
					FROM @MaterialType AS mt2
					INNER JOIN @Tonnes AS tonnes ON (tonnes.MaterialTypeId = mt2.MaterialTypeId)
				) AS mt
			-- pivot in the results
			LEFT OUTER JOIN @Tonnes AS r
				ON (r.CalendarDate = d.CalendarDate
					AND r.MaterialTypeId = mt.MaterialTypeId
					AND r.Type = t.Type)
		GROUP BY t.Type, t.BlockModelId, d.CalendarDate,
			mt.RootAbbreviation, mt.RootMaterialTypeId
		ORDER BY d.CalendarDate, mt.RootAbbreviation, t.Type

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

/* testing

EXEC dbo.GetBhpbioReportBaseDataAsTonnes
	@iDateFrom = '01-APR-2008',
	@iDateTo = '30-JUN-2008',
	@iDateBreakdown = NULL,
	@iLocationId = 1,
	@iIncludeBlockModels = 1,
	@iBlockModels = NULL,
	@iIncludeActuals = 1,
	@iMaterialCategoryId = 'Designation',
	@iRootMaterialTypeId = NULL,
	@iIncludeLiveData = 0
	@iIncludeApprovedData = 1
*/

IF OBJECT_ID('dbo.GetBhpbioReportDataActualBeneProduct') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportDataActualBeneProduct
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReportDataActualBeneProduct
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iChildLocations BIT,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT
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

	DECLARE @ProductRecord TABLE
	(
		CalendarDate DATETIME NOT NULL,
		WeightometerSampleId INT NOT NULL,
		EffectiveTonnes FLOAT NOT NULL,
		MaterialTypeId INT NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		ParentLocationId INT NULL,
		PRIMARY KEY (CalendarDate, WeightometerSampleId, MaterialTypeId)
	)
	
	DECLARE @OutputTonnes TABLE
	(
		CalendarDate DATETIME,
		DateFrom DATETIME,
		DateTo DATETIME,
		LocationId INTEGER,
		MaterialTypeId INTEGER,
		Tonnes FLOAT
	)
	
	DECLARE @OutputGrades TABLE
	(
		CalendarDate DATETIME,
		DateFrom DATETIME,
		DateTo DATETIME,
		LocationId INTEGER,
		MaterialTypeId INTEGER,
		GradeId INTEGER,
		GradeValue FLOAT,
		Tonnes FLOAT
	)
	
	DECLARE @BeneProductMaterialTypeId INT
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioReportDataActualBeneProduct',
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
		-- collect the location subtree
		INSERT INTO @Location
			(LocationId, ParentLocationId)
		SELECT LocationId, ParentLocationId
		FROM dbo.GetBhpbioReportLocationBreakdown(@iLocationId, @iChildLocations, NULL)

		IF @iIncludeLiveData = 1
		BEGIN
			-- determine the return material type
			SET @BeneProductMaterialTypeId =
				(
					SELECT Material_Type_Id
					FROM dbo.MaterialType
					WHERE Material_Category_Id = 'Designation'
						AND Abbreviation = 'Bene Product'
				)

			INSERT INTO @ProductRecord
			(
				CalendarDate, WeightometerSampleId, EffectiveTonnes,
				MaterialTypeId, DateFrom, DateTo, ParentLocationId
			)
			SELECT b.CalendarDate, ws.Weightometer_Sample_Id, ISNULL(ws.Corrected_Tonnes, ws.Tonnes),
				@BeneProductMaterialTypeId, b.DateFrom, b.DateTo, l.ParentLocationId
			FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS b
				INNER JOIN dbo.WeightometerSample AS ws
					ON (ws.Weightometer_Sample_Date BETWEEN b.DateFrom AND b.DateTo)
				INNER JOIN
					(
						SELECT DISTINCT dttf.Weightometer_Sample_Id, ml.Location_Id
						FROM dbo.DataTransactionTonnesFlow AS dttf
							-- sourced from a mill
							INNER JOIN dbo.Mill AS m
								ON (m.Stockpile_Id = dttf.Source_Stockpile_Id)
							INNER JOIN dbo.MillLocation AS ml
								ON (m.Mill_Id = ml.Mill_Id)
							-- delivered to a post crusher stockpile
							INNER JOIN dbo.StockpileGroupStockpile AS sgs
								ON (dttf.Destination_Stockpile_Id = sgs.Stockpile_Id)
						WHERE sgs.Stockpile_Group_Id IN ('Post Crusher', 'High Grade')
					) AS dttf
					ON (dttf.Weightometer_Sample_Id = ws.Weightometer_Sample_Id)
				INNER JOIN @Location AS l
					ON (l.LocationId = dttf.Location_Id)
				LEFT JOIN dbo.BhpbioApprovalData bad
					ON bad.LocationId IN (l.ParentLocationId, l.LocationId)
					AND bad.TagId = 'F2MineProductionActuals'
					AND bad.ApprovedMonth = dbo.GetDateMonth(b.CalendarDate)
					AND @iIncludeApprovedData = 1
			WHERE bad.LocationId IS NULL
			
			-- return Tonnes
			INSERT INTO  @OutputTonnes
			(
				CalendarDate,
				DateFrom,
				DateTo,
				LocationId,
				MaterialTypeId,
				Tonnes
			)
			SELECT CalendarDate, DateFrom, DateTo, ParentLocationId, MaterialTypeId, SUM(EffectiveTonnes) AS Tonnes
			FROM @ProductRecord
			GROUP BY CalendarDate, ParentLocationId, DateFrom, DateTo, MaterialTypeId
				
			-- return Grades
			INSERT INTO @OutputGrades
			(
				CalendarDate,
				DateFrom,
				DateTo,
				LocationId,
				MaterialTypeId,
				GradeId,
				GradeValue,
				Tonnes
			)
			SELECT p.CalendarDate, p.DateFrom, p.DateTo, p.ParentLocationId, p.MaterialTypeId, wsg.Grade_Id, 
				SUM(p.EffectiveTonnes * wsg.Grade_Value) / SUM(p.EffectiveTonnes) AS GradeValue,
				SUM(p.EffectiveTonnes)
			FROM @ProductRecord AS p
				INNER JOIN dbo.WeightometerSampleGrade AS wsg
					ON wsg.Weightometer_Sample_Id = p.WeightometerSampleId 
			GROUP BY p.CalendarDate, p.DateFrom, p.DateTo, p.ParentLocationId, p.MaterialTypeId, wsg.Grade_Id
		END
		
		IF @iIncludeApprovedData = 1
		BEGIN
			DECLARE @summaryEntryType VARCHAR(24)
			SET @summaryEntryType = 'ActualBeneProduct'
			
			-- Retrieve Tonnes
			INSERT INTO  @OutputTonnes
			(
				CalendarDate,
				DateFrom,
				DateTo,
				LocationId,
				MaterialTypeId,
				Tonnes
			)
			SELECT s.CalendarDate, s.DateFrom, s.DateTo, l.ParentLocationId, s.MaterialTypeId, s.Tonnes
			FROM dbo.GetBhpbioSummaryTonnesBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryType, 0) s
				INNER JOIN @Location l
					ON l.LocationId = s.LocationId
			
			-- Retrieve Grades
			INSERT INTO @OutputGrades
			(
				CalendarDate,
				DateFrom,
				DateTo,
				LocationId,
				MaterialTypeId,
				GradeId,
				GradeValue,
				Tonnes
			)
			SELECT s.CalendarDate, s.DateFrom, s.DateTo,  l.ParentLocationId, s.MaterialTypeId, s.GradeId,  s.GradeValue, s.Tonnes
			FROM dbo.GetBhpbioSummaryGradeBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryType, 0, 1, 0) s
				INNER JOIN @Location l
					ON l.LocationId = s.LocationId
		END
		
		SELECT o.CalendarDate, o.LocationId AS ParentLocationId, o.DateFrom, o.DateTo, o.MaterialTypeId, SUM(o.Tonnes) AS Tonnes
		FROM @OutputTonnes o
		GROUP BY o.CalendarDate, o.LocationId, o.DateFrom, o.DateTo, o.MaterialTypeId
				
		-- return Grades
		SELECT o.CalendarDate, o.LocationId AS ParentLocationId, o.MaterialTypeId, g.Grade_Id, g.Grade_Name AS GradeName,
			SUM(o.Tonnes * o.GradeValue) / SUM(o.Tonnes) AS GradeValue
		FROM @OutputGrades o
			INNER JOIN dbo.Grade AS g
				ON g.Grade_Id = o.GradeId
		GROUP BY o.CalendarDate, o.LocationId, o.DateFrom, o.DateTo, o.MaterialTypeId, g.Grade_Id, g.Grade_Name

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

GRANT EXECUTE ON dbo.GetBhpbioReportDataActualBeneProduct TO BhpbioGenericManager
GO

/* testing

EXEC dbo.GetBhpbioReportDataActualBeneProduct 
	@iDateFrom = '1-apr-2008',
	@iDateTo = '30-apr-2008',
	@iDateBreakdown = 'MONTH',
	@iLocationId = 6,
	@iChildLocations = 1,
	@iIncludeLiveData = 0,
	@iIncludeApprovedData = 1
	
*/

IF OBJECT_ID('dbo.GetBhpbioReportDataActualExpitToStockpile') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportDataActualExpitToStockpile 
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReportDataActualExpitToStockpile
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iChildLocations BIT,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @ExpitToStockpile TABLE
	(
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		MaterialTypeId INT NOT NULL,
		LocationId INT NULL,
		Attribute INT NULL,
		Value FLOAT NULL
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioReportDataActualExpitToStockpile',
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
	
		INSERT INTO @ExpitToStockpile
			(CalendarDate, DateFrom, DateTo, MaterialTypeId, LocationId, Attribute, Value)
		SELECT Y.CalendarDate, Y.DateFrom, Y.DateTo, Y.DesignationMaterialTypeId, Y.LocationId, Y.Attribute, Y.Value
		FROM dbo.GetBhpbioReportActualY(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, @iChildLocations, @iIncludeLiveData, @iIncludeApprovedData) AS Y
			INNER JOIN dbo.GetBhpbioReportHighGrade() AS hg
				ON (Y.DesignationMaterialTypeId = hg.MaterialTypeId)
			
		SELECT CalendarDate, LocationId AS ParentLocationId, DateFrom, DateTo, MaterialTypeId, Value AS Tonnes
		FROM @ExpitToStockpile
		WHERE Attribute = 0
		
		SELECT CalendarDate, LocationId AS ParentLocationId, Attribute As GradeId,
			MaterialTypeId, G.Grade_Name As GradeName, ISNULL(Value, 0.0) As GradeValue
		FROM @ExpitToStockpile AS ETS
			INNER JOIN dbo.Grade AS G
				ON (ETS.Attribute = G.Grade_Id)
		WHERE ETS.Attribute > 0
	
		-- if we started a new transaction that istill valid then commit the changes
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

GRANT EXECUTE ON dbo.GetBhpbioReportDataActualExpitToStockpile TO BhpbioGenericManager
GO

/*
EXEC dbo.GetBhpbioReportDataActualExpitToStockpile
	@iDateFrom = '1-apr-2008', 
	@iDateTo = '30-apr-2008', 
	@iDateBreakdown = NULL,
	@iLocationId = 6,
	@iChildLocations = 1,
	@iIncludeLiveData = 0
	@iIncludeApprovedData = 1
*/
IF OBJECT_ID('dbo.GetBhpbioReportDataActualMineProduction') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportDataActualMineProduction  
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReportDataActualMineProduction
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iChildLocations BIT,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	DECLARE @ChildLocations BIT
	
	DECLARE @MineProductionActual TABLE
	(
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		MaterialTypeId INT NOT NULL,
		LocationId INT NULL,
		Attribute INT NOT NULL,
		Value FLOAT NULL
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioReportDataActualMineProduction',
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
		INSERT INTO @MineProductionActual
			(CalendarDate, DateFrom, DateTo, MaterialTypeId, LocationId, Attribute, Value)
		SELECT CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value
		FROM dbo.GetBhpbioReportActualC(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, @iChildLocations, @iIncludeLiveData, @iIncludeApprovedData)

		SELECT CalendarDate, LocationId AS ParentLocationId, DateFrom, DateTo, MaterialTypeId, Value AS Tonnes
		FROM @MineProductionActual
		WHERE Attribute = 0
		
		SELECT mpa.CalendarDate, mpa.LocationId AS ParentLocationId, mpa.Attribute As GradeId,
			mpa.MaterialTypeId, g.Grade_Name As GradeName, mpa.Value As GradeValue
		FROM @MineProductionActual AS mpa
			INNER JOIN dbo.Grade AS g
				ON (mpa.Attribute = g.Grade_Id)
		WHERE mpa.Attribute > 0

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

GRANT EXECUTE ON dbo.GetBhpbioReportDataActualMineProduction TO BhpbioGenericManager
GO

/*
EXEC dbo.GetBhpbioReportDataActualMineProduction 
	@iDateFrom = '1-JUN-2009', 
	@iDateTo = '30-JUN-2009', 
	@iDateBreakdown = null,
	@iLocationId = 1,
	@iChildLocations = 0,
	@iIncludeLiveData = 0,
	@iIncludeApprovedData = 1
*/
IF OBJECT_ID('dbo.GetBhpbioReportDataActualStockpileToCrusher') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportDataActualStockpileToCrusher 
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReportDataActualStockpileToCrusher
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iChildLocations BIT,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @StockpileToCrusher TABLE
	(
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		MaterialTypeId INT NOT NULL,
		LocationId INT NULL,
		Attribute INT NULL,
		Value FLOAT NULL
	)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioReportDataActualStockpileToCrusher',
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
		INSERT INTO @StockpileToCrusher
			(CalendarDate, DateFrom, DateTo, MaterialTypeId, LocationId, Attribute, Value)
		SELECT CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value
		FROM dbo.GetBhpbioReportActualZ(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, @iChildLocations, @iIncludeLiveData, @iIncludeApprovedData)
			
		SELECT CalendarDate, LocationId AS ParentLocationId, DateFrom, DateTo, MaterialTypeId, Value AS Tonnes
		FROM @StockpileToCrusher
		WHERE Attribute = 0
		
		SELECT CalendarDate, LocationId AS ParentLocationId, Attribute As GradeId,
			MaterialTypeId, G.Grade_Name As GradeName, ISNULL(Value, 0.0) As GradeValue
		FROM @StockpileToCrusher AS STC
			INNER JOIN dbo.Grade AS G
				ON (STC.Attribute = G.Grade_Id)
		WHERE STC.Attribute > 0

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

GRANT EXECUTE ON dbo.GetBhpbioReportDataActualStockpileToCrusher TO BhpbioGenericManager
GO

/*
EXEC dbo.GetBhpbioReportDataActualStockpileToCrusher
	@iDateFrom = '1-apr-2008', 
	@iDateTo = '30-apr-2008', 
	@iDateBreakdown = NULL,
	@iLocationId = 6,
	@iChildLocations = 1,
	@iIncludeLiveData = 0
	@iIncludeApprovedData = 1
*/
IF OBJECT_ID('dbo.GetBhpbioReportDataBlockModel') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportDataBlockModel
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReportDataBlockModel
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iChildLocations BIT,
	@iBlockModelName VARCHAR(31),
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @modelApprovalTagId VARCHAR(31)
	DECLARE @BlockModelId INT
	DECLARE @MaterialCategory VARCHAR(31)
	SET @MaterialCategory = 'Designation'
	
	DECLARE @TonnesTable TABLE
	(
		BlockModelId INT NULL,
		BlockModelName VARCHAR(31) NULL,
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		MaterialTypeId INT NOT NULL,
		ParentLocationId INT NULL,
		Tonnes FLOAT NOT NULL
	)
	DECLARE @GradesTable TABLE
	(
		BlockModelId INT NULL,
		BlockModelName VARCHAR(31) NULL,
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		MaterialTypeId INT NOT NULL,
		ParentLocationId INT NULL,
		GradeId INT NOT NULL,
		GradeValue FLOAT NOT NULL,
		Tonnes FLOAT NOT NULL
	)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioReportDataBlockModel',
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

	DECLARE curBlockModelCursor CURSOR FOR	SELECT DISTINCT Block_Model_Id, Name 
											FROM dbo.BlockModel bm
											WHERE (Name = @iBlockModelName OR @iBlockModelName IS NULL)
												AND bm.Is_Default = 1

	DECLARE @currentBlockModelName VARCHAR(31)
  			
	BEGIN TRY
	
		OPEN curBlockModelCursor
		DECLARE @Location TABLE
		(
			LocationId INTEGER,
			ParentLocationId INTEGER
		)
		
		DECLARE @ModelMovement TABLE
				(
					CalendarDate DATETIME NOT NULL,
					DateFrom DATETIME NOT NULL,
					DateTo DATETIME NOT NULL,
					MaterialTypeId INT NOT NULL,
					BlockModelId INT NOT NULL,
					ParentLocationId INT NULL,
					ModelBlockId INT NOT NULL,
					SequenceNo INT NOT NULL,
					MinedPercentage FLOAT NOT NULL,
					Tonnes FLOAT NOT NULL,
					PRIMARY KEY (CalendarDate, DateFrom, DateTo, MaterialTypeId, BlockModelId, ModelBlockId, SequenceNo)
				)
		
		INSERT INTO @Location
			(LocationId, ParentLocationId)
		SELECT LocationId, ParentLocationId
		FROM dbo.GetBhpbioReportLocationBreakdown(@iLocationId, @iChildLocations, NULL)
		
		FETCH NEXT FROM curBlockModelCursor INTO @BlockModelId, @currentBlockModelName
		
		WHILE @@FETCH_STATUS = 0
		BEGIN
		
			DELETE FROM @ModelMovement

			IF @iIncludeLiveData  = 1
			BEGIN
			
				SELECT @modelApprovalTagId = 
				'F1' + REPLACE(@currentBlockModelName,' ','') + 'Model'

				-- Insert the MBP
				INSERT INTO @ModelMovement
					(CalendarDate, DateFrom, DateTo, BlockModelId, MaterialTypeId, ParentLocationId, ModelBlockId, SequenceNo, MinedPercentage, Tonnes)
				SELECT B.CalendarDate, B.DateFrom, B.DateTo, MB.Block_Model_Id, MT.Material_Type_Id, L.ParentLocationId, 
					MBP.Model_Block_Id, MBP.Sequence_No, 
					SUM(RM.MinedPercentage), SUM(RM.MinedPercentage * MBP.Tonnes)
				FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
					INNER JOIN dbo.BhpbioImportReconciliationMovement AS RM
						ON (RM.DateFrom >= B.DateFrom
							AND RM.DateTo <= B.DateTo)
					INNER JOIN @Location AS L
						ON (L.LocationId = RM.BlockLocationId)
					INNER JOIN dbo.ModelBlockLocation AS MBL
						ON (L.LocationId = MBL.Location_Id)
					INNER JOIN dbo.ModelBlock AS MB
						ON (MBL.Model_Block_Id = MB.Model_Block_Id)
					INNER JOIN dbo.ModelBlockPartial AS MBP
						ON (MB.Model_Block_Id = MBP.Model_Block_Id)
					INNER JOIN dbo.GetMaterialsByCategory(@MaterialCategory) AS MC
						ON (MC.MaterialTypeId = MBP.Material_Type_Id)
					INNER JOIN dbo.MaterialType AS MT
						ON (MC.RootMaterialTypeId = MT.Material_Type_Id)
					INNER JOIN dbo.GetBhpbioReportHighGrade() AS BRHG
						ON (BRHG.MaterialTypeId = MT.Material_Type_Id)
					INNER JOIN dbo.Location block 
						ON block.Location_Id = L.LocationId
					INNER JOIN dbo.Location blast 
						ON blast.Location_Id = block.Parent_Location_Id
					INNER JOIN dbo.Location bench 
						ON bench.Location_Id = blast.Parent_Location_Id
					INNER JOIN dbo.Location pit 
						ON pit.Location_Id = bench.Parent_Location_Id
					LEFT JOIN dbo.BhpbioApprovalData a
						ON a.LocationId = pit.Location_Id
						AND a.TagId = @modelApprovalTagId
						AND a.ApprovedMonth = dbo.GetDateMonth(RM.DateFrom)
				WHERE	(	
							MB.Block_Model_Id = @BlockModelId 
						)
						AND
						(
							@iIncludeApprovedData = 0
							OR 
							a.LocationId IS NULL
						)
				GROUP BY B.CalendarDate, B.DateFrom, B.DateTo, MB.Block_Model_Id, MT.Material_Type_Id, 
					L.ParentLocationId, MBP.Model_Block_Id, MBP.Sequence_No
				-- Retrieve Tonnes
				INSERT INTO @TonnesTable
				(
					BlockModelId,
					BlockModelName,
					CalendarDate,
					DateFrom,
					DateTo,
					MaterialTypeId,
					ParentLocationId,
					Tonnes
				)
				SELECT MM.BlockModelId, BM.Name AS ModelName, MM.CalendarDate, MM.DateFrom, MM.DateTo, MM.MaterialTypeId, MM.ParentLocationId, SUM(MM.Tonnes) AS Tonnes
				FROM @ModelMovement AS MM
					INNER JOIN dbo.BlockModel AS BM
						ON (BM.Block_Model_Id = MM.BlockModelId)
				GROUP BY MM.CalendarDate, MM.DateFrom, MM.DateTo, MM.MaterialTypeId, MM.ParentLocationId, MM.BlockModelId, BM.Name

				-- Retrieve Grades
				INSERT INTO @GradesTable
				(
					BlockModelId,
					BlockModelName,
					CalendarDate,
					DateFrom,
					DateTo,
					MaterialTypeId,
					ParentLocationId,
					GradeId,
					GradeValue,
					Tonnes
				)
				SELECT MM.BlockModelId, BM.Name AS ModelName, MM.CalendarDate, MM.DateFrom, MM.DateTo, MM.MaterialTypeId, MM.ParentLocationId, MBPG.Grade_Id,
					SUM(MBP.Tonnes * MM.MinedPercentage * MBPG.Grade_Value) / SUM(MBP.Tonnes * MM.MinedPercentage) As GradeValue,
					SUM(MBP.Tonnes * MM.MinedPercentage)
				FROM @ModelMovement AS MM
					INNER JOIN dbo.BlockModel AS BM
						ON (BM.Block_Model_Id = MM.BlockModelId)
					INNER JOIN dbo.ModelBlockPartial AS MBP
						ON (MBP.Model_Block_Id = MM.ModelBlockId
							AND MBP.Sequence_No = MM.SequenceNo)
					INNER JOIN dbo.ModelBlockPartialGrade AS MBPG
						ON (MBP.Model_Block_Id = MBPG.Model_Block_Id
							AND MBP.Sequence_No = MBPG.Sequence_No)
				GROUP BY MM.BlockModelId, BM.Name, MM.CalendarDate, MM.ParentLocationId, MM.DateFrom, MM.DateTo, MM.MaterialTypeId, MBPG.Grade_Id
			END
			
			IF @iIncludeApprovedData  = 1
			BEGIN
			
				DECLARE @summaryEntryTypeId INT
		
				SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
				FROM dbo.BhpbioSummaryEntryType bset
				WHERE bset.Name = REPLACE(@currentBlockModelName,' ','') + 'ModelMovement'
					AND bset.AssociatedBlockModelId = @BlockModelId
							
				-- Retrieve Tonnes
				INSERT INTO @TonnesTable
				(
					BlockModelId,
					BlockModelName,
					CalendarDate,
					DateFrom,
					DateTo,
					MaterialTypeId,
					ParentLocationId,
					Tonnes
				)
				SELECT @BlockModelId AS BlockModelId, @currentBlockModelName AS ModelName, B.CalendarDate AS CalendarDate, B.DateFrom, B.DateTo, MT.Material_Type_Id, l.ParentLocationId AS ParentLocationId, SUM(bse.Tonnes) AS Tonnes
				FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
					INNER JOIN dbo.BhpbioSummary s
						ON s.SummaryMonth >= B.DateFrom AND s.SummaryMonth < B.DateTo
					INNER JOIN dbo.BhpbioSummaryEntry AS bse
						ON bse.SummaryId = s.SummaryId
						AND bse.SummaryEntryTypeId = @summaryEntryTypeId
					INNER JOIN @Location l
						ON l.LocationId = bse.LocationId
					INNER JOIN dbo.GetMaterialsByCategory(@MaterialCategory) AS MC
						ON (MC.MaterialTypeId = bse.MaterialTypeId)
					INNER JOIN dbo.MaterialType AS MT
						ON (MC.RootMaterialTypeId = MT.Material_Type_Id)
					INNER JOIN dbo.GetBhpbioReportHighGrade() AS BRHG
						ON (BRHG.MaterialTypeId = MT.Material_Type_Id)
				GROUP BY B.CalendarDate, B.DateFrom, B.DateTo, MT.Material_Type_Id, l.ParentLocationId

				-- Retrieve Grades
				INSERT INTO @GradesTable
				(
					BlockModelId,
					BlockModelName,
					CalendarDate,
					DateFrom,
					DateTo,
					ParentLocationId,
					MaterialTypeId,
					GradeId,
					GradeValue,
					Tonnes
				)
				SELECT @BlockModelId AS BlockModelId, @currentBlockModelName AS ModelName, B.CalendarDate AS CalendarDate, B.DateFrom, B.DateTo, l.ParentLocationId AS ParentLocationId, MT.Material_Type_Id, bseg.GradeId,
					SUM(bse.Tonnes * bseg.GradeValue) / SUM(bse.Tonnes) As GradeValue,
					SUM(bse.Tonnes)
				FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
					INNER JOIN dbo.BhpbioSummary s
						ON s.SummaryMonth >= B.DateFrom AND s.SummaryMonth < B.DateTo
					INNER JOIN dbo.BhpbioSummaryEntry AS bse
						ON bse.SummaryId = s.SummaryId
						AND bse.SummaryEntryTypeId = @summaryEntryTypeId
					INNER JOIN @Location l
						ON l.LocationId = bse.LocationId
					INNER JOIN dbo.BhpbioSummaryEntryGrade AS bseg
						ON bseg.SummaryEntryId = bse.SummaryEntryId
					INNER JOIN dbo.GetMaterialsByCategory(@MaterialCategory) AS MC
						ON (MC.MaterialTypeId = bse.MaterialTypeId)
					INNER JOIN dbo.MaterialType AS MT
						ON (MC.RootMaterialTypeId = MT.Material_Type_Id)
					INNER JOIN dbo.GetBhpbioReportHighGrade() AS BRHG
						ON (BRHG.MaterialTypeId = MT.Material_Type_Id)
				GROUP BY B.CalendarDate, l.ParentLocationId, B.DateFrom, B.DateTo, MT.Material_Type_Id, bseg.GradeId
			END
			
			FETCH NEXT FROM curBlockModelCursor INTO @BlockModelId, @currentBlockModelName
			
		END
		-- output combined tonnes
		SELECT t.BlockModelId, t.BlockModelName AS ModelName, t.CalendarDate, 
			t.DateFrom, t.DateTo, t.MaterialTypeId, t.ParentLocationId, Sum(t.Tonnes) as Tonnes
		FROM @TonnesTable t
		GROUP BY t.CalendarDate, t.DateFrom, t.DateTo, t.MaterialTypeId, t.ParentLocationId, t.BlockModelId, t.BlockModelName
		
		-- output combined grades
		SELECT gt.BlockModelId, gt.BlockModelName AS ModelName, gt.CalendarDate, 
			gt.DateFrom, gt.DateTo, gt.ParentLocationId, gt.MaterialTypeId, g.Grade_Name As GradeName,
			SUM(gt.Tonnes * gt.GradeValue) / SUM(gt.Tonnes) As GradeValue
		FROM @GradesTable AS gt
			INNER JOIN dbo.Grade g
				ON (g.Grade_Id = gt.GradeId)
		GROUP BY gt.BlockModelId, gt.BlockModelName, gt.CalendarDate, gt.ParentLocationId, gt.DateFrom, gt.DateTo, gt.MaterialTypeId, g.Grade_Name
		
		CLOSE curBlockModelCursor
		DEALLOCATE curBlockModelCursor
		
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

GRANT EXECUTE ON dbo.GetBhpbioReportDataBlockModel TO BhpbioGenericManager
GO

/*
EXEC dbo.GetBhpbioReportDataBlockModel
	@iDateFrom = '1-apr-2008',
	@iDateTo = '1-jun-2009',
	@iDateBreakdown = 'MONTH',
	@iLocationId = 1,
	@iLocationBreakdown = 'ChildLocations',
	@iBlockModelName = NULL,
	@iIncludeLiveData = 1,
	@iIncludeApprovedData = 1
*/
IF OBJECT_ID('dbo.GetBhpbioReportDataHubPostCrusherStockpileDelta') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportDataHubPostCrusherStockpileDelta
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReportDataHubPostCrusherStockpileDelta
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iChildLocations BIT,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @OutputTonnes TABLE
	(
		CalendarDate DATETIME,
		DateFrom DATETIME,
		DateTo DATETIME,
		LocationId INTEGER,
		Tonnes FLOAT
	)
	
	DECLARE @OutputGrades TABLE
	(
		CalendarDate DATETIME,
		LocationId INTEGER,
		GradeId INTEGER,
		GradeValue FLOAT,
		Tonnes FLOAT
	)
	
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		ParentLocationId INT NULL,
		PRIMARY KEY (LocationId)
	)

	DECLARE @StockpileDelta TABLE
	(
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		StockpileId INT NOT NULL,
		WeightometerSampleId INT NOT NULL,
		Tonnes FLOAT NOT NULL,
		LocationId INT NULL,
		Addition BIT NOT NULL,
		ChildLocationId INT NULL,
		PRIMARY KEY (CalendarDate, StockpileId, WeightometerSampleId, Addition)
	)
	
	DECLARE @GradeLocation TABLE
	(
		CalendarDate DATETIME NOT NULL,
		ActualLocationId INT NULL
	)
	
	DECLARE @StockpileGroupId VARCHAR(31)
	SET @StockpileGroupId = 'Post Crusher'
	DECLARE @LastShift CHAR(1)
	DECLARE @HubLocationTypeId INT
	DECLARE @SiteLocationTypeId INT
	DECLARE @SampleSourceField VARCHAR(31)
	SET @SampleSourceField = 'SampleSource'
	DECLARE @SampleTonnesField VARCHAR(31)
	SET @SampleTonnesField = 'SampleTonnes'
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioReportDataHubPostCrusherStockpileDelta',
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
		INSERT INTO @Location
			(LocationId, ParentLocationId)
		SELECT LocationId, ParentLocationId
		FROM dbo.GetBhpbioReportLocationBreakdown(@iLocationId, @iChildLocations, 'Site')

		IF @iIncludeLiveData = 1
		BEGIN

			SELECT @HubLocationTypeId = Location_Type_Id
			FROM dbo.LocationType WITH (NOLOCK) 
			WHERE Description = 'Hub'
			SELECT @SiteLocationTypeId = Location_Type_Id
			FROM dbo.LocationType WITH (NOLOCK) 
			WHERE Description = 'Site'

			-- Get Removals
			INSERT INTO @StockpileDelta
				(CalendarDate, DateFrom, DateTo, StockpileId, WeightometerSampleId, Addition, Tonnes, LocationId, ChildLocationId)		
			SELECT CalendarDate, DateFrom, DateTo, S.Stockpile_Id, WS.Weightometer_Sample_Id, 0, WS.Tonnes, L.ParentLocationId, L.LocationId
			FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
				INNER JOIN dbo.WeightometerSample AS WS WITH (NOLOCK) 
					ON (WS.Weightometer_Sample_Date BETWEEN B.DateFrom AND B.DateTo)
				INNER JOIN dbo.Stockpile AS S WITH (NOLOCK)
					ON (S.Stockpile_Id = WS.Source_Stockpile_Id)
				INNER JOIN dbo.StockpileGroupStockpile AS SGS WITH (NOLOCK)
					ON (SGS.Stockpile_Id = S.Stockpile_Id)
				INNER JOIN dbo.StockpileLocation AS SL WITH (NOLOCK) 
					ON (SL.Stockpile_Id = S.Stockpile_Id)
				INNER JOIN @Location AS L
					ON (L.LocationId = SL.Location_Id)
				INNER JOIN dbo.Location AS LL WITH (NOLOCK)
					ON (LL.Location_Id = L.LocationId)
				LEFT JOIN dbo.BhpbioLocationStockpileConfiguration AS BSLC WITH (NOLOCK)
					ON (BSLC.LocationId = SL.Location_Id)
				LEFT JOIN dbo.StockpileGroupStockpile AS SGS_D WITH (NOLOCK)
					ON (SGS_D.Stockpile_Id = WS.Destination_Stockpile_Id
						AND SGS_D.Stockpile_Group_Id = @StockpileGroupId)
				LEFT JOIN dbo.BhpbioApprovalData bad
					ON bad.LocationId = CASE WHEN LL.Location_Type_Id = @HubLocationTypeId THEN LL.Location_Id ELSE LL.Parent_Location_Id END
					AND bad.TagId = 'F3PostCrusherStockpileDelta'
					AND bad.ApprovedMonth = dbo.GetDateMonth(WS.Weightometer_Sample_Date)
			WHERE Coalesce(WS.Source_Stockpile_Id, -1) <> Coalesce(WS.Destination_Stockpile_Id, -1)
				AND SGS.Stockpile_Group_Id = @StockpileGroupId
				AND SGS_D.Stockpile_Group_Id IS NULL -- Ensure join to check if destination is Post Crusher isn't true.
				AND (LL.Location_Type_Id = @HubLocationTypeId OR
				(BSLC.PromoteStockpiles = 1 AND LL.Location_Type_Id = @SiteLocationTypeId))
				AND (@iIncludeApprovedData = 0 OR bad.TagId IS NULL)
				
			-- Get Additions
			INSERT INTO @StockpileDelta
				(CalendarDate, DateFrom, DateTo, StockpileId, WeightometerSampleId, Addition, Tonnes, LocationId, ChildLocationId)		
			SELECT CalendarDate, DateFrom, DateTo, S.Stockpile_Id, WS.Weightometer_Sample_ID, 1, WS.Tonnes, L.ParentLocationId, L.LocationId
			FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
				INNER JOIN dbo.WeightometerSample AS WS WITH (NOLOCK)
					ON (WS.Weightometer_Sample_Date BETWEEN B.DateFrom AND B.DateTo)
				INNER JOIN dbo.Stockpile AS S WITH (NOLOCK)
					ON (S.Stockpile_Id = WS.Destination_Stockpile_Id)
				INNER JOIN dbo.StockpileGroupStockpile AS SGS WITH (NOLOCK)
					ON (SGS.Stockpile_Id = S.Stockpile_Id)
				INNER JOIN dbo.StockpileLocation AS SL WITH (NOLOCK)
					ON (SL.Stockpile_Id = S.Stockpile_Id)
				INNER JOIN @Location AS L
					ON (L.LocationId = SL.Location_Id)
				INNER JOIN dbo.Location AS LL WITH (NOLOCK)
					ON (LL.Location_Id = L.LocationId)
				LEFT JOIN dbo.BhpbioLocationStockpileConfiguration AS BSLC WITH (NOLOCK)
					ON (BSLC.LocationId = SL.Location_Id)
				LEFT JOIN dbo.StockpileGroupStockpile AS SGS_S WITH (NOLOCK)
					ON (SGS_S.Stockpile_Id = WS.Source_Stockpile_Id
						AND SGS_S.Stockpile_Group_Id = @StockpileGroupId)
				LEFT JOIN dbo.BhpbioApprovalData bad
					ON bad.LocationId = CASE WHEN LL.Location_Type_Id = @HubLocationTypeId THEN LL.Location_Id ELSE LL.Parent_Location_Id END
					AND bad.TagId = 'F3PostCrusherStockpileDelta'
					AND bad.ApprovedMonth = dbo.GetDateMonth(WS.Weightometer_Sample_Date)
			WHERE Coalesce(WS.Source_Stockpile_Id, -1) <> Coalesce(WS.Destination_Stockpile_Id, -1)
				AND SGS.Stockpile_Group_Id = @StockpileGroupId
				AND SGS_S.Stockpile_Group_Id IS NULL  -- Ensure join to check if source is Post Crusher isn't true.
				AND (LL.Location_Type_Id = @HubLocationTypeId OR 
				(BSLC.PromoteStockpiles = 1 AND LL.Location_Type_Id = @SiteLocationTypeId))
				AND (@iIncludeApprovedData = 0 OR bad.TagId IS NULL)
				
			-- Obtain the Delta tonnes
			INSERT INTO @OutputTonnes
			(
				CalendarDate,
				DateFrom,
				DateTo,
				LocationId,
				Tonnes
			)
			SELECT SD.CalendarDate, SD.DateFrom, SD.DateTo, SD.LocationId AS ParentLocationId,
				Sum(CASE WHEN SD.Addition = 1 THEN SD.Tonnes ELSE -SD.Tonnes END) AS Tonnes
			FROM @StockpileDelta AS SD
			GROUP BY SD.CalendarDate, SD.DateFrom, SD.DateTo, SD.LocationId;

			-- calculate grade values by location and time period and select these for use in output query
			-- these grade values should be weighted based on sample tonnes for the location
			WITH GradesByLocationAndPeriod AS
			(
				SELECT B.CalendarDate, G.Grade_Id AS GradeId, L.ParentLocationId, L.LocationId, 
					sum(WSV.Field_Value * WSG.Grade_Value) / nullif(sum(WSV.Field_Value), 0) As GradeValue				
				FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
					INNER JOIN dbo.WeightometerSample AS WS WITH (NOLOCK)
						ON (WS.Weightometer_Sample_Date BETWEEN B.DateFrom AND B.DateTo)
					INNER JOIN WeightometerSampleGrade AS WSG WITH (NOLOCK)
						ON (ws.Weightometer_Sample_Id = WSG.Weightometer_Sample_Id)
					INNER JOIN dbo.WeightometerLocation AS WL WITH (NOLOCK)
						ON (ws.Weightometer_Id = wl.Weightometer_Id)
					INNER JOIN @Location AS L
						ON (L.LocationId = wl.Location_Id)
					INNER JOIN dbo.WeightometerSampleNotes AS WSN WITH (NOLOCK)
						ON (wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
							AND wsn.Weightometer_Sample_Field_Id = @SampleSourceField)
					INNER JOIN dbo.WeightometerSampleValue AS WSV WITH (NOLOCK)
						ON (wsv.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
							AND wsv.Weightometer_Sample_Field_Id = @SampleTonnesField)
					INNER JOIN dbo.GetBhpbioWeightometerSampleSource(@iLocationId, @iDateFrom, @iDateTo) AS ss
						ON (dbo.GetDateMonth(ws.Weightometer_Sample_Date) = ss.MonthPeriod
							AND L.LocationId = ss.LocationId
								AND wsn.Notes = ss.SampleSource)
					INNER JOIN dbo.Location AS LL WITH (NOLOCK)
						ON (LL.Location_Id = L.LocationId)
					INNER JOIN Grade AS G WITH (NOLOCK)
						ON (G.Grade_Id = WSG.Grade_Id)
					LEFT JOIN dbo.BhpbioLocationStockpileConfiguration AS BSLC WITH (NOLOCK)
						ON (BSLC.LocationId = L.LocationId)
					LEFT JOIN dbo.BhpbioApprovalData bad
						ON bad.LocationId = CASE WHEN LL.Location_Type_Id = @HubLocationTypeId THEN LL.Location_Id ELSE LL.Parent_Location_Id END
						AND bad.TagId = 'F3PostCrusherStockpileDelta'
					 AND bad.ApprovedMonth = dbo.GetDateMonth(WS.Weightometer_Sample_Date)
				WHERE (LL.Location_Type_Id = @HubLocationTypeId OR 
					(BSLC.PromoteStockpiles = 1 AND LL.Location_Type_Id = @SiteLocationTypeId))
					 AND (@iIncludeApprovedData = 0 OR bad.TagId IS NULL)
				GROUP BY B.CalendarDate, G.Grade_Id, L.ParentLocationId, L.LocationId
			)
			INSERT INTO @OutputGrades
			(
				CalendarDate,
				LocationId,
				GradeId,
				GradeValue,
				Tonnes
			)
			-- now weight the lower level locations to get values at the parent level
			-- this second round of weighting should be done on tonnes rather than sample tonnes
			-- (ie locations weighted against each other based on tonnes)
			SELECT gblp.CalendarDate, gblp.ParentLocationId, gblp.GradeId,
				SUM(gblp.GradeValue * sd.Tonnes) / NULLIF(SUM(sd.Tonnes), 0) AS GradeValue,
				SUM(sd.Tonnes)
			FROM GradesByLocationAndPeriod AS gblp
				-- inner join the temporary table summing all tones by location
				INNER JOIN (SELECT sd.CalendarDate, sd.ChildLocationId AS LocationId,
								ABS(SUM(CASE WHEN sd.Addition = 1 THEN sd.Tonnes ELSE -sd.Tonnes END)) AS Tonnes
							FROM @StockpileDelta sd
							GROUP BY sd.CalendarDate, sd.ChildLocationId) AS sd
					ON sd.LocationId = gblp.LocationId
					AND sd.CalendarDate = gblp.CalendarDate
			-- group by time period, grade and parent location level
			GROUP BY gblp.CalendarDate, gblp.GradeId, gblp.ParentLocationId
		END
		
		IF @iIncludeApprovedData = 1
		BEGIN
			DECLARE @summaryEntryType VARCHAR(31)
			SET @summaryEntryType = 'HubPostCrusherStockpileDelta'
			
			DECLARE @summaryEntryTypeId INT
			SELECT @summaryEntryTypeId = st.SummaryEntryTypeId
			FROM dbo.BhpbioSummaryEntryType st
			WHERE st.Name = @summaryEntryType
			
			DECLARE @summaryGradesEntryType VARCHAR(31)
			SET @summaryGradesEntryType = 'HubPostCrusherSpDeltaGrades'
			
			DECLARE @summaryGradesEntryTypeId INT
			SELECT @summaryGradesEntryTypeId = st.SummaryEntryTypeId
			FROM dbo.BhpbioSummaryEntryType st
			WHERE st.Name = @summaryGradesEntryType
			
			-- Retrieve Tonnes
			INSERT INTO @OutputTonnes
				(CalendarDate, DateFrom, DateTo, LocationId, Tonnes)
			SELECT s.CalendarDate, s.DateFrom, s.DateTo, l.ParentLocationId, s.Tonnes
			FROM dbo.GetBhpbioSummaryTonnesBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryType, 1) s
				INNER JOIN @Location l
					ON l.LocationId = s.LocationId;
			
			-- weight the grades by location by sample tonnes
			WITH GradesWeightedBySampleTonnes AS
			(
				SELECT	B.CalendarDate AS CalendarDate, 
						B.DateFrom, 
						B.DateTo,
						bse.LocationId,
						ll.Parent_Location_Id,
						bseg.GradeId,
						SUM(bseg.GradeValue * bse.Tonnes)/ SUM(bse.Tonnes) AS GradeValue
				FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
					INNER JOIN dbo.BhpbioSummary s WITH (NOLOCK)
						ON s.SummaryMonth >= B.DateFrom AND s.SummaryMonth < B.DateTo
					INNER JOIN dbo.BhpbioSummaryEntry AS bse WITH (NOLOCK)
						ON bse.SummaryId = s.SummaryId
						AND bse.SummaryEntryTypeId = @summaryGradesEntryTypeId
					INNER JOIN dbo.BhpbioSummaryEntryGrade AS bseg WITH (NOLOCK)
						ON bseg.SummaryEntryId = bse.SummaryEntryId
					INNER JOIN @Location l
						ON l.LocationId = bse.LocationId
					INNER JOIN dbo.Location ll
						ON ll.Location_Id = l.LocationId
				GROUP BY B.CalendarDate, B.DateFrom, B.DateTo, bse.LocationId, ll.Parent_Location_Id, bseg.GradeId
				HAVING SUM(ABS(bse.Tonnes)) > 0
			), TonnesByLocation AS
			(
				SELECT B.CalendarDate, bse.LocationId, SUM(bse.Tonnes) AS Tonnes
				FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
					INNER JOIN dbo.BhpbioSummary s WITH (NOLOCK)
							ON s.SummaryMonth >= B.DateFrom AND s.SummaryMonth < B.DateTo
					INNER JOIN dbo.BhpbioSummaryEntry AS bse WITH (NOLOCK)
						ON bse.SummaryId = s.SummaryId
						AND bse.SummaryEntryTypeId = @summaryEntryTypeId
					INNER JOIN @Location l
						ON l.LocationId = bse.LocationId
				GROUP BY B.CalendarDate, bse.LocationId
			)
			-- then weight across locations by normal tonnes
			-- Retrieve Grades
			INSERT INTO @OutputGrades
			(
				CalendarDate,
				LocationId,
				GradeId,
				GradeValue,
				Tonnes
			)
			SELECT B.CalendarDate, l.ParentLocationId, gwbst.GradeId,  
				SUM(gwbst.GradeValue * ABS(tbl.Tonnes))/SUM(ABS(tbl.Tonnes)), 
				SUM(tbl.Tonnes)
			FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
				INNER JOIN TonnesByLocation tbl ON tbl.CalendarDate = B.CalendarDate
				INNER JOIN GradesWeightedBySampleTonnes gwbst
					ON gwbst.CalendarDate = B.CalendarDate
					AND gwbst.LocationId = tbl.LocationId
				INNER JOIN @Location l
					ON l.LocationId = gwbst.LocationId
			GROUP BY B.CalendarDate, l.ParentLocationId, gwbst.GradeId
		END

		-- Output the tonnes
		SELECT o.CalendarDate, o.DateFrom, o.DateTo, NULL AS MaterialTypeId, o.LocationId AS ParentLocationId,
			Sum(o.Tonnes) AS Tonnes
		FROM @OutputTonnes o
		GROUP BY o.CalendarDate, o.DateFrom, o.DateTo, o.LocationId

		-- Output the grades
		SELECT o.CalendarDate, G.Grade_Name As GradeName, NULL AS MaterialTypeId, o.LocationId AS ParentLocationId,
			Sum(ABS(o.Tonnes) * o.GradeValue) / NULLIF(Sum(ABS(o.Tonnes)), 0) AS GradeValue
		FROM @OutputGrades AS o
			INNER JOIN dbo.Grade AS G
				ON (G.Grade_Id = o.GradeId)
		GROUP BY o.CalendarDate, G.Grade_Name, o.LocationId
		
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

GRANT EXECUTE ON dbo.GetBhpbioReportDataHubPostCrusherStockpileDelta TO BhpbioGenericManager
GO

/*
exec dbo.GetBhpbioReportDataHubPostCrusherStockpileDelta 
@iDateFrom='2008-04-01 00:00:00',@iDateTo='2008-Jun-30 00:00:00',@iDateBreakdown=NULL,@iLocationId=1,@iChildLocations=0
*/
IF OBJECT_ID('dbo.GetBhpbioReportDataPortBlendedAdjustment') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportDataPortBlendedAdjustment 
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReportDataPortBlendedAdjustment
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iChildLocations BIT,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT
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
	
	DECLARE @Blending TABLE
	(
		CalendarDate DATETIME,
		DateFrom DATETIME,
		DateTo DATETIME,
		BhpbioPortBlendingId INT,
		ParentLocationId INT,
		Tonnes FLOAT,
		Removal BIT
	)
	
	DECLARE @BlendingGrades TABLE
	(
		CalendarDate DATETIME,
		DateFrom DATETIME,
		DateTo DATETIME,
		ParentLocationId INT,
		GradeId FLOAT,
		GradeValue FLOAT,
		Tonnes FLOAT
	)
		
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioReportDataPortBlendedAdjustment',
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
		INSERT INTO @Location
			(LocationId, ParentLocationId)
		SELECT LocationId, ParentLocationId
		FROM dbo.GetBhpbioReportLocationBreakdown(@iLocationId, @iChildLocations, 'SITE')

		IF @iIncludeLiveData = 1
		BEGIN
			INSERT INTO @Blending
				(CalendarDate, DateFrom, DateTo, BhpbioPortBlendingId, ParentLocationId, Tonnes, Removal)
			SELECT B.CalendarDate, B.DateFrom, B.DateTo, BPB.BhpbioPortBlendingId,
				L.ParentLocationId, BPB.Tonnes, CASE WHEN BPB.DestinationHubLocationId = L.LocationId THEN 0 ELSE 1 END
			FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
				INNER JOIN dbo.BhpbioPortBlending AS BPB
					ON (BPB.StartDate >= B.DateFrom
						AND BPB.EndDate <= DateAdd(Second, 59, DateAdd(Minute, 59, DateAdd(Hour, 23, B.DateTo))))
				INNER JOIN @Location AS L
					ON (BPB.DestinationHubLocationId = L.LocationId OR BPB.LoadSiteLocationId = L.LocationId)
				LEFT JOIN dbo.Location siteLocation
					ON siteLocation.Location_Id = BPB.LoadSiteLocationId
				-- This join is used to determine whether there is an approval associated with the data
				LEFT JOIN dbo.BhpbioApprovalData bad
					ON bad.LocationId = CASE WHEN BPB.DestinationHubLocationId = L.LocationId THEN BPB.DestinationHubLocationId ELSE siteLocation.Parent_Location_Id END
					AND bad.TagId = 'F3PortBlendedAdjustment'
					AND bad.ApprovedMonth = dbo.GetDateMonth(BPB.StartDate)
			WHERE	-- where there is no associated approval OR there is and Approved data is not being included
					(	bad.TagId IS NULL
						OR @iIncludeApprovedData = 0)

			-- Obtain the Port Blending Grades
			INSERT INTO @BlendingGrades
			(
				CalendarDate,
				DateFrom,
				DateTo,
				ParentLocationId,
				GradeId,
				GradeValue,
				Tonnes
			)
			SELECT B.CalendarDate,  B.DateFrom, B.DateTo, B.ParentLocationId,
				BPBG.GradeId,
				SUM(ABS(B.Tonnes) * BPBG.GradeValue) / NULLIF(SUM(ABS(B.Tonnes)), 0) AS GradeValue,
				SUM(ABS(B.Tonnes))
			FROM @Blending AS B
				INNER JOIN dbo.BhpbioPortBlendingGrade AS BPBG
					ON BPBG.BhpbioPortBlendingId = B.BhpbioPortBlendingId
			GROUP BY B.CalendarDate, B.DateFrom, B.DateTo, B.ParentLocationId, BPBG.GradeId
		END
		
		IF @iIncludeApprovedData = 1
		BEGIN
			DECLARE @summaryEntryType VARCHAR(24)
			SET @summaryEntryType = 'PortBlending'
			
			-- Retrieve Tonnes
			INSERT INTO @Blending
				(CalendarDate, DateFrom, DateTo, ParentLocationId, Tonnes, Removal)
			SELECT s.CalendarDate, s.DateFrom, s.DateTo, l.ParentLocationId, ABS(s.Tonnes), CASE WHEN s.Tonnes < 0 THEN 1 ELSE 0 END
			FROM dbo.GetBhpbioSummaryTonnesBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryType, 1) s
				INNER JOIN @Location l
					ON l.LocationId = s.LocationId
			
			-- Retrieve Grades
			INSERT INTO @BlendingGrades
			(
				CalendarDate,
				DateFrom,
				DateTo,
				ParentLocationId,
				GradeId,
				GradeValue,
				Tonnes
			)
			SELECT s.CalendarDate, s.DateFrom, s.DateTo,  l.ParentLocationId,
					s.GradeId, s.GradeValue, s.Tonnes
			FROM dbo.GetBhpbioSummaryGradeBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryType, 1, 1, 0) s
				INNER JOIN @Location l
					ON l.LocationId = s.LocationId
		END
		
		-- Obtain the Port Blending tonnes
		SELECT B.CalendarDate, B.DateFrom, B.DateTo, B.ParentLocationId, NULL AS MaterialTypeId,
			Sum(CASE WHEN B.Removal = 0 THEN B.Tonnes ELSE -B.Tonnes END) AS Tonnes
		FROM @Blending AS B
		GROUP BY B.CalendarDate, B.DateFrom, B.DateTo, B.ParentLocationId
		
		
		SELECT BG.CalendarDate, G.Grade_Name AS GradeName, BG.ParentLocationId,
			NULL AS MaterialTypeId,
			SUM(ABS(BG.Tonnes) * BG.GradeValue) / NULLIF(SUM(ABS(BG.Tonnes)), 0) AS GradeValue
		FROM @BlendingGrades AS BG
			INNER JOIN dbo.Grade AS G
				ON G.Grade_Id = BG.GradeId
		GROUP BY BG.CalendarDate, BG.ParentLocationId, G.Grade_Name
			
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

GRANT EXECUTE ON dbo.GetBhpbioReportDataPortBlendedAdjustment TO BhpbioGenericManager
GO

IF OBJECT_ID('dbo.GetBhpbioReportDataPortOreShipped') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportDataPortOreShipped 
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReportDataPortOreShipped
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iChildLocations BIT,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT
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
	
	DECLARE @OutputTonnes TABLE
	(
		CalendarDate DATETIME,
		DateFrom DATETIME,
		DateTo DATETIME,
		LocationId INTEGER,
		Tonnes FLOAT
	)
	
	DECLARE @OutputGrades TABLE
	(
		CalendarDate DATETIME,
		LocationId INTEGER,
		GradeId INTEGER,
		GradeValue FLOAT,
		Tonnes FLOAT
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioReportDataPortOreShipped',
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
		INSERT INTO @Location
			(LocationId, ParentLocationId)
		SELECT LocationId, ParentLocationId
		FROM dbo.GetBhpbioReportLocationBreakdown(@iLocationId, @iChildLocations, NULL)

		IF @iChildLocations = 1
		BEGIN
			INSERT INTO @Location (LocationId, ParentLocationId)
			SELECT @iLocationId, @iLocationId
		END
		
		IF @iIncludeLiveData = 1
		BEGIN
	
			-- Obtain the Shipping tonnes
			INSERT INTO @OutputTonnes
			(
				CalendarDate,
				DateFrom,
				DateTo,
				LocationId,
				Tonnes
			)
			SELECT B.CalendarDate, B.DateFrom, B.DateTo,
				L.ParentLocationId, SUM(S.Tonnes) AS Tonnes
			FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
				INNER JOIN dbo.BhpbioShippingTransactionNomination AS S
					ON (S.OfficialFinishTime >= B.DateFrom
						AND S.OfficialFinishTime <= DateAdd(Second, 59, DateAdd(Minute, 59, DateAdd(Hour, 23, B.DateTo))))
				INNER JOIN @Location AS L
					ON (S.HubLocationId = L.LocationId)
				-- this join is used to test whether there is an approval associated with this data
				LEFT JOIN dbo.BhpbioApprovalData bad
					ON bad.TagId = 'F3OreShipped'
					AND bad.LocationId = S.HubLocationId
					AND bad.ApprovedMonth = dbo.GetDateMonth(S.OfficialFinishTime)
			WHERE ( @iIncludeApprovedData = 0
					OR bad.TagId IS NULL)		
					-- where approved data is not being included OR there is no associated approval
			GROUP BY B.CalendarDate, B.DateFrom, B.DateTo, L.ParentLocationId
			
			-- Obtain the Shipping Grades
			INSERT INTO @OutputGrades
			(
				CalendarDate,
				LocationId,
				GradeId,
				GradeValue,
				Tonnes
			)
			SELECT B.CalendarDate, L.ParentLocationId, G.Grade_Id AS GradeId,
				 Coalesce(SUM(SG.GradeValue * S.Tonnes) / NullIf(SUM(Tonnes), 0), 0) AS GradeValue,
				 SUM(Tonnes)
			FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
				INNER JOIN dbo.BhpbioShippingTransactionNomination AS S
					ON (S.OfficialFinishTime >= B.DateFrom
						AND S.OfficialFinishTime <= DateAdd(Second, 59, DateAdd(Minute, 59, DateAdd(Hour, 23, B.DateTo))))
				INNER JOIN @Location AS L
					ON (S.HubLocationId = L.LocationId)
				CROSS JOIN dbo.Grade AS G
				LEFT JOIN dbo.BhpbioShippingTransactionNominationGrade AS SG
					ON (S.BhpbioShippingTransactionNominationId = SG.BhpbioShippingTransactionNominationId
						AND G.Grade_Id = SG.GradeId)
				LEFT JOIN dbo.BhpbioApprovalData bad
					ON bad.TagId = 'F3OreShipped'
					AND bad.LocationId = S.HubLocationId
					AND bad.ApprovedMonth = dbo.GetDateMonth(S.OfficialFinishTime)
			WHERE ( 
					@iIncludeApprovedData = 0
					OR 
					bad.TagId IS NULL
				)		
			GROUP BY B.CalendarDate, G.Grade_Id, L.ParentLocationId
		END
		
		IF @iIncludeApprovedData = 1
		BEGIN
			DECLARE @summaryEntryType VARCHAR(24)
			SET @summaryEntryType = 'ShippingTransaction'
			
			-- Retrieve Tonnes
			INSERT INTO @OutputTonnes
			(
				CalendarDate,
				DateFrom,
				DateTo,
				LocationId,
				Tonnes
			)
			SELECT s.CalendarDate, s.DateFrom, s.DateTo, l.ParentLocationId, s.Tonnes
			FROM dbo.GetBhpbioSummaryTonnesBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryType, 1) s
				INNER JOIN @Location l
					ON l.LocationId = s.LocationId
			
			-- Retrieve Grades
			INSERT INTO @OutputGrades
			(
				CalendarDate,
				LocationId,
				GradeId,
				GradeValue,
				Tonnes
			)
			SELECT s.CalendarDate,  l.ParentLocationId, s.GradeId,  s.GradeValue, s.Tonnes
			FROM dbo.GetBhpbioSummaryGradeBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryType, 1, 1, 0) s
				INNER JOIN @Location l
					ON l.LocationId = s.LocationId
		END
		
		-- output the tonnes
		SELECT o.CalendarDate, o.DateFrom, o.DateTo, NULL AS MaterialTypeId,
				o.LocationId AS ParentLocationId, SUM(o.Tonnes) AS Tonnes
		FROM @OutputTonnes o
		GROUP BY o.CalendarDate, o.DateFrom, o.DateTo, o.LocationId
			
		-- output the grades
		SELECT o.CalendarDate, g.Grade_Name AS GradeName, o.GradeId, NULL AS MaterialTypeId,
				o.LocationId AS ParentLocationId, Coalesce(SUM(o.GradeValue * o.Tonnes) / NullIf(SUM(o.Tonnes), 0), 0) AS GradeValue
		FROM @OutputGrades o
			INNER JOIN dbo.Grade g
				ON g.Grade_Id = o.GradeId
		GROUP BY o.CalendarDate, g.Grade_Name, o.LocationId, o.GradeId
			
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

GRANT EXECUTE ON dbo.GetBhpbioReportDataPortOreShipped TO BhpbioGenericManager
GO

/*
EXEC dbo.GetBhpbioReportDataPortOreShipped
	@iDateFrom = '1-apr-2008', 
	@iDateTo = '30-apr-2008', 
	@iDateBreakdown = 'MONTH',
	@iLocationId = 4,
	@iLocationBreakdown = 'SITE'
*/

IF OBJECT_ID('dbo.GetBhpbioReportDataPortStockpileDelta') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportDataPortStockpileDelta 
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReportDataPortStockpileDelta
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iChildLocations BIT,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT
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
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		ParentLocationId INT NULL,
		LastBalanceDate DATETIME NULL,
		Tonnes FLOAT NULL,
		LastTonnes FLOAT NULL
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioReportDataPortStockpileDelta',
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
		INSERT INTO @Location
			(LocationId, ParentLocationId)
		SELECT LocationId, ParentLocationId
		FROM dbo.GetBhpbioReportLocationBreakdown(@iLocationId, @iChildLocations, NULL)
	
		IF @iIncludeLiveData = 1
		BEGIN
			INSERT INTO @PortDelta
				(CalendarDate, DateFrom, DateTo, ParentLocationId, LastBalanceDate, Tonnes, LastTonnes)
			SELECT B.CalendarDate, B.DateFrom, B.DateTo, L.ParentLocationId, BPBPREV.BalanceDate, Sum(BPB.Tonnes), Sum(BPBPREV.Tonnes)
			FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
				INNER JOIN dbo.BhpbioPortBalance AS BPB
					ON (BPB.BalanceDate = B.DateTo)
				INNER JOIN @Location AS L
					ON (BPB.HubLocationId = L.LocationId)
				LEFT JOIN dbo.BhpbioPortBalance AS BPBPREV
					ON (BPBPREV.BalanceDate = DateAdd(Day, -1, B.DateFrom)
						And BPB.HubLocationId = BPBPREV.HubLocationId)
				-- this join is used to test whether there is an approval associated with this data
				LEFT JOIN dbo.BhpbioApprovalData bad
					ON bad.TagId = 'F3PortStockpileDelta'
					AND bad.LocationId = BPB.HubLocationId
					AND bad.ApprovedMonth = dbo.GetDateMonth(BPB.BalanceDate)
			WHERE (@iIncludeApprovedData = 0 OR bad.TagId IS NULL)
			-- where Approved data is not being included in this call OR where there is no associated approval
			GROUP BY B.CalendarDate, B.DateFrom, B.DateTo, BPBPREV.BalanceDate, L.ParentLocationId
		END

		IF @iIncludeApprovedData = 1
		BEGIN
			DECLARE @summaryEntryType VARCHAR(24)
			SET @summaryEntryType = 'PortStockpileDelta'
			
			-- Retrieve Tonnes
			INSERT INTO @PortDelta
				(CalendarDate, DateFrom, DateTo, ParentLocationId, LastBalanceDate, Tonnes, LastTonnes)
			SELECT s.CalendarDate, s.DateFrom, s.DateTo, l.ParentLocationId, NULL, s.Tonnes, 0
			FROM dbo.GetBhpbioSummaryTonnesBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryType, 1) s
				INNER JOIN @Location l
					ON l.LocationId = s.LocationId
		END
		
		SELECT CalendarDate, DateFrom, DateTo, NULL As MaterialTypeId, ParentLocationId,
			Coalesce(Tonnes - LastTonnes, 0) AS Tonnes
		FROM @PortDelta		
		
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

GRANT EXECUTE ON dbo.GetBhpbioReportDataPortStockpileDelta TO BhpbioGenericManager
GRANT EXECUTE ON dbo.GetBhpbioReportDataPortStockpileDelta TO BhpbioGenericManager
GO

/*
EXEC dbo.GetBhpbioReportDataPortStockpileDelta
	@iDateFrom = '1-apr-2008', 
	@iDateTo = '30-apr-2008', 
	@iDateBreakdown = 'MONTH',
	@iLocationId = 4,
	@iChildLocations = 1,
	@iIncludeLiveData = 1,
	@iIncludeApprovedData = 1
	
*/
--exec dbo.GetBhpbioReportDataPortStockpileDelta @iDateFrom='2008-04-01 00:00:00',@iDateTo='2008-04-30 00:00:00',@iDateBreakdown=NULL,@iLocationId=1,@iLocationBreakdown='ChildLocations'
IF OBJECT_ID('dbo.GetBhpbioReportDataSitePostCrusherStockpileDelta') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportDataSitePostCrusherStockpileDelta 
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReportDataSitePostCrusherStockpileDelta
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iChildLocations BIT,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @OutputTonnes TABLE
	(
		CalendarDate DATETIME,
		DateFrom DATETIME,
		DateTo DATETIME,
		LocationId INTEGER,
		Tonnes FLOAT
	)
	
	DECLARE @OutputGrades TABLE
	(
		CalendarDate DATETIME,
		LocationId INTEGER,
		GradeId INTEGER,
		GradeValue FLOAT,
		Tonnes FLOAT
	)
	
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		ParentLocationId INT NULL,
		PRIMARY KEY (LocationId)
	)

	DECLARE @StockpileDelta TABLE
	(
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		StockpileId INT NOT NULL,
		WeightometerSampleId INT NOT NULL,
		Tonnes FLOAT NOT NULL,
		LocationId INT NULL,
		Addition BIT NOT NULL,
		PRIMARY KEY (CalendarDate, StockpileId, WeightometerSampleId, Addition)
	)
	
	DECLARE @StockpileGroupId VARCHAR(31)
	SET @StockpileGroupId = 'Post Crusher'
	DECLARE @LastShift CHAR(1)

	DECLARE @HubLocationTypeId INT
	DECLARE @SiteLocationTypeId INT
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioReportDataSitePostCrusherStockpileDelta',
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
	
	
		SELECT @HubLocationTypeId = Location_Type_Id
		FROM dbo.LocationType
		WHERE Description = 'Hub'
		SELECT @SiteLocationTypeId = Location_Type_Id
		FROM dbo.LocationType
		WHERE Description = 'Site'
		
		INSERT INTO @Location
			(LocationId, ParentLocationId)
		SELECT LocationId, ParentLocationId
		FROM dbo.GetBhpbioReportLocationBreakdown(@iLocationId, @iChildLocations, NULL)

		IF @iIncludeLiveData = 1
		BEGIN
			-- Get Removals
			INSERT INTO @StockpileDelta
				(CalendarDate, DateFrom, DateTo, StockpileId, WeightometerSampleId, Addition, Tonnes, LocationId)		
			SELECT CalendarDate, DateFrom, DateTo, S.Stockpile_Id, WS.Weightometer_Sample_Id, 0, WS.Tonnes, L.ParentLocationId
			FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
				INNER JOIN dbo.WeightometerSample AS WS
					ON (WS.Weightometer_Sample_Date BETWEEN B.DateFrom AND B.DateTo)
				INNER JOIN dbo.Stockpile AS S
					ON (S.Stockpile_Id = WS.Source_Stockpile_Id)
				INNER JOIN dbo.StockpileGroupStockpile AS SGS
					ON (SGS.Stockpile_Id = S.Stockpile_Id)
				INNER JOIN dbo.StockpileLocation AS SL
					ON (SL.Stockpile_Id = S.Stockpile_Id)
				INNER JOIN @Location AS L
					ON (L.LocationId = SL.Location_Id)
				LEFT JOIN dbo.BhpbioLocationStockpileConfiguration AS BSLC
					ON (BSLC.LocationId = SL.Location_Id)
				INNER JOIN dbo.Location AS LL
					ON (LL.Location_Id = L.LocationId)
				LEFT JOIN dbo.StockpileGroupStockpile SGS_D
					ON (SGS_D.Stockpile_Id = WS.Destination_Stockpile_Id
						AND SGS_D.Stockpile_Group_Id = @StockpileGroupId)
				LEFT JOIN dbo.BhpbioApprovalData bad
					ON bad.LocationId = LL.Parent_Location_Id
					AND bad.TagId = 'F3PostCrusherStockpileDelta'
					AND bad.ApprovedMonth = dbo.GetDateMonth(WS.Weightometer_Sample_Date)
			WHERE Coalesce(WS.Source_Stockpile_Id, -1) <> Coalesce(WS.Destination_Stockpile_Id, -1)
				AND SGS.Stockpile_Group_Id = @StockpileGroupId
				AND SGS_D.Stockpile_Group_Id IS NULL -- Ensure join to check if destination is Post Crusher isn't true.
				AND (LL.Location_Type_Id = @SiteLocationTypeId AND
				(BSLC.PromoteStockpiles = 0 OR BSLC.PromoteStockpiles IS NULL))
				AND WS.Weightometer_Id NOT LIKE '%Raw%'
				AND (@iIncludeApprovedData = 0 OR bad.TagId IS NULL)

			-- Get Additions
			INSERT INTO @StockpileDelta
				(CalendarDate, DateFrom, DateTo, StockpileId, WeightometerSampleId, Addition, Tonnes, LocationId)		
			SELECT CalendarDate, DateFrom, DateTo, S.Stockpile_Id, WS.Weightometer_Sample_ID, 1, WS.Tonnes, L.ParentLocationId
			FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
				INNER JOIN dbo.WeightometerSample AS WS
					ON (WS.Weightometer_Sample_Date BETWEEN B.DateFrom AND B.DateTo)
				INNER JOIN dbo.Stockpile AS S
					ON (S.Stockpile_Id = WS.Destination_Stockpile_Id)
				INNER JOIN dbo.StockpileGroupStockpile AS SGS
					ON (SGS.Stockpile_Id = S.Stockpile_Id)
				INNER JOIN dbo.StockpileLocation AS SL
					ON (SL.Stockpile_Id = S.Stockpile_Id)
				INNER JOIN @Location AS L
					ON (L.LocationId = SL.Location_Id)
				LEFT JOIN dbo.BhpbioLocationStockpileConfiguration AS BSLC
					ON (BSLC.LocationId = SL.Location_Id)
				INNER JOIN dbo.Location AS LL
					ON (LL.Location_Id = L.LocationId)
				LEFT JOIN dbo.StockpileGroupStockpile SGS_S
					ON (SGS_S.Stockpile_Id = WS.Source_Stockpile_Id
						AND SGS_S.Stockpile_Group_Id = @StockpileGroupId)
				-- this join is used to test whether there is an approval associated with this data
				LEFT JOIN dbo.BhpbioApprovalData bad
					ON bad.LocationId = LL.Parent_Location_Id
					AND bad.TagId = 'F3PostCrusherStockpileDelta'
					AND bad.ApprovedMonth = dbo.GetDateMonth(WS.Weightometer_Sample_Date)
			WHERE Coalesce(WS.Source_Stockpile_Id, -1) <> Coalesce(WS.Destination_Stockpile_Id, -1)
				AND SGS.Stockpile_Group_Id = @StockpileGroupId
				AND SGS_S.Stockpile_Group_Id IS NULL  -- Ensure join to check if source is Post Crusher isn't true.
				AND (LL.Location_Type_Id = @SiteLocationTypeId AND
				(BSLC.PromoteStockpiles = 0 OR BSLC.PromoteStockpiles IS NULL))
				AND WS.Weightometer_Id NOT LIKE '%Raw%'
				AND (@iIncludeApprovedData = 0 OR bad.TagId IS NULL)
				
			-- Obtain the Delta tonnes
			INSERT INTO @OutputTonnes
			(
				CalendarDate,
				DateFrom,
				DateTo,
				LocationId,
				Tonnes
			)
			SELECT SD.CalendarDate, SD.DateFrom, SD.DateTo, SD.LocationId AS ParentLocationId,
				Sum(CASE WHEN SD.Addition = 1 THEN SD.Tonnes ELSE -SD.Tonnes END) AS Tonnes
			FROM @StockpileDelta AS SD
			GROUP BY SD.CalendarDate, SD.DateFrom, SD.DateTo, SD.LocationId

			INSERT INTO @OutputGrades
			(
				CalendarDate,
				LocationId,
				GradeId,
				GradeValue,
				Tonnes
			)
			-- Obtain the Delta Grades
			SELECT SD.CalendarDate, SD.LocationId, WSG.Grade_Id,
				Sum(WS.Tonnes * WSG.Grade_Value) / NULLIF(Sum(WS.Tonnes), 0),
				Sum(WS.Tonnes)
			FROM @StockpileDelta AS SD
				INNER JOIN dbo.WeightometerSample AS WS
					ON (WS.Weightometer_Sample_Id = SD.WeightometerSampleId)
				INNER JOIN dbo.WeightometerSampleGrade AS WSG
					ON (WSG.Weightometer_Sample_Id = WS.Weightometer_Sample_Id)
			GROUP BY SD.CalendarDate, WSG.Grade_Id, SD.LocationId
		END
		
		IF @iIncludeApprovedData = 1
		BEGIN
			DECLARE @summaryEntryType VARCHAR(31)
			SET @summaryEntryType = 'SitePostCrusherStockpileDelta'
			
			DECLARE @summaryEntryGradeType VARCHAR(31)
			SET @summaryEntryGradeType = 'SitePostCrusherSpDeltaGrades'
			
			-- Retrieve Tonnes
			INSERT INTO @OutputTonnes
				(CalendarDate, DateFrom, DateTo, LocationId, Tonnes)
			SELECT s.CalendarDate, s.DateFrom, s.DateTo, l.ParentLocationId, s.Tonnes
			FROM dbo.GetBhpbioSummaryTonnesBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryType, 1) s
				INNER JOIN @Location l
					ON l.LocationId = s.LocationId
			
			-- Retrieve Grades
			INSERT INTO @OutputGrades
			(
				CalendarDate,
				LocationId,
				GradeId,
				GradeValue,
				Tonnes
			)
			SELECT s.CalendarDate, l.ParentLocationId, s.GradeId,  s.GradeValue, s.Tonnes
			FROM dbo.GetBhpbioSummaryGradeBreakdown(@iDateFrom, @iDateTo, @iDateBreakdown, @summaryEntryGradeType, 1, 1, 0) s
				INNER JOIN @Location l
					ON l.LocationId = s.LocationId
		END
		
		-- Output the tonnes
		SELECT o.CalendarDate, o.DateFrom, o.DateTo, NULL AS MaterialTypeId, o.LocationId AS ParentLocationId,
			Sum(o.Tonnes) AS Tonnes
		FROM @OutputTonnes o
		GROUP BY o.CalendarDate, o.DateFrom, o.DateTo, o.LocationId

		-- Output the grades
		SELECT o.CalendarDate, G.Grade_Name As GradeName, NULL AS MaterialTypeId, o.LocationId AS ParentLocationId,
			Sum(ABS(o.Tonnes) * o.GradeValue) / NULLIF(Sum(ABS(o.Tonnes)), 0) AS GradeValue
		FROM @OutputGrades AS o
			INNER JOIN dbo.Grade AS G
				ON (G.Grade_Id = o.GradeId)
		GROUP BY o.CalendarDate, G.Grade_Name, o.LocationId
		
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

GRANT EXECUTE ON dbo.GetBhpbioReportDataSitePostCrusherStockpileDelta TO BhpbioGenericManager
GO

/*
exec dbo.GetBhpbioReportDataSitePostCrusherStockpileDelta 
@iDateFrom='2008-04-01 00:00:00',@iDateTo='2008-Jun-30 00:00:00',@iDateBreakdown=NULL,@iLocationId=1,@iChildLocations=0
*/
IF OBJECT_ID('dbo.GetBhpbioSummaryIdForMonth') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioSummaryIdForMonth 
GO 
    
CREATE PROCEDURE dbo.GetBhpbioSummaryIdForMonth
(
	@iSummaryMonth DATETIME,
	@oSummaryId INT OUTPUT
)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	-- Get a version of datetime that is gauranteed to be the start of the month
	DECLARE @sanitisedMonth DATETIME
	SELECT @sanitisedMonth = dbo.GetDateMonth(@iSummaryMonth)
			
	BEGIN TRY
		-- First make attempt to find an existing summary for the month
		SELECT @oSummaryId = SummaryId
		FROM dbo.BhpbioSummary 
		WHERE SummaryMonth = @sanitisedMonth

		IF (@oSummaryId IS NULL)
		BEGIN
			-- if no existing summary exists for the month then need to start a new one
			INSERT INTO dbo.BhpbioSummary(SummaryMonth) 
			VALUES (@sanitisedMonth)
	
			SELECT @oSummaryId = @@IDENTITY
		END
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END
GO

GRANT EXECUTE ON dbo.GetBhpbioSummaryIdForMonth TO BhpbioGenericManager
GO

/*
DECLARE @testDateTime DATETIME
DECLARE @summaryId INTEGER

SET @testDateTime = '2010-11-23'

EXEC dbo.GetBhpbioSummaryIdForMonth @iSummaryMonth = @testDateTime,
									@oSummaryId = @summaryId OUTPUT
									
SELECT @summaryId								
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.GetBhpbioSummaryIdForMonth">
 <Procedure>
	Finds the Id of the Summary for a month (if one exists) or creates and outputs a new one if none already exists
	
	Pass: 
			@iSummaryMonth: The month to get a Summary Id for
			@oSummaryId: Outputs the found or created SummaryId
 </Procedure>
</TAG>
*/
IF OBJECT_ID('dbo.IsBhpbioApprovalOtherMovementDate') IS NOT NULL
     DROP PROCEDURE dbo.IsBhpbioApprovalOtherMovementDate  
GO 
    
CREATE PROCEDURE dbo.IsBhpbioApprovalOtherMovementDate 
(
	@iLocationId INT,
	@iMonth DATETIME,
	@oMovementsExist BIT OUTPUT
)
WITH ENCRYPTION
AS 
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	
	DECLARE @BlockModelXml VARCHAR(500)
	SET @BlockModelXml = ''
	
	DECLARE @MaterialCategoryId VARCHAR(31)
	SET @MaterialCategoryId = 'Designation'
	
	DECLARE @DateFrom DATETIME
	DECLARE @DateTo DATETIME
	SET @DateFrom = dbo.GetDateMonth(@iMonth)
	SET @DateTo = DateAdd(Day, -1, DateAdd(Month, 1, @DateFrom))
		

	DECLARE @Tonnes TABLE
	(
		Type VARCHAR(255) COLLATE DATABASE_DEFAULT NOT NULL,
		BlockModelId INT NULL,
		CalendarDate DATETIME NOT NULL,
		Material VARCHAR(65) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialTypeId INT NOT NULL,
		Tonnes FLOAT,
		PRIMARY KEY CLUSTERED (CalendarDate, Material, Type)
	)
	
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		PRIMARY KEY (LocationId)
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'IsBhpbioApprovalOtherMovementDate',
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
		-- Updated the locations
		INSERT INTO @Location
		SELECT LocationId
		FROM dbo.GetBhpbioReportLocation(@iLocationId)
		
		-- Obtain the Block Model XML
		SELECT @BlockModelXml = @BlockModelXml + '<BlockModel id="' + CAST(Block_Model_Id AS VARCHAR) + '"/>'
		FROM dbo.BlockModel
		SET @BlockModelXml = '<BlockModels>' + @BlockModelXml + '</BlockModels>'
		
		-- load the base data
		INSERT INTO @Tonnes
		(
			Type, BlockModelId, CalendarDate, Material, MaterialTypeId, Tonnes
		)
		EXEC dbo.GetBhpbioReportBaseDataAsTonnes
			@iDateFrom = @DateFrom,
			@iDateTo = @DateTo,
			@iDateBreakdown = NULL,
			@iLocationId = @iLocationId,
			@iIncludeBlockModels = 1,
			@iBlockModels = @BlockModelXml,
			@iIncludeActuals = 1,
			@iMaterialCategoryId = 'Designation',
			@iRootMaterialTypeId = NULL,
			@iIncludeLiveData = 1,
			@iIncludeApprovedData = 1
			

		-- Put the block model tonnes in.
		IF (SELECT Sum(Tonnes)
			FROM @Tonnes AS T
			WHERE T.Material NOT IN (SELECT Description FROM dbo.GetBhpbioReportHighGrade()) 
				AND T.Material IS NOT NULL) > 0
		BEGIN
			SET @oMovementsExist = 1
		END
		ELSE
		BEGIN
			SET @oMovementsExist = 0
		END
		
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

GRANT EXECUTE ON dbo.IsBhpbioApprovalOtherMovementDate TO BhpbioGenericManager

GO
IF OBJECT_ID('dbo.SummariseBhpbioActualBeneProduct') IS NOT NULL
     DROP PROCEDURE dbo.SummariseBhpbioActualBeneProduct 
GO 
    
CREATE PROCEDURE dbo.SummariseBhpbioActualBeneProduct
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

	DECLARE @ProductRecord TABLE
	(
		CalendarDate DATETIME NOT NULL,
		WeightometerSampleId INT NOT NULL,
		EffectiveTonnes FLOAT NOT NULL,
		MaterialTypeId INT NOT NULL,
		ParentLocationId INT NULL,
		PRIMARY KEY (CalendarDate, WeightometerSampleId, MaterialTypeId)
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'SummariseBhpbioActualBeneProduct',
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
		DECLARE @BeneProductMaterialTypeId INTEGER
		
		-- obtain the Actual Type Id for ActualC storage
		SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
		FROM dbo.BhpbioSummaryEntryType bset
		WHERE bset.Name = 'ActualBeneProduct'
		
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

		-- collect the location subtree
		INSERT INTO @Location
			(LocationId, ParentLocationId)
		SELECT LocationId, ParentLocationId
		FROM dbo.GetBhpbioReportLocationBreakdown(@iSummaryLocationId, 0, NULL)

		-- determine the return material type
		SET @BeneProductMaterialTypeId =
			(
				SELECT Material_Type_Id
				FROM dbo.MaterialType
				WHERE Material_Category_Id = 'Designation'
					AND Abbreviation = 'Bene Product'
			)

		INSERT INTO @ProductRecord
		(
			CalendarDate,
			WeightometerSampleId, 
			EffectiveTonnes,
			MaterialTypeId, 
			ParentLocationId
		)
		SELECT @startOfMonth, ws.Weightometer_Sample_Id, ISNULL(ws.Corrected_Tonnes, ws.Tonnes),
			@BeneProductMaterialTypeId, CASE WHEN l.ParentLocationId IS NULL THEN l.LocationId ELSE l.ParentLocationId END
		FROM dbo.WeightometerSample AS ws
			INNER JOIN
				(
					SELECT DISTINCT dttf.Weightometer_Sample_Id, ml.Location_Id
					FROM dbo.DataTransactionTonnesFlow AS dttf
						-- sourced from a mill
						INNER JOIN dbo.Mill AS m
							ON (m.Stockpile_Id = dttf.Source_Stockpile_Id)
						INNER JOIN dbo.MillLocation AS ml
							ON (m.Mill_Id = ml.Mill_Id)
						-- delivered to a post crusher stockpile
						INNER JOIN dbo.StockpileGroupStockpile AS sgs
							ON (dttf.Destination_Stockpile_Id = sgs.Stockpile_Id)
					WHERE sgs.Stockpile_Group_Id IN ('Post Crusher', 'High Grade')
				) AS dttf
				ON (dttf.Weightometer_Sample_Id = ws.Weightometer_Sample_Id)
			INNER JOIN @Location AS l
				ON (l.LocationId = dttf.Location_Id)
		WHERE ws.Weightometer_Sample_Date >= @startOfMonth
			AND ws.Weightometer_Sample_Date < @startOfNextMonth
		
		-- insert main actual row using a Sum of Tonnes
		INSERT INTO dbo.BhpbioSummaryEntry
		(
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			Tonnes
		)
		SELECT  @summaryId,
				@summaryEntryTypeId,
				pr.ParentLocationId, 
				pr.MaterialTypeId, 
				SUM(pr.EffectiveTonnes)
		FROM @ProductRecord pr
		GROUP BY ParentLocationId, MaterialTypeId
			
		-- insert the summary grades
		INSERT INTO dbo.BhpbioSummaryEntryGrade
		(
			SummaryEntryId,
			GradeId,
			GradeValue
		)
		SELECT bse.SummaryEntryId, wsg.Grade_Id, 
			SUM(p.EffectiveTonnes * wsg.Grade_Value) / SUM(p.EffectiveTonnes) AS GradeValue
		FROM @ProductRecord AS p
			INNER JOIN dbo.BhpbioSummaryEntry bse
				ON bse.LocationId = p.ParentLocationId
				AND bse.SummaryEntryTypeId = @summaryEntryTypeId
				AND bse.SummaryId = @summaryId
			INNER JOIN dbo.WeightometerSampleGrade AS wsg
				ON wsg.Weightometer_Sample_Id = p.WeightometerSampleId
		GROUP BY bse.SummaryEntryId, wsg.Grade_Id
		
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

GRANT EXECUTE ON dbo.SummariseBhpbioActualBeneProduct TO BhpbioGenericManager
GO

/*
exec dbo.SummariseBhpbioActualBeneProduct
	@iSummaryMonth = '2009-11-01',
	@iLocationId = 3
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.SummariseBhpbioActualBeneProduct">
 <Procedure>
	Generates a set of summary Actual Bene Product data based on supplied criteria.
			
	Pass: 
			@iSummaryMonth: the month for which summary data is to be generated,
			@iSummaryLocationId: the location (typically a Site) for which data will be summarised
 </Procedure>
</TAG>
*/	
IF OBJECT_ID('dbo.SummariseBhpbioActualC') IS NOT NULL
     DROP PROCEDURE dbo.SummariseBhpbioActualC 
GO 
    
CREATE PROCEDURE dbo.SummariseBhpbioActualC
(
	@iSummaryMonth DATETIME,
	@iSummaryLocationId INTEGER
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'SummariseBhpbioActualC',
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
		DECLARE @sampleTonnesSummaryEntryTypeId INTEGER
		
		-- obtain the Actual Type Id for ActualC storage
		SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
		FROM dbo.BhpbioSummaryEntryType bset
		WHERE bset.Name = 'ActualC'
		
		SELECT @sampleTonnesSummaryEntryTypeId = bset.SummaryEntryTypeId
		FROM dbo.BhpbioSummaryEntryType bset
		WHERE bset.Name = 'ActualCSampleTonnes'
		
		-- the first step is to remove previously summarised data for the same filtering criteria that the current summary is running on
		exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iSummaryMonth,
											@iSummaryLocationId = @iSummaryLocationId,
											@iSummaryEntryTypeId = @summaryEntryTypeId
		
		exec dbo.DeleteBhpbioSummaryEntry	@iSummaryMonth = @iSummaryMonth,
											@iSummaryLocationId = @iSummaryLocationId,
											@iSummaryEntryTypeId = @sampleTonnesSummaryEntryTypeId
											
		-- get the start of the summary month and the start of the following month
		-- this gives us a window of time to operate within
		SELECT @startOfMonth = dbo.GetDateMonth(@iSummaryMonth)
		SELECT @startOfNextMonth = DATEADD(month,1,@iSummaryMonth)

		-- get a Summary Id for the month (or create a new one if needed)
		EXEC dbo.GetBhpbioSummaryIdForMonth @iSummaryMonth = @startOfMonth,
											@oSummaryId = @summaryId OUTPUT

		-- this DOES NOT and CAN NOT return data below the site level
		-- this is because:
		-- (1) weightometers & crushers are at the SITE level, and
		-- (2) the way Sites aggregate is based on the "Sample" tonnes method,
		--     .. hence these records need to be returned at the Site level
		-- note that data must not be returned at the Hub/Company level either

		-- 'C' - all crusher removals
		-- returns [High Grade] & [Bene Feed] as designation types

		DECLARE @Weightometer TABLE
		(
			WeightometerSampleId INT NOT NULL,
			SiteLocationId INT NULL,
			RealTonnes FLOAT NULL,
			SampleTonnes FLOAT NOT NULL,
			MaterialTypeId INT NOT NULL,
			PRIMARY KEY (WeightometerSampleId)
		)
		
		DECLARE @GradeLocation TABLE
		(
			CalendarMonth DATETIME NOT NULL,
			SiteLocationId INT NOT NULL,
			PRIMARY KEY (SiteLocationId, CalendarMonth)
		)
				
		DECLARE @SiteLocation TABLE
		(
			LocationId INT NOT NULL,
			PRIMARY KEY (LocationId)
		)
		
		DECLARE @HighGradeMaterialTypeId INT
		DECLARE @BeneFeedMaterialTypeId INT
		DECLARE @SampleTonnesField VARCHAR(31)
		DECLARE @SampleSourceField VARCHAR(31)
		DECLARE @SiteLocationTypeId SMALLINT
				
		SET @SampleTonnesField = 'SampleTonnes'
		SET @SampleSourceField = 'SampleSource'
		
		SET @HighGradeMaterialTypeId =
			(
				SELECT Material_Type_Id
				FROM dbo.MaterialType
				WHERE Abbreviation = 'High Grade'
					AND Material_Category_Id = 'Designation'
			)

		SET @BeneFeedMaterialTypeId = 
			(
				SELECT Material_Type_Id
				FROM dbo.MaterialType
				WHERE Abbreviation = 'Bene Feed'
					AND Material_Category_Id = 'Designation'
			)
		
		-- Setup the Locations
		-- collect at site level (this is used to ensure the site's sampled tonnes are collated)
		SET @SiteLocationTypeId =
			(
				SELECT Location_Type_Id
				FROM dbo.LocationType
				WHERE Description = 'Site'
			)
		INSERT INTO @SiteLocation
			(LocationId)
		SELECT LocationId
		FROM dbo.GetLocationSubtreeByLocationType(@iSummaryLocationId, @SiteLocationTypeId, @SiteLocationTypeId)
		
		-- -----------------------------------------------------------------------------------------------------------------------------------
		-- The queries used in this procedure are based on / taken from the original reporting implementation (on non-summarised data)
		-- -----------------------------------------------------------------------------------------------------------------------------------
		
		-- retrieve the list of Weightometer Records to be used in the calculations
		INSERT INTO @Weightometer
			(
				WeightometerSampleId,
				SiteLocationId,
				RealTonnes, 
				SampleTonnes, 
				MaterialTypeId
			)
		SELECT  w.WeightometerSampleId, l.LocationId,
			-- calculate the REAL tonnes
			CASE
				WHEN w.UseAsRealTonnes = 1
					THEN ISNULL(ws.Corrected_Tonnes, ws.Tonnes)
				ELSE NULL
			END AS RealTonnes,
			-- calculate the SAMPLE tonnes
			-- if a sample tonnes hasn't been provided then use the actual tonnes recorded for the transaction
			-- not all flows will have this recorded (in particular CVF corrected plant balanced records)
			CASE BeneFeed
				WHEN 1 THEN ISNULL(ws.Corrected_Tonnes, ws.Tonnes)
				ELSE ISNULL(wsv.Field_Value, 0.0)
			END AS SampleTonnes,
			-- return the Material Type based on whether it is bene feed
			CASE w.BeneFeed
				WHEN 1 THEN @BeneFeedMaterialTypeId
				WHEN 0 THEN @HighGradeMaterialTypeId
			END AS MaterialTypeId
		FROM dbo.WeightometerSample AS ws
			INNER JOIN
				(
					-- collect the weightometer sample id's for all movements from the crusher
					-- these are used to ease lookup and ensure uniqueness of the weightometer_sample_ids returned
					SELECT dttf.Weightometer_Sample_Id AS WeightometerSampleId, 1 AS UseAsRealTonnes,
						CASE
							WHEN m.Mill_Id IS NOT NULL
								THEN 1
							ELSE 0
						END AS BeneFeed, l.LocationId
					FROM dbo.DataTransactionTonnes AS dtt
						INNER JOIN dbo.DataTransactionTonnesFlow AS dttf
							ON (dttf.Data_Transaction_Tonnes_Id = dtt.Data_Transaction_Tonnes_Id)
						INNER JOIN dbo.CrusherLocation AS cl
							ON (dttf.Source_Crusher_Id = cl.Crusher_Id)
						LEFT JOIN dbo.Mill AS m
							ON (dttf.Destination_Stockpile_Id = m.Stockpile_Id)
						INNER JOIN @SiteLocation AS l
							ON (cl.Location_Id = l.LocationId)
					WHERE dtt.Data_Transaction_Tonnes_Date >= @startOfMonth
						AND  dtt.Data_Transaction_Tonnes_Date < @startOfNextMonth
						AND dttf.Destination_Crusher_Id IS NULL  -- ignore crusher to crusher feeds
					GROUP BY dttf.Weightometer_Sample_Id, m.Mill_Id, l.LocationId
					UNION 
					-- collect weightometer sample id's for all movements to train rakes
					-- (by definition it's always delivers to train rake stockpiles...
					--  the grades (but not the tonnes) from these weightometers samples are important to us)
					SELECT dttf.Weightometer_Sample_Id, 0, 0, l.LocationId
					FROM dbo.DataTransactionTonnes AS dtt
						INNER JOIN dbo.DataTransactionTonnesFlow AS dttf
							ON (dttf.Data_Transaction_Tonnes_Id = dtt.Data_Transaction_Tonnes_Id)
						INNER JOIN dbo.WeightometerSample AS ws
							ON (dttf.Weightometer_Sample_Id = ws.Weightometer_Sample_Id)
						INNER JOIN dbo.StockpileGroupStockpile AS sgs
							ON (sgs.Stockpile_Id = dttf.Destination_Stockpile_Id)
						INNER JOIN dbo.WeightometerLocation AS wl
							ON (ws.Weightometer_Id = wl.Weightometer_Id)
						INNER JOIN @SiteLocation AS l
							ON (wl.Location_Id = l.LocationId)
					WHERE dtt.Data_Transaction_Tonnes_Date >= @startOfMonth
						AND dtt.Data_Transaction_Tonnes_Date < @startOfNextMonth
						AND sgs.Stockpile_Group_Id = 'Port Train Rake'
					GROUP BY dttf.Weightometer_Sample_Id, l.LocationId
				  ) AS w
				ON (ws.Weightometer_Sample_Id = w.WeightometerSampleId)
				-- ensure the weightometer belongs to the required location
			INNER JOIN dbo.WeightometerLocation AS wl
				ON (wl.Weightometer_Id = ws.Weightometer_Id)
			INNER JOIN @SiteLocation AS l
				ON (l.LocationId = wl.Location_Id)
			LEFT OUTER JOIN dbo.WeightometerSampleValue AS wsv
				ON (ws.Weightometer_Sample_Id = wsv.Weightometer_Sample_Id
					AND wsv.Weightometer_Sample_Field_Id = @SampleTonnesField)
		WHERE ws.Weightometer_Sample_Date >= @startOfMonth
			AND ws.Weightometer_Sample_Date < @startOfNextMonth
		
		-- insert main actual row using a Sum of Tonnes
		INSERT INTO dbo.BhpbioSummaryEntry
		(
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			Tonnes
		)
		SELECT  @summaryId,
				@summaryEntryTypeId,
				w.SiteLocationId,
				w.MaterialTypeId,
				Sum(w.RealTonnes)
		FROM @Weightometer w
		GROUP BY 
			w.SiteLocationId,
			w.MaterialTypeId
		HAVING SUM(w.RealTonnes) IS NOT NULL
		
		-- Get the valid locations to be used for the grades. 
		-- This is so locations with no valid real tonnes are not included in the calc.
		INSERT INTO @GradeLocation	(CalendarMonth, SiteLocationId)
		SELECT DISTINCT dbo.GetDateMonth(ws.Weightometer_Sample_Date), w.SiteLocationId
		FROM @Weightometer w
			INNER JOIN dbo.WeightometerSample ws ON ws.Weightometer_Sample_Id = w.WeightometerSampleId
		WHERE w.RealTonnes IS NOT NULL
		
		-- insert the sample tonnes values related to the selction of haulage we are working with
		INSERT INTO dbo.BhpbioSummaryEntry
		(
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			Tonnes
		)
		SELECT  @summaryId,
				@sampleTonnesSummaryEntryTypeId,
				w.SiteLocationId,
				w.MaterialTypeId,
				Sum(w.SampleTonnes)
		FROM @Weightometer w
			LEFT OUTER JOIN
			(
				SELECT ws.Weightometer_Sample_Id
				FROM dbo.WeightometerSample AS ws
					INNER JOIN dbo.WeightometerLocation AS wl
						ON (ws.Weightometer_Id = wl.Weightometer_Id)
					INNER JOIN dbo.WeightometerSampleNotes AS wsn
						ON (wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
							AND wsn.Weightometer_Sample_Field_Id = @SampleSourceField)
					INNER JOIN dbo.GetBhpbioWeightometerSampleSource(@iSummaryLocationId, @startOfMonth, @startOfNextMonth) AS ss
						ON (dbo.GetDateMonth(ws.Weightometer_Sample_Date) = ss.MonthPeriod
							AND wl.Location_Id = ss.LocationId
							AND wsn.Notes = ss.SampleSource)
			) AS sSource ON (sSource.Weightometer_Sample_Id = w.WeightometerSampleId)
			INNER JOIN dbo.WeightometerSample ws
				ON ws.Weightometer_Sample_Id = w.WeightometerSampleId
			INNER JOIN @GradeLocation AS gl
				ON (gl.CalendarMonth = dbo.GetDateMonth(ws.Weightometer_Sample_Date)
					AND ISNULL(gl.SiteLocationId, -1) = ISNULL(w.SiteLocationId, -1))
		WHERE
			-- only include if:
			-- 1. the Material Type is Bene Feed and there is no Sample Source
			-- 2. the Material Type is High Grade and there is a matching SampleSource
			CASE
				WHEN (w.MaterialTypeId = @BeneFeedMaterialTypeId) AND (sSource.Weightometer_Sample_Id IS NULL) THEN 1
				WHEN (w.MaterialTypeId = @HighGradeMaterialTypeId) AND (sSource.Weightometer_Sample_Id IS NOT NULL) THEN 1
				ELSE 0
			END = 1
			AND EXISTS (SELECT * 
						FROM dbo.WeightometerSampleGrade AS wsg
						WHERE wsg.Weightometer_Sample_Id = w.WeightometerSampleId
							AND wsg.Grade_Value IS NOT NULL
						)
		GROUP BY 
			w.SiteLocationId,
			w.MaterialTypeId
		HAVING SUM(w.SampleTonnes) IS NOT NULL
		
		-- insert the actual grades related to the selection of Haulage we are working with and the actual tonnes rows created above
		INSERT INTO dbo.BhpbioSummaryEntryGrade
		(
			SummaryEntryId,
			GradeId,
			GradeValue
		)
		SELECT	bse.SummaryEntryId,
				wsg.Grade_Id,
				SUM(w.SampleTonnes * wsg.Grade_Value) / SUM(w.SampleTonnes)
		FROM @Weightometer AS w
			INNER JOIN dbo.BhpbioSummaryEntry bse
				ON bse.LocationId = w.SiteLocationId
				AND bse.MaterialTypeId = w.MaterialTypeId
				AND bse.SummaryId = @summaryId
				AND bse.SummaryEntryTypeId = @sampleTonnesSummaryEntryTypeId
			-- check the membership with the Sample Source
			LEFT OUTER JOIN
			(
				SELECT ws.Weightometer_Sample_Id
				FROM dbo.WeightometerSample AS ws
					INNER JOIN dbo.WeightometerLocation AS wl
						ON (ws.Weightometer_Id = wl.Weightometer_Id)
					INNER JOIN dbo.WeightometerSampleNotes AS wsn
						ON (wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
							AND wsn.Weightometer_Sample_Field_Id = @SampleSourceField)
					INNER JOIN dbo.GetBhpbioWeightometerSampleSource(@iSummaryLocationId, @startOfMonth, @startOfNextMonth) AS ss
						ON (dbo.GetDateMonth(ws.Weightometer_Sample_Date) = ss.MonthPeriod
							AND wl.Location_Id = ss.LocationId
							AND wsn.Notes = ss.SampleSource)
			) AS sSource
			ON (sSource.Weightometer_Sample_Id = w.WeightometerSampleId)
			INNER JOIN dbo.WeightometerSample ws
				ON ws.Weightometer_Sample_Id = w.WeightometerSampleId
			INNER JOIN dbo.WeightometerSampleGrade AS wsg
				ON (wsg.Weightometer_Sample_Id = w.WeightometerSampleId)
			INNER JOIN @GradeLocation AS gl
				ON (gl.CalendarMonth = dbo.GetDateMonth(ws.Weightometer_Sample_Date)
					AND ISNULL(gl.SiteLocationId, -1) = ISNULL(w.SiteLocationId, -1))
		WHERE 
				-- only include if:
				-- 1. the Material Type is Bene Feed and there is no Sample Source
				-- 2. the Material Type is High Grade and there is a matching SampleSource
				CASE
					WHEN (w.MaterialTypeId = @BeneFeedMaterialTypeId) AND (sSource.Weightometer_Sample_Id IS NULL) THEN 1
					WHEN (w.MaterialTypeId = @HighGradeMaterialTypeId) AND (sSource.Weightometer_Sample_Id IS NOT NULL) THEN 1
					ELSE 0
				END = 1
		GROUP BY bse.SummaryEntryId, wsg.Grade_Id
		
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

GRANT EXECUTE ON dbo.SummariseBhpbioActualC TO BhpbioGenericManager
GO

/*
exec dbo.SummariseBhpbioActualC
	@iSummaryMonth = '2009-11-01',
	@iLocationId = 3
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.SummariseBhpbioActualC">
 <Procedure>
	Generates a set of summary ActualC data based on supplied criteria.
			
	Pass: 
			@iSummaryMonth: the month for which summary data is to be generated,
			@iSummaryLocationId: the location (typically a Site) for which data will be summarised
 </Procedure>
</TAG>
*/
IF OBJECT_ID('dbo.SummariseBhpbioActualY') IS NOT NULL
     DROP PROCEDURE dbo.SummariseBhpbioActualY 
GO 
    
CREATE PROCEDURE dbo.SummariseBhpbioActualY
(
	@iSummaryMonth DATETIME,
	@iSummaryLocationId INTEGER
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT	@TransactionName = 'SummariseBhpbioActualY',
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
		
		-- the first step is to remove previously summarised data for the same filtering criteria that the current summary is running on
		exec dbo.DeleteBhpbioSummaryActualY @iSummaryMonth = @iSummaryMonth,
											@iSummaryLocationId = @iSummaryLocationId
		
		-- obtain the Actual Type Id for ActualY storage
		SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
		FROM dbo.BhpbioSummaryEntryType bset
		WHERE bset.Name = 'ActualY'

		-- get the start of the summary month and the start of the following month
		-- this gives us a window of time to operate within
		SELECT @startOfMonth = dbo.GetDateMonth(@iSummaryMonth)
		SELECT @startOfNextMonth = DATEADD(month,1,@iSummaryMonth)

		-- get a Summary Id for the month (or create a new one if needed)
		EXEC dbo.GetBhpbioSummaryIdForMonth @iSummaryMonth = @startOfMonth,
											@oSummaryId = @summaryId OUTPUT

		-- create and populate a table variable used to store Ids of relevant locations
		DECLARE @Location TABLE
		(
			LocationId INT NOT NULL,
			ParentLocationId INT NULL,
			PRIMARY KEY (LocationId)
		)

		INSERT INTO @Location(
			LocationId, 
			ParentLocationId)
		SELECT LocationId, ParentLocationId
		FROM dbo.GetBhpbioReportLocationBreakdown(@iSummaryLocationId, 1, NULL)

		-- create a table to store details of relevant haulage rows
		DECLARE @SelectedHaulage TABLE
			(
				HaulageId INT NOT NULL,
				LocationId INT NULL,
				Tonnes FLOAT NOT NULL,
				MaterialTypeId INT NOT NULL
			)
		
		-- -----------------------------------------------------------------------------------------------------------------------------------
		-- The queries used in this procedure are based on / taken from the original reporting implementation (on non-summarised data)
		-- -----------------------------------------------------------------------------------------------------------------------------------

		-- populate the table used to store details of relevant haulage rows
		-- to be only the haulage rows within the time window
		-- and for the appropriate material types
		INSERT INTO @SelectedHaulage(
						HaulageId, 
						LocationId, 
						Tonnes, 
						MaterialTypeId
						)
		SELECT h.Haulage_Id, l.LocationId, h.Tonnes, destinationStockpile.MaterialTypeId
		FROM dbo.Haulage AS h
			INNER JOIN dbo.DigblockLocation dl 
				ON (dl.Digblock_Id = h.Source_Digblock_Id)
			INNER JOIN @Location AS l
				ON (l.LocationId = dl.Location_Id)
			-- join to the destination stockpile
			-- this is a way of filtering for Actual Y (ie material from digblocks to stockpiles)
			INNER JOIN
				(
					SELECT sl2.Stockpile_Id, sgd2.MaterialTypeId
					FROM dbo.BhpbioStockpileGroupDesignation AS sgd2
					INNER JOIN dbo.StockpileGroupStockpile AS sgs2
						ON (sgs2.Stockpile_Group_Id = sgd2.StockpileGroupId)
					INNER JOIN dbo.StockpileLocation AS sl2
							ON (sl2.Stockpile_Id = sgs2.Stockpile_Id)
				) AS destinationStockpile
				ON (destinationStockpile.Stockpile_Id = h.Destination_Stockpile_Id)
			INNER JOIN dbo.GetBhpbioFilteredMaterialTypes(1,null) mt
				ON mt.MaterialTypeId = destinationStockpile.MaterialTypeId
		WHERE h.Haulage_State_Id IN ('N', 'A')
			AND h.Child_Haulage_Id IS NULL
			AND h.Source_Digblock_Id IS NOT NULL
			AND h.Haulage_Date >= @startOfMonth 
			AND h.Haulage_Date < @startOfNextMonth
			AND h.Tonnes > 0

		-- insert main actual row using a Sum of Tonnes
		INSERT INTO dbo.BhpbioSummaryEntry (
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			Tonnes
		)
		SELECT  @summaryId,
				@summaryEntryTypeId,
				h.LocationId,
				h.MaterialTypeId,
				Sum(h.Tonnes)
		FROM @SelectedHaulage h
		GROUP BY h.LocationId, h.MaterialTypeId

		-- insert the actual grades related to the selection of Haulage we are working with and the actual tonnes rows created above
		INSERT INTO dbo.BhpbioSummaryEntryGrade (
			SummaryEntryId,
			GradeId,
			GradeValue
		)
		SELECT  bse.SummaryEntryId,
				hg.Grade_Id,
				-- weight-average the tonnes
				-- note that the AVG(bsa.Tonnes) could be any aggregate operation as there will only be one value per group
				-- as we are grouping on bse.SummaryEntryId
				SUM(h.Tonnes * hg.Grade_Value) / AVG(bse.Tonnes)
		FROM BhpbioSummaryEntry bse
			INNER JOIN @SelectedHaulage h 
				ON h.LocationId = bse.LocationId
				AND h.MaterialTypeId = bse.MaterialTypeId
			INNER JOIN dbo.HaulageGrade hg
				ON hg.Haulage_Id = h.HaulageId
		WHERE bse.SummaryId = @summaryId
			AND bse.SummaryEntryTypeId = @summaryEntryTypeId
		GROUP BY bse.SummaryEntryId, hg.Grade_Id
		
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

GRANT EXECUTE ON dbo.SummariseBhpbioActualY TO BhpbioGenericManager
GO

/*
-- A call like this is used for F1 related summarisation
exec dbo.SummariseBhpbioActualY
	@iSummaryMonth = '2009-11-01',
	@iLocationId = 3,
	
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.SummariseBhpbioActualY">
 <Procedure>
	Generates a set of summary ActualY data based on supplied criteria.
	Haulage data is the key source for this summarisation
			
	Pass: 
			@iSummaryMonth: the month for which summary data is to be deleted,
			@iSummaryLocationId: the location (typically a Pit) within which child locations will have data removed,
 </Procedure>
</TAG>
*/	
IF OBJECT_ID('dbo.SummariseBhpbioActualZ') IS NOT NULL
     DROP PROCEDURE dbo.SummariseBhpbioActualZ 
GO 
    
CREATE PROCEDURE dbo.SummariseBhpbioActualZ
(
	@iSummaryMonth DATETIME,
	@iSummaryLocationId INTEGER
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'SummariseBhpbioActualZ',
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
		
		-- obtain the Entry Type Id
		SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
		FROM dbo.BhpbioSummaryEntryType bset
		WHERE bset.Name = 'ActualZ'
		
		-- the first step is to remove previously summarised data for the same filtering criteria that the current summary is running on
		exec dbo.DeleteBhpbioSummaryEntry @iSummaryMonth = @iSummaryMonth,
											@iSummaryLocationId = @iSummaryLocationId,
											@iSummaryEntryTypeId = @summaryEntryTypeId
		

		-- get the start of the summary month and the start of the following month
		-- this gives us a window of time to operate within
		SELECT @startOfMonth = dbo.GetDateMonth(@iSummaryMonth)
		SELECT @startOfNextMonth = DATEADD(month,1,@iSummaryMonth)

		-- get a Summary Id for the month (or create a new one if needed)
		EXEC dbo.GetBhpbioSummaryIdForMonth @iSummaryMonth = @startOfMonth,
											@oSummaryId = @summaryId OUTPUT

		DECLARE @HighGradeMaterialTypeId INT
		DECLARE @BeneFeedMaterialTypeId INT

		-- set the material types
		SET @HighGradeMaterialTypeId =
			(
				SELECT Material_Type_Id
				FROM dbo.MaterialType
				WHERE Abbreviation = 'High Grade'
					AND Material_Category_Id = 'Designation'
			)

		SET @BeneFeedMaterialTypeId =
			(
				SELECT Material_Type_Id
				FROM dbo.MaterialType
				WHERE Abbreviation = 'Bene Feed'
					AND Material_Category_Id = 'Designation'
			)
	
		DECLARE @Location TABLE
		(
			LocationId INT NOT NULL,
			ParentLocationId INT NULL,
			PRIMARY KEY (LocationId)
		)
		
		-- setup the Locations
		INSERT INTO @Location
			(LocationId, ParentLocationId)
		SELECT LocationId, ParentLocationId
				FROM dbo.GetBhpbioReportLocationBreakdown(@iSummaryLocationId, 1, 'PIT')
		UNION 
		SELECT l.Location_Id, l.Parent_Location_Id
		FROM Location l
		WHERE l.Location_Id = @iSummaryLocationId

		DECLARE @SelectedHaulage TABLE
		(
			HaulageId INT NOT NULL,
			LocationId INT NULL,
			Tonnes FLOAT NOT NULL,
			MaterialTypeId INT NOT NULL,
			PRIMARY KEY (HaulageId)
		)
		
		-- -----------------------------------------------------------------------------------------------------------------------------------
		-- The queries used in this procedure are based on / taken from the original reporting implementation (on non-summarised data)
		-- -----------------------------------------------------------------------------------------------------------------------------------

		-- collect the haualge data that matches:
		-- 1. the date range specified
		-- 2. delivers to a crusher (which belongs to the location subtree specified)
		-- 3. sources from a designation stockpile group
		--
		-- for the Material Type, the following rule applies:
		-- If the Weightometer deliveres to a plant then it is BENE, otherwise it is High Grade.

		-- retrieve the list of Haulage Records to be used in the calculations
		INSERT INTO @SelectedHaulage
			(HaulageId, LocationId, Tonnes, MaterialTypeId)
		SELECT h.Haulage_Id, l.LocationId, h.Tonnes,
			CASE WHEN W.Weightometer_Id IS NOT NULL THEN @BeneFeedMaterialTypeId
					ELSE @HighGradeMaterialTypeId
			END
		FROM dbo.Haulage AS h
			INNER JOIN dbo.Crusher AS c
				ON (c.Crusher_Id = h.Destination_Crusher_Id)
			INNER JOIN dbo.CrusherLocation AS cl
				ON (cl.Crusher_Id = c.Crusher_Id)
			INNER JOIN @Location AS l
				ON (l.LocationId = cl.Location_Id)
			INNER JOIN dbo.Stockpile AS s
				ON (s.Stockpile_Id = h.Source_Stockpile_Id)
			INNER JOIN dbo.StockpileGroupStockpile AS sgs
				ON (sgs.Stockpile_Id = s.Stockpile_Id)
			INNER JOIN dbo.BhpbioStockpileGroupDesignation AS sgd
				ON (sgd.StockpileGroupId = sgs.Stockpile_Group_Id)
				
			LEFT JOIN dbo.WeightometerFlowPeriodView AS WFPV
				ON (WFPV.Source_Crusher_Id = c.Crusher_Id
					AND WFPV.Destination_Mill_Id IS NOT NULL
					AND (@startOfMonth > WFPV.Start_Date Or WFPV.Start_Date IS NULL)
					AND (@startOfMonth < WFPV.End_Date Or WFPV.End_Date IS NULL))
			LEFT JOIN dbo.Weightometer AS W
				ON (W.Weightometer_Id = WFPV.Weightometer_Id)
		WHERE 
			h.Haulage_State_Id IN ('N', 'A')
			AND h.Child_Haulage_Id IS NULL
			AND (W.Weightometer_Type_Id LIKE '%L1%' OR W.Weightometer_Type_Id IS NULL)
			AND h.Source_Stockpile_Id IS NOT NULL
			AND h.Haulage_Date >= @startOfMonth
			AND h.Haulage_Date < @startOfNextMonth
			
		-- insert main actual row using a Sum of Tonnes
		INSERT INTO dbo.BhpbioSummaryEntry (
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			Tonnes
		)
		SELECT  @summaryId,
				@summaryEntryTypeId,
				h.LocationId,
				h.MaterialTypeId,
				Sum(h.Tonnes)
		FROM @SelectedHaulage h
		GROUP BY h.LocationId, h.MaterialTypeId

		-- insert the actual grades related to the selection of Haulage we are working with and the actual tonnes rows created above
		INSERT INTO dbo.BhpbioSummaryEntryGrade (
			SummaryEntryId,
			GradeId,
			GradeValue
		 )
		SELECT  bse.SummaryEntryId,
				hg.Grade_Id,
				-- weight-average the tonnes
				-- note that the AVG(bsa.Tonnes) could be any aggregate operation as there will only be one value per group
				-- as we are grouping on bse.SummaryEntryId
				SUM(h.Tonnes * hg.Grade_Value) / AVG(bse.Tonnes)
		FROM dbo.BhpbioSummaryEntry bse
			INNER JOIN @SelectedHaulage h 
				ON h.LocationId = bse.LocationId
				AND h.MaterialTypeId = bse.MaterialTypeId
			INNER JOIN dbo.HaulageGrade hg
				ON hg.Haulage_Id = h.HaulageId
		WHERE bse.SummaryId = @summaryId
			AND bse.SummaryEntryTypeId = @summaryEntryTypeId
			AND hg.Grade_Value IS NOT NULL
		GROUP BY bse.SummaryEntryId, hg.Grade_Id
		
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

GRANT EXECUTE ON dbo.SummariseBhpbioActualZ TO BhpbioGenericManager
GO

/*
exec dbo.SummariseBhpbioActualZ
	@iSummaryMonth = '2009-11-01',
	@iLocationId = 3,
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.SummariseBhpbioActualZ">
 <Procedure>
	Generates a set of summary ActualZ data based on supplied criteria.
			
	Pass: 
			@iSummaryMonth: the month for which summary data is to be generated,
			@iSummaryLocationId: the location (typically a Site) for which data will be summarised,
 </Procedure>
</TAG>
*/	
IF OBJECT_ID('dbo.SummariseBhpbioAdditionalHaulageRelated') IS NOT NULL
     DROP PROCEDURE dbo.SummariseBhpbioAdditionalHaulageRelated
GO 

CREATE PROCEDURE dbo.SummariseBhpbioAdditionalHaulageRelated
(
	@iSummaryMonth DATETIME,
	@iSummaryLocationId INTEGER,
	@iIsHighGrade BIT,
	@iSpecificMaterialTypeId INTEGER
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	DECLARE @summaryEntryTypeId INTEGER
	DECLARE @blockModelId INTEGER
	DECLARE @HauledFieldId VARCHAR(31)
	DECLARE @SurveyedFieldId VARCHAR(31)
	DECLARE @MaterialCategory VARCHAR(31)
	SET @MaterialCategory = 'Designation'
		
	SET NOCOUNT ON 

	SELECT @TransactionName = 'SummariseBhpbioAdditionalHaulageRelated',
		@TransactionCount = @@TranCount 

	DECLARE @monthlyHauledSummaryEntryTypeId INTEGER
	DECLARE @monthlyBestSummaryEntryTypeId INTEGER
	DECLARE @surveySummaryEntryTypeId INTEGER
	DECLARE @cumulativeHauledEntryTypeId INTEGER
	DECLARE @totalGradeControlEntryTypeId INTEGER
	DECLARE @gradeControlBlockModelId INTEGER
	
	SELECT @monthlyHauledSummaryEntryTypeId = bset.SummaryEntryTypeId
	FROM dbo.BhpbioSummaryEntryType bset
	WHERE bset.Name like 'BlastBlockMonthlyHauled'
	
	SELECT @monthlyBestSummaryEntryTypeId = bset.SummaryEntryTypeId
	FROM dbo.BhpbioSummaryEntryType bset
	WHERE bset.Name like 'BlastBlockMonthlyBest'
	
	SELECT @surveySummaryEntryTypeId = bset.SummaryEntryTypeId
	FROM dbo.BhpbioSummaryEntryType bset
	WHERE bset.Name like 'BlastBlockSurvey'
	
	SELECT @cumulativeHauledEntryTypeId = bset.SummaryEntryTypeId
	FROM dbo.BhpbioSummaryEntryType bset
	WHERE bset.Name like 'BlastBlockCumulativeHauled'
	
	SELECT @totalGradeControlEntryTypeId = bset.SummaryEntryTypeId,
		@gradeControlBlockModelId = bset.AssociatedBlockModelId
	FROM dbo.BhpbioSummaryEntryType bset
	WHERE bset.Name like 'BlastBlockTotalGradeControl'
	
	SET @HauledFieldId = 'HauledTonnes'
	SET @SurveyedFieldId = 'GroundSurveyTonnes'
	
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

		-- the first step is to remove data already summarised for this set of criteria
		exec dbo.DeleteBhpbioSummaryAdditionalHaulageRelated	@iSummaryMonth = @iSummaryMonth,
																@iSummaryLocationId = @iSummaryLocationId,
																@iIsHighGrade = @iIsHighGrade,
																@iSpecificMaterialTypeId = @iSpecificMaterialTypeId

		-- determine the start of the summary month and the start of the following month
		-- this gives us a window of time to operate within
		SELECT @startOfMonth = dbo.GetDateMonth(@iSummaryMonth)
		SELECT @startOfNextMonth = DATEADD(month,1,@iSummaryMonth)

		-- determine the appropriate Summary Id the data calculated here is to be appended with
		EXEC dbo.GetBhpbioSummaryIdForMonth @iSummaryMonth = @startOfMonth,
											@oSummaryId = @summaryId OUTPUT

		-- create and populate a table variable to store Identifiers for relevant locations
		DECLARE @Location TABLE
		(
			LocationId INT NOT NULL,
			ParentLocationId INT NULL,
			PRIMARY KEY (LocationId)
		)
		
		INSERT INTO @Location(
			LocationId,
			ParentLocationId)
		SELECT LocationId, ParentLocationId
		FROM dbo.GetBhpbioReportLocationBreakdown(@iSummaryLocationId, 1, NULL)
				
		DECLARE @Staging TABLE
		(
			LocationId INT NOT NULL,
			MaterialTypeId INT NULL,
			BestTonnes REAL,
			HauledTonnes REAL,
			SurveyTonnes REAL,
			CumulativeHauledTonnes REAL,
			TotalGradeControl REAL
			PRIMARY KEY (LocationId)
		)
		
		DECLARE @ActiveDigblock TABLE
		(
			DigblockId VARCHAR(31)
		)
	
		-- find the digblocks active through either BhpbioImportReconciliationMovement or Haulage
		INSERT INTO @ActiveDigblock
		SELECT DISTINCT d.Digblock_Id
		FROM (
			SELECT DISTINCT dl.Digblock_Id
			FROM dbo.BhpbioImportReconciliationMovement rm
				INNER JOIN dbo.DigblockLocation dl ON dl.Location_Id = rm.BlockLocationId
			WHERE rm.DateTo >= @startOfMonth AND rm.DateTo < @startOfNextMonth
			UNION
			SELECT DISTINCT h.Source_Digblock_Id
			FROM dbo.Haulage h
			WHERE h.Haulage_Date >= @startOfMonth 
				AND h.Haulage_Date < @startOfNextMonth
		) as d
		
		-- calculate the best, hauled and survey tonnes
		INSERT INTO @Staging
		(
			LocationId,
			MaterialTypeId,
			BestTonnes,
			HauledTonnes,
			SurveyTonnes
		)
		SELECT	l.LocationId, 
				d.Material_Type_Id,
				COALESCE(SUM(h.Tonnes), 0) As BestTonnes,
				COALESCE(SUM(hauled.Field_Value), 0) As HauledTonnes,
				COALESCE(SUM(survey.Field_Value), 0) As SurveyTonnes
		FROM @ActiveDigblock ad
			INNER JOIN dbo.Digblock d
				ON d.Digblock_Id = ad.DigblockId
			INNER JOIN dbo.DigblockLocation dl
				ON dl.Digblock_Id = d.Digblock_Id
			INNER JOIN dbo.GetBhpbioFilteredMaterialTypes(@iIsHighGrade,@iSpecificMaterialTypeId) fmt
				ON fmt.MaterialTypeId = d.Material_Type_Id
			INNER JOIN @Location l
				ON l.LocationId = dl.Location_Id
			LEFT JOIN dbo.Haulage h
				ON h.Source_Digblock_Id = ad.DigblockId
				AND h.Haulage_Date >= @startOfMonth 
				AND h.Haulage_Date < @startOfNextMonth
				AND h.Haulage_State_Id IN ('N', 'A')
				AND h.Child_Haulage_Id IS NULL
			LEFT JOIN dbo.HaulageValue AS hauled
				ON h.Haulage_Id = hauled.Haulage_Id
					AND hauled.Haulage_Field_Id = @HauledFieldId
			LEFT JOIN dbo.HaulageValue AS survey
				ON h.Haulage_Id = survey.Haulage_Id
					AND survey.Haulage_Field_Id = @SurveyedFieldId
		GROUP BY l.LocationId, d.Material_Type_Id	
				
		-- update the cumulative tonnes				
		UPDATE s
		SET CumulativeHauledTonnes = cumulative.Best
		FROM @Staging AS s
			INNER JOIN (
				SELECT dl.Location_Id,
						Coalesce(Sum(ch.Tonnes), 0) As Best
					FROM dbo.Haulage AS ch
						INNER JOIN dbo.Digblock d
							ON d.Digblock_Id = ch.Source_Digblock_Id
						INNER JOIN dbo.DigblockLocation dl
							ON dl.Digblock_Id = d.Digblock_Id
					WHERE ch.Haulage_Date < @startOfNextMonth
						AND ch.Haulage_State_Id IN ('N', 'A')
						AND ch.Child_Haulage_Id IS NULL
					GROUP BY dl.Location_Id	
				) AS cumulative
					ON s.LocationId = cumulative.Location_Id

		-- update the grade control tonnes				
		UPDATE s
		SET TotalGradeControl = model.GradeControl
		FROM @Staging AS s
			LEFT JOIN 
				(
					SELECT R.LocationId,
						Sum(CASE WHEN BM.Name = 'Grade Control' THEN MBP.Tonnes ELSE NULL END) As GradeControl
					FROM @Staging AS R
						INNER JOIN dbo.ModelBlockLocation AS MBL
							ON (R.LocationId = MBL.Location_Id)
						INNER JOIN dbo.ModelBlock AS MB
							ON (MBL.Model_Block_Id = MB.Model_Block_Id)
						INNER JOIN dbo.BlockModel AS BM
							ON (BM.Block_Model_Id = MB.Block_Model_Id)
						INNER JOIN dbo.ModelBlockPartial AS MBP
							ON (MB.Model_Block_Id = MBP.Model_Block_Id)
						INNER JOIN dbo.GetMaterialsByCategory(@MaterialCategory) AS MC
							ON (MC.MaterialTypeId = MBP.Material_Type_Id)
						INNER JOIN dbo.MaterialType AS MT
							ON (MC.RootMaterialTypeId = MT.Material_Type_Id)
						WHERE BM.Block_Model_Id = @gradeControlBlockModelId
					GROUP BY R.LocationId
				) AS model
					ON s.LocationId = model.LocationId
		
		---- Insert the haulage tonnes
		INSERT INTO dbo.BhpbioSummaryEntry
		(
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			Tonnes
		)
		SELECT	@summaryId,
				@monthlyHauledSummaryEntryTypeId,
				s.LocationId,
				s.MaterialTypeId,
				COALESCE(s.HauledTonnes,0)
		FROM 	@Staging s
		
		---- Insert the Best tonnes
		INSERT INTO dbo.BhpbioSummaryEntry
		(
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			Tonnes
		)
		SELECT	@summaryId,
				@monthlyBestSummaryEntryTypeId,
				s.LocationId,
				s.MaterialTypeId,
				COALESCE(s.BestTonnes,0)
		FROM 	@Staging s
		
		---- Insert the Survey tonnes
		INSERT INTO dbo.BhpbioSummaryEntry
		(
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			Tonnes
		)
		SELECT	@summaryId,
				@surveySummaryEntryTypeId,
				s.LocationId,
				s.MaterialTypeId,
				COALESCE(s.SurveyTonnes,0)
		FROM 	@Staging s
		
		---- Insert the Cumulative Hauled tonnes
		INSERT INTO dbo.BhpbioSummaryEntry
		(
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			Tonnes
		)
		SELECT	@summaryId,
				@cumulativeHauledEntryTypeId,
				s.LocationId,
				s.MaterialTypeId,
				s.CumulativeHauledTonnes
		FROM 	@Staging s
		WHERE s.CumulativeHauledTonnes IS NOT NULL
		
		---- Insert the Total Grade Control
		INSERT INTO dbo.BhpbioSummaryEntry
		(
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			Tonnes
		)
		SELECT	@summaryId,
				@totalGradeControlEntryTypeId,
				s.LocationId,
				s.MaterialTypeId,
				s.TotalGradeControl
		FROM 	@Staging s
		WHERE s.TotalGradeControl IS NOT NULL
		
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

GRANT EXECUTE ON dbo.SummariseBhpbioAdditionalHaulageRelated TO BhpbioGenericManager
GO

/*
-- A call like this is used for additional haulage summarisation for a model
exec dbo.SummariseBhpbioAdditionalHaulageRelated
	@iSummaryMonth = '2009-11-01',
	@@iSummaryLocationId = 3,
	@iIsHighGrade = 1,
	@iSpecificMaterialTypeId = null
	
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.SummariseBhpbioAdditionalHaulageRelated">
 <Procedure>
	Generates a set of summary additional haulage data based on supplied criteria.
	The core set of data for this operation is that stored in:
		- the BhpbioImportReconciliationMovement table
		- the BlockModel and Model* tables
	
	Note that the BhpbioImportReconciliationMovement table contains MinedPercentage values.  These are combined with Model data
	to create a set of summarised Model Movements
	
	In the descriptions below the term Related Material Type means a MeterialType that is either
			- the Root for the specified type
			- a material type that has the specified type as its root
	In the descriptions below the phrase High Grade Related type means a type that is:
			- returned by the dbo.GetBhpbioReportHighGrade() function
			
	Pass: 
			@iSummaryMonth: the month for which summary data is to be generated,
			@iSummaryLocationId: the location (typically a Pit) used to filter the movements to have summary data generated,
			@iIsHighGrade : 
							when 0 - Data for High grade related types is excluded
							when 1 - Only data for high grade related types is included
							when null - this criteria has no impact on filtering
			@iSpecificMaterialTypeId:
							when specified - only Data for the exact matching MaterialTypeId or for MaterialTypes related to the exact match is included
							when null - this criteria has no impact on filtering
 </Procedure>
</TAG>
*/

IF OBJECT_ID('dbo.SummariseBhpbioDataRelatedToApproval') IS NOT NULL
     DROP PROCEDURE dbo.SummariseBhpbioDataRelatedToApproval
GO 
  
CREATE PROCEDURE dbo.SummariseBhpbioDataRelatedToApproval
(
	@iTagId VARCHAR(31),
	@iLocationId INT,
	@iApprovalMonth DATETIME,
	@iUserId INT
)
WITH ENCRYPTION
AS 
BEGIN 
	SET NOCOUNT ON 
	
	DECLARE @TransactionName VARCHAR
	DECLARE @TransactionCount INTEGER
	
	SELECT @TransactionName = 'SummariseBhpbioDataRelatedToApproval',
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
	
		-- Here we plug-in data summarisation steps as part of the approval
		-- based on the supplied @iTagId
		
		IF @iTagId = 'F1Factor'
		BEGIN
			-- summarise ActualY data
			exec dbo.SummariseBhpbioActualY @iSummaryMonth = @iApprovalMonth, 
											@iSummaryLocationId = @iLocationId
											
			exec dbo.SummariseBhpbioAdditionalHaulageRelated @iSummaryMonth = @iApprovalMonth, 
										@iSummaryLocationId = @iLocationId,
										@iIsHighGrade = 1,
										@iSpecificMaterialTypeId = null
		END
		
		IF @iTagId = 'F1GeologyModel'
		BEGIN
			-- summarise geology model movements
			exec dbo.SummariseBhpbioModelMovement	@iSummaryMonth = @iApprovalMonth, 
													@iSummaryLocationId = @iLocationId,
													@iIsHighGrade = 1,
													@iSpecificMaterialTypeId = null,
													@iModelName = 'Geology'
		END
		
		IF @iTagId = 'F1GradeControlModel'
		BEGIN
			-- summarise grade control movements
			exec dbo.SummariseBhpbioModelMovement	@iSummaryMonth = @iApprovalMonth, 
													@iSummaryLocationId = @iLocationId,
													@iIsHighGrade = 1,
													@iSpecificMaterialTypeId = null,
													@iModelName = 'Grade Control'
		END
		
		IF @iTagId = 'F1MiningModel'
		BEGIN
			-- summarise mining model movements
			exec dbo.SummariseBhpbioModelMovement	@iSummaryMonth = @iApprovalMonth, 
													@iSummaryLocationId = @iLocationId,
													@iIsHighGrade = 1,
													@iSpecificMaterialTypeId = null,
													@iModelName = 'Mining'
		END
		
		IF @iTagId like 'OtherMaterial%'
		BEGIN
			DECLARE @otherMaterialTypeId INTEGER
			
			-- determine the MaterialType associated with the OtherMaterial movement
			SELECT @otherMaterialTypeId = OtherMaterialTypeId
			FROM dbo.BhpbioReportDataTags rdt
			WHERE rdt.TagId = @iTagId
			
			-- summarise Geology Model Movements
			exec dbo.SummariseBhpbioModelMovement	@iSummaryMonth = @iApprovalMonth, 
													@iSummaryLocationId = @iLocationId,
													@iIsHighGrade = null,
													@iSpecificMaterialTypeId = @otherMaterialTypeId,
													@iModelName = 'Geology'
			
			-- summarise Grade Control Model Movements
			exec dbo.SummariseBhpbioModelMovement	@iSummaryMonth = @iApprovalMonth, 
													@iSummaryLocationId = @iLocationId,
													@iIsHighGrade = null,
													@iSpecificMaterialTypeId = @otherMaterialTypeId,
													@iModelName = 'Grade Control'

			-- summarise Mining Model Movements													
			exec dbo.SummariseBhpbioModelMovement	@iSummaryMonth = @iApprovalMonth, 
													@iSummaryLocationId = @iLocationId,
													@iIsHighGrade = null,
													@iSpecificMaterialTypeId = @otherMaterialTypeId,
													@iModelName = 'Mining'
													
			-- summarise stockpile movements (for the specific type)
			exec dbo.SummariseBhpbioOMToStockpile @iSummaryMonth = @iApprovalMonth, 
											@iSummaryLocationId = @iLocationId,
											@iSpecificMaterialTypeId = @otherMaterialTypeId
			
			exec dbo.SummariseBhpbioAdditionalHaulageRelated @iSummaryMonth = @iApprovalMonth,
																		@iSummaryLocationId = @iLocationId,
																		@iIsHighGrade = null,
																		@iSpecificMaterialTypeId = @otherMaterialTypeId
		END
		
		IF @iTagId = 'F2MineProductionActuals'
		BEGIN
			-- summarise ActualC data
			exec dbo.SummariseBhpbioActualC @iSummaryMonth = @iApprovalMonth, 
											@iSummaryLocationId = @iLocationId
											
			-- and at the same time summarise the Bene Feed
			exec dbo.SummariseBhpbioActualBeneProduct	@iSummaryMonth = @iApprovalMonth, 
														@iSummaryLocationId = @iLocationId
		END
		
		IF @iTagId = 'F2StockpileToCrusher'
		BEGIN
			-- summarise ActualZ data for the site
			exec dbo.SummariseBhpbioActualZ @iSummaryMonth = @iApprovalMonth, 
											@iSummaryLocationId = @iLocationId
		END
		
		IF @iTagId = 'F3PostCrusherStockpileDelta'
		BEGIN
			-- summarise SitePostCrusherStockpileDelta data
			
			-- for Hub crushers
			exec dbo.SummariseBhpbioPostCrusherStockpileDelta @iSummaryMonth = @iApprovalMonth, 
															  @iSummaryLocationId = @iLocationId,
															  @iPostCrusherLevel = 'Hub'
			
			-- and Site crushers												  
			exec dbo.SummariseBhpbioPostCrusherStockpileDelta @iSummaryMonth = @iApprovalMonth, 
															  @iSummaryLocationId = @iLocationId,
															  @iPostCrusherLevel = 'Site'
		END
		
		IF @iTagId = 'F3PortStockpileDelta'
		BEGIN
			exec dbo.SummariseBhpbioPortStockpileDelta	@iSummaryMonth = @iApprovalMonth, 
														@iSummaryLocationId = @iLocationId
		END
		
		IF @iTagId = 'F3PortBlendedAdjustment'
		BEGIN
			exec dbo.SummariseBhpbioPortBlendedAdjustment	@iSummaryMonth = @iApprovalMonth, 
															@iSummaryLocationId = @iLocationId
		END
		
		IF @iTagId = 'F3OreShipped'
		BEGIN
			exec dbo.SummariseBhpbioShippingTransaction @iSummaryMonth = @iApprovalMonth, 
														@iSummaryLocationId = @iLocationId
		END
		
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

GRANT EXECUTE ON dbo.SummariseBhpbioDataRelatedToApproval TO BhpbioGenericManager
GO

/*
exec dbo.SummariseBhpbioDataRelatedToApproval
	@iTagId = 'F2Factor',
	@iLocationId = 3,
	@iApprovalMonth = '2009-11-01',
	@iUserId = 1
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.SummariseBhpbioDataRelatedToApproval">
 <Procedure>
	Generates a set of summary data based on supplied criteria.
	The criteria used is the same that would be passed to the corresponding Approval call
	
	Pass: 
			@iTagId: indicates the type of approval to generate summary information for
			@iLocationId: indicates a location related to the approval operation (for F1 approvals this would be a Pit and so on)
			@iApprovalMonth: the approval month to generate summary data for
			@iUserId: Identifies the user performing the operation			
 </Procedure>
</TAG>
*/
IF OBJECT_ID('dbo.SummariseBhpbioModelMovement') IS NOT NULL
     DROP PROCEDURE dbo.SummariseBhpbioModelMovement
GO 

CREATE PROCEDURE dbo.SummariseBhpbioModelMovement
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
	DECLARE @blockModelId INTEGER
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'SummariseBhpbioModelMovement',
		@TransactionCount = @@TranCount 

	SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
	FROM dbo.BhpbioSummaryEntryType bset
	WHERE bset.Name like REPLACE(@iModelName,' ','') + 'ModelMovement'
	
	SELECT @blockModelId = bm.Block_Model_Id
	FROM dbo.BlockModel bm
	WHERE bm.Name like @iModelName
	
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


		-- the first step is to remove data already summarised for this set of criteria
		exec dbo.DeleteBhpbioSummaryModelMovement	@iSummaryMonth = @iSummaryMonth,
													@iSummaryLocationId = @iSummaryLocationId,
													@iIsHighGrade = @iIsHighGrade,
													@iSpecificMaterialTypeId = @iSpecificMaterialTypeId,
													@iModelName = @iModelName

		-- determine the start of the summary month and the start of the following month
		-- this gives us a window of time to operate within
		SELECT @startOfMonth = dbo.GetDateMonth(@iSummaryMonth)
		SELECT @startOfNextMonth = DATEADD(month,1,@iSummaryMonth)

		-- determine the appropriate Summary Id the data calculated here is to be appended with
		EXEC dbo.GetBhpbioSummaryIdForMonth @iSummaryMonth = @startOfMonth,
											@oSummaryId = @summaryId OUTPUT

		-- create and populate a table variable to store Identifiers for relevant locations
		DECLARE @Location TABLE
		(
			LocationId INT NOT NULL,
			ParentLocationId INT NULL,
			PRIMARY KEY (LocationId)
		)
		
		INSERT INTO @Location(
			LocationId, 
			ParentLocationId)
		SELECT LocationId, ParentLocationId
		FROM dbo.GetBhpbioReportLocationBreakdown(@iSummaryLocationId, 1, NULL)
		
		DECLARE @ImportStaging TABLE
		(
			LocationId INT NOT NULL,
			MinedPercentage FLOAT NOT NULL,
			TotalDurationSeconds INTEGER,
			TruncatedStart DATETIME,
			TruncatedEnd DATETIME,
			EffectiveMinedPercentage FLOAT
		)
		
		-- -----------------------------------------------------------------------------------------------------------------------------------
		-- The queries used in this procedure are based on / taken from the original reporting implementation (on non-summarised data)
		-- -----------------------------------------------------------------------------------------------------------------------------------
	
		-- select import movements within the period for the specified location
		INSERT INTO @ImportStaging 
					(
					LocationId,
					MinedPercentage,
					TotalDurationSeconds,
					TruncatedStart,
					TruncatedEnd
					)
		SELECT	irm.BlockLocationId, 
				irm.MinedPercentage, 
				DATEDIFF(second, irm.DateFrom, irm.DateTo) as totalSeconds,
				CASE WHEN irm.DateFrom >= @startOfMonth THEN irm.DateFrom ELSE @startOfMonth END as truncatedStart,
				CASE WHEN irm.DateTo <= @startOfNextMonth THEN irm.DateTo ELSE @startOfNextMonth END as truncatedEnd
		FROM dbo.BhpbioImportReconciliationMovement irm
			INNER JOIN @Location loc 
				ON loc.LocationId = irm.BlockLocationId
		WHERE irm.DateFrom < @startOfNextMonth
			AND irm.DateTo > @startOfMonth

		-- update the mined percentage to be only the proportion that is within the summary period
		-- this is used to handle cases where a movement extends beyond the end of a summary period or starts before it
		UPDATE @ImportStaging
			SET EffectiveMinedPercentage =	MinedPercentage 
											* DATEDIFF(second, TruncatedStart, TruncatedEnd) 
											/ TotalDurationSeconds
						
		---- Insert the actual tonnes
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
				imp.LocationId,
				mbp.Material_Type_Id,
				Sum(mbp.Tonnes * imp.EffectiveMinedPercentage)
		FROM 	@ImportStaging imp
			INNER JOIN ModelBlockLocation mbl
				ON mbl.Location_Id = imp.LocationId
			INNER JOIN ModelBlock mb
				ON mb.Model_Block_Id = mbl.Model_Block_Id
			INNER JOIN ModelBlockPartial mbp 
				ON mbp.Model_Block_Id = mb.Model_Block_Id
			INNER JOIN dbo.GetBhpbioFilteredMaterialTypes(@iIsHighGrade,@iSpecificMaterialTypeId) mt
				ON mt.MaterialTypeId = mbp.Material_Type_Id
		WHERE	mbp.Tonnes > 0 
				AND imp.EffectiveMinedPercentage > 0
				AND mb.Block_Model_Id = @blockModelId
		GROUP BY imp.LocationId, mbp.Material_Type_Id
		
		-- Calculate the grades
		-- this uses the same data as that for the tonnage above but joins the grade values from the block model
		-- Note: As material within a block is taken proportionately evenly the weighted averaging that is done
		-- can use the total tonnes of block partials (easire) rather than just the moved tonnes 
		--   e.g The block may have contained 2 partials, 1 of 100 and one of 50 tonnes
		--       only 10 tonnes of the first partial and 5 tonnes of the second partial were moved
		--       the weighted average operation will produce the same result whether total tonnes or moved tonnes are used
		--			(100 and 50 or 10 and 5)
		INSERT INTO dbo.BhpbioSummaryEntryGrade
		(
			SummaryEntryId,
			GradeId,
			GradeValue
		)
		SELECT  bse.SummaryEntryId,
			   mbpg.Grade_Id,
			   Sum(mbpg.Grade_Value * mbp.Tonnes) / Sum(mbp.Tonnes)
		FROM dbo.BhpbioSummaryEntry bse
			INNER JOIN @Location loc 
					ON loc.LocationId = bse.LocationId
			INNER JOIN dbo.GetBhpbioFilteredMaterialTypes(@iIsHighGrade,@iSpecificMaterialTypeId) mt
				ON mt.MaterialTypeId = bse.MaterialTypeId
			INNER JOIN ModelBlockLocation mbl
					ON mbl.Location_Id = bse.LocationId
			INNER JOIN ModelBlock mb
					ON mb.Model_Block_Id = mbl.Model_Block_Id
			INNER JOIN ModelBlockPartial mbp 
					ON mbp.Model_Block_Id = mb.Model_Block_Id
					AND mbp.Material_Type_Id = bse.MaterialTypeId
			INNER JOIN ModelBlockPartialGrade mbpg
					ON mbpg.Model_Block_Id = mbp.Model_Block_Id
					AND mbpg.Sequence_No = mbp.Sequence_No
		WHERE	mbp.Tonnes > 0 
				AND bse.SummaryId = @summaryId
				AND bse.SummaryEntryTypeId = @summaryEntryTypeId
				AND bse.Tonnes > 0
				AND mb.Block_Model_Id = @blockModelId
		GROUP BY bse.SummaryEntryId, mbpg.Grade_Id
		
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

GRANT EXECUTE ON dbo.SummariseBhpbioModelMovement TO BhpbioGenericManager
GO

/*
-- A call like this is used for F1 related summarisation for a model
exec dbo.SummariseBhpbioModelMovement
	@iSummaryMonth = '2009-11-01',
	@@iSummaryLocationId = 3,
	@iIsHighGrade = 1,
	@iSpecificMaterialTypeId = null,
	@iModelName = 'Geology Model'
	
	
-- A call like this is used for Other Movements related summarisation for a particular material type
exec dbo.SummariseBhpbioModelMovement
	@iSummaryMonth = '2009-11-01',
	@iLocationId = 3,
	@iIsHighGrade = null,
	@iSpecificMaterialTypeId = 6,
	@iModelName = 'Grade Control Model'
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.SummariseBhpbioModelMovement">
 <Procedure>
	Generates a set of summary Model Movement data based on supplied criteria.
	The core set of data for this operation is that stored in:
		- the BhpbioImportReconciliationMovement table
		- the BlockModel and Model* tables
	
	Note that the BhpbioImportReconciliationMovement table contains MinedPercentage values.  These are combined with Model data
	to create a set of summarised Model Movements
	
	In the descriptions below the term Related Material Type means a MeterialType that is either
			- the Root for the specified type
			- a material type that has the specified type as its root
	In the descriptions below the phrase High Grade Related type means a type that is:
			- returned by the dbo.GetBhpbioReportHighGrade() function
			
	Pass: 
			@iSummaryMonth: the month for which summary data is to be generated,
			@iSummaryLocationId: the location (typically a Pit) used to filter the movements to have summary data generated,
			@iIsHighGrade : 
							when 0 - Data for High grade related types is excluded
							when 1 - Only data for high grade related types is included
							when null - this criteria has no impact on filtering
			@iSpecificMaterialTypeId:
							when specified - only Data for the exact matching MaterialTypeId or for MaterialTypes related to the exact match is included
							when null - this criteria has no impact on filtering
			@iModelName: Name of the block model used to obtain data
 </Procedure>
</TAG>
*/	
IF OBJECT_ID('dbo.SummariseBhpbioOMToStockpile') IS NOT NULL
     DROP PROCEDURE dbo.SummariseBhpbioOMToStockpile 
GO 
    
CREATE PROCEDURE dbo.SummariseBhpbioOMToStockpile
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

	SELECT @TransactionName = 'SummariseBhpbioOMToStockpile',
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
		
		-- the first step is to remove previously summarised data for the same filtering criteria that the current summary is running on
		exec dbo.DeleteBhpbioSummaryOMToStockpile @iSummaryMonth = @iSummaryMonth,
											@iSummaryLocationId = @iSummaryLocationId,
											@iSpecificMaterialTypeId = @iSpecificMaterialTypeId
		
		-- obtain the Actual Type Id for ActualY storage
		SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
		FROM dbo.BhpbioSummaryEntryType bset
		WHERE bset.Name = 'ActualOMToStockpile'

		-- get the start of the summary month and the start of the following month
		-- this gives us a window of time to operate within
		SELECT @startOfMonth = dbo.GetDateMonth(@iSummaryMonth)
		SELECT @startOfNextMonth = DATEADD(month,1,@iSummaryMonth)

		-- get a Summary Id for the month (or create a new one if needed)
		EXEC dbo.GetBhpbioSummaryIdForMonth @iSummaryMonth = @startOfMonth,
											@oSummaryId = @summaryId OUTPUT

		-- create and populate a table variable used to store Ids of relevant locations
		DECLARE @Location TABLE
		(
			LocationId INT NOT NULL,
			ParentLocationId INT NULL,
			PRIMARY KEY (LocationId)
		)

		INSERT INTO @Location(
			LocationId, 
			ParentLocationId)
		SELECT LocationId, ParentLocationId
		FROM dbo.GetBhpbioReportLocationBreakdown(@iSummaryLocationId, 1, NULL)

		-- create a table to store details of relevant haulage rows
		DECLARE @SelectedHaulage TABLE
			(
				HaulageId INT NOT NULL,
				LocationId INT NULL,
				Tonnes FLOAT NOT NULL,
				MaterialTypeId INT NOT NULL
			)
			
		-- -----------------------------------------------------------------------------------------------------------------------------------
		-- The queries used in this procedure are based on / taken from the original reporting implementation (on non-summarised data)
		-- -----------------------------------------------------------------------------------------------------------------------------------

		-- populate the table used to store details of relevant haulage rows
		-- to be only the haulage rows within the time window
		-- and for the appropriate material types
		INSERT INTO @SelectedHaulage(
						HaulageId, 
						LocationId, 
						Tonnes, 
						MaterialTypeId
						)
		SELECT h.Haulage_Id, l.LocationId, h.Tonnes, destinationStockpile.MaterialTypeId
		FROM dbo.Haulage AS h
			INNER JOIN dbo.DigblockLocation dl 
				ON (dl.Digblock_Id = h.Source_Digblock_Id)
			INNER JOIN @Location AS l
				ON (l.LocationId = dl.Location_Id)
			-- join to the destination stockpile
			-- this is a way of filtering for material from digblocks to stockpiles
			INNER JOIN
				(
					SELECT sl2.Stockpile_Id, sgd2.MaterialTypeId
					FROM dbo.BhpbioStockpileGroupDesignation AS sgd2
					INNER JOIN dbo.StockpileGroupStockpile AS sgs2
						ON (sgs2.Stockpile_Group_Id = sgd2.StockpileGroupId)
					INNER JOIN dbo.StockpileLocation AS sl2
							ON (sl2.Stockpile_Id = sgs2.Stockpile_Id)
				) AS destinationStockpile
				ON (destinationStockpile.Stockpile_Id = h.Destination_Stockpile_Id)
			INNER JOIN dbo.GetBhpbioFilteredMaterialTypes(null,@iSpecificMaterialTypeId) mt
				ON mt.MaterialTypeId = destinationStockpile.MaterialTypeId
		WHERE h.Haulage_State_Id IN ('N', 'A')
			AND h.Child_Haulage_Id IS NULL
			AND h.Source_Digblock_Id IS NOT NULL
			AND h.Haulage_Date >= @startOfMonth 
			AND h.Haulage_Date < @startOfNextMonth
			AND h.Tonnes > 0

		-- insert main actual row using a Sum of Tonnes
		INSERT INTO dbo.BhpbioSummaryEntry (
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			Tonnes
		)
		SELECT  @summaryId,
				@summaryEntryTypeId,
				h.LocationId,
				h.MaterialTypeId,
				Sum(h.Tonnes)
		FROM @SelectedHaulage h
		GROUP BY h.LocationId, h.MaterialTypeId

		-- insert the actual grades related to the selection of Haulage we are working with and the actual tonnes rows created above
		INSERT INTO dbo.BhpbioSummaryEntryGrade (
			SummaryEntryId,
			GradeId,
			GradeValue
		)
		SELECT  bse.SummaryEntryId,
				hg.Grade_Id,
				-- weight-average the tonnes
				-- note that the AVG(bsa.Tonnes) could be any aggregate operation as there will only be one value per group
				-- as we are grouping on bse.SummaryEntryId
				SUM(h.Tonnes * hg.Grade_Value) / AVG(bse.Tonnes)
		FROM dbo.BhpbioSummaryEntry bse
			INNER JOIN @SelectedHaulage h 
				ON h.LocationId = bse.LocationId
				AND h.MaterialTypeId = bse.MaterialTypeId
			INNER JOIN dbo.HaulageGrade hg 
				ON hg.Haulage_Id = h.HaulageId
		WHERE bse.SummaryId = @summaryId
			AND bse.SummaryEntryTypeId = @summaryEntryTypeId
		GROUP BY bse.SummaryEntryId, hg.Grade_Id
		
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

GRANT EXECUTE ON dbo.SummariseBhpbioOMToStockpile TO BhpbioGenericManager
GO

/*
-- A call like this is used for Other Movements related summarisation for a particular material type
exec dbo.SummariseBhpbioOMToStockpile
	@iSummaryMonth = '2009-11-01',
	@iLocationId = 3,
	@iSpecificMaterialTypeId = 6
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.SummariseBhpbioOMToStockpile">
 <Procedure>
	Generates a set of summary Actual Other Movements to Stockpiles data based on supplied criteria.
	
	Pass: 
			@iSummaryMonth: the month for which summary data is to be deleted,
			@iSummaryLocationId: the location (typically a Pit) within which child locations will have data removed,
			@iSpecificMaterialTypeId:
							when specified - only Data for the exact matching MaterialTypeId or for MaterialTypes related to the exact match is included
							when null - this criteria has no impact on filtering
 </Procedure>
</TAG>
*/	
IF OBJECT_ID('dbo.SummariseBhpbioPortBlendedAdjustment') IS NOT NULL
     DROP PROCEDURE dbo.SummariseBhpbioPortBlendedAdjustment 
GO 
    
CREATE PROCEDURE dbo.SummariseBhpbioPortBlendedAdjustment
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
	
	DECLARE @Blending TABLE
	(
		BhpbioPortBlendingId INT,
		LocationId INT,
		Tonnes FLOAT,
		Removal BIT
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'SummariseBhpbioPortBlendedAdjustment',
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
		WHERE bset.Name = 'PortBlending'
		
		-- the first step is to remove previously summarised data for the same filtering criteria that the current summary is running on
		exec dbo.DeleteBhpbioSummaryEntry @iSummaryMonth = @iSummaryMonth,
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
		
		-- -----------------------------------------------------------------------------------------------------------------------------------
		-- The queries used in this procedure are based on / taken from the original reporting implementation (on non-summarised data)
		-- -----------------------------------------------------------------------------------------------------------------------------------

		INSERT INTO @Blending
			(
				BhpbioPortBlendingId, 
				LocationId, 
				Tonnes, 
				Removal
			)
		SELECT BPB.BhpbioPortBlendingId,
			L.LocationId, BPB.Tonnes, CASE WHEN BPB.DestinationHubLocationId = L.LocationId THEN 0 ELSE 1 END
		FROM dbo.BhpbioPortBlending AS BPB
			INNER JOIN @Location AS L
				ON (BPB.DestinationHubLocationId = L.LocationId OR BPB.LoadSiteLocationId = L.LocationId)
		WHERE BPB.StartDate >= @startOfMonth
				AND BPB.EndDate < @startOfNextMonth

		---- Insert the tonnes
		INSERT INTO dbo.BhpbioSummaryEntry
		(
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			Tonnes
		)
		SELECT @summaryId,
			   @summaryEntryTypeId,
			   b.LocationId,
			   NULL,
			   SUM(CASE WHEN b.Removal = 0 THEN b.Tonnes ELSE -b.Tonnes END)
		FROM @Blending AS b
		GROUP BY b.LocationId
		
		-- Insert the Grade values
		INSERT INTO dbo.BhpbioSummaryEntryGrade
		(
			SummaryEntryId,
			GradeId,
			GradeValue
		)
		SELECT 
			bse.SummaryEntryId,
			BPBG.GradeId,
			SUM(B.Tonnes * BPBG.GradeValue) / SUM(B.Tonnes) AS GradeValue
		FROM @Blending AS B
			INNER JOIN dbo.BhpbioPortBlendingGrade AS BPBG
				ON BPBG.BhpbioPortBlendingId = B.BhpbioPortBlendingId
			INNER JOIN dbo.BhpbioSummaryEntry bse
				ON bse.SummaryEntryTypeId = @summaryEntryTypeId
				AND bse.LocationId = B.LocationId
				AND bse.SummaryId = @summaryId
		--WHERE B.Tonnes > 0
		GROUP BY bse.SummaryEntryId, BPBG.GradeId
		
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

GRANT EXECUTE ON dbo.SummariseBhpbioPortBlendedAdjustment TO BhpbioGenericManager
GO

/*
exec dbo.SummariseBhpbioPortBlendedAdjustment
	@iSummaryMonth = '2009-11-01',
	@iLocationId = 3
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.SummariseBhpbioPortBlendedAdjustment">
 <Procedure>
	Generates a set of summary Port Blending Adjustment data based on supplied criteria.
	
	Pass: 
			@iSummaryMonth: the month for which summary data is to be generated,
			@iSummaryLocationId: the location (a Hub) for which data will be summarised

 </Procedure>
</TAG>
*/
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
	
	DECLARE @PortDelta TABLE
	(
		ParentLocationId INT NULL,
		LastBalanceDate DATETIME NULL,
		Tonnes FLOAT NULL,
		LastTonnes FLOAT NULL
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
			Tonnes
		)
		SELECT @summaryId,
			   @summaryEntryTypeId,
			   L.LocationId,
			   NULL,
			   COALESCE(Sum(BPB.Tonnes) - Sum(BPBPREV.Tonnes),0)
		FROM dbo.BhpbioPortBalance AS BPB
			INNER JOIN @Location AS L
				ON (BPB.HubLocationId = L.LocationId)
			LEFT JOIN dbo.BhpbioPortBalance AS BPBPREV
				ON (BPBPREV.BalanceDate = DateAdd(Day, -1, @startOfMonth)
					And BPB.HubLocationId = BPBPREV.HubLocationId)
		WHERE BPB.BalanceDate = DateAdd(Day, -1, @startOfNextMonth)
		GROUP BY L.LocationId
		
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
	@iSummaryMonth = '2009-11-01',
	@iLocationId = 3
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
IF OBJECT_ID('dbo.SummariseBhpbioPostCrusherStockpileDelta') IS NOT NULL
     DROP PROCEDURE dbo.SummariseBhpbioPostCrusherStockpileDelta 
GO 
    
CREATE PROCEDURE dbo.SummariseBhpbioPostCrusherStockpileDelta
(
	@iSummaryMonth DATETIME,
	@iSummaryLocationId INTEGER,
	@iPostCrusherLevel VARCHAR(24)
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
	
	DECLARE @StockpileDelta TABLE
	(
		StockpileId INT NOT NULL,
		WeightometerSampleId INT NOT NULL,
		Tonnes FLOAT NOT NULL,
		LocationId INT NULL,
		Addition BIT NOT NULL,
		PRIMARY KEY (WeightometerSampleId, Addition)
	)
	
	DECLARE @SampleSourceField VARCHAR(31)
	SET @SampleSourceField = 'SampleSource'
	
	DECLARE @SampleTonnesField VARCHAR(31)
	SET @SampleTonnesField = 'SampleTonnes'
	
	DECLARE @StockpileGroupId VARCHAR(31)
	SET @StockpileGroupId = 'Post Crusher'
	DECLARE @LastShift CHAR(1)

	DECLARE @HubLocationTypeId INT
	DECLARE @SiteLocationTypeId INT
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'SummariseBhpbioPostCrusherStockpileDelta',
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
		DECLARE @summaryGradesEntryTypeId INTEGER
		
		DECLARE @isSiteCrusher BIT
		DECLARE @isHubCrusher BIT
		
		SELECT @isSiteCrusher = CASE WHEN @iPostCrusherLevel = 'Site' THEN 1 ELSE 0 END
		SELECT @isHubCrusher = CASE WHEN @iPostCrusherLevel = 'Hub' THEN 1 ELSE 0 END
		
		-- obtain the Actual Type Id for ActualY storage
		SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
		FROM dbo.BhpbioSummaryEntryType bset
		WHERE bset.Name = @iPostCrusherLevel + 'PostCrusherStockpileDelta'
		
		SELECT @summaryGradesEntryTypeId = bset.SummaryEntryTypeId
		FROM dbo.BhpbioSummaryEntryType bset
		WHERE bset.Name = @iPostCrusherLevel + 'PostCrusherSpDeltaGrades'
		
		-- the first step is to remove previously summarised data for the same filtering criteria that the current summary is running on
		exec dbo.DeleteBhpbioSummaryEntry @iSummaryMonth = @iSummaryMonth,
											@iSummaryLocationId = @iSummaryLocationId,
											@iSummaryEntryTypeId = @summaryEntryTypeId
											
		-- the first step is to remove previously summarised data for the same filtering criteria that the current summary is running on
		exec dbo.DeleteBhpbioSummaryEntry @iSummaryMonth = @iSummaryMonth,
											@iSummaryLocationId = @iSummaryLocationId,
											@iSummaryEntryTypeId = @summaryGradesEntryTypeId
		
		-- get the start of the summary month and the start of the following month
		-- this gives us a window of time to operate within
		SELECT @startOfMonth = dbo.GetDateMonth(@iSummaryMonth)
		SELECT @startOfNextMonth = DATEADD(month,1,@iSummaryMonth)

		-- get a Summary Id for the month (or create a new one if needed)
		EXEC dbo.GetBhpbioSummaryIdForMonth @iSummaryMonth = @startOfMonth,
											@oSummaryId = @summaryId OUTPUT
		
		SELECT @HubLocationTypeId = Location_Type_Id
		FROM dbo.LocationType
		WHERE Description = 'Hub'
		
		SELECT @SiteLocationTypeId = Location_Type_Id
		FROM dbo.LocationType
		WHERE Description = 'Site'
		
		INSERT INTO @Location (LocationId, ParentLocationId)
		SELECT LocationId, ParentLocationId
		FROM dbo.GetBhpbioReportLocationBreakdown(@iSummaryLocationId, 1, 'SITE')
		UNION
		SELECT l.Location_Id, l.Parent_Location_Id
		FROM Location l
		WHERE l.Location_Id = @iSummaryLocationId
		
		-- -----------------------------------------------------------------------------------------------------------------------------------
		-- The queries used in this procedure are based on / taken from the original reporting implementation (on non-summarised data)
		-- -----------------------------------------------------------------------------------------------------------------------------------
		
		-- Get Removals
		INSERT INTO @StockpileDelta
			(StockpileId, WeightometerSampleId, Addition, Tonnes, LocationId)		
		SELECT S.Stockpile_Id, WS.Weightometer_Sample_Id, 0, WS.Tonnes, 
			CASE WHEN @isSiteCrusher = 1 THEN L.ParentLocationId ELSE L.LocationId END
		FROM dbo.WeightometerSample AS WS
			INNER JOIN dbo.Stockpile AS S
				ON (S.Stockpile_Id = WS.Source_Stockpile_Id)
			INNER JOIN dbo.StockpileGroupStockpile AS SGS
				ON (SGS.Stockpile_Id = S.Stockpile_Id)
			INNER JOIN dbo.StockpileLocation AS SL
				ON (SL.Stockpile_Id = S.Stockpile_Id)
			INNER JOIN @Location AS L
				ON (L.LocationId = SL.Location_Id)				
			INNER JOIN dbo.Location AS LL
				ON (LL.Location_Id = L.LocationId)
			LEFT JOIN dbo.BhpbioLocationStockpileConfiguration AS BSLC
				ON (BSLC.LocationId = SL.Location_Id)
			LEFT JOIN dbo.StockpileGroupStockpile SGS_D
				ON (SGS_D.Stockpile_Id = WS.Destination_Stockpile_Id
					AND SGS_D.Stockpile_Group_Id = @StockpileGroupId)
		WHERE Coalesce(WS.Source_Stockpile_Id, -1) <> Coalesce(WS.Destination_Stockpile_Id, -1)
			AND SGS.Stockpile_Group_Id = @StockpileGroupId
			AND SGS_D.Stockpile_Group_Id IS NULL -- Ensure join to check if destination is Post Crusher isn't true.
			AND WS.Weightometer_Id NOT LIKE '%Raw%'
			AND	WS.Weightometer_Sample_Date >= @startOfMonth
			AND WS.Weightometer_Sample_Date < @startOfNextMonth
			AND 
			(
				(
					@isSiteCrusher = 1
					AND (LL.Location_Type_Id = @SiteLocationTypeId AND (BSLC.PromoteStockpiles = 0 OR BSLC.PromoteStockpiles IS NULL))
				)
				OR 
				(
					@isHubCrusher = 1
					AND (
							LL.Location_Type_Id = @HubLocationTypeId 
						OR (BSLC.PromoteStockpiles = 1 AND LL.Location_Type_Id = @SiteLocationTypeId)
						)
				)
			)
			
		-- Get Additions
		INSERT INTO @StockpileDelta
			(StockpileId, WeightometerSampleId, Addition, Tonnes, LocationId)		
		SELECT S.Stockpile_Id, WS.Weightometer_Sample_ID, 1, WS.Tonnes, 
			CASE WHEN @isSiteCrusher = 1 THEN L.ParentLocationId ELSE L.LocationId END
		FROM dbo.WeightometerSample AS WS
			INNER JOIN dbo.Stockpile AS S
				ON (S.Stockpile_Id = WS.Destination_Stockpile_Id)
			INNER JOIN dbo.StockpileGroupStockpile AS SGS
				ON (SGS.Stockpile_Id = S.Stockpile_Id)
			INNER JOIN dbo.StockpileLocation AS SL
				ON (SL.Stockpile_Id = S.Stockpile_Id)
			INNER JOIN @Location AS L
				ON (L.LocationId = SL.Location_Id)
			LEFT JOIN dbo.BhpbioLocationStockpileConfiguration AS BSLC
				ON (BSLC.LocationId = SL.Location_Id)
			INNER JOIN dbo.Location AS LL
				ON (LL.Location_Id = L.LocationId)
			LEFT JOIN dbo.StockpileGroupStockpile SGS_S
				ON (SGS_S.Stockpile_Id = WS.Source_Stockpile_Id
					AND SGS_S.Stockpile_Group_Id = @StockpileGroupId)
		WHERE Coalesce(WS.Source_Stockpile_Id, -1) <> Coalesce(WS.Destination_Stockpile_Id, -1)
			AND SGS.Stockpile_Group_Id = @StockpileGroupId
			AND SGS_S.Stockpile_Group_Id IS NULL  -- Ensure join to check if source is Post Crusher isn't true.
			AND WS.Weightometer_Id NOT LIKE '%Raw%'
			AND	WS.Weightometer_Sample_Date >= @startOfMonth
			AND WS.Weightometer_Sample_Date < @startOfNextMonth
			AND 
			(
				(
					@isSiteCrusher = 1
					AND (LL.Location_Type_Id = @SiteLocationTypeId AND (BSLC.PromoteStockpiles = 0 OR BSLC.PromoteStockpiles IS NULL))
				)
				OR 
				(
					@isHubCrusher = 1
					AND (
							LL.Location_Type_Id = @HubLocationTypeId 
						OR (BSLC.PromoteStockpiles = 1 AND LL.Location_Type_Id = @SiteLocationTypeId)
						)
				)
			)
			
		---- Insert the actual tonnes
		INSERT INTO dbo.BhpbioSummaryEntry
		(
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			Tonnes
		)
		SELECT  @summaryId,
				@summaryEntryTypeId,
				d.LocationId,
				null,
				Sum(CASE WHEN d.Addition = 1 THEN d.Tonnes ELSE -d.Tonnes END) AS Tonnes
		FROM @StockpileDelta d
		GROUP BY d.LocationId;
		
		IF @isSiteCrusher = 1
		BEGIN
			-- insert the grade tonnes (the tonnes used for grade blending are NOT the same as the tonnes reported for stockpile delta)
			INSERT INTO dbo.BhpbioSummaryEntry
			(
				SummaryId,
				SummaryEntryTypeId,
				LocationId,
				MaterialTypeId,
				Tonnes
			)
			SELECT 
				@summaryId,
				@summaryGradesEntryTypeId,
				SD.LocationId,
				null,
				Sum(WS.Tonnes)
			FROM @StockpileDelta AS SD
				INNER JOIN dbo.WeightometerSample AS WS
					ON (WS.Weightometer_Sample_Id = SD.WeightometerSampleId)
			WHERE EXISTS	(	SELECT * 
								FROM dbo.WeightometerSampleGrade AS WSG
								WHERE WSG.Weightometer_Sample_Id = WS.Weightometer_Sample_Id
							)	
			GROUP BY SD.LocationId
			
			-- insert grade values
			INSERT INTO dbo.BhpbioSummaryEntryGrade
			(
				SummaryEntryId,
				GradeId,
				GradeValue
			)
			SELECT 
				bse.SummaryEntryId,
				WSG.Grade_Id,
				Sum(WS.Tonnes * WSG.Grade_Value)/ NULLIF(Sum(WS.Tonnes), 0) AS GradeValue
			FROM dbo.BhpbioSummaryEntry bse
				INNER JOIN dbo.Location l 
					ON l.Location_Id = bse.LocationId
				INNER JOIN @StockpileDelta AS SD
					ON (SD.LocationId = l.Location_Id)
				INNER JOIN dbo.WeightometerSample AS WS
					ON (WS.Weightometer_Sample_Id = SD.WeightometerSampleId)
				INNER JOIN dbo.WeightometerSampleGrade AS WSG
					ON (WSG.Weightometer_Sample_Id = WS.Weightometer_Sample_Id)
			WHERE	bse.SummaryId = @summaryId
					AND bse.SummaryEntryTypeId = @summaryGradesEntryTypeId
			GROUP BY bse.SummaryEntryId, WSG.Grade_Id
		END
		
		IF @isHubCrusher = 1
		BEGIN
		
			DECLARE @gradesAndTonnes TABLE
			(
				LocationId INT NOT NULL,
				GradeId INT NOT NULL,
				GradeValue FLOAT NULL,
				GradeTonnes FLOAT NULL
			);
			
			WITH GradesByLocationAndPeriod AS
			(
				SELECT WSG.Grade_Id, L.ParentLocationId, L.LocationId,
					SUM(WSV.Field_Value * WSG.Grade_Value) / NULLIF(SUM(WSV.Field_Value), 0) As GradeValue,
					NULLIF(SUM(WSV.Field_Value),0) AS SampleTonnes
				FROM dbo.WeightometerSample AS WS WITH (NOLOCK)
					INNER JOIN WeightometerSampleGrade AS WSG WITH (NOLOCK)
						ON (ws.Weightometer_Sample_Id = WSG.Weightometer_Sample_Id)
					INNER JOIN dbo.WeightometerLocation AS WL WITH (NOLOCK)
						ON (ws.Weightometer_Id = wl.Weightometer_Id)
					INNER JOIN @Location AS L
						ON (L.LocationId = wl.Location_Id)
					INNER JOIN dbo.WeightometerSampleNotes AS WSN WITH (NOLOCK)
						ON (wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
							AND wsn.Weightometer_Sample_Field_Id = @SampleSourceField)
					INNER JOIN dbo.WeightometerSampleValue AS WSV WITH (NOLOCK)
						ON (wsv.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
							AND wsv.Weightometer_Sample_Field_Id = @SampleTonnesField)
					INNER JOIN dbo.GetBhpbioWeightometerSampleSource(@iSummaryLocationId, @startOfMonth, @startOfNextMonth) AS ss
						ON (dbo.GetDateMonth(ws.Weightometer_Sample_Date) = ss.MonthPeriod
						AND L.LocationId = ss.LocationId
							AND wsn.Notes = ss.SampleSource)
					INNER JOIN dbo.Location AS LL WITH (NOLOCK)
						ON (LL.Location_Id = L.LocationId)
					LEFT JOIN dbo.BhpbioLocationStockpileConfiguration AS BSLC WITH (NOLOCK)
						ON (BSLC.LocationId = L.LocationId)
				WHERE (LL.Location_Type_Id = @HubLocationTypeId OR 
						(BSLC.PromoteStockpiles = 1 AND LL.Location_Type_Id = @SiteLocationTypeId))
					AND WS.Weightometer_Sample_Date >= @startOfMonth
					AND WS.Weightometer_Sample_Date  < @startOfNextMonth
				GROUP BY WSG.Grade_Id, L.ParentLocationId, L.LocationId
			)
			-- now weight the lower level locations to get values at the parent level
			-- this second round of weighting should be done on tonnes rather than sample tonnes
			-- (ie locations weighted against each other based on tonnes)
			INSERT INTO @gradesAndTonnes
			(
				LocationId,
				GradeId,
				GradeValue,
				GradeTonnes
			)
			SELECT 
				gblp.LocationId,
				gblp.Grade_Id,
				SUM(ABS(sd.Tonnes) * gblp.GradeValue) /	SUM(ABS(sd.Tonnes)) AS GradeValue,
				SUM(gblp.SampleTonnes)
			FROM GradesByLocationAndPeriod AS gblp
				INNER JOIN (SELECT LocationId,
								SUM(CASE WHEN Addition = 1 THEN Tonnes ELSE -Tonnes END) AS Tonnes
							FROM @StockpileDelta
							GROUP BY LocationId) AS sd
					ON sd.LocationId = gblp.LocationId
			WHERE ABS(sd.Tonnes) > 0
			GROUP BY gblp.LocationId, gblp.Grade_Id
			
			INSERT INTO dbo.BhpbioSummaryEntry
			(
				SummaryId,
				SummaryEntryTypeId,
				LocationId,
				MaterialTypeId,
				Tonnes
			)
			SELECT	DISTINCT -- there is one entry per grade Id, each with the same tonnes value.. in this case we just need the tonnes value
					@summaryId,
					@summaryGradesEntryTypeId,
					gt.LocationId,
					null,
					gt.GradeTonnes
			FROM @gradesAndTonnes gt
			
			INSERT INTO dbo.BhpbioSummaryEntryGrade
			(
				SummaryEntryId,
				GradeId,
				GradeValue
			)
			SELECT bse.SummaryEntryId,
				   gt.GradeId,
				   gt.GradeValue
			FROM @gradesAndTonnes gt
				INNER JOIN dbo.BhpbioSummaryEntry bse
					ON bse.SummaryId = @summaryId
					AND bse.SummaryEntryTypeId = @summaryGradesEntryTypeId
					AND bse.LocationId = gt.LocationId
		END
		
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

GRANT EXECUTE ON dbo.SummariseBhpbioPostCrusherStockpileDelta TO BhpbioGenericManager
GO

/*
exec dbo.SummariseBhpbioPostCrusherStockpileDelta
	@iSummaryMonth = '2009-11-01',
	@iLocationId = 3,
	'Hub'
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.SummariseBhpbioSitePostCrusherStockpileDelta">
 <Procedure>
	Generates a set of summary PostCrusherStockpile Delta data based on supplied criteria.
	This may be for a site or a hub
	
	Delta refers to the difference between additions and reclaims
			
	Pass: 
			@iSummaryMonth: the month for which summary data is to be generated,
			@iSummaryLocationId: the location (a Site or Hub) for which data will be summarised
			@iPostCrusherLevel: 'Site' or 'Hub'
 </Procedure>
</TAG>
*/

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
		WHERE S.OfficialFinishTime >= @startOfMonth
			AND S.OfficialFinishTime < @startOfNextMonth
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
		WHERE 
			S.OfficialFinishTime >= @startOfMonth
			AND S.OfficialFinishTime < @startOfNextMonth
			AND S.Tonnes > 0
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
	@iLocationId = 3
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
IF OBJECT_ID('dbo.UnapproveBhpbioApprovalData') IS NOT NULL
     DROP PROCEDURE dbo.UnapproveBhpbioApprovalData
GO 
  
CREATE PROCEDURE dbo.UnapproveBhpbioApprovalData
(
	@iTagId VARCHAR(31),
	@iLocationId INT,
	@iApprovalMonth DATETIME
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'UnapproveBhpbioApprovalData',
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
		IF NOT EXISTS (SELECT 1 FROM dbo.BhpbioReportDataTags WHERE TagId = @iTagId)
		BEGIN
			RAISERROR('The tag does not exist', 16, 1)
		END
	
		IF NOT EXISTS (SELECT 1 FROM dbo.Location WHERE Location_Id = @iLocationId)
		BEGIN
			RAISERROR('The location does not exist', 16, 1)
		END
		
		IF @iApprovalMonth <> dbo.GetDateMonth(@iApprovalMonth)
		BEGIN
			RAISERROR('The date supplied is not the start of a month', 16, 1)
		END

		-- Determine the latest month that was purged
		-- and ensure that the user is not attempting an unapproval in a month that has already been purged
		DECLARE @latestPurgedMonth DATETIME
		exec dbo.GetBhpbioLatestPurgedMonth @oLatestPurgedMonth = @latestPurgedMonth OUTPUT
		
		IF @latestPurgedMonth IS NOT NULL AND @latestPurgedMonth >= @iApprovalMonth
		BEGIN
			RAISERROR('It is not possible to unapprove data in this period as the period has been purged', 16, 1)
		END

		IF NOT EXISTS	(
							SELECT 1 
							FROM dbo.BhpbioApprovalData 
							WHERE TagId = @iTagId 
								AND ApprovedMonth = @iApprovalMonth 
									AND LocationID = @iLocationId
						)
		BEGIN
			RAISERROR('The calculation and month provided has not been approved. Please ensure this calculation has not been approved at a higher level.', 16, 1)
		END
		
		DELETE
		FROM dbo.BhpbioApprovalData
		WHERE TagId = @iTagId 
			AND ApprovedMonth = @iApprovalMonth
			AND LocationId = @iLocationId


		-- Clear out any summary data that is no longer valid due to the unapproval
		exec dbo.DeleteBhpbioSummaryDataRelatedToApproval	@iTagId = @iTagId,
															@iLocationId = @iLocationId,
															@iApprovalMonth = @iApprovalMonth
															

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

GRANT EXECUTE ON dbo.UnapproveBhpbioApprovalData TO BhpbioGenericManager
GO

IF OBJECT_ID('dbo.UpdateBhpbioPurgeRequests') IS NOT NULL
     DROP PROCEDURE dbo.UpdateBhpbioPurgeRequests
GO 

CREATE PROC dbo.UpdateBhpbioPurgeRequests
(
	@iIds VARCHAR(1000),
	@iPurgeRequestStatusId INT,
	@iApprovingUserId INT = NULL
)
WITH ENCRYPTION
AS
BEGIN
	UPDATE R
	SET PurgeRequestStatusId = @iPurgeRequestStatusId,
		ApprovingUserId = ISNULL(@iApprovingUserId, R.ApprovingUserId),
		LastStatusChangeDateTime = GETDATE()
	FROM dbo.BhpbioPurgeRequest AS R
		INNER JOIN dbo.GetBhpbioIntCollection(@iIds) AS I
			ON (R.PurgeRequestId = I.Value)
	WHERE
		R.PurgeRequestStatusId != @iPurgeRequestStatusId 
END
GO

GRANT EXECUTE ON dbo.UpdateBhpbioPurgeRequests TO BhpbioGenericManager
GO








