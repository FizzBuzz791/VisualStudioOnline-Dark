--drop table Staging.Tmp_StratWeatheringImport

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
	[WEATHERING_FOUND] BIT NOT NULL DEFAULT 0,
	[PROCESSED] BIT NOT NULL DEFAULT 0,
	[PROCESSED_DATETIME] DATETIME NULL,
	[ERROR_MESSAGE] varchar(max) NULL,
	CONSTRAINT [PK_Staging_Tmp_StratWeatheringImport] PRIMARY KEY CLUSTERED
	(
		[DIGBLOCK_ID] ASC
	)
)

END

GO