

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

CREATE TABLE #AsDroppedImportFile 
	(
	SITE varchar(31) NULL ,
	PIT varchar(31) NULL,
	MQ2_PIT_CODE varchar(31) NULL,
	BENCH varchar(31) NULL,
	PATTERN_ID varchar(31) NULL,
	PATTERN_NUMBER varchar(31)  NULL,
	BLOCK_NAME varchar(50) NULL,
	BLOCK_FULL_NAME varchar(50) NULL,
	MODEL varchar(31) NULL,
	ORE_TYPE varchar(31) NULL,
	AD_LUMP_PCT real null,
	AD_LUMP_FE real null,
	AD_LUMP_P real null,
	AD_LUMP_SIO2 real null,
	AD_LUMP_AL2O3 real null,
	AD_LUMP_LOI real null,
	AD_LUMP_H2O real null,
	AS_LUMP_PCT real null,
	AS_LUMP_FE real null,
	AS_LUMP_P real null,
	AS_LUMP_SIO2 real null,
	AS_LUMP_AL2O3 real null,
	AS_LUMP_LOI real null,
	AS_LUMP_H2O real null,
	AD_FINES_PCT real null,
	AD_FINES_FE real null,
	AD_FINES_P real null,
	AD_FINES_SIO2 real null,
	AD_FINES_AL2O3 real null,
	AD_FINES_LOI real null,
	AD_FINES_H2O real null,
	AS_FINES_PCT real null,
	AS_FINES_FE real null,
	AS_FINES_P real null,
	AS_FINES_SIO2 real null,
	AS_FINES_AL2O3 real null,
	AS_FINES_LOI real null,
	AS_FINES_H2O real null,
	AD_UFPCT_LUMP real null,
	AS_UFPCT_LUMP real null,
	AD_UF_WEIGHTED_PCT real null,
	AS_UF_WEIGHTED_PCT real null
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

		SET @sql = 'BULK INSERT #AsDroppedImportFile
		FROM ''' + @directory + @file + '''
		WITH
		(
			FIRSTROW = 2,
			FORMATFILE = '''+ @directory + 'AsDroppedImportFile.xml'',
			TABLOCK
		) '

		exec (@sql)

		INSERT INTO [Staging].[TmpAsDroppedImport]
           ([SITE], [PIT], [MQ2_PIT_CODE], [BENCH], [PATTERN_ID], [PATTERN_NUMBER], [BLOCK_NAME], [BLOCK_FULL_NAME],
           [MODEL], ORE_TYPE, [AD_LUMP_PCT], 
		   [AD_LUMP_FE], [AD_LUMP_P], [AD_LUMP_SIO2], [AD_LUMP_AL2O3], [AD_LUMP_LOI], AD_LUMP_H2O,
           [AD_FINES_FE], [AD_FINES_P], [AD_FINES_SIO2], [AD_FINES_AL2O3], [AD_FINES_LOI], AD_FINES_H2O,
		   [AS_FINES_UF], [AD_FINES_UF], 
		   AS_LUMP_H2O, AS_FINES_H2O,
		   [ImportDate], [ImportFile], [Processed])
		SELECT 
			[SITE], [PIT], [MQ2_PIT_CODE], [BENCH], [PATTERN_ID], [PATTERN_NUMBER], [BLOCK_NAME], [BLOCK_FULL_NAME],
			[MODEL], ORE_TYPE, [AD_LUMP_PCT], 
			[AD_LUMP_FE], [AD_LUMP_P], [AD_LUMP_SIO2], [AD_LUMP_AL2O3], [AD_LUMP_LOI], AD_LUMP_H2O,
			[AD_FINES_FE], [AD_FINES_P], [AD_FINES_SIO2], [AD_FINES_AL2O3], [AD_FINES_LOI], AD_FINES_H2O,
			AS_UFPCT_LUMP, AD_UFPCT_LUMP,
			AS_LUMP_H2O, AS_FINES_H2O,
			GETDATE(), @file, 0
		FROM #AsDroppedImportFile 

		delete from #AsDroppedImportFile

	END

	FETCH NEXT FROM CUR_IMPORTFILE INTO @file
END

CLOSE CUR_IMPORTFILE;
DEALLOCATE CUR_IMPORTFILE;

DROP TABLE #AsDroppedImportFile

if (@value_in_use = 0)
BEGIN
	PRINT 'disallow xp_cmdshell'
	EXEC ('EXEC sp_configure ''xp_cmdshell'', 0;')
	EXEC ('RECONFIGURE;')
END

Go

Update [Staging].[TmpAsDroppedImport]
Set Model = 'Grade Control'
Where Model = 'block'

UPDATE ad	
	set ad.StagingBlockModelId = smb.BlockModelId
from [Staging].[TmpAsDroppedImport] ad
	inner join Staging.StageBlock sb 
		on sb.BlockFullName = ad.BLOCK_FULL_NAME
			and sb.[Site] = ad.[SITE]
	inner join Staging.StageBlockModel smb
		on smb.MaterialTypeName = ad.ORE_TYPE
			and smb.BlockModelName = ad.MODEL
			and smb.BlockId = sb.BlockId

UPDATE [Staging].TmpAsDroppedImport
	SET Message = 'Unable to map block to BlockModelId'
WHERE StagingBlockModelId IS NULL
