-- this directory must contain the csv, and the xml schema definition
-- 'Resource Classification Migration.xml', the name of the csv doesn't
-- matter, but make sure that its the only csv in the directory
DECLARE @directory varchar(256) = 'C:\temp\'

-- Load data from CSV files into [Staging].[StratNumImport] table
DECLARE @sql varchar(max)
Declare @file varchar(256)
declare @newfileName varchar(256)
declare @value_in_use sql_variant
DECLARE @Block_ImportSyncTableId Int
DECLARE @sourceRow XML
DECLARE @importSyncRowId BIGINT

select	@value_in_use = value_in_use
from	sys.configurations
where	name = 'xp_cmdshell'

if (@value_in_use = 0)
BEGIN
	PRINT 'show advanced options'
	EXEC ('EXEC sp_configure ''show advanced options'', 1;')
	EXEC ('RECONFIGURE;')

	PRINT 'allow xp_cmdshell'
	EXEC ('EXEC sp_configure ''xp_cmdshell'', 1;')
	EXEC ('RECONFIGURE;')
END



DECLARE @fileList TABLE
(
	[FileName] varchar(256)
)

IF OBJECT_ID('tempdb..#StratWeatheringImportFile') IS NOT NULL 
BEGIN
	PRINT '#StratWeatheringImportFile - dropping'
	DROP TABLE #StratWeatheringImportFile
END


CREATE TABLE #StratWeatheringImportFile 
(
	SITE varchar(31) COLLATE Latin1_General_CI_AS NULL ,					--1
	PIT varchar(31) COLLATE Latin1_General_CI_AS NULL,					--2
	BENCH varchar(31) COLLATE Latin1_General_CI_AS NULL,					--3
	PATTERN varchar(31) COLLATE Latin1_General_CI_AS NULL,				--4
	BLOCK_NAME varchar(50) COLLATE Latin1_General_CI_AS NULL,			--5
	STRATIGRAPHY varchar(50) COLLATE Latin1_General_CI_AS NULL,			--6
	GEOMET_STRATNUM varchar(7) COLLATE Latin1_General_CI_AS NULL,		--7
	GEOMET_WEATHERING INT NULL,				--8
	BLOCK_GUID varchar(32) NULL,			--9
	[GUID] varchar(36) COLLATE Latin1_General_CI_AS NULL,				--NA
	[DIGBLOCK_ID] varchar(36) COLLATE Latin1_General_CI_AS NULL, 	--NA
	[DIGBLOCK_FOUND] BIT NOT NULL DEFAULT 0,
	[STRATNUM_FOUND] BIT NOT NULL DEFAULT 0,
	[WEATHERING_FOUND] BIT NOT NULL DEFAULT 0,
	[IMPORT_SYNC_ROW_ID] BIGINT NULL
)

-- Get List of csv files in a folder
SET @sql = 'master.dbo.xp_cmdshell ''dir "' + @directory + '*.csv" /B'''

print @sql

SET NOCOUNT ON

INSERT INTO @fileList
EXEC (@sql)

DELETE FROM @fileList
WHERE [FileName] IS NULL

DECLARE CUR_IMPORTFILE CURSOR  FOR
SELECT FILENAME FROM @fileList;

OPEN CUR_IMPORTFILE;

FETCH NEXT FROM CUR_IMPORTFILE INTO @file

