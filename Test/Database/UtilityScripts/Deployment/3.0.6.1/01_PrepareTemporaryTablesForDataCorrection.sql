-- make sure the temporary table for storage of blocks needing correction exists
IF OBJECT_ID('Staging.TmpStageLumpFinesBlockCorrectionBlocks') IS NULL
BEGIN
	CREATE TABLE Staging.TmpStageLumpFinesBlockCorrectionBlocks
	(
		BlockFullName varchar(50),
		MinLastUpdateDateTime DateTime,
		MaxLastUpdateDateTime DateTime,
		FlagDelete BIT Default(0)
	)
END
GO 

IF OBJECT_ID('Staging.TmpLumpFinesStageBlockModelGradeCorrection') IS NULL
BEGIN
	CREATE TABLE [Staging].[TmpLumpFinesStageBlockModelGradeCorrection](
		[BlockModelId] [int] NOT NULL,
		[GradeName] [varchar](31) NOT NULL,
		[GradeValue] [float] NULL,
		[LumpValue] [float] NULL,
		[FinesValue] [float] NULL,
		[CorrectedGradeValue] [float] NULL,
		[CorrectedLumpValue] [float] NULL,
		[CorrectedFinesValue] [float] NULL,
	 CONSTRAINT [PK_TmpLumpFinesStageBlockModelGradeCorrection] PRIMARY KEY CLUSTERED 
	(
		[BlockModelId] ASC,
		[GradeName] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
ELSE
BEGIN
	DELETE FROM [Staging].[TmpLumpFinesStageBlockModelGradeCorrection]
END
GO 


IF OBJECT_ID('Staging.TmpLumpFinesBhpbioBlastBlockLumpFinesGradeCorrection') IS NULL
BEGIN
	CREATE TABLE Staging.TmpLumpFinesBhpbioBlastBlockLumpFinesGradeCorrection(
		[ModelBlockId] [int] NOT NULL,
		[SequenceNo] [int] NOT NULL,
		[GradeId] [smallint] NOT NULL,
		[LumpValue] [real] NOT NULL,
		[FinesValue] [real] NOT NULL,
		[CorrectedLumpValue] [real] NOT NULL,
		[CorrectedFinesValue] [real] NOT NULL,
	 CONSTRAINT [PK_TmpLumpFinesBhpbioBlastBlockLumpFinesGradeCorrection] PRIMARY KEY CLUSTERED 
	(
		[ModelBlockId] ASC,
		[SequenceNo] ASC,
		[GradeId] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
	) ON [PRIMARY]
END
ELSE
BEGIN
	DELETE FROM [Staging].TmpLumpFinesBhpbioBlastBlockLumpFinesGradeCorrection
END
GO 

IF OBJECT_ID('Staging.TmpBhpbioSummaryEntryGradeCorrection') IS NULL
BEGIN
	CREATE TABLE Staging.TmpBhpbioSummaryEntryGradeCorrection(
		[TotalSummaryEntryGradeId] [int]  NOT NULL,
		[FinesSummaryEntryGradeId] [int] NULL,
		[LumpSummaryEntryGradeId] [int]  NULL,
		[TotalSummaryEntryId] [int] NOT NULL,
		[FinesSummaryEntryId] [int] NULL,
		[LumpSummaryEntryId] [int]  NULL,
		[GradeId] [smallint] NOT NULL,
		[TotalGradeValue] [real] NULL,
		[FinesGradeValue] [real] NULL,
		[LumpGradeValue] [real] NULL,
		[LumpPercent] [real] NULL,
		[CorrectedTotalGradeValue] [real] NULL,
		[CorrectedFinesGradeValue] [real] NULL,
		[CorrectedLumpGradeValue] [real] NULL,
	 CONSTRAINT [PK_TmpBhpbioSummaryEntryGradeCorrection] PRIMARY KEY NONCLUSTERED 
	(
		[TotalSummaryEntryId] ASC,
		[GradeId] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
	) ON [PRIMARY]
END
ELSE
BEGIN
	DELETE FROM [Staging].TmpBhpbioSummaryEntryGradeCorrection
END
GO 

IF OBJECT_ID('Staging.TmpStageImportSyncRowCorrection') IS NULL
BEGIN
	CREATE TABLE Staging.TmpStageImportSyncRowCorrection
	(
		ImportSyncRowId INTEGER,
		[Site] varchar(50),
		Pit varchar(50),
		Bench varchar(50),
		PatternNumber varchar(50),
		ModelName varchar(50),
		BlockName varchar(50),
		ModelLumpPercent Float,
		GradeText varchar(max),
		LastProcessedDateTime DATETIME,
		InitialComparedDateTime DATETIME
	)
END
ELSE
BEGIN
	DELETE FROM Staging.TmpStageImportSyncRowCorrection
END
GO 

IF OBJECT_ID('Staging.TmpStageImportSyncRowCorrectionLog') IS NULL
BEGIN
	CREATE TABLE Staging.TmpStageImportSyncRowCorrectionLog
	(
		ImportSyncRowId INTEGER,
		ProcessedDateTime DATETIME
	)
END
GO

IF OBJECT_ID('Staging.TmpStageImportSyncBlockChangesLog') IS NULL
BEGIN
	CREATE TABLE Staging.TmpStageImportSyncBlockChangesLog
	(
		ImportSyncRowId INTEGER,
		ModelBlockId INTEGER,
		ProcessedDateTime DATETIME
	)
END
ELSE
BEGIN
	DELETE FROM Staging.TmpStageImportSyncBlockChangesLog
END
GO
-- Work out the ModelBlocks that were actually changed
INSERT INTO Staging.TmpStageImportSyncBlockChangesLog(ImportSyncRowId, ModelBlockId, ProcessedDateTime)
SELECT isq.ImportSyncRowId, 
		DestinationRow.value('/BlockModelDestination[1]/*[1]/ModelBlockId[1]','int')  as ModelBlockId,
		isq.LastProcessedDateTime
FROM ImportSyncRow isr
	INNER JOIN ImportSyncQueue isq ON isq.ImportSyncRowId = isr.ImportSyncRowId
WHERE isq.ImportId = 1
	AND isr.IsCurrent = 1
	AND isq.LastProcessedDateTime > '2015-08-20 20:00:00'
	AND isq.IsPending = 0
ORDER BY isq.LastProcessedDateTime
GO