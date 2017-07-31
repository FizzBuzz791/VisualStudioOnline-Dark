-- 
-- This script will do the first stage of the Resource Classification data import - 
-- it wil import any number of CSV files
--
-- To Run:
--	1) Copy the migration schema xml file to C:\Temp on the database server
--	2) Copy all the required csv files to the same directory
--	3) Execute this script (it should only take a few minutes to run)
--	4) check that the data has been imported to Staging.ResourceClassificationTemp & 
--	   Staging.ResourceClassificationTempWithMaterialType
--
-- Once the data has been validated, run the next scripts. '02' will import the data to the 
-- staging, live and summary tables, while the subsequent scripts will update the ImportSyncRow
-- data so that imports are not triggered unnecessarily
--
-- Note that '02' might take up to 24 HOURS to run, so it will probably be necessary to 
-- create a SQL job to run this
--
-- ===================================================
--

-- We need to permission in order to read the csv files from the disk
-- it will be disabled again after the script is run
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO

EXEC sp_configure 'xp_cmdshell', 1;
GO
RECONFIGURE;
GO

-- this directory must contain the csv, and the xml schema definition
-- 'Resource Classification Migration.xml', the name of the csv doesn't
-- matter, but make sure that its the only csv in the directory
DECLARE @directory varchar(256) = 'C:\Temp\'

-- Drop and Create [Staging].[ResourceClassificationTemp] working tables
IF OBJECT_ID('[Staging].[ResourceClassificationTempWithMaterialType]') IS NOT NULL 
     DROP TABLE [Staging].[ResourceClassificationTempWithMaterialType]

IF OBJECT_ID('[Staging].[ResourceClassificationTemp]') IS NOT NULL 
     DROP TABLE [Staging].[ResourceClassificationTemp]