WHILE @@FETCH_STATUS = 0  
BEGIN  
   PRINT @file

	IF (@File = 'File Not DIGBLOCK_FOUND')
		PRINT 'No CSV file DIGBLOCK_FOUND'
	ELSE
	BEGIN

		SET @sql = 'BULK INSERT #StratWeatheringImportFile
		FROM ''' + @directory + @file + '''
		WITH
		(
			FIRSTROW = 2,
			FORMATFILE = '''+ @directory + 'BlastholesImport.xml'',
			TABLOCK
		) '

		exec (@sql)

		END

	FETCH NEXT FROM CUR_IMPORTFILE INTO @file
END

CLOSE CUR_IMPORTFILE;
DEALLOCATE CUR_IMPORTFILE;

UPDATE #StratWeatheringImportFile
    SET GUID =     SUBSTRING(BLOCK_GUID, 1, 8) + '-' + SUBSTRING(BLOCK_GUID, 9, 4) + '-' + SUBSTRING(BLOCK_GUID, 13, 4) + '-' +
        SUBSTRING(BLOCK_GUID, 17, 4) + '-' + SUBSTRING(BLOCK_GUID, 21, 12)

--	POPULATE DigBlockId
UPDATE	#StratWeatheringImportFile
	SET #StratWeatheringImportFile.[DIGBLOCK_ID] = PIT + '-' + Right('0000' +BENCH, 4) + '-' + Right('0000' +PATTERN, 4) + '-' + BLOCK_NAME

UPDATE	#StratWeatheringImportFile
	SET DIGBLOCK_FOUND = CASE WHEN EXISTS(SELECT 1 FROM dbo.DigBlock WHERE Digblock_Id = #StratWeatheringImportFile.DIGBLOCK_ID COLLATE Latin1_General_CI_AS) THEN 1 ELSE 0 END

UPDATE	#StratWeatheringImportFile
	SET STRATNUM_FOUND = CASE WHEN EXISTS(SELECT 1 FROM dbo.BhpbioStratigraphyHierarchy WHERE StratNum = #StratWeatheringImportFile.GEOMET_STRATNUM COLLATE Latin1_General_CI_AS) THEN 1 ELSE 0 END

UPDATE	#StratWeatheringImportFile
	SET WEATHERING_FOUND = CASE WHEN EXISTS(SELECT 1 FROM dbo.BhpbioWeathering WHERE DisplayValue = #StratWeatheringImportFile.GEOMET_WEATHERING) THEN 1 ELSE 0 END


-- Determine the Table Ids
SELECT	@Block_ImportSyncTableId = ImportSyncTableId
FROM	ImportSyncTable
WHERE	Name = 'BlastModelBlockWithPointAndGrade'


DELETE FROM Staging.Tmp_BlockModelSyncRow
		
-- get the Block data for all sync rows
INSERT INTO Staging.Tmp_BlockModelSyncRow (ImportSyncRowId, Pit, Bench, Pattern, BlockName)
SELECT	isr.ImportSyncRowId, 
		isr.SourceRow.value('(/BlockModelSource/BlastModelBlockWithPointAndGrade/Pit)[1]', 'nvarchar(10)') as Pit,
		isr.SourceRow.value('(/BlockModelSource/BlastModelBlockWithPointAndGrade/Bench)[1]', 'nvarchar(4)') as Bench,
		isr.SourceRow.value('(/BlockModelSource/BlastModelBlockWithPointAndGrade/PatternNumber)[1]', 'nvarchar(4)') as PatternNumber,
		isr.SourceRow.value('(/BlockModelSource/BlastModelBlockWithPointAndGrade/BlockName)[1]', 'nvarchar(14)') as BlockName
FROM	ImportSyncQueue isq INNER JOIN ImportSyncRow isr ON isr.ImportSyncRowId = isq.ImportSyncRowId
WHERE	isq.ImportId = 1
AND		isq.SyncAction IN ('I','U')
AND		isr.IsCurrent = 1
AND		isq.IsPending = 0
AND		isr.ImportSyncTableId = @Block_ImportSyncTableId
AND		isr.SourceRow.exist('(/BlockModelSource/BlastModelBlockWithPointAndGrade/ModelName[.="Grade Control"])[1]') = 1
ORDER BY isq.ImportSyncRowId


UPDATE Staging.Tmp_BlockModelSyncRow
	SET [DIGBLOCK_ID] = Pit + '-' + Right('0000' + Bench, 4) + '-' + Right('0000' + Pattern, 4) + '-' + BlockName

SELECT	*
FROM	#StratWeatheringImportFile

INSERT INTO [Staging].[Tmp_StratWeatheringImport]
           ([SITE] ,[PIT], [BENCH], [PATTERN], [BLOCK_NAME], [STRATIGRAPHY], [GEOMET_STRATNUM], [GEOMET_WEATHERING], [BLOCK_GUID], [GUID],
			[DIGBLOCK_ID], [DIGBLOCK_FOUND], [STRATNUM_FOUND], [WEATHERING_FOUND])
SELECT		[SITE], [PIT], [BENCH] ,[PATTERN], [BLOCK_NAME], [STRATIGRAPHY], [GEOMET_STRATNUM], [GEOMET_WEATHERING], [BLOCK_GUID], [GUID],
           [DIGBLOCK_ID], [DIGBLOCK_FOUND], [STRATNUM_FOUND], [WEATHERING_FOUND]
FROM		#StratWeatheringImportFile
WHERE		NOT EXISTS (select	1 
						FROM	[Staging].[Tmp_StratWeatheringImport]
						WHERE	[Staging].[Tmp_StratWeatheringImport].[DIGBLOCK_ID] = #StratWeatheringImportFile.[DIGBLOCK_ID])


DROP TABLE #StratWeatheringImportFile

if (@value_in_use = 0)
BEGIN
	PRINT 'disallow xp_cmdshell'
	EXEC ('EXEC sp_configure ''xp_cmdshell'', 0;')
	EXEC ('RECONFIGURE;')
END