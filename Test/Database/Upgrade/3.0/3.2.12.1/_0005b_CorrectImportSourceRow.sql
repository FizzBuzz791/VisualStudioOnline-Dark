
PRINT 'Performing Import Source Row correction'

DECLARE @MaxImportSyncRowIdProcessed INTEGER
SELECT @MaxImportSyncRowIdProcessed = MAX(ImportSyncRowId) FROM Staging.TmpStageImportSyncRowCorrectionLog

DECLARE @ImportSyncRowId INTEGER
SELECT @ImportSyncRowId = Min(ImportSyncRowId) FROM ImportSyncRow bk WHERE bk.ImportId = 1 and bk.IsCurrent = 1 AND bk.ImportSyncRowId > IsNull(@MaxImportSyncRowIdProcessed, 0)

DECLARE @site VARCHAR(255)
DECLARE @pit VARCHAR(255)
DECLARE @bench VARCHAR(255)
DECLARE @patternNumber VARCHAR(255)
DECLARE @modelName VARCHAR(255)
DECLARE @blockName VARCHAR(255)
DECLARE @oreType VARCHAR(255)
DECLARE @lumpPercent DECIMAL(7,4)
DECLARE @correctedLumpPercent DECIMAL(7,4)
DECLARE @correctedLumpPercentString varchar(10)

DECLARE @sourceRow XML
DECLARE @changeCount BIT
DECLARE @lpNullCount INTEGER

SET @changeCount  = 0
SET @lpNullCount = 0

WHILE NOT @ImportSyncRowId IS NULL
BEGIN

	SELECT @sourceRow = SourceRow
	FROM ImportSyncRow isr 
	WHERE isr.ImportSyncRowId = @ImportSyncRowId
	
	SET @site = @sourceRow.value('/BlockModelSource[1]/*[1]/Site[1]','varchar(255)')
	SET @pit = @sourceRow.value('/BlockModelSource[1]/*[1]/Pit[1]','varchar(255)')
	SET @bench = @sourceRow.value('/BlockModelSource[1]/*[1]/Bench[1]','varchar(255)')
	SET @patternNumber = @sourceRow.value('/BlockModelSource[1]/*[1]/PatternNumber[1]','varchar(255)')
	SET @modelName = @sourceRow.value('/BlockModelSource[1]/*[1]/ModelName[1]','varchar(255)') 
	SET @blockName = @sourceRow.value('/BlockModelSource[1]/*[1]/BlockName[1]','varchar(255)')
	SET @oreType = @sourceRow.value('/BlockModelSource[1]/*[1]/ModelOreType[1]','varchar(255)')
	SET @lumpPercent = @sourceRow.value('/BlockModelSource[1]/*[1]/ModelLumpPercent[1]','float')

	IF @modelName = 'Grade Control' AND NOT @lumpPercent IS NULL
	BEGIN
		SELECT @correctedLumpPercent = bm.LumpPercent
		FROM Staging.StageBlock b 
			INNER JOIN Staging.StageBlockModel bm ON bm.BlockId = b.BlockId AND bm.BlockModelName = @modelName AND bm.MaterialTypeName = @oreType
		WHERE b.Site = @site AND b.Bench = @bench and b.PatternNumber = @patternNumber AND b.BlockName = @blockName and (b.Pit = @pit OR b.AlternativePitCode = @pit)

		IF @correctedLumpPercent IS NULL
		BEGIN
			SET @lpNullCount = @lpNullCount + 1
		END
		ELSE
		BEGIN
			SET @correctedLumpPercentString = convert(varchar(10), @correctedLumpPercent)

			IF NOT convert(varchar(10),@lumpPercent) = @correctedLumpPercentString
			BEGIN
				SET @changeCount = @changeCount + 1
			
				UPDATE isr
				SET SourceRow.modify('replace value of  (/BlockModelSource/BlastModelBlockWithPointAndGrade/ModelLumpPercent/text())[1] with sql:variable("@correctedLumpPercentString")') 
				FROM ImportSyncRow isr 
				WHERE isr.ImportSyncRowId = @importSyncRowId
			END
		END
	END
	-- log the fact that this import sync row has been processed...this way the processing can be stopped and continued
	INSERT INTO Staging.TmpStageImportSyncRowCorrectionLog(ImportSyncRowId, ProcessedDateTime)
	VALUES (@importSyncRowId, GetDate())
	
	SET @MaxImportSyncRowIdProcessed = @ImportSyncRowId
	SELECT @ImportSyncRowId = Min(ImportSyncRowId) FROM ImportSyncRow bk WHERE bk.ImportId = 1 and bk.IsCurrent = 1 AND bk.ImportSyncRowId > IsNull(@MaxImportSyncRowIdProcessed, 0)
END
DECLARE @processedCount INTEGER
SELECT @processedCount = COUNT(*) FROM Staging.TmpStageImportSyncRowCorrectionLog

PRINT 'Import Source Row correction complete'
PRINT 'Processed: ' + convert(varchar(10), @processedCount)
PRINT 'Changed: '+ convert(Varchar(10),@changeCount)
PRINT 'LP Null Count: '+ convert(Varchar(10),@lpNullCount)

GO