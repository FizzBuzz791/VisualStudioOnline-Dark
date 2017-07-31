-- SCHEMA
ALTER TABLE [dbo].[NotificationInstanceNegativeStockpile] DROP CONSTRAINT [FK_NotificationInstanceNegativeStockpile_NotificationInstance]
GO
ALTER TABLE [dbo].[NotificationInstanceNegativeStockpile] DROP CONSTRAINT [FK_NotificationInstanceNegativeStockpile_Location]
GO
ALTER TABLE [dbo].[NotificationInstanceNegativeStockpile] DROP CONSTRAINT [FK_NotificationInstanceNegativeStockpile_Stockpile]
GO
ALTER TABLE [dbo].[NotificationInstanceNegativeStockpile] DROP CONSTRAINT [FK_NotificationInstanceNegativeStockpile_StockpileGroup]
GO
ALTER TABLE [dbo].[BhpbioBlastBlockPointHolding] DROP CONSTRAINT [FK_BhpbioBlastBlockPointHolding_BhpbioBlastBlockHolding]
GO
ALTER TABLE [dbo].[TruckTypeFactorPeriod] DROP CONSTRAINT [FK__TRUCK_TYPE_FACTOR_PERIOD__TRUCK_TYPE]
GO
ALTER TABLE [dbo].[BhpbioBlastBlockModelGradeHolding] DROP CONSTRAINT [FK_BhpbioBlastBlockModelGradeHolding_BhpbioBlastBlockModelHolding]
GO
ALTER TABLE [dbo].[BhpbioBlastBlockModelHolding] DROP CONSTRAINT [FK_BhpbioBlastBlockModelHolding_BhpbioBlastBlockHolding]
GO
ALTER TABLE [dbo].[ModelBlockPartial] DROP CONSTRAINT [FK__MODEL_BLOCK_PARTIAL__SEQUENCE]
GO
ALTER TABLE [dbo].[Digblock] DROP CONSTRAINT [FK__DIGBLOCK__BLAST_BLOCK]
GO
ALTER TABLE [dbo].[NotificationInstanceNegativeStockpile] DROP CONSTRAINT [CK_StockpileSelectionType]
GO
ALTER TABLE [dbo].[NotificationInstanceNegativeStockpile] DROP CONSTRAINT [PK_NotificationInstanceNegativeStockpile]
GO
DROP PROCEDURE [dbo].[GetRecalcHistoryCountSinceLastSuccess]
GO
DROP PROCEDURE [dbo].[AddOrUpdateDigblockSurveySampleFormula]
GO
DROP PROCEDURE [dbo].[GetHaulageValidHaulagePointList]
GO
DROP PROCEDURE [dbo].[GetImportSyncRowsInDateRange]
GO
DROP PROCEDURE [dbo].[SummariseBhpbioActualC]
GO
DROP PROCEDURE [dbo].[CorrectRtioWeightometerSamplesByAddition]
GO
DROP VIEW [dbo].[StockpileSurveyView]
GO
DROP VIEW [dbo].[WeightometerSampleReportView]
GO
DROP VIEW [dbo].[HaulageView]
GO
DROP FUNCTION [dbo].[DoesQueuedBlocksJobExist]
GO
DROP VIEW [dbo].[ReconciledStockpileBalancesView]
GO
DROP VIEW [dbo].[ReconciledTransactionsView]
GO
DROP VIEW [dbo].[BhpbioImportBlockFailure]
GO
DROP VIEW [dbo].[MinePlanView]
GO
DROP VIEW [dbo].[BhpbioImportHaulage2]
GO
DROP VIEW [dbo].[BlastDigblockView]
GO
DROP VIEW [dbo].[BlockModelView]
GO
DROP VIEW [dbo].[BhpbioImportBlockDel]
GO
DROP VIEW [dbo].[ReconciliationSummaryByDigblockView]
GO
DROP INDEX [IX_NotificationInstanceNegativeStockpile_Lookup] ON [dbo].[NotificationInstanceNegativeStockpile]
GO
DROP INDEX [IX_DATA_PROCESS_STOCKPILE_BALANCE__DATE_STOCKPILE_BUILD] ON [dbo].[DataProcessStockpileBalance]
GO
DROP INDEX [IX_Location_Parent] ON [dbo].[Location]
GO
DROP TABLE [dbo].[ModelBlockPartialSequence]
GO
DROP TABLE [dbo].[Temp_StockpileGroupStockpile]
GO
DROP TABLE [dbo].[TempDataExceptionPRO12279]
GO
DROP TABLE [dbo].[TempBhpbioApprovalDataPreAutoApprove]
GO
DROP TABLE [dbo].[TempBhpbioApprovalDigblockPreAutoApprove]
GO
DROP TABLE [dbo].[BHPBIOImportFix]
GO
UPDATE [dbo].[NotificationTypeRegistration] SET [DisplayOnUi] = 0 WHERE [DisplayOnUi] IS NULL
GO
ALTER TABLE [dbo].[DigblockSurvey] ADD 
[Start_Date] [datetime] NULL,
[Start_Shift] [char] (1) COLLATE Latin1_General_CI_AS NULL,
[Parent_Location_Id] [int] NULL
GO
ALTER TABLE [dbo].[MinePlan] ADD 
[Parent_Location_Id] [int] NULL
GO
ALTER TABLE [dbo].[Digblock] DROP COLUMN [Blast_Block_Id]
GO
ALTER TABLE [dbo].[BlockModel] ADD 
[Parent_Location_Id] [int] NULL
GO
ALTER TABLE [dbo].[Grade] ALTER COLUMN [Units] [varchar] (15) COLLATE Latin1_General_CI_AS NULL
GO
ALTER TABLE [dbo].[Import] ADD 
[ImportConflictTypeId] [int] NULL
GO
ALTER TABLE [dbo].[MinePlanPeriod] ADD 
[Planned_Location_Name] [varchar] (31) COLLATE Latin1_General_CI_AS NULL
GO
ALTER TABLE [dbo].[NotificationTypeRegistration] ALTER COLUMN [DisplayOnUi] [bit] NOT NULL
GO
ALTER TABLE [dbo].[AuditHistory] ALTER COLUMN [Details] [varchar] (max) COLLATE Latin1_General_CI_AS NULL
GO
ALTER TABLE [dbo].[Crusher] ADD 
[Is_Visible] [bit] NOT NULL CONSTRAINT [DF__Crusher__Is_Visi__46B27FE2] DEFAULT ((1))
GO
ALTER TABLE [dbo].[StockpileSurveyType] ADD 
[Is_Visible] [bit] NOT NULL CONSTRAINT [DF__Stockpile__Is_Vi__6F7F8B4B] DEFAULT ((1))
GO
ALTER TABLE [dbo].[ModelBlockPartial] DROP COLUMN [Digblock_Survey_Date],[Digblock_Survey_Shift]
GO
ALTER TABLE [dbo].[SecurityUser] ADD 
[UserCultureInfo] [varchar] (10) COLLATE Latin1_General_CI_AS NULL
GO
CREATE TABLE [dbo].[ImportConflictType]
(
	[ImportConflictTypeId] [int] IDENTITY (1,1) NOT NULL,
	[Name] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
	CONSTRAINT [PK_ImportConflictType] PRIMARY KEY CLUSTERED
	(
		[ImportConflictTypeId] ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[ImportConflictOverride]
(
	[Id] [int] IDENTITY (1,1) NOT NULL,
	[ImportSyncRowId] [bigint] NULL
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[ImportAutoQueueProfile]
(
	[ImportAutoQueueProfileId] [int] IDENTITY (1,1) NOT NULL,
	[ImportId] [smallint] NOT NULL,
	[FrequencyHours] [smallint] NULL,
	[TimeOfDay] [datetime] NULL,
	[IsActive] [bit] NOT NULL CONSTRAINT [DF__ImportAut__IsAct__6FD49106] DEFAULT ((0)),
	[Priority] [smallint] NOT NULL CONSTRAINT [DF__ImportAut__Prior__70C8B53F] DEFAULT ((1)),
	CONSTRAINT [PK_ImportAutoQueueProfile] PRIMARY KEY CLUSTERED
	(
		[ImportAutoQueueProfileId] ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
	CONSTRAINT [UQ_ImportAutoQueueProfile_ImportId] UNIQUE NONCLUSTERED
	(
		[ImportId] ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[ImportLoadRowMessages]
(
	[ImportLoadRowMessagesId] [bigint] IDENTITY (1,1) NOT NULL,
	[ImportLoadRowId] [bigint] NULL,
	[ValidationMessage] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
	CONSTRAINT [PK_LoadRowMessages] PRIMARY KEY CLUSTERED
	(
		[ImportLoadRowMessagesId] ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_ImportLoadRowMessages] ON [dbo].[ImportLoadRowMessages]
(
	[ImportLoadRowId] ASC
) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO


CREATE TABLE [dbo].[ImportLoadRow]
(
	[ImportLoadRowId] [bigint] NOT NULL,
	[ImportId] [smallint] NULL,
	[ImportSource] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
	[SyncAction] [varchar] (1) COLLATE Latin1_General_CI_AS NULL,
	[ImportRow] [xml] NULL,
	CONSTRAINT [PK_ImportLoadRow] PRIMARY KEY CLUSTERED
	(
		[ImportLoadRowId] ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE TABLE [dbo].[ImportMappingRevision]
(
	[MappingRevisionId] [int] IDENTITY (1,1) NOT NULL,
	[MappingTypeId] [int] NULL,
	[ImportId] [smallint] NULL,
	[RevisionName] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
	[CreatedDateTime] [datetime] NULL,
	[CreatedBy] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
	CONSTRAINT [PK_ImportMappingRevision] PRIMARY KEY CLUSTERED
	(
		[MappingRevisionId] ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[ImportMapping]
(
	[MappingId] [bigint] IDENTITY (1,1) NOT NULL,
	[MappingRevisionId] [int] NULL,
	[SourceField] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
	[ImportDestinationId] [int] NULL,
	CONSTRAINT [PK_ImportMapping] PRIMARY KEY CLUSTERED
	(
		[MappingId] ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[ImportDigblockPolygonLoad]
(
	[Digblock_Id] [varchar] (31) COLLATE Latin1_General_CI_AS NOT NULL,
	[Order_No] [int] NOT NULL,
	[X] [float] NOT NULL,
	[Y] [float] NOT NULL,
	[Z] [float] NOT NULL
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[ImportDestination]
(
	[ImportDestinationId] [int] IDENTITY (1,1) NOT NULL,
	[MappingTypeId] [int] NULL,
	[DestinationField] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
	[DataType] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
	[IsGradeField] [bit] NULL,
	[IsPrimaryKey] [bit] NULL,
	[DisplayOrder] [int] NULL,
	[Description] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
	CONSTRAINT [PK_ImportDestination] PRIMARY KEY CLUSTERED
	(
		[ImportDestinationId] ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[ImportMappingType]
(
	[MappingTypeId] [int] IDENTITY (1,1) NOT NULL,
	[TypeName] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
	[PrimaryHoldingTable] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
	[GradeHoldingTable] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
	CONSTRAINT [PK_ImportMappingType] PRIMARY KEY CLUSTERED
	(
		[MappingTypeId] ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[ImportMappingTypeImport]
(
	[ImportId] [smallint] NOT NULL,
	[MappingTypeId] [int] NOT NULL,
	CONSTRAINT [PK_ImportMappingTypeImport] PRIMARY KEY CLUSTERED
	(
		[ImportId] ASC,
		[MappingTypeId] ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[ImportSimpleNotification]
(
	[ImportSimpleNotificationId] [int] IDENTITY (1,1) NOT NULL,
	[SimpleNotificationId] [int] NOT NULL,
	[ImportId] [int] NOT NULL,
	[HoursSince] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
	[ReminderHours] [varchar] (100) COLLATE Latin1_General_CI_AS NOT NULL,
	[ImportState] [int] NOT NULL
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[InvalidMovementType]
(
	[InvalidMovementTypeId] [int] IDENTITY (1,1) NOT NULL,
	[Description] [varchar] (50) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsSourceType] [bit] NOT NULL,
	[IsDestinationType] [bit] NOT NULL,
	CONSTRAINT [PK__INVALID_MOVEMENT_TYPE] PRIMARY KEY CLUSTERED
	(
		[InvalidMovementTypeId] ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[StockpileBalanceRawGrade]
(
	[StockpileBalanceRawGradeId] [bigint] IDENTITY (1,1) NOT NULL,
	[StockpileBalanceRawId] [bigint] NOT NULL,
	[GradeId] [smallint] NOT NULL,
	[GradeValue] [decimal] (18,2) NOT NULL,
	CONSTRAINT [PK_StockpileBalanceRawGrade] PRIMARY KEY CLUSTERED
	(
		[StockpileBalanceRawGradeId] ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_StockpileBalanceRawGrade_IdGradeId] ON [dbo].[StockpileBalanceRawGrade]
(
	[StockpileBalanceRawId] ASC,
	[GradeId] ASC
) INCLUDE ([GradeValue],[StockpileBalanceRawGradeId]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO


CREATE TABLE [dbo].[InvalidMovementDefinition]
(
	[InvalidMovementDefinitionId] [int] IDENTITY (1,1) NOT NULL,
	[DefinitionName] [varchar] (100) COLLATE Latin1_General_CI_AS NOT NULL,
	[SourceTypeId] [int] NOT NULL,
	[SourceDescription] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
	[DestinationTypeId] [int] NOT NULL,
	[DestinationDescription] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
	[SourceMaterialTypeId] [int] NULL,
	[SourceStockpileId] [int] NULL,
	[SourceStockpileGroupId] [varchar] (31) COLLATE Latin1_General_CI_AS NULL,
	[DestinationMaterialTypeId] [int] NULL,
	[DestinationStockpileId] [int] NULL,
	[DestinationStockpileGroupId] [varchar] (31) COLLATE Latin1_General_CI_AS NULL,
	[DestinationCrusherId] [varchar] (31) COLLATE Latin1_General_CI_AS NULL,
	[DestinationMillId] [varchar] (31) COLLATE Latin1_General_CI_AS NULL,
	CONSTRAINT [PK__INVALID_MOVEMENT_DEFINITION] PRIMARY KEY CLUSTERED
	(
		[InvalidMovementDefinitionId] ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
	CONSTRAINT [UC_DEFINITION_NAME] UNIQUE NONCLUSTERED
	(
		[DefinitionName] ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SimpleNotificationQueue]
(
	[SimpleNotificationQueueId] [int] IDENTITY (1,1) NOT NULL,
	[SimpleNotificationId] [int] NOT NULL,
	[DateAdded] [datetime] NOT NULL,
	[Message] [varchar] (2000) COLLATE Latin1_General_CI_AS NOT NULL,
	[Subject] [varchar] (100) COLLATE Latin1_General_CI_AS NOT NULL
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SimpleNotification]
(
	[SimpleNotificationId] [int] IDENTITY (1,1) NOT NULL,
	[TypeId] [int] NOT NULL,
	[Name] [varchar] (1023) COLLATE Latin1_General_CI_AS NOT NULL,
	[LastEmailSent] [datetime] NULL,
	[AllowMultipleEntries] [bit] NOT NULL
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SimpleNotificationRecipient]
(
	[SimpleNotificationRecipientId] [int] IDENTITY (1,1) NOT NULL,
	[SimpleNotificationId] [int] NULL,
	[ImportSimpleNotificationId] [int] NOT NULL,
	[UserId] [int] NULL,
	[Email] [varchar] (100) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[ParcelGrade]
(
	[Parcel_Grade_Id] [bigint] NOT NULL,
	[Grade_Id] [smallint] NOT NULL,
	[Grade_Value] [float] NOT NULL,
	CONSTRAINT [PK_PARCEL_GRADE] PRIMARY KEY CLUSTERED
	(
		[Parcel_Grade_Id] ASC,
		[Grade_Id] ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

GRANT ALTER, INSERT, DELETE, SELECT ON dbo.[ParcelGrade] TO RecalcDirect
GO

CREATE TABLE [dbo].[StockpileBalanceRaw]
(
	[StockpileBalanceRawId] [bigint] IDENTITY (1,1) NOT NULL,
	[StockpileId] [int] NOT NULL,
	[BuildId] [int] NOT NULL,
	[ComponentId] [int] NOT NULL,
	[Date] [datetime] NOT NULL,
	[Shift] [char] (1) COLLATE Latin1_General_CI_AS NOT NULL,
	[Tonnes] [decimal] (18,2) NOT NULL,
	CONSTRAINT [PK_StockpileBalanceRaw] PRIMARY KEY CLUSTERED
	(
		[StockpileBalanceRawId] ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_StockpileBalanceRaw_DateShift] ON [dbo].[StockpileBalanceRaw]
(
	[Date] ASC,
	[Shift] ASC
) INCLUDE ([ComponentId],[Tonnes],[BuildId],[StockpileBalanceRawId],[StockpileId]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE TABLE [dbo].[DataProcessTransactionParcel]
(
	[Data_Process_Transaction_Parcel_Id] [bigint] IDENTITY (1,1) NOT NULL,
	[Data_Process_Transaction_Id] [bigint] NOT NULL,
	[Parcel_Grade_Id] [bigint] NOT NULL,
	[Source_Digblock_Id] [varchar] (31) COLLATE Latin1_General_CI_AS NULL,
	[Tonnes] [float] NOT NULL,
	CONSTRAINT [PK_DATA_PROCESS_TRANSACTION_PARCEL] PRIMARY KEY CLUSTERED
	(
		[Data_Process_Transaction_Parcel_Id] ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_DataProcessTransactionParcel] ON [dbo].[DataProcessTransactionParcel]
(
	[Parcel_Grade_Id] ASC
) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_DataProcessTransactionParcel2] ON [dbo].[DataProcessTransactionParcel]
(
	[Data_Process_Transaction_Id] ASC
) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_DataProcessTransactionParcel3] ON [dbo].[DataProcessTransactionParcel]
(
	[Source_Digblock_Id] ASC
) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

GRANT ALTER, INSERT, DELETE, SELECT ON dbo.[DataProcessTransactionParcel] TO RecalcDirect
GO

CREATE TABLE [dbo].[DataProcessStockpileBalanceParcel]
(
	[Data_Process_Stockpile_Balance_Parcel_Id] [bigint] IDENTITY (1,1) NOT NULL,
	[Data_Process_Stockpile_Balance_Id] [bigint] NOT NULL,
	[Parcel_Grade_Id] [bigint] NOT NULL,
	[Source_Digblock_Id] [varchar] (31) COLLATE Latin1_General_CI_AS NULL,
	[Tonnes] [float] NOT NULL,
	[Added_To_Stockpile_Date] [datetime] NULL,
	[Added_To_Stockpile_Shift] [char] (1) COLLATE Latin1_General_CI_AS NULL,
	CONSTRAINT [PK_DATA_PROCESS_STOCKPILE_BALANCE_PARCEL] PRIMARY KEY CLUSTERED
	(
		[Data_Process_Stockpile_Balance_Parcel_Id] ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_DataProcessStockpileBalanceParcel] ON [dbo].[DataProcessStockpileBalanceParcel]
(
	[Parcel_Grade_Id] ASC
) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_DataProcessStockpileBalanceParcel2] ON [dbo].[DataProcessStockpileBalanceParcel]
(
	[Data_Process_Stockpile_Balance_Id] ASC
) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_DataProcessStockpileBalanceParcel3] ON [dbo].[DataProcessStockpileBalanceParcel]
(
	[Data_Process_Stockpile_Balance_Id] ASC,
	[Parcel_Grade_Id] ASC
) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

GRANT ALTER, INSERT, DELETE, SELECT ON dbo.[DataProcessStockpileBalanceParcel] TO RecalcDirect
GO

CREATE TABLE [dbo].[BhpbioDefaultLumpFines]
(
	[BhpbioDefaultLumpFinesId] [int] IDENTITY (1,1) NOT NULL,
	[LocationId] [int] NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[LumpPercent] [decimal] (5,4) NOT NULL,
	[IsNonDeletable] [bit] NOT NULL CONSTRAINT [DF__BhpbioDef__IsNon__33208881] DEFAULT ((0)),
	CONSTRAINT [PK_BhpbioDefaultLumpFines] PRIMARY KEY CLUSTERED
	(
		[BhpbioDefaultLumpFinesId] ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[TempTruckTypeFactorPeriod]
(
	[Truck_Type_Id] [int] NOT NULL,
	[End_Date] [datetime] NULL,
	[Max_Tonnes] [real] NOT NULL,
	[Ave_Tonnes] [real] NOT NULL,
	[Min_Tonnes] [real] NOT NULL,
	[Max_Volume] [real] NOT NULL,
	[Ave_Volume] [real] NOT NULL,
	[Min_Volume] [real] NOT NULL

) ON [PRIMARY]
GO

INSERT INTO [dbo].[TempTruckTypeFactorPeriod] ([Truck_Type_Id],[End_Date],[Max_Tonnes],[Ave_Tonnes],[Min_Tonnes],[Max_Volume],[Ave_Volume],[Min_Volume]) SELECT [Truck_Type_Id],[End_Date],[Max_Tonnes],[Ave_Tonnes],[Min_Tonnes],0.0,0.0,0.0 FROM [dbo].[TruckTypeFactorPeriod]
DROP TABLE [dbo].[TruckTypeFactorPeriod]
GO
EXEC sp_rename N'[dbo].[TempTruckTypeFactorPeriod]',N'TruckTypeFactorPeriod', 'OBJECT'
GO


CREATE TABLE [dbo].[TempNotificationInstanceNegativeStockpile]
(
	[InstanceId] [int] NOT NULL,
	[StockpileSelectionType] [varchar] (31) COLLATE Latin1_General_CI_AS NOT NULL,
	[StockpileId] [int] NULL,
	[StockpileGroupId] [varchar] (31) COLLATE Latin1_General_CI_AS NULL,
	[LocationId] [int] NULL

) ON [PRIMARY]
GO

INSERT INTO [dbo].[TempNotificationInstanceNegativeStockpile] ([InstanceId],[StockpileId],[StockpileGroupId],[LocationId],[StockpileSelectionType]) SELECT [InstanceId],[StockpileId],[StockpileGroupId],[LocationId],[StockpileSelectionType] FROM [dbo].[NotificationInstanceNegativeStockpile]
DROP TABLE [dbo].[NotificationInstanceNegativeStockpile]
GO
EXEC sp_rename N'[dbo].[TempNotificationInstanceNegativeStockpile]',N'NotificationInstanceNegativeStockpile', 'OBJECT'
GO


CREATE NONCLUSTERED INDEX [IX_NotificationInstanceNegativeStockpile_Lookup] ON [dbo].[NotificationInstanceNegativeStockpile]
(
	[StockpileId] ASC,
	[InstanceId] ASC,
	[StockpileGroupId] ASC
) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [IX_DATA_PROCESS_STOCKPILE_BALANCE__DATE_STOCKPILE_BUILD] ON [dbo].[DataProcessStockpileBalance]
(
	[Data_Process_Stockpile_Balance_Date] ASC,
	[Stockpile_Id] ASC,
	[Build_Id] ASC
) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Digblock_XYZ] ON [dbo].[Digblock]
(
	[X] ASC,
	[Y] ASC,
	[Z] ASC,
	[Digblock_Id] ASC
) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Location__Name] ON [dbo].[Location]
(
	[Name] ASC
) INCLUDE ([Location_Type_Id],[Location_Id]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[NotificationInstanceNegativeStockpile] ADD CONSTRAINT [CK_StockpileSelectionType] CHECK  (([StockpileSelectionType]='SpecificStockpileGroup' OR [StockpileSelectionType]='SpecificStockpile' OR [StockpileSelectionType]='UngroupedStockpiles' OR [StockpileSelectionType]='AllStockpiles'))
GO
ALTER TABLE [dbo].[BhpbioSummary] ADD CONSTRAINT [UQ_BhpbioSummary_SummaryMonth] UNIQUE NONCLUSTERED
	(
		[SummaryMonth] ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[NotificationInstanceNegativeStockpile] ADD CONSTRAINT [PK_NotificationInstanceNegativeStockpile] PRIMARY KEY CLUSTERED
	(
		[InstanceId] ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BhpbioDefaultLumpFines] ADD CONSTRAINT [FK_BhpbioDefaultLumpFines_Location] FOREIGN KEY
	(
		[LocationId]
	)
	REFERENCES [dbo].[Location]
	(
		[Location_Id]
	)
GO

ALTER TABLE [dbo].[ImportMappingRevision] ADD CONSTRAINT [FK_ImportMappingRevision_ImportId] FOREIGN KEY
	(
		[ImportId]
	)
	REFERENCES [dbo].[Import]
	(
		[ImportId]
	)
GO

ALTER TABLE [dbo].[ImportMappingRevision] ADD CONSTRAINT [FK_ImportMappingRevision_MappingTypeId] FOREIGN KEY
	(
		[MappingTypeId]
	)
	REFERENCES [dbo].[ImportMappingType]
	(
		[MappingTypeId]
	)
GO

ALTER TABLE [dbo].[ImportMappingTypeImport] ADD CONSTRAINT [FK_ImportMappingTypeImport_ImportId] FOREIGN KEY
	(
		[ImportId]
	)
	REFERENCES [dbo].[Import]
	(
		[ImportId]
	)
GO

ALTER TABLE [dbo].[ImportMappingTypeImport] ADD CONSTRAINT [FK_ImportMappingTypeImport_MappingTypeId] FOREIGN KEY
	(
		[MappingTypeId]
	)
	REFERENCES [dbo].[ImportMappingType]
	(
		[MappingTypeId]
	)
GO

ALTER TABLE [dbo].[ImportDestination] ADD CONSTRAINT [FK_ImportDestination_ImportMappingType] FOREIGN KEY
	(
		[MappingTypeId]
	)
	REFERENCES [dbo].[ImportMappingType]
	(
		[MappingTypeId]
	)
GO

ALTER TABLE [dbo].[ImportAutoQueueProfile] ADD CONSTRAINT [FK_ImportAutoQueueProfile_ImportId] FOREIGN KEY
	(
		[ImportId]
	)
	REFERENCES [dbo].[Import]
	(
		[ImportId]
	) ON DELETE CASCADE
GO

ALTER TABLE [dbo].[DataProcessStockpileBalanceParcel] ADD CONSTRAINT [FK__DATA_PROCESS_STOCKPILE_BALANCE_PARCEL__DATA_PROCESS_STOCKPILE_BALANCE] FOREIGN KEY
	(
		[Data_Process_Stockpile_Balance_Id]
	)
	REFERENCES [dbo].[DataProcessStockpileBalance]
	(
		[Data_Process_Stockpile_Balance_Id]
	)
GO

ALTER TABLE [dbo].[ImportMapping] ADD CONSTRAINT [FK_ImportMapping_ImportDestination] FOREIGN KEY
	(
		[ImportDestinationId]
	)
	REFERENCES [dbo].[ImportDestination]
	(
		[ImportDestinationId]
	)
GO

ALTER TABLE [dbo].[ImportMapping] ADD CONSTRAINT [FK_ImportMapping_ImportMappingRevision] FOREIGN KEY
	(
		[MappingRevisionId]
	)
	REFERENCES [dbo].[ImportMappingRevision]
	(
		[MappingRevisionId]
	)
GO

ALTER TABLE [dbo].[DataProcessTransactionParcel] ADD CONSTRAINT [FK__DATA_PROCESS_TRANSACTION_PARCEL__DATA_PROCESS_TRANSACTION] FOREIGN KEY
	(
		[Data_Process_Transaction_Id]
	)
	REFERENCES [dbo].[DataProcessTransaction]
	(
		[Data_Process_Transaction_Id]
	)
GO

ALTER TABLE [dbo].[InvalidMovementDefinition] ADD CONSTRAINT [FK__INVALID_MOVEMENT_DEFINITION__DESTINATION_MATERIAL_TYPE] FOREIGN KEY
	(
		[DestinationMaterialTypeId]
	)
	REFERENCES [dbo].[MaterialType]
	(
		[Material_Type_Id]
	)
GO

ALTER TABLE [dbo].[InvalidMovementDefinition] ADD CONSTRAINT [FK__INVALID_MOVEMENT_DEFINITION__DESTINATION_STOCKPILE] FOREIGN KEY
	(
		[DestinationStockpileId]
	)
	REFERENCES [dbo].[Stockpile]
	(
		[Stockpile_Id]
	)
GO

ALTER TABLE [dbo].[InvalidMovementDefinition] ADD CONSTRAINT [FK__INVALID_MOVEMENT_DEFINITION__DESTINATION_STOCKPILE_GROUP] FOREIGN KEY
	(
		[DestinationStockpileGroupId]
	)
	REFERENCES [dbo].[StockpileGroup]
	(
		[Stockpile_Group_Id]
	)
GO

ALTER TABLE [dbo].[InvalidMovementDefinition] ADD CONSTRAINT [FK__INVALID_MOVEMENT_DEFINITION__DESTINATION_TYPE] FOREIGN KEY
	(
		[DestinationTypeId]
	)
	REFERENCES [dbo].[InvalidMovementType]
	(
		[InvalidMovementTypeId]
	)
GO

ALTER TABLE [dbo].[InvalidMovementDefinition] ADD CONSTRAINT [FK__INVALID_MOVEMENT_DEFINITION__SOURCE_MATERIAL_TYPE] FOREIGN KEY
	(
		[SourceMaterialTypeId]
	)
	REFERENCES [dbo].[MaterialType]
	(
		[Material_Type_Id]
	)
GO

ALTER TABLE [dbo].[InvalidMovementDefinition] ADD CONSTRAINT [FK__INVALID_MOVEMENT_DEFINITION__SOURCE_STOCKPILE] FOREIGN KEY
	(
		[SourceStockpileId]
	)
	REFERENCES [dbo].[Stockpile]
	(
		[Stockpile_Id]
	)
GO

ALTER TABLE [dbo].[InvalidMovementDefinition] ADD CONSTRAINT [FK__INVALID_MOVEMENT_DEFINITION__SOURCE_STOCKPILE_GROUP] FOREIGN KEY
	(
		[SourceStockpileGroupId]
	)
	REFERENCES [dbo].[StockpileGroup]
	(
		[Stockpile_Group_Id]
	)
GO

ALTER TABLE [dbo].[InvalidMovementDefinition] ADD CONSTRAINT [FK__INVALID_MOVEMENT_DEFINITION__SOURCE_TYPE] FOREIGN KEY
	(
		[SourceTypeId]
	)
	REFERENCES [dbo].[InvalidMovementType]
	(
		[InvalidMovementTypeId]
	)
GO

ALTER TABLE [dbo].[ParcelGrade] ADD CONSTRAINT [FK__PARCEL_GRADE__GRADE] FOREIGN KEY
	(
		[Grade_Id]
	)
	REFERENCES [dbo].[Grade]
	(
		[Grade_Id]
	)
GO

ALTER TABLE [dbo].[StockpileBalanceRawGrade] ADD CONSTRAINT [FK_StockpileBalanceRawGrade_Grade] FOREIGN KEY
	(
		[GradeId]
	)
	REFERENCES [dbo].[Grade]
	(
		[Grade_Id]
	)
GO

ALTER TABLE [dbo].[StockpileBalanceRawGrade] ADD CONSTRAINT [FK_StockpileBalanceRawGrade_StockpileBalanceRaw] FOREIGN KEY
	(
		[StockpileBalanceRawId]
	)
	REFERENCES [dbo].[StockpileBalanceRaw]
	(
		[StockpileBalanceRawId]
	)
GO

ALTER TABLE [dbo].[StockpileBalanceRaw] ADD CONSTRAINT [FK_StockpileBalanceRaw_ShiftType] FOREIGN KEY
	(
		[Shift]
	)
	REFERENCES [dbo].[ShiftType]
	(
		[Shift]
	)
GO

ALTER TABLE [dbo].[StockpileBalanceRaw] ADD CONSTRAINT [FK_StockpileBalanceRaw_Stockpile] FOREIGN KEY
	(
		[StockpileId]
	)
	REFERENCES [dbo].[Stockpile]
	(
		[Stockpile_Id]
	)
GO

ALTER TABLE [dbo].[StockpileBalanceRaw] ADD CONSTRAINT [FK_StockpileBalanceRaw_StockpileBuild] FOREIGN KEY
	(
		[StockpileId],
		[BuildId]
	)
	REFERENCES [dbo].[StockpileBuild]
	(
		[Stockpile_Id],
		[Build_Id]
	)
GO

ALTER TABLE [dbo].[StockpileBalanceRaw] ADD CONSTRAINT [FK_StockpileBalanceRaw_StockpileBuildComponent] FOREIGN KEY
	(
		[StockpileId],
		[BuildId],
		[ComponentId]
	)
	REFERENCES [dbo].[StockpileBuildComponent]
	(
		[Stockpile_Id],
		[Build_Id],
		[Component_Id]
	)
GO

ALTER TABLE [dbo].[BhpbioBlastBlockPointHolding] ADD CONSTRAINT [FK_BhpbioBlastBlockPointHolding_BhpbioBlastBlockHolding] FOREIGN KEY
	(
		[BlockID]
	)
	REFERENCES [dbo].[BhpbioBlastBlockHolding]
	(
		[BlockId]
	)
GO
ALTER TABLE [dbo].[BhpbioBlastBlockModelGradeHolding] ADD CONSTRAINT [FK_BhpbioBlastBlockModelGradeHolding_BhpbioBlastBlockModelHolding] FOREIGN KEY
	(
		[BlockId],
		[ModelName],
		[ModelOreType]
	)
	REFERENCES [dbo].[BhpbioBlastBlockModelHolding]
	(
		[BlockId],
		[ModelName],
		[ModelOreType]
	)
GO
ALTER TABLE [dbo].[NotificationInstanceNegativeStockpile] ADD CONSTRAINT [FK_NotificationInstanceNegativeStockpile_Location] FOREIGN KEY
	(
		[LocationId]
	)
	REFERENCES [dbo].[Location]
	(
		[Location_Id]
	)
GO
ALTER TABLE [dbo].[TruckTypeFactorPeriod] ADD CONSTRAINT [FK__TRUCK_TYPE_FACTOR_PERIOD__TRUCK_TYPE] FOREIGN KEY
	(
		[Truck_Type_Id]
	)
	REFERENCES [dbo].[TruckType]
	(
		[Truck_Type_Id]
	)
GO
ALTER TABLE [dbo].[NotificationInstanceNegativeStockpile] ADD CONSTRAINT [FK_NotificationInstanceNegativeStockpile_StockpileGroup] FOREIGN KEY
	(
		[StockpileGroupId]
	)
	REFERENCES [dbo].[StockpileGroup]
	(
		[Stockpile_Group_Id]
	)
GO
ALTER TABLE [dbo].[NotificationInstanceNegativeStockpile] ADD CONSTRAINT [FK_NotificationInstanceNegativeStockpile_NotificationInstance] FOREIGN KEY
	(
		[InstanceId]
	)
	REFERENCES [dbo].[NotificationInstance]
	(
		[InstanceId]
	)
GO
ALTER TABLE [dbo].[NotificationInstanceNegativeStockpile] ADD CONSTRAINT [FK_NotificationInstanceNegativeStockpile_Stockpile] FOREIGN KEY
	(
		[StockpileId]
	)
	REFERENCES [dbo].[Stockpile]
	(
		[Stockpile_Id]
	)
GO
ALTER TABLE [dbo].[MinePlan] ADD CONSTRAINT [FK_MINEPLAN__LOCATION] FOREIGN KEY
	(
		[Parent_Location_Id]
	)
	REFERENCES [dbo].[Location]
	(
		[Location_Id]
	)
GO
ALTER TABLE [dbo].[DigblockSurvey] ADD CONSTRAINT [FK_DIGBLOCK_SURVEY_LOCATION] FOREIGN KEY
	(
		[Parent_Location_Id]
	)
	REFERENCES [dbo].[Location]
	(
		[Location_Id]
	)
GO
ALTER TABLE [dbo].[BhpbioBlastBlockModelHolding] ADD CONSTRAINT [FK_BhpbioBlastBlockModelHolding_BhpbioBlastBlockHolding] FOREIGN KEY
	(
		[BlockId]
	)
	REFERENCES [dbo].[BhpbioBlastBlockHolding]
	(
		[BlockId]
	)
GO
ALTER TABLE [dbo].[Import] ADD CONSTRAINT [FK_Import_ImportConflictType] FOREIGN KEY
	(
		[ImportConflictTypeId]
	)
	REFERENCES [dbo].[ImportConflictType]
	(
		[ImportConflictTypeId]
	)
GO
ALTER TABLE [dbo].[BlockModel] ADD CONSTRAINT [FK_BlockModel__Location] FOREIGN KEY
	(
		[Parent_Location_Id]
	)
	REFERENCES [dbo].[Location]
	(
		[Location_Id]
	)
GO


-- BASIC REFERENCE DATA
Insert Into dbo.Setting
(
	Setting_Id, Description, Data_Type, Is_User_Editable, Value, Acceptable_Values
)
SELECT 'DIGBLOCK_START_SHIFT_TOLERANCE', 'How many shifts after the end date can haulage actually occur', 'INTEGER', 0, '0', NULL UNION ALL
SELECT 'DIGBLOCK_END_SHIFT_TOLERANCE', 'How many shifts before the start date can haulage actually occur', 'INTEGER', 0, '2', NULL UNION ALL
SELECT 'DEFAULT_CULTUREINFO', 'The default CultureInfo for system users', 'STRING', 0, 'en-AU', 'en-AU,pt-BR' UNION ALL
SELECT 'MINIMUM_PARCEL_TONNES', 'The minimum tonnes allowable for a parcel', 'INT', 0, '1', NULL UNION ALL
SELECT 'CALENDAR_MIN_DATE', 'Minimum year appearing in calendar dialog', 'INTEGER', 1, '2009' ,NULL UNION ALL
SELECT 'CALENDAR_MAX_DATE', 'Maximum year appearing in calendar dialog', 'INTEGER', 1, '2030', NULL UNION ALL
SELECT 'IS_LOCATION_MANDATORY_FOR_DIGBLOCK', 'Determines whether location must be provided when adding or editing a digblock', 'BOOLEAN', 0, 'FALSE', 'TRUE,FALSE' UNION ALL
SELECT 'VARIANCE_PERCENTAGE_F', 'Spatial comparison variance percentage for cutoff F', 'REAL', 0, '-5', NULL UNION ALL
SELECT 'VARIANCE_COLOUR_F', 'Spatial comparison variance colour for cutoff F', 'STRING', 0, 'Aqua', NULL UNION ALL
SELECT 'VARIANCE_PERCENTAGE_G', 'Spatial comparison variance percentage for cutoff G', 'REAL', 0, '-10', NULL UNION ALL
SELECT 'VARIANCE_COLOUR_G', 'Spatial comparison variance colour for cutoff G', 'STRING', 0, 'DarkCyan', NULL UNION ALL
SELECT 'VARIANCE_PERCENTAGE_H', 'Spatial comparison variance percentage for cutoff H', 'REAL', 0, '-15', NULL UNION ALL
SELECT 'VARIANCE_COLOUR_H', 'Spatial comparison variance colour for cutoff H', 'STRING', 0, 'SlateBlue', NULL UNION ALL
SELECT 'VARIANCE_PERCENTAGE_I', 'Spatial comparison variance percentage for cutoff I', 'REAL', 0, '-20', NULL UNION ALL
SELECT 'VARIANCE_COLOUR_I', 'Spatial comparison variance colour for cutoff I', 'STRING', 0, 'Blue', NULL UNION ALL
SELECT 'VARIANCE_PERCENTAGE_J', 'Spatial comparison variance percentage for cutoff J', 'REAL', 0, '-25', NULL UNION ALL
SELECT 'VARIANCE_COLOUR_J', 'Spatial comparison variance colour for cutoff J', 'STRING', 0, 'DarkBlue', NULL UNION ALL
SELECT 'HAULAGE_SOURCE_STOCKPILE_GROUP', 'If set, stockpiles in this group will be used to populate the source stockpile list in the Haulage management screen','STRING', 1, '', NULL UNION ALL
SELECT 'HAULAGE_DESTINATION_STOCKPILE_GROUP', 'If set, stockpiles in this group will be used to populate the destination stockpile list in the Haulage management screen','STRING', 1, '', NULL UNION ALL
SELECT 'CALCULATE_RAW_BALANCES', 'Calculate raw stockpile balances', 'BOOLEAN', 0, 'FALSE', 'TRUE,FALSE'
Go