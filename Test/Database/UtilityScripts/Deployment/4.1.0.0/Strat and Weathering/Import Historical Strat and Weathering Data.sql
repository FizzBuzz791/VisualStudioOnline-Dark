declare @value_in_use sql_variant

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

-- this directory must contain the csv, and the xml schema definition
-- 'Resource Classification Migration.xml', the name of the csv doesn't
-- matter, but make sure that its the only csv in the directory
DECLARE @directory varchar(256) = 'C:\temp\'

-- Load data from CSV files into [Staging].[ResourceClassificationTemp] table
DECLARE @sql varchar(max)
Declare @file varchar(256)
declare @newfileName varchar(256)

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
	SITE varchar(31) NULL ,					--1
	PIT varchar(31) NULL,					--2
	MQ2_PIT_CODE varchar(31) NULL,			--3
	BENCH varchar(31) NULL,					--4
	PATTERN_ID varchar(31) NULL,			--5
	--PATTERN_NUMBER varchar(31)  NULL,		--
	BLOCK_NAME varchar(50) NULL,			--6
	BLOCK_NO varchar(50) NULL,				--7
	GEOMET_WEATHERING INT NULL,				--8
	GEOMET_STRATNUM varchar(7) NULL,		--9
	BLOCK_GUID varchar(32) NULL,			--10
	[GUID] varchar(36) NULL,					--NA
	[DIGBLOCK_ID] varchar(36) NULL 					--NA
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

	IF (@File = 'File Not Found')
		PRINT 'No CSV file found'
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
	SET #StratWeatheringImportFile.[DIGBLOCK_ID] = [dbo].[DigblockNotes].[Digblock_Id]
FROM	[dbo].[DigblockNotes]
		where	[dbo].[DigblockNotes].[Digblock_Field_Id] = 'BlockExternalSystemId'
		AND		[dbo].[DigblockNotes].[Notes] = #StratWeatheringImportFile.GUID
COLLATE Latin1_General_CI_AS

SELECT	*
FROM	#StratWeatheringImportFile

DROP TABLE #StratWeatheringImportFile

if (@value_in_use = 0)
BEGIN
	PRINT 'disallow xp_cmdshell'
	EXEC ('EXEC sp_configure ''xp_cmdshell'', 0;')
	EXEC ('RECONFIGURE;')
END