CREATE TABLE [Staging].[ResourceClassificationTemp](
	[Site] [varchar](16) NULL,
	[Pit] [varchar](10) NULL,
	[Mq2PitCode] [varchar](10) NULL,
	[Bench] [varchar](10) NULL,
	[PatternId] [int] NULL,
	[PatternNumber] [varchar](16) NULL,
	[BlockName] [varchar](10) NULL,
	[BlockFullName] [varchar](50) NULL,
	[BMF] [int] NULL,
	[BlockModelName] [varchar](31) NULL,
	ResourceClassification1 [float] NULL,
	ResourceClassification2 [float] NULL,
	ResourceClassification3 [float] NULL,
	ResourceClassification4 [float] NULL,
	ResourceClassification5 [float] NULL,
	[RowId] [int] IDENTITY(1,1) NOT NULL,
	[Source] [varchar](256) NULL,
	[StageBlock_BlockId] [int] NULL,
	[MaterialTypeId] [int] NULL,
	[Message] [nvarchar](max) NULL,
	[Processed] [tinyint] NOT NULL CONSTRAINT [ResourceClassificationTemp_Processed]  DEFAULT ((0)), -- 0 - Unprocessed, 1 - Processed, 2 - Skipped, 3 - Partial Load, 4 - Error
 CONSTRAINT [PK_ResourceClassificationTemp] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

SET NOCOUNT ON

-- Clear Test Data
/*

DELETE FROM [dbo].[ModelBlockPartialValue]
WHERE Model_Block_Partial_Field_Id LIKE 'Res%'
	AND [Field_Value] = 0

*/

--


-- Load data from CSV files into [Staging].[ResourceClassificationTemp] table
DECLARE @sql varchar(max)
Declare @file varchar(256)

DECLARE @fileList TABLE
(
	[FileName] varchar(256)
)

-- Get List of csv files in a folder
SET @sql = 'master.dbo.xp_cmdshell ''dir "' + @directory + '*.csv" /B'''

SET NOCOUNT ON

INSERT INTO @fileList
EXEC (@sql)

DELETE FROM @fileList
WHERE [FileName] IS NULL

WHILE (EXISTS (SELECT 1 FROM @fileList))
BEGIN
	SET @file = (SELECT TOP 1 [FileName] FROM @fileList)

	DELETE FROM @fileList
	WHERE [FileName] = @file

	--TODO: check directories
	SET @sql = 'BULK INSERT [Staging].[ResourceClassificationTemp]
	FROM ''' + @directory + @file + '''
	WITH
	(
		FIRSTROW = 2,
		FORMATFILE = '''+ @directory+ 'Resource Classification Migration.xml'',
		TABLOCK
	)

'

	PRINT @sql
	EXEC (@sql)

	UPDATE [Staging].[ResourceClassificationTemp] SET
		[Source] = @directory + @file
	WHERE [Source] IS NULL
END

-- primary match... match on component parts
UPDATE t SET
	[StageBlock_BlockId] = b.[BlockId]
FROM [Staging].[ResourceClassificationTemp] as t
	INNER JOIN [Staging].[StageBlock] as b
		ON t.Site = b.Site -- match on site
		AND COALESCE(t.Mq2PitCode, t.Pit) = COALESCE(b.AlternativePitCode, b.Pit) -- match on pit
		AND RIGHT('000' + convert(varchar,t.Bench),4) = RIGHT('000' + b.Bench,4) -- match on bench
		AND RIGHT('000' + convert(varchar,t.PatternNumber),4) = RIGHT('000' + b.PatternNumber,4) -- match on pattern number
		AND t.BlockName = b.BlockName -- match on block name

-- secondary match... match on block full name
UPDATE t SET
	[StageBlock_BlockId] = b.[BlockId]
FROM [Staging].[ResourceClassificationTemp] AS t
	INNER JOIN [Staging].[StageBlock] AS b
		ON t.[BlockFullName] = b.[BlockFullName]
WHERE t.StageBlock_BlockId IS NULL -- only where not already matched
	AND NOT t.Site = 'OB18' -- but not for OB18 which has known problems with name matching

UPDATE [Staging].[ResourceClassificationTemp] SET
	[Message] = 'Skipped - Could not match StageBlock.BlockId',
	[Processed] = 2
WHERE [Processed] = 0
	AND [StageBlock_BlockId] IS NULL

SELECT t.*, b.[BlockModelId] AS [StageBlockModel_BlockModelId], b.[MaterialTypeName]
INTO [Staging].[ResourceClassificationTempWithMaterialType]
FROM [Staging].[ResourceClassificationTemp] AS t
	INNER JOIN [Staging].[StageBlockModel] AS b
		ON t.[BlockModelName] = b.[BlockModelName]
		AND t.[StageBlock_BlockId] = b.[BlockId]
WHERE t.[Processed] = 0

ALTER TABLE [Staging].[ResourceClassificationTempWithMaterialType] ADD [NewRowId] [int] IDENTITY(1, 1) NOT NULL

CREATE NONCLUSTERED INDEX [ResourceClassificationTemp_NewRowID] ON [Staging].[ResourceClassificationTempWithMaterialType] 
(
	[NewRowId] ASC,
	[Processed] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, 
	DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

UPDATE [Staging].[ResourceClassificationTemp] SET
	[Message] = 'Skipped - Could not match StageBlockModel.BlockModelId',
	[Processed] = 2
WHERE [RowId] NOT IN (SELECT [RowId] FROM [Staging].[ResourceClassificationTempWithMaterialType])
	AND [Processed] = 0

UPDATE t SET
	[MaterialTypeId] = m.[Material_Type_id]
FROM [Staging].[ResourceClassificationTempWithMaterialType] AS t
	INNER JOIN [dbo].[MaterialType] AS m
		ON t.[MaterialTypeName] = m.[Abbreviation]
			And m.Material_Category_Id = 'OreType'

UPDATE [Staging].[ResourceClassificationTempWithMaterialType] SET
	[Message] = 'Skipped - Could not match MaterialType.Material_Type_id',
	[Processed] = 2
WHERE [Processed] = 0
	AND [MaterialTypeId] IS NULL


-- disable the perms again
EXEC sp_configure 'xp_cmdshell', 0;
GO
RECONFIGURE;
GO