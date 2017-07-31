-- PROCESS EACH IMPORT SYNC ROW IN TURN
DECLARE curRowsToCorrect CURSOR FOR
	SELECT DISTINCT t.ImportSyncRowId, t.ResourceClassification, b.BlockId, bm.BlockModelId
	FROM Staging.TmpStageImportSyncRowRCCorrection t
		INNER JOIN Staging.StageBlock b ON b.Site = t.Site AND b.Bench = t.Bench and b.PatternNumber = t.PatternNumber AND b.BlockName = t.BlockName and b.Pit = t.Pit
		INNER JOIN Staging.StageBlockModel bm ON bm.BlockId = b.BlockId AND bm.BlockModelName = t.ModelName AND bm.MaterialTypeName = t.ModelOreType
	WHERE NOT EXISTS (SELECT * FROM Staging.TmpStageImportSyncRowRCCorrectionLog lg WHERE lg.ImportSyncRowId = t.ImportSyncRowId)

OPEN curRowsToCorrect

DECLARE @importSyncRowId BIGINT
DECLARE @resourceClassificationText VARCHAR(MAX)
DECLARE @blockId INTEGER
DECLARE @blockModelId INTEGER
DECLARE @processedText VARCHAR(MAX)

DECLARE @modified BIT

FETCH NEXT FROM curRowsToCorrect INTO  @importSyncRowId, @resourceClassificationText, @blockId,  @blockModelId

WHILE @@FETCH_STATUS = 0
BEGIN 
	SET @modified = 0

	DECLARE @newResourceClassificationXML XML
	
	SELECT @newResourceClassificationXML = (
				Select
					rc.ResourceClassification,
					rc.Percentage
				From Staging.StageBlockModelResourceClassification rc
					Inner Join Staging.StageBlockModel mb
						On mb.BlockModelId = rc.BlockModelId
				Where mb.BlockModelId = @blockModelId
				FOR XML PATH, ELEMENTS, ROOT('ResourceClassification')
	)	
	
	SET @processedText = CONVERT(varchar(max),@newResourceClassificationXML)
	PRINT @processedText	
	PRINT @importSyncRowId
	
	BEGIN TRANSACTION	
	
	--- DELETE any existing ResourceClassification NODE FIRST
	UPDATE isr
	SET SourceRow.modify('delete (/BlockModelSource/BlastModelBlockWithPointAndGrade/ResourceClassification)[1]') 
	FROM ImportSyncRow isr 
	WHERE isr.ImportSyncRowId = @importSyncRowId

	-- insert the replacement value
	UPDATE isr
		SET SourceRow.modify('insert <ResourceClassification>{sql:variable("@processedText")}</ResourceClassification> as last into (/BlockModelSource/BlastModelBlockWithPointAndGrade)[1]')
	FROM ImportSyncRow isr 
	WHERE isr.ImportSyncRowId = @importSyncRowId
		
	-- log the fact that this import sync row has been processed...this way the processing can be stopped and continued
	INSERT INTO Staging.TmpStageImportSyncRowRCCorrectionLog(ImportSyncRowId, ProcessedDateTime)
	VALUES (@importSyncRowId, GetDate())
			
	--ROLLBACK TRANSACTION -- for testing
	COMMIT TRANSACTION
	
	FETCH NEXT FROM curRowsToCorrect INTO  @importSyncRowId, @resourceClassificationText, @blockId,  @blockModelId
END

CLOSE curRowsToCorrect
DEALLOCATE curRowsToCorrect

