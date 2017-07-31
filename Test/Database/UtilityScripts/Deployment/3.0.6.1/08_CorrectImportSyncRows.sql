DECLARE @issueIntroductionDateTime DATETIME
DECLARE @processCorrectionDate DATETIME

SET @issueIntroductionDateTime = '2015-08-20 20:00:00'

SELECT @processCorrectionDate = CONVERT(datetime, value) 
FROM Setting s
WHERE Setting_Id = 'BHPBIO_LUMPFINES_IMPORT_CORRECTION_DATE'

DELETE FROM Staging.TmpStageImportSyncRowCorrection
-----------------------------------------------------------
-- ImportSyncRow
-- Identify the current sync row for all impacted blocks
INSERT INTO Staging.TmpStageImportSyncRowCorrection(ImportSyncRowId, [Site], Pit, Bench, PatternNumber, ModelName, BlockName, ModelLumpPercent, GradeText, LastProcessedDateTime, InitialComparedDateTime)
SELECT isq.ImportSyncRowId,
	SourceRow.value('/BlockModelSource[1]/*[1]/Site[1]','varchar(255)') as [Site],
	SourceRow.value('/BlockModelSource[1]/*[1]/Pit[1]','varchar(255)') as Pit,
	SourceRow.value('/BlockModelSource[1]/*[1]/Bench[1]','varchar(255)')  as Bench,
	SourceRow.value('/BlockModelSource[1]/*[1]/PatternNumber[1]','varchar(255)') as PatternNumber,
	SourceRow.value('/BlockModelSource[1]/*[1]/ModelName[1]','varchar(255)')  as ModelName,
	SourceRow.value('/BlockModelSource[1]/*[1]/BlockName[1]','varchar(255)')  as BlockName,
	SourceRow.value('/BlockModelSource[1]/*[1]/ModelLumpPercent[1]','float')  as ModelLumpPercent,
	SourceRow.value('(/BlockModelSource/BlastModelBlockWithPointAndGrade/Grade)[1]', 'nvarchar(MAX)') as GradeText,
	isq.LastProcessedDateTime,
	isq.InitialComparedDateTime
FROM ImportSyncQueue isq 
INNER JOIN ImportSyncRow isr ON isr.ImportSyncRowId = isq.ImportSyncRowId
WHERE isq.ImportId = 1
	AND isq.LastProcessedDateTime>= @issueIntroductionDateTime
	AND isq.LastProcessedDateTime <= @processCorrectionDate
	AND isr.IsCurrent = 1
	AND NOT SourceRow.value('/BlockModelSource[1]/*[1]/ModelName[1]','varchar(255)') like '%Grade%'
	
DECLARE curRowsToCorrect CURSOR FOR
	SELECT DISTINCT t.ImportSyncRowId, t.ModelLumpPercent, t.GradeText
	FROM Staging.TmpStageImportSyncRowCorrection t
		INNER JOIN Staging.StageBlock b ON b.Site = t.Site AND b.Bench = t.Bench and b.PatternNumber = t.PatternNumber AND b.BlockName = t.BlockName and b.Pit = t.Pit
		INNER JOIN Staging.TmpStageLumpFinesBlockCorrectionBlocks cb ON cb.BlockFullName = b.BlockFullName
	WHERE t.LastProcessedDateTime >= cb.MinLastUpdateDateTime
		AND NOT EXISTS (SELECT * FROM Staging.TmpStageImportSyncRowCorrectionLog cl WHERE cl.ImportSyncRowId = t.ImportSyncRowId)

OPEN curRowsToCorrect

DECLARE @importSyncRowId BIGINT
DECLARE @modelLumpPercent FLOAT
DECLARE @gradeText VARCHAR(MAX)

DECLARE @modified BIT

FETCH NEXT FROM curRowsToCorrect INTO  @importSyncRowId, @modelLumpPercent, @gradeText 

WHILE @@FETCH_STATUS = 0
BEGIN 
	SET @modified = 0
	
	DECLARE @processedText VARCHAR(Max)
	SET @processedText = @gradeText
	
	SET @processedText = REPLACE(@processedText,'&gt;','>')
	SET @processedText = REPLACE(@processedText, '&lt;','<')

	DECLARE @xml XML
	SET @xml = convert(XML, @processedText)

	DECLARE @gradeName VARCHAR(31)
	
	DECLARE curGrades CURSOR FOR 
			SELECT g.Grade_Name
			FROM Grade g
			WHERE Not Grade_Name = 'Density'
	
	OPEN curGrades
	FETCH NEXT FROM curGrades INTO  @gradeName

	WHILE @@FETCH_STATUS = 0
	BEGIN 
		DECLARE @headValue FLOAT
		DECLARE @lumpValue FLOAT
		DECLARE @finesValue FLOAT
		
		DECLARE @correctedHeadValue FLOAT
		DECLARE @correctedLumpValue FLOAT
		DECLARE @correctedFinesValue FLOAT
		
		SELECT @headValue = @xml.value('(/Grade/row[GradeName=sql:variable("@gradeName")]/GradeValue)[1]', 'float')
		SELECT @lumpValue = @xml.value('(/Grade/row[GradeName=sql:variable("@gradeName")]/GradeLumpValue)[1]', 'float')
		SELECT @finesValue = @xml.value('(/Grade/row[GradeName=sql:variable("@gradeName")]/GradeFinesValue)[1]', 'float')
		
		
		IF NOT (@headValue IS NULL OR @lumpValue IS NULL OR @finesValue IS NULL)
		BEGIN
			-- only proceed if all required values are present ... remembering that this is only to prevent uneccessary import runs... if some rows are skipped there won't be any impact
			-- other than the potential for some import jobs to be queued that strictly wouldn't need to be ru
			
			SET @correctedLumpValue = @finesValue -- switch lump and fines
			SET @correctedFinesValue = @lumpValue -- switch lump and fines
			SET @correctedHeadValue = @headValue
			
			IF @gradeName = 'H2O' OR @gradeName = 'H2O-As-Dropped' OR @gradeName = 'H2O-As-Shipped'
			BEGIN
				-- recalculate head value if appropriate
				IF NOT @modelLumpPercent IS NULL
					AND NOT @correctedLumpValue IS NULL
					AND NOT @correctedFinesValue IS NULL
				BEGIN
					SET @correctedHeadValue = (@correctedLumpValue * (@modelLumpPercent/100.0))+(@correctedFinesValue*((100-@modelLumpPercent)/100.0))
				END
			END
			
			DECLARE @headValueText VARCHAR(max)
			DECLARE @lumpValueText VARCHAR(max)
			DECLARE @finesValueText VARCHAR(max)
			
			IF NOT @correctedHeadValue IS NULL AND NOT @correctedHeadValue = @headValue
			BEGIN		
				SET @headValueText = CONVERT(varchar(max), @correctedHeadValue, 2)
				SET @xml.modify('replace value of (/Grade/row[GradeName=sql:variable("@gradeName")]/GradeValue/text())[1] with sql:variable("@headValueText")')
				SET @modified = 1
			END
			
			IF NOT @correctedLumpValue IS NULL AND NOT @correctedLumpValue = @lumpValue
			BEGIN		
				SET @lumpValueText = CONVERT(varchar(max), @correctedLumpValue, 2)
				-- need to update element
				SET @xml.modify('replace value of (/Grade/row[GradeName=sql:variable("@gradeName")]/GradeLumpValue/text())[1] with sql:variable("@lumpValueText")')
				SET @modified = 1
			END
			
			IF NOT @correctedFinesValue IS NULL AND NOT @correctedFinesValue = @finesValue
			BEGIN
				SET @finesValueText = CONVERT(varchar(max), @correctedFinesValue, 2)
				SET @xml.modify('replace value of (/Grade/row[GradeName=sql:variable("@gradeName")]/GradeFinesValue/text())[1] with sql:variable("@finesValueText")')
				SET @modified = 1
			END
			
		END
		
		FETCH NEXT FROM curGrades INTO  @gradeName
	END
	
	CLOSE curGrades
	DEALLOCATE curGrades

	SET @processedText = CONVERT(varchar(max),@xml)
	
	/*
	IF @modified = 1
	BEGIN	
		
		--- DEBUG OUTPUT FOR TESTING
		PRINT('-----------------------')
		PRINT('ImportSyncRowId: ' + convert(varchar, @importSyncRowId))
		PRINT('BEFORE: ' + @gradeText)
		PRINT('-----------------------')
		
		PRINT('-----------------------')
		PRINT('AFTER: ' + @processedText)
		PRINT('-----------------------')
	END
	*/
	
	BEGIN TRANSACTION
		
		-- update the row and log the change in the one transaction .. this avoids double processing
		UPDATE isr
			SET SourceRow.modify('replace value of (/BlockModelSource/BlastModelBlockWithPointAndGrade/Grade/text())[1] with sql:variable("@processedText")')
		FROM ImportSyncRow isr 
		WHERE isr.ImportSyncRowId = @importSyncRowId
	
		INSERT INTO Staging.TmpStageImportSyncRowCorrectionLog(ImportSyncRowId, ProcessedDateTime)
		VALUES (@importSyncRowId, GetDate())
			
	--ROLLBACK TRANSACTION -- for testing
	COMMIT TRANSACTION
	
	FETCH NEXT FROM curRowsToCorrect INTO  @importSyncRowId, @modelLumpPercent, @gradeText 
END

CLOSE curRowsToCorrect
DEALLOCATE curRowsToCorrect

--SELECT * FROM Staging.TmpStageImportSyncRowCorrectionLog