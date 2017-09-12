﻿--drop table Staging.Tmp_StratWeatheringImport

IF OBJECT_ID('Staging.Tmp_StratWeatheringImport') IS NULL 
BEGIN

CREATE TABLE Staging.Tmp_StratWeatheringImport 
(
	[DIGBLOCK_ID] varchar(36) COLLATE Latin1_General_CI_AS NOT NULL, 	--NA
	SITE varchar(31) NULL ,					--1
	PIT varchar(31) NULL,					--2
	BENCH varchar(31) NULL,					--3
	PATTERN varchar(31) NULL,				--4
	BLOCK_NAME varchar(50) NULL,			--5
	STRATIGRAPHY varchar(50) NULL,			--6
	GEOMET_STRATNUM varchar(7) NULL,		--7
	GEOMET_WEATHERING INT NULL,				--8
	BLOCK_GUID varchar(32) NULL,			--9
	[GUID] varchar(36) NULL,				--NA
	[DIGBLOCK_FOUND] BIT NOT NULL DEFAULT 0,
	[STRATNUM_FOUND] BIT NOT NULL DEFAULT 0,
	[STRATNUM_FOUND_IN_XML] BIT NOT NULL DEFAULT 0,
	[WEATHERING_FOUND] BIT NOT NULL DEFAULT 0,
	[WEATHERING_FOUND_IN_XML] BIT NOT NULL DEFAULT 0,
	[IMPORT_SYNC_ROW_ID] BIGINT NULL,
	[PROCESSED] BIT NOT NULL DEFAULT 0,
	[PROCESSED_DATETIME] DATETIME NULL,
	[ERROR_MESSAGE] nvarchar(4000) NULL,
	CONSTRAINT [PK_Staging_Tmp_StratWeatheringImport] PRIMARY KEY CLUSTERED
	(
		[DIGBLOCK_ID] ASC
	)
)

CREATE NONCLUSTERED INDEX [IX_Tmp_StratWeatheringImport_Processed] ON [Staging].[Tmp_StratWeatheringImport]
(
	[PROCESSED] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_Tmp_StratWeatheringImport_BlockCols] ON [Staging].[Tmp_StratWeatheringImport]
(
	PIT ASC,
	BENCH ASC,
	PATTERN ASC,
	BLOCK_NAME ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

END

GO

IF OBJECT_ID('Staging.Tmp_BlockModelSyncRow') IS NULL 
BEGIN
	CREATE TABLE Staging.Tmp_BlockModelSyncRow 
	(
		ImportSyncRowId BigInt Primary Key,
		Pit nvarchar(10) COLLATE Latin1_General_CI_AS NULL,
		Bench nvarchar(4) COLLATE Latin1_General_CI_AS NULL,
		Pattern nvarchar(4) COLLATE Latin1_General_CI_AS NULL,
		BlockName nvarchar(14) COLLATE Latin1_General_CI_AS NULL,
		DigBlock_Id NVARCHAR(31) COLLATE Latin1_General_CI_AS NULL
		UNIQUE (ImportSyncRowId)
	)


	CREATE NONCLUSTERED INDEX [IX_Tmp_BlockModelSyncRow] ON [Staging].[Tmp_BlockModelSyncRow]
	(
		Pit ASC,
		Bench ASC,
		Pattern ASC,
		BlockName ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]



	CREATE NONCLUSTERED INDEX [IX_Tmp_BlockModelSyncRow2] ON [Staging].[Tmp_BlockModelSyncRow]
	(
		DigBlock_Id ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
END
GO