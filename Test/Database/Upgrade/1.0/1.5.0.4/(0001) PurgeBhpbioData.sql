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
	@FirstDayAfterPurge DATETIME,
	@purgeMonth DATETIME
	
	SELECT  @Compare = CONVERT(VARCHAR(6),PurgeMonth,112),
			@purgeMonth = PurgeMonth
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
	
	-- We need to ensure there is a MonthlyApproval record for all months between the system start and the purge month
	-- This is to prevent unwanted recalcs in purged periods
	-- First find the system start date
	DECLARE @systemStartDate DATETIME
	
	SELECT @systemStartDate = convert(datetime, Value)
	FROM dbo.Setting
	WHERE Setting_Id = 'SYSTEM_START_DATE'
	
	-- then process each month up to the purge month
	DECLARE @processMonth DATETIME
	SET @processMonth = @systemStartDate
	
	WHILE @processMonth <= @purgeMonth
	BEGIN
		-- check if there is already an approval record for each month prior to the purge month
		IF NOT EXISTS (SELECT * FROM dbo.MonthlyApproval WHERE Monthly_Approval_Month = @processMonth)
		BEGIN
			-- if not existing, then insert one
			INSERT INTO dbo.MonthlyApproval(Monthly_Approval_Month, Is_Approved)
			SELECT @processMonth, 1
		END
		ELSE
		BEGIN
			-- otherwise there is already a record, just ensure that the Is_Approved flag is set if not already
			UPDATE dbo.MonthlyApproval
			SET Is_Approved = 1
			WHERE Monthly_Approval_Month = @processMonth
				AND NOT Is_Approved = 1
		END
		SET @processMonth = DATEADD(month, 1, @processMonth)
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
	
	DELETE he
	FROM dbo.HaulageRawError AS he
		INNER JOIN dbo.HaulageRaw AS h WITH (NOLOCK)
			ON he.Haulage_Raw_Id = h.Haulage_Raw_Id
	WHERE CONVERT(VARCHAR(6),h.Haulage_Date,112) <= @Compare
	
	DELETE dbo.HaulageRaw
	WHERE CONVERT(VARCHAR(6),Haulage_Date,112) <= @Compare
	
	DELETE del
	FROM dbo.BhpbioDataExceptionLocation AS del
		INNER JOIN dbo.DataException AS d WITH (NOLOCK)
			ON del.DataExceptionId = d.Data_Exception_Id
	WHERE 
		d.Data_Exception_Date IS NOT NULL
		AND	CONVERT(VARCHAR(6),d.Data_Exception_Date,112) <= @Compare
	
	DELETE dbo.DataException
	WHERE 
		Data_Exception_Date IS NOT NULL
		AND	CONVERT(VARCHAR(6),Data_Exception_Date,112) <= @Compare
	
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
		AND isq.InitialComparedDateTime < @FirstDayAfterPurge
	
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
