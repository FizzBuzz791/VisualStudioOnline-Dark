IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'DataSeries')
BEGIN
    -- Have to use 'exec' or the query fails
    EXEC( 'CREATE SCHEMA DataSeries' );
	EXEC( 'ALTER AUTHORIZATION ON SCHEMA::DataSeries TO [dbo]' );
END
Go

GO
PRINT N'Creating [DataSeries].[SeriesQueueEntry]...';


GO
CREATE TABLE [DataSeries].[SeriesQueueEntry] (
    [Id]                       BIGINT        IDENTITY (1, 1) NOT NULL,
    [SeriesQueueEntryTypeId]   INT           NOT NULL,
    [SeriesTypeGroupId]        VARCHAR (100) NOT NULL,
    [SeriesPointOrdinal]       BIGINT        NOT NULL,
    [ProcessedDateTime]        DATETIME      NULL,
    [AddedDateTime]            DATETIME      NOT NULL,
    [SeriesQueueEntryStatusId] INT           NOT NULL,
    CONSTRAINT [PK_SeriesQueueEntry] PRIMARY KEY CLUSTERED ([Id] ASC) ON [PRIMARY]
) ON [PRIMARY];


GO
PRINT N'Creating [DataSeries].[SeriesQueueEntryStatus]...';


GO
CREATE TABLE [DataSeries].[SeriesQueueEntryStatus] (
    [Id]          INT           NOT NULL,
    [Name]        NVARCHAR (50) NOT NULL,
    [IsPending]   BIT           NOT NULL,
    [IsCancelled] BIT           NOT NULL,
    [IsProcessed] BIT           NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
PRINT N'Creating [DataSeries].[SeriesPoint]...';


GO
CREATE TABLE [DataSeries].[SeriesPoint] (
    [SeriesId] INT        NOT NULL,
    [Ordinal]  BIGINT     NOT NULL,
    [Value]    FLOAT (53) NULL,
    CONSTRAINT [PK_SeriesPoint] PRIMARY KEY CLUSTERED ([SeriesId] ASC, [Ordinal] ASC) ON [PRIMARY]
) ON [PRIMARY];


GO
PRINT N'Creating [DataSeries].[SeriesTypeAttribute]...';


GO
CREATE TABLE [DataSeries].[SeriesTypeAttribute] (
    [SeriesTypeId]  VARCHAR (100) NOT NULL,
    [Name]          VARCHAR (100) NOT NULL,
    [StringValue]   VARCHAR (250) NULL,
    [IntegerValue]  INT           NULL,
    [BooleanValue]  BIT           NULL,
    [DateTimeValue] DATETIME      NULL,
    [DoubleValue]   FLOAT (53)    NULL,
    CONSTRAINT [PK_SeriesTypeAttribute] PRIMARY KEY CLUSTERED ([SeriesTypeId] ASC, [Name] ASC) ON [PRIMARY]
) ON [PRIMARY];


GO
PRINT N'Creating [DataSeries].[SeriesTypeGroup]...';


GO
CREATE TABLE [DataSeries].[SeriesTypeGroup] (
    [Id]         VARCHAR (100) NOT NULL,
    [Name]       VARCHAR (100) NOT NULL,
    [ContextKey] VARCHAR (100) NULL,
    CONSTRAINT [PK_SeriesTypeGroup] PRIMARY KEY CLUSTERED ([Id] ASC) ON [PRIMARY]
) ON [PRIMARY];


GO
PRINT N'Creating [DataSeries].[SeriesTypeGroupMembership]...';


GO
CREATE TABLE [DataSeries].[SeriesTypeGroupMembership] (
    [SeriesTypeId]      VARCHAR (100) NOT NULL,
    [SeriesTypeGroupId] VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_SeriesTypeAnalysisGroup] PRIMARY KEY CLUSTERED ([SeriesTypeId] ASC, [SeriesTypeGroupId] ASC) ON [PRIMARY]
) ON [PRIMARY];


GO
PRINT N'Creating [DataSeries].[SeriesAttribute]...';


GO
CREATE TABLE [DataSeries].[SeriesAttribute] (
    [SeriesId]      INT           NOT NULL,
    [Name]          VARCHAR (100) NOT NULL,
    [StringValue]   VARCHAR (250) NULL,
    [IntegerValue]  INT           NULL,
    [BooleanValue]  BIT           NULL,
    [DateTimeValue] DATETIME      NULL,
    [DoubleValue]   FLOAT (53)    NULL,
    CONSTRAINT [PK_SeriesAttribute] PRIMARY KEY CLUSTERED ([SeriesId] ASC, [Name] ASC) ON [PRIMARY]
) ON [PRIMARY];


GO
PRINT N'Creating [DataSeries].[SeriesType]...';


GO
CREATE TABLE [DataSeries].[SeriesType] (
    [Id]          VARCHAR (100) NOT NULL,
    [Name]        VARCHAR (100) NULL,
    [IsDependant] BIT           NOT NULL,
    [IsActive]    BIT           NOT NULL,
    CONSTRAINT [PK_SeriesType] PRIMARY KEY CLUSTERED ([Id] ASC) ON [PRIMARY]
) ON [PRIMARY];


GO
PRINT N'Creating [DataSeries].[Series]...';


GO
CREATE TABLE [DataSeries].[Series] (
    [Id]                     INT           IDENTITY (1, 1) NOT NULL,
    [SeriesKey]              VARCHAR (100) NOT NULL,
    [SeriesTypeId]           VARCHAR (100) NOT NULL,
    [PrimaryRelatedSeriesId] INT           NULL,
    CONSTRAINT [PK_Series] PRIMARY KEY CLUSTERED ([Id] ASC) ON [PRIMARY]
) ON [PRIMARY];


GO
PRINT N'Creating [DataSeries].[SeriesQueueEntryTrigger]...';


GO
CREATE TABLE [DataSeries].[SeriesQueueEntryTrigger] (
    [Id]                       INT           IDENTITY (1, 1) NOT NULL,
    [TriggerQueueEntryTypeId]  INT           NOT NULL,
    [TriggerSeriesTypeGroupId] VARCHAR (100) NULL,
    [RaiseQueueEntryTypeId]    INT           NOT NULL,
    [RaiseSeriesTypeGroupId]   VARCHAR (100) NULL,
    [OrdinalOffset]            BIGINT        NOT NULL,
    CONSTRAINT [PK_SeriesQueueEntryTrigger] PRIMARY KEY CLUSTERED ([Id] ASC) ON [PRIMARY]
);


GO
PRINT N'Creating [DataSeries].[SeriesQueueEntryType]...';


GO
CREATE TABLE [DataSeries].[SeriesQueueEntryType] (
    [Id]                          INT          NOT NULL,
    [Code]                        VARCHAR (50) NOT NULL,
    [Priority]                    INT          NOT NULL,
    [CausesAutomaticPointRemoval] BIT          NOT NULL,
    CONSTRAINT [PK_SeriesQueueEntryType] PRIMARY KEY CLUSTERED ([Id] ASC) ON [PRIMARY]
) ON [PRIMARY];


GO
PRINT N'Creating unnamed constraint on [DataSeries].[SeriesQueueEntryStatus]...';


GO
ALTER TABLE [DataSeries].[SeriesQueueEntryStatus]
    ADD DEFAULT 0 FOR [IsPending];


GO
PRINT N'Creating unnamed constraint on [DataSeries].[SeriesQueueEntryStatus]...';


GO
ALTER TABLE [DataSeries].[SeriesQueueEntryStatus]
    ADD DEFAULT 0 FOR [IsCancelled];


GO
PRINT N'Creating unnamed constraint on [DataSeries].[SeriesQueueEntryStatus]...';


GO
ALTER TABLE [DataSeries].[SeriesQueueEntryStatus]
    ADD DEFAULT 0 FOR [IsProcessed];


GO
PRINT N'Creating unnamed constraint on [DataSeries].[SeriesType]...';


GO
ALTER TABLE [DataSeries].[SeriesType]
    ADD DEFAULT (0) FOR [IsDependant];


GO
PRINT N'Creating unnamed constraint on [DataSeries].[SeriesType]...';


GO
ALTER TABLE [DataSeries].[SeriesType]
    ADD DEFAULT (0) FOR [IsActive];


GO
PRINT N'Creating unnamed constraint on [DataSeries].[SeriesQueueEntryType]...';


GO
ALTER TABLE [DataSeries].[SeriesQueueEntryType]
    ADD DEFAULT 0 FOR [CausesAutomaticPointRemoval];


GO
PRINT N'Creating [DataSeries].[FK_SeriesQueueEntry_SeriesQueueEntryStatus]...';


GO
ALTER TABLE [DataSeries].[SeriesQueueEntry] WITH NOCHECK
    ADD CONSTRAINT [FK_SeriesQueueEntry_SeriesQueueEntryStatus] FOREIGN KEY ([SeriesQueueEntryStatusId]) REFERENCES [DataSeries].[SeriesQueueEntryStatus] ([Id]);


GO
PRINT N'Creating [DataSeries].[FK_SeriesQueueEntry_SeriesQueueEntryType]...';


GO
ALTER TABLE [DataSeries].[SeriesQueueEntry] WITH NOCHECK
    ADD CONSTRAINT [FK_SeriesQueueEntry_SeriesQueueEntryType] FOREIGN KEY ([SeriesQueueEntryTypeId]) REFERENCES [DataSeries].[SeriesQueueEntryType] ([Id]);


GO
PRINT N'Creating [DataSeries].[FK_SeriesPoint_Series]...';


GO
ALTER TABLE [DataSeries].[SeriesPoint] WITH NOCHECK
    ADD CONSTRAINT [FK_SeriesPoint_Series] FOREIGN KEY ([SeriesId]) REFERENCES [DataSeries].[Series] ([Id]);


GO
PRINT N'Creating [DataSeries].[FK_SeriesTypeAttribute_SeriesType]...';


GO
ALTER TABLE [DataSeries].[SeriesTypeAttribute] WITH NOCHECK
    ADD CONSTRAINT [FK_SeriesTypeAttribute_SeriesType] FOREIGN KEY ([SeriesTypeId]) REFERENCES [DataSeries].[SeriesType] ([Id]);


GO
PRINT N'Creating [DataSeries].[FK_SeriesTypeGroupMembership_SeriesTypeGroup]...';


GO
ALTER TABLE [DataSeries].[SeriesTypeGroupMembership] WITH NOCHECK
    ADD CONSTRAINT [FK_SeriesTypeGroupMembership_SeriesTypeGroup] FOREIGN KEY ([SeriesTypeGroupId]) REFERENCES [DataSeries].[SeriesTypeGroup] ([Id]);


GO
PRINT N'Creating [DataSeries].[FK_SeriesTypeGroupMembership_SeriesType]...';


GO
ALTER TABLE [DataSeries].[SeriesTypeGroupMembership] WITH NOCHECK
    ADD CONSTRAINT [FK_SeriesTypeGroupMembership_SeriesType] FOREIGN KEY ([SeriesTypeId]) REFERENCES [DataSeries].[SeriesType] ([Id]);


GO
PRINT N'Creating [DataSeries].[FK_SeriesAttribute_Series]...';


GO
ALTER TABLE [DataSeries].[SeriesAttribute] WITH NOCHECK
    ADD CONSTRAINT [FK_SeriesAttribute_Series] FOREIGN KEY ([SeriesId]) REFERENCES [DataSeries].[Series] ([Id]);


GO
PRINT N'Creating [DataSeries].[FK_Series_Series]...';


GO
ALTER TABLE [DataSeries].[Series] WITH NOCHECK
    ADD CONSTRAINT [FK_Series_Series] FOREIGN KEY ([PrimaryRelatedSeriesId]) REFERENCES [DataSeries].[Series] ([Id]);


GO
PRINT N'Creating [DataSeries].[FK_SeriesQueueEntryTrigger_TriggerQueueEntryTypeId]...';


GO
ALTER TABLE [DataSeries].[SeriesQueueEntryTrigger] WITH NOCHECK
    ADD CONSTRAINT [FK_SeriesQueueEntryTrigger_TriggerQueueEntryTypeId] FOREIGN KEY ([TriggerQueueEntryTypeId]) REFERENCES [DataSeries].[SeriesQueueEntryType] ([Id]);


GO
PRINT N'Creating [DataSeries].[FK_SeriesQueueEntryTrigger_RaiseQueueEntryTypeId]...';


GO
ALTER TABLE [DataSeries].[SeriesQueueEntryTrigger] WITH NOCHECK
    ADD CONSTRAINT [FK_SeriesQueueEntryTrigger_RaiseQueueEntryTypeId] FOREIGN KEY ([RaiseQueueEntryTypeId]) REFERENCES [DataSeries].[SeriesQueueEntryType] ([Id]);


GO
PRINT N'Creating [DataSeries].[FK_SeriesQueueEntryTrigger_TriggerSeriesTypeGroupId]...';


GO
ALTER TABLE [DataSeries].[SeriesQueueEntryTrigger] WITH NOCHECK
    ADD CONSTRAINT [FK_SeriesQueueEntryTrigger_TriggerSeriesTypeGroupId] FOREIGN KEY ([TriggerSeriesTypeGroupId]) REFERENCES [DataSeries].[SeriesTypeGroup] ([Id]);


GO
PRINT N'Creating [DataSeries].[AddOrUpdateSeries]...';


GO
CREATE PROCEDURE [DataSeries].[AddOrUpdateSeries]
	@iId int,
	@iSeriesKey varchar(100),
	@iSeriesTypeId varchar(100),
	@iPrimaryRelatedSeriesId int,
	@oId Int Output
WITH ENCRYPTION
AS
BEGIN
	IF @iId IS NULL
	BEGIN
		SELECT @iId = Id FROM DataSeries.Series WHERE SeriesKey = @iSeriesKey
	END

	IF @iId IS NULL
	BEGIN
		INSERT INTO DataSeries.Series (SeriesKey, SeriesTypeId, PrimaryRelatedSeriesId)
		VALUES (@iSeriesKey, @iSeriesTypeId, @iPrimaryRelatedSeriesId)

		SET @oId = SCOPE_IDENTITY()
	END
	ELSE
	BEGIN
		SET @oId = @iId

		UPDATE DataSeries.Series
			SET SeriesKey = SeriesKey, SeriesTypeId  = SeriesTypeId, PrimaryRelatedSeriesId = @iPrimaryRelatedSeriesId
		WHERE Id = @iId
	END
END
GO

GRANT EXECUTE ON [DataSeries].[AddOrUpdateSeries] TO BhpbioGenericManager

GO
PRINT N'Creating [DataSeries].[AddOrUpdateSeriesAttribute]...';


GO
CREATE PROCEDURE [DataSeries].[AddOrUpdateSeriesAttribute]
	@iSeriesId int,
	@iName varchar(50),
	@iStringValue varchar(250),
	@iIntegerValue int,
	@iBooleanValue bit,
	@iDateTimeValue DATETIME,
	@iDoubleValue FLOAT
WITH ENCRYPTION
AS
BEGIN
	-- attempt an update
	UPDATE att
	SET att.StringValue = @iStringValue,
		att.IntegerValue = @iIntegerValue,
		att.BooleanValue = @iBooleanValue,
		att.DateTimeValue = @iDateTimeValue,
		att.DoubleValue = @iDoubleValue
	FROM DataSeries.SeriesAttribute as att
	WHERE att.SeriesId = @iSeriesId
		AND att.Name = @iName

	-- if the update effected no rowws
	IF @@ROWCOUNT = 0
	BEGIN
		INSERT INTO DataSeries.SeriesAttribute(SeriesId, Name, StringValue, IntegerValue, BooleanValue, DateTimeValue, DoubleValue)
		VALUES (@iSeriesId, @iName, @iStringValue, @iIntegerValue, @iBooleanValue, @iDateTimeValue, @iDoubleValue)
	END
END
GO

GRANT EXECUTE ON [DataSeries].[AddOrUpdateSeriesAttribute] TO BhpbioGenericManager

GO
PRINT N'Creating [DataSeries].[AddOrUpdateSeriesType]...';


GO
CREATE PROCEDURE [DataSeries].[AddOrUpdateSeriesType]
	@iId varchar(100),
	@iName varchar(100),
	@iIsDependant int,
	@iIsActive int
WITH ENCRYPTION
AS
BEGIN
	-- Check Existing
	DECLARE @existingId VARCHAR(100)
	
	SELECT @existingId = Id FROM DataSeries.SeriesType WHERE Id = @iId

	IF @existingId IS NULL
	BEGIN
		INSERT INTO DataSeries.SeriesType (Id, Name, IsDependant, IsActive)
		VALUES (@iId, @iName, @iIsDependant, @iIsActive)
	END
	ELSE
	BEGIN
		UPDATE DataSeries.SeriesType
			SET Name = @iName, IsDependant  = @iIsDependant, IsActive = @iIsActive
		WHERE Id = @iId
	END
END
GO

GRANT EXECUTE ON [DataSeries].[AddOrUpdateSeriesType] TO BhpbioGenericManager

GO
PRINT N'Creating [DataSeries].[AddOrUpdateSeriesTypeAttribute]...';


GO
CREATE PROCEDURE [DataSeries].[AddOrUpdateSeriesTypeAttribute]
	@iSeriesTypeId varchar(100),
	@iName varchar(100),
	@iStringValue varchar(250),
	@iIntegerValue int,
	@iBooleanValue bit,
	@iDateTimeValue DATETIME,
	@iDoubleValue FLOAT
WITH ENCRYPTION
AS
BEGIN
	-- attempt an update
	UPDATE att
	SET att.StringValue = @iStringValue,
		att.IntegerValue = @iIntegerValue,
		att.BooleanValue = @iBooleanValue,
		att.DateTimeValue = @iDateTimeValue,
		att.DoubleValue = @iDoubleValue
	FROM DataSeries.SeriesTypeAttribute as att
	WHERE att.SeriesTypeId = @iSeriesTypeId
		AND att.Name = @iName

	-- if the update effected no rowws
	IF @@ROWCOUNT = 0
	BEGIN
		INSERT INTO DataSeries.SeriesTypeAttribute(SeriesTypeId, Name, StringValue, IntegerValue, BooleanValue, DateTimeValue, DoubleValue)
		VALUES (@iSeriesTypeId, @iName, @iStringValue, @iIntegerValue, @iBooleanValue, @iDateTimeValue, @iDoubleValue)
	END
END
GO

GRANT EXECUTE ON [DataSeries].[AddOrUpdateSeriesTypeAttribute] TO BhpbioGenericManager

GO
PRINT N'Creating [DataSeries].[AddQueueEntry]...';


GO
CREATE PROCEDURE [DataSeries].[AddQueueEntry]
	@iSeriesTypeGroupId varchar(100),
	@iOrdinal bigint,
	@iQueueEntryType varchar(50),
	@oId bigint out
WITH ENCRYPTION
AS
BEGIN
	INSERT INTO DataSeries.SeriesQueueEntry(SeriesQueueEntryTypeId, SeriesTypeGroupId, SeriesPointOrdinal, ProcessedDateTime, AddedDateTime, SeriesQueueEntryStatusId)
	SELECT qt.Id, @iSeriesTypeGroupId, @iOrdinal, null, GETDATE(), qs.SeriesQueueEntryStatusId
	FROM
		(
			SELECT MIN(qstatus.Id) as SeriesQueueEntryStatusId
			FROM DataSeries.SeriesQueueEntryStatus qstatus
			WHERE qstatus.IsPending = 1
		) qs
		,DataSeries.SeriesQueueEntryType qt
	WHERE qt.Code = @iQueueEntryType

	SET @oId = SCOPE_IDENTITY()
END
GO

GRANT EXECUTE ON [DataSeries].[AddQueueEntry] TO BhpbioGenericManager

GO
PRINT N'Creating [DataSeries].[AddSeriesTypeToGroup]...';


GO
CREATE PROCEDURE [DataSeries].[AddSeriesTypeToGroup]
	@iSeriesTypeId varchar(100),
	@iSeriesTypeGroupId varchar(100)
WITH ENCRYPTION
AS
BEGIN
	IF NOT EXISTS (SELECT * FROM DataSeries.SeriesTypeGroupMembership WHERE SeriesTypeId = @iSeriesTypeId AND SeriesTypeGroupId = @iSeriesTypeGroupId)
	BEGIN
		INSERT INTO DataSeries.SeriesTypeGroupMembership(SeriesTypeId,SeriesTypeGroupId)
		VALUES(@iSeriesTypeId, @iSeriesTypeGroupId)
	END
END
GO

GRANT EXECUTE ON [DataSeries].[AddSeriesTypeToGroup] TO BhpbioGenericManager

GO
PRINT N'Creating [DataSeries].[AddTriggerQueueEntries]...';


GO
CREATE PROCEDURE [DataSeries].[AddTriggerQueueEntries]
	@iSeriesTypeGroupId varchar(100),
	@iOrdinal bigint,
	@iQueueEntryType varchar(50)
WITH ENCRYPTION
AS
BEGIN
	INSERT INTO DataSeries.SeriesQueueEntry(SeriesQueueEntryTypeId, SeriesTypeGroupId, SeriesPointOrdinal, ProcessedDateTime, AddedDateTime, SeriesQueueEntryStatusId)
	SELECT trig.RaiseQueueEntryTypeId,
		CASE WHEN trig.RaiseSeriesTypeGroupId IS NULL OR trig.RaiseSeriesTypeGroupId = '{Copy}' THEN @iSeriesTypeGroupId 
		WHEN trig.RaiseSeriesTypeGroupId = '{Null}' THEN NULL
		ELSE trig.RaiseSeriesTypeGroupId
		END,
		@iOrdinal + trig.OrdinalOffset,
		null,
		GetDate(),
		qs.SeriesQueueEntryStatusId
	FROM (
			SELECT MIN(qstatus.Id) as SeriesQueueEntryStatusId
			FROM DataSeries.SeriesQueueEntryStatus qstatus
			WHERE qstatus.IsPending = 1
		) qs,
		DataSeries.SeriesQueueEntryTrigger trig 
		INNER JOIN DataSeries.SeriesQueueEntryType qt ON qt.Id = trig.TriggerQueueEntryTypeId
	WHERE (@iSeriesTypeGroupId IS NULL OR trig.TriggerSeriesTypeGroupId IS NULL OR trig.TriggerSeriesTypeGroupId = @iSeriesTypeGroupId)
		AND qt.Code = @iQueueEntryType
END
GO

GRANT EXECUTE ON [DataSeries].[AddTriggerQueueEntries] TO BhpbioGenericManager

GO
PRINT N'Creating [DataSeries].[CancelQueueEntry]...';


GO
CREATE PROCEDURE [DataSeries].[CancelQueueEntry]
	@iId BIGINT
WITH ENCRYPTION
AS
BEGIN
	UPDATE DataSeries.SeriesQueueEntry
	SET SeriesQueueEntryStatusId = (
			SELECT MIN(qstatus.Id) as SeriesQueueEntryStatusId
			FROM DataSeries.SeriesQueueEntryStatus qstatus
			WHERE qstatus.IsCancelled = 1
	)
	WHERE Id = @iId
END
GO

GRANT EXECUTE ON [DataSeries].[CancelQueueEntry] TO BhpbioGenericManager

GO
PRINT N'Creating [DataSeries].[ClearPoints]...';


GO
CREATE PROCEDURE [DataSeries].[ClearPoints]
	@iSeriesTypeId varchar(100),
	@iSeriesTypeGroupId varchar(100),
	@iSeriesId int,
	@iOrdinalMin bigint,
	@iOrdinalMax bigint,
	@iAlsoDeletePointsOfDependentSeries BIT
WITH ENCRYPTION
AS
BEGIN
	DELETE sp 
	FROM DataSeries.SeriesPoint sp
		INNER JOIN DataSeries.Series s ON s.Id = sp.SeriesId
		LEFT JOIN DataSeries.SeriesTypeGroupMembership stg ON stg.SeriesTypeId = s.SeriesTypeId AND stg.SeriesTypeGroupId = @iSeriesTypeGroupId
	WHERE (@iSeriesId IS NULL OR sp.SeriesId = @iSeriesId)
		AND (@iSeriesTypeId IS NULL OR s.SeriesTypeId = @iSeriesTypeId)
		AND (@iOrdinalMin IS NULL OR sp.Ordinal >= @iOrdinalMin)
		AND (@iOrdinalMax IS NULL OR sp.Ordinal <= @iOrdinalMax)
		AND (@iSeriesTypeGroupId IS NULL OR stg.SeriesTypeGroupId = @iSeriesTypeGroupId)

	IF @iAlsoDeletePointsOfDependentSeries = 1
	BEGIN
		DELETE sp 
		FROM DataSeries.SeriesPoint sp
			INNER JOIN DataSeries.Series s ON s.Id = sp.SeriesId
			INNER JOIN DataSeries.SeriesType st ON st.Id = s.SeriesTypeId
			INNER JOIN DataSeries.Series rs ON rs.Id = s.PrimaryRelatedSeriesId
			LEFT JOIN DataSeries.SeriesTypeGroupMembership rstg ON rstg.SeriesTypeId = rs.SeriesTypeId AND rstg.SeriesTypeGroupId = @iSeriesTypeGroupId
		WHERE 
			st.IsDependant = 1
			AND (@iSeriesId IS NULL OR rs.Id = @iSeriesId)
			AND (@iSeriesTypeId IS NULL OR rs.SeriesTypeId = @iSeriesTypeId)
			AND (@iOrdinalMin IS NULL OR sp.Ordinal >= @iOrdinalMin)
			AND (@iOrdinalMax IS NULL OR sp.Ordinal <= @iOrdinalMax)
			AND (@iSeriesTypeGroupId IS NULL OR rstg.SeriesTypeGroupId = @iSeriesTypeGroupId)
	END
END
GO

GRANT EXECUTE ON [DataSeries].[ClearPoints] TO BhpbioGenericManager

GO
PRINT N'Creating [DataSeries].[ClearQueueEntries]...';


GO
CREATE PROCEDURE [DataSeries].[ClearQueueEntries]
(
	@iQueueEntryType varchar(50),
	@iSeriesTypeGroupId varchar(100),
	@iOrdinalMin bigint,
	@iOrdinalMax bigint
)
WITH ENCRYPTION
AS
BEGIN

	DELETE sqe
	FROM DataSeries.SeriesQueueEntry sqe
	INNER JOIN DataSeries.SeriesQueueEntryType qt ON qt.Id = sqe.SeriesQueueEntryTypeId
	WHERE (@iQueueEntryType IS NULL OR qt.Code = @iQueueEntryType)
		AND (@iSeriesTypeGroupId IS NULL OR sqe.SeriesTypeGroupId = @iSeriesTypeGroupId)
		AND (@iOrdinalMin IS NULL OR sqe.SeriesPointOrdinal >= @iOrdinalMin)
		AND (@iOrdinalMax IS NULL OR sqe.SeriesPointOrdinal <= @iOrdinalMax)
END
GO

GRANT EXECUTE ON [DataSeries].[ClearQueueEntries] TO BhpbioGenericManager

GO
PRINT N'Creating [DataSeries].[DeleteSeriesAttributes]...';


GO
CREATE PROCEDURE [DataSeries].[DeleteSeriesAttributes]
	@iSeriesId int
WITH ENCRYPTION
AS
BEGIN
	DELETE FROM DataSeries.SeriesAttribute WHERE SeriesId = @iSeriesId
END
GO

GRANT EXECUTE ON [DataSeries].[DeleteSeriesAttributes] TO BhpbioGenericManager

GO
PRINT N'Creating [DataSeries].[DeleteSeriesTypeAttributes]...';


GO
CREATE PROCEDURE [DataSeries].[DeleteSeriesTypeAttributes]
	@iSeriesTypeId varchar(100)
WITH ENCRYPTION
AS
BEGIN
	DELETE FROM DataSeries.SeriesTypeAttribute WHERE SeriesTypeId = @iSeriesTypeId
END
GO

GRANT EXECUTE ON [DataSeries].[DeleteSeriesTypeAttributes] TO BhpbioGenericManager

GO
PRINT N'Creating [DataSeries].[GetNextPendingQueueEntry]...';


GO
CREATE PROCEDURE [DataSeries].[GetNextPendingQueueEntry]
	@iQueueEntryType VARCHAR(50)
WITH ENCRYPTION
AS
BEGIN
	SELECT TOP 1 qe.Id, qe.SeriesPointOrdinal, qt.Code as QueueEntryType, qe.SeriesQueueEntryStatusId, qe.SeriesTypeGroupId, qe.AddedDateTime, qe.ProcessedDateTime, GetDate() as RetrievedDateTime,
				qt.CausesAutomaticPointRemoval
	FROM DataSeries.SeriesQueueEntry qe
		INNER JOIN DataSeries.SeriesQueueEntryStatus ss ON ss.Id = qe.SeriesQueueEntryStatusId
		INNER JOIN DataSeries.SeriesQueueEntryType qt ON qt.Id = qe.SeriesQueueEntryTypeId
	WHERE (@iQueueEntryType IS NULL OR qt.Code = @iQueueEntryType)
		AND ss.IsPending = 1
	ORDER BY qe.SeriesPointOrdinal, qt.[Priority], qe.AddedDateTime, qe.Id
END
GO

GRANT EXECUTE ON [DataSeries].[GetNextPendingQueueEntry] TO BhpbioGenericManager

GO
PRINT N'Creating [DataSeries].[GetPoints]...';


GO
CREATE PROCEDURE [DataSeries].[GetPoints]
	@iSeriesId int,
	@iOrdinalMin bigint,
	@iOrdinalMax bigint
WITH ENCRYPTION
AS
BEGIN
	SELECT SeriesId, Ordinal, Value
	FROM DataSeries.SeriesPoint
	WHERE SeriesId = @iSeriesId 
		AND Ordinal BETWEEN @iOrdinalMin AND @iOrdinalMax
	ORDER BY Ordinal
END
GO

GRANT EXECUTE ON [DataSeries].[GetPoints] TO BhpbioGenericManager

GO
PRINT N'Creating [DataSeries].[GetPointsForSeriesTypeGroup]...';


GO
CREATE PROCEDURE [DataSeries].[GetPointsForSeriesTypeGroup]
	@iSeriesTypeGroupId varchar(100),
	@iOrdinalMin bigint,
	@iOrdinalMax bigint
WITH ENCRYPTION
AS
BEGIN
	SELECT sp.SeriesId, sp.Ordinal, sp.Value
	FROM DataSeries.SeriesPoint sp
		INNER JOIN DataSeries.Series s ON s.Id = sp.SeriesId
		INNER JOIN DataSeries.SeriesTypeGroupMembership gm ON gm.SeriesTypeId = s.SeriesTypeId
	WHERE gm.SeriesTypeGroupId = @iSeriesTypeGroupId 
		AND sp.Ordinal BETWEEN @iOrdinalMin AND @iOrdinalMax
	ORDER BY Ordinal
END
GO

GRANT EXECUTE ON [DataSeries].[GetPointsForSeriesTypeGroup] TO BhpbioGenericManager

GO
PRINT N'Creating [DataSeries].[GetSeries]...';


GO
CREATE PROCEDURE [DataSeries].[GetSeries]
	@iSeriesId int,
	@iSeriesKey VARCHAR(100),
	@iSeriesTypeId VARCHAR(100)
WITH ENCRYPTION
AS
BEGIN
	SELECT s.Id, s.SeriesKey, s.SeriesTypeId, s.PrimaryRelatedSeriesId
	FROM DataSeries.Series s
	WHERE (@iSeriesId IS NULL OR @iSeriesId = s.Id)
		AND (@iSeriesKey IS NULL OR @iSeriesKey = s.SeriesKey)
		AND (@iSeriesTypeId IS NULL OR @iSeriesTypeId = s.SeriesTypeId)
END
GO

GRANT EXECUTE ON [DataSeries].[GetSeries] TO BhpbioGenericManager

GO
PRINT N'Creating [DataSeries].[GetSeriesAttributes]...';


GO
CREATE PROCEDURE [DataSeries].[GetSeriesAttributes]
	@iSeriesId int,
	@iSeriesKey VARCHAR(100),
	@iSeriesTypeId VARCHAR(100)
WITH ENCRYPTION
AS
BEGIN
	SELECT sa.SeriesId,
		sa.Name,
		sa.StringValue,
		sa.IntegerValue,
		sa.BooleanValue,
		sa.DateTimeValue,
		sa.DoubleValue
	FROM SeriesAttribute sa
		INNER JOIN DataSeries.Series s ON s.Id = sa.SeriesId
	WHERE (@iSeriesId IS NULL OR @iSeriesId = s.Id)
		AND (@iSeriesKey IS NULL OR @iSeriesKey = s.SeriesKey)
		AND (@iSeriesTypeId IS NULL OR @iSeriesTypeId = s.SeriesTypeId)
	ORDER BY sa.SeriesId
END
GO

GRANT EXECUTE ON [DataSeries].[GetSeriesAttributes] TO BhpbioGenericManager

GO
PRINT N'Creating [DataSeries].[GetSeriesTypeAttributes]...';


GO
CREATE PROCEDURE [DataSeries].[GetSeriesTypeAttributes]
	@iSeriesTypeId VARCHAR(100),
	@iIncludeDependant BIT,
	@iActiveOnly BIT,
	@iSeriesTypeGroupId VARCHAR(50),
	@iSeriesTypeGroupName VARCHAR(50)
WITH ENCRYPTION
AS
BEGIN
	SELECT sa.SeriesTypeId,
		sa.Name,
		sa.StringValue,
		sa.IntegerValue,
		sa.BooleanValue,
		sa.DateTimeValue,
		sa.DoubleValue
	FROM SeriesTypeAttribute sa
		INNER JOIN SeriesType st ON st.Id = sa.SeriesTypeId
	WHERE (@iSeriesTypeId IS NULL OR @iSeriesTypeId = st.Id)
		AND (IsNull(@iActiveOnly, 0)  = 0 OR st.IsActive = 1)
		AND (IsNull(@iIncludeDependant, 1) = 1 OR st.IsDependant = 0)
		AND (
				(@iSeriesTypeGroupId IS NULL AND @iSeriesTypeGroupName IS NULL)
				OR EXISTS (
							SELECT * 
							FROM DataSeries.SeriesTypeGroup sag
								INNER JOIN DataSeries.SeriesTypeGroupMembership stag ON stag.SeriesTypeGroupId = sag.Id
							WHERE 
								stag.SeriesTypeId = st.Id
								AND (@iSeriesTypeGroupId IS NULL OR sag.Id = @iSeriesTypeGroupId)
								AND (@iSeriesTypeGroupName IS NULL OR sag.Name = @iSeriesTypeGroupName)
						  )
		)
END
GO

GRANT EXECUTE ON [DataSeries].[GetSeriesTypeAttributes] TO BhpbioGenericManager

GO
PRINT N'Creating [DataSeries].[GetSeriesTypeGroups]...';


GO
CREATE PROCEDURE [DataSeries].[GetSeriesTypeGroups]
WITH ENCRYPTION
AS
BEGIN
	SELECT Id, Name, ContextKey FROM DataSeries.SeriesTypeGroup ORDER BY Name
END
GO

GRANT EXECUTE ON [DataSeries].[GetSeriesTypeGroups] TO BhpbioGenericManager

GO
PRINT N'Creating [DataSeries].[GetSeriesTypes]...';


GO
CREATE PROCEDURE [DataSeries].[GetSeriesTypes]
	@iSeriesTypeId VARCHAR(100),
	@iIncludeDependant BIT,
	@iActiveOnly BIT,
	@iSeriesTypeGroupId VARCHAR(50),
	@iSeriesTypeGroupName VARCHAR(50)
WITH ENCRYPTION
AS
BEGIN
	SELECT st.Id, st.IsActive, st.IsDependant, st.Name
	FROM DataSeries.SeriesType st
	WHERE (@iSeriesTypeId IS NULL OR @iSeriesTypeId = st.Id)
		AND (IsNull(@iActiveOnly, 0)  = 0 OR st.IsActive = 1)
		AND (IsNull(@iIncludeDependant, 1) = 1 OR st.IsDependant = 0)
		AND (
				(@iSeriesTypeGroupId IS NULL AND @iSeriesTypeGroupName IS NULL)
				OR EXISTS (
							SELECT * 
							FROM DataSeries.SeriesTypeGroup sag
								INNER JOIN DataSeries.SeriesTypeGroupMembership stag ON stag.SeriesTypeGroupId = sag.Id
							WHERE 
								stag.SeriesTypeId = st.Id
								AND (@iSeriesTypeGroupId IS NULL OR sag.Id = @iSeriesTypeGroupId)
								AND (@iSeriesTypeGroupName IS NULL OR sag.Name = @iSeriesTypeGroupName)
						  )
		)		
END
GO

GRANT EXECUTE ON [DataSeries].[GetSeriesTypes] TO BhpbioGenericManager

GO
PRINT N'Creating [DataSeries].[MarkQueueEntryProcessed]...';


GO
CREATE PROCEDURE [DataSeries].[MarkQueueEntryProcessed]
	@iId BIGINT
WITH ENCRYPTION
AS
BEGIN
	UPDATE DataSeries.SeriesQueueEntry
	SET SeriesQueueEntryStatusId = (
			SELECT MIN(qstatus.Id) as SeriesQueueEntryStatusId
			FROM DataSeries.SeriesQueueEntryStatus qstatus
			WHERE qstatus.IsProcessed = 1
	),
	 ProcessedDateTime = GETDATE()
	WHERE Id = @iId
END
GO

GRANT EXECUTE ON [DataSeries].[MarkQueueEntryProcessed] TO BhpbioGenericManager

GO
PRINT N'Creating [DataSeries].[RemoveDuplicateQueueEntries]...';


GO
CREATE PROCEDURE [DataSeries].[RemoveDuplicateQueueEntries]
(
	@iSeriesTypeGroupId varchar(100),
	@iOrdinal bigint,
	@iQueueEntryType varchar(50),
	@iAddedBeforeDateTime datetime
)
WITH ENCRYPTION
AS
BEGIN
	DELETE qe
	FROM DataSeries.SeriesQueueEntry qe
		INNER JOIN DataSeries.SeriesQueueEntryType qt ON qt.Id = qe.SeriesQueueEntryTypeId
		INNER JOIN DataSeries.SeriesQueueEntryStatus stat ON stat.Id = qe.SeriesQueueEntryStatusId
	WHERE (@iSeriesTypeGroupId IS NULL OR @iSeriesTypeGroupId = qe.SeriesTypeGroupId)
		AND qe.SeriesPointOrdinal = @iOrdinal
		AND qt.Code = @iQueueEntryType
		AND qe.AddedDateTime < @iAddedBeforeDateTime
		AND stat.IsPending = 1
END
GO

GRANT EXECUTE ON [DataSeries].[RemoveDuplicateQueueEntries] TO BhpbioGenericManager

GO
PRINT N'Creating [DataSeries].[RemoveSeriesTypeFromGroup]...';


GO
CREATE PROCEDURE [DataSeries].[RemoveSeriesTypeFromGroup]
	@iSeriesTypeId varchar(100),
	@iSeriesTypeGroupId varchar(100)
WITH ENCRYPTION
AS
BEGIN
	DELETE FROM DataSeries.SeriesTypeGroupMembership
	WHERE SeriesTypeId = @iSeriesTypeId AND SeriesTypeGroupId = @iSeriesTypeGroupId
END
GO

GRANT EXECUTE ON [DataSeries].[RemoveSeriesTypeFromGroup] TO BhpbioGenericManager

GO
-- Refactoring step to update target server with deployed transaction logs

IF OBJECT_ID(N'dbo.__RefactorLog') IS NULL
BEGIN
    CREATE TABLE [dbo].[__RefactorLog] (OperationKey UNIQUEIDENTIFIER NOT NULL PRIMARY KEY)
    EXEC sp_addextendedproperty N'microsoft_database_tools_support', N'refactoring log', N'schema', N'dbo', N'table', N'__RefactorLog'
END
GO
IF NOT EXISTS (SELECT OperationKey FROM [dbo].[__RefactorLog] WHERE OperationKey = 'efa077af-ecbe-410b-9995-f86b2088f5a8')
INSERT INTO [dbo].[__RefactorLog] (OperationKey) values ('efa077af-ecbe-410b-9995-f86b2088f5a8')
IF NOT EXISTS (SELECT OperationKey FROM [dbo].[__RefactorLog] WHERE OperationKey = '8fa5b787-252d-4ff4-ae0d-5d36ef84ff39')
INSERT INTO [dbo].[__RefactorLog] (OperationKey) values ('8fa5b787-252d-4ff4-ae0d-5d36ef84ff39')
IF NOT EXISTS (SELECT OperationKey FROM [dbo].[__RefactorLog] WHERE OperationKey = '7e022bc8-891a-4e75-81dc-e7bc97529d54')
INSERT INTO [dbo].[__RefactorLog] (OperationKey) values ('7e022bc8-891a-4e75-81dc-e7bc97529d54')
IF NOT EXISTS (SELECT OperationKey FROM [dbo].[__RefactorLog] WHERE OperationKey = 'ee0416f7-4376-4655-8645-db4b148f20df')
INSERT INTO [dbo].[__RefactorLog] (OperationKey) values ('ee0416f7-4376-4655-8645-db4b148f20df')
IF NOT EXISTS (SELECT OperationKey FROM [dbo].[__RefactorLog] WHERE OperationKey = '25f991e0-de97-4570-b843-91bd9235a013')
INSERT INTO [dbo].[__RefactorLog] (OperationKey) values ('25f991e0-de97-4570-b843-91bd9235a013')
IF NOT EXISTS (SELECT OperationKey FROM [dbo].[__RefactorLog] WHERE OperationKey = '803041a8-a095-40ed-b196-092c5909dfe8')
INSERT INTO [dbo].[__RefactorLog] (OperationKey) values ('803041a8-a095-40ed-b196-092c5909dfe8')
IF NOT EXISTS (SELECT OperationKey FROM [dbo].[__RefactorLog] WHERE OperationKey = '1ca7b459-d66e-4f19-9968-1819e9c06e95')
INSERT INTO [dbo].[__RefactorLog] (OperationKey) values ('1ca7b459-d66e-4f19-9968-1819e9c06e95')
IF NOT EXISTS (SELECT OperationKey FROM [dbo].[__RefactorLog] WHERE OperationKey = '1c0aba9b-6aa9-4e5c-b2d2-250c06915aa5')
INSERT INTO [dbo].[__RefactorLog] (OperationKey) values ('1c0aba9b-6aa9-4e5c-b2d2-250c06915aa5')
IF NOT EXISTS (SELECT OperationKey FROM [dbo].[__RefactorLog] WHERE OperationKey = '65c04757-39ae-46c3-ac01-28be1c0417ae')
INSERT INTO [dbo].[__RefactorLog] (OperationKey) values ('65c04757-39ae-46c3-ac01-28be1c0417ae')
IF NOT EXISTS (SELECT OperationKey FROM [dbo].[__RefactorLog] WHERE OperationKey = '47d9a932-4295-4fdc-ae4b-f4529a412717')
INSERT INTO [dbo].[__RefactorLog] (OperationKey) values ('47d9a932-4295-4fdc-ae4b-f4529a412717')
IF NOT EXISTS (SELECT OperationKey FROM [dbo].[__RefactorLog] WHERE OperationKey = 'f44a126c-1ff0-4713-acb6-0fa624889731')
INSERT INTO [dbo].[__RefactorLog] (OperationKey) values ('f44a126c-1ff0-4713-acb6-0fa624889731')
IF NOT EXISTS (SELECT OperationKey FROM [dbo].[__RefactorLog] WHERE OperationKey = '9632a34d-71eb-4d46-8604-1cba488f1048')
INSERT INTO [dbo].[__RefactorLog] (OperationKey) values ('9632a34d-71eb-4d46-8604-1cba488f1048')
IF NOT EXISTS (SELECT OperationKey FROM [dbo].[__RefactorLog] WHERE OperationKey = 'afc3e2c6-bc24-4027-85c2-b35af478892e')
INSERT INTO [dbo].[__RefactorLog] (OperationKey) values ('afc3e2c6-bc24-4027-85c2-b35af478892e')

GO

GO
/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/

IF NOT EXISTS (SELECT * FROM DataSeries.SeriesQueueEntryType WHERE Code = 'OutlierProcessRequest')
BEGIN
	INSERT INTO DataSeries.SeriesQueueEntryType(Id, Code, [Priority],CausesAutomaticPointRemoval)
	VALUES (10, 'OutlierProcessRequest', 10, 0)
END

IF NOT EXISTS (SELECT * FROM DataSeries.SeriesTypeGroup WHERE Id = 'OutlierSeriesTypeGroup')
BEGIN
	INSERT INTO DataSeries.SeriesTypeGroup(Id, Name, ContextKey)
	VALUES ('OutlierSeriesTypeGroup','OutlierSeriesTypeGroup', 'Outlier')
END

IF NOT EXISTS (SELECT * FROM DataSeries.SeriesType WHERE Id = 'OD_LinearProjection')
BEGIN
	INSERT INTO DataSeries.SeriesType(Id, Name, IsDependant, IsActive)
	VALUES ('OD_RollingAverageProjection','Rolling Average Projection for Outlier Comparison', 1, 1)

	INSERT INTO DataSeries.SeriesType(Id, Name, IsDependant, IsActive)
	VALUES ('OD_LinearProjection','Linear Projection for Outlier Comparison', 1, 1)

	INSERT INTO DataSeries.SeriesType(Id, Name, IsDependant, IsActive)
	VALUES ('OD_LinearProjectionSlope','Slope of the Linear Projection Line', 1, 1)

	INSERT INTO DataSeries.SeriesType(Id, Name, IsDependant, IsActive)
	VALUES ('OD_LinearProjectionIntercept','Intercept of the Linear Projection Line', 1, 1)

	INSERT INTO DataSeries.SeriesType(Id, Name, IsDependant, IsActive)
	VALUES ('OD_OutlierStandardDeviation','Standard Deviation of the series', 1, 1)

	INSERT INTO DataSeries.SeriesType(Id, Name, IsDependant, IsActive)
	VALUES ('OD_OutllierStandardisedDeviation','Standardised Deviation of Points to identify outliers', 1, 1)
END

IF NOT EXISTS (SELECT * FROM DataSeries.SeriesQueueEntryStatus) BEGIN
	INSERT INTO DataSeries.SeriesQueueEntryStatus([Id], [Name], [IsPending], [IsCancelled], [IsProcessed])
		VALUES (1, 'Pending', 1, 0, 0)

	INSERT INTO DataSeries.SeriesQueueEntryStatus([Id], [Name], [IsPending], [IsCancelled], [IsProcessed])
		VALUES (2, 'Processed', 0, 0, 1)

	INSERT INTO DataSeries.SeriesQueueEntryStatus([Id], [Name], [IsPending], [IsCancelled], [IsProcessed])
		VALUES (3, 'Cancelled', 0, 1, 0)
END
GO

GO
PRINT N'Checking existing data against newly created constraints';


GO
ALTER TABLE [DataSeries].[SeriesQueueEntry] WITH CHECK CHECK CONSTRAINT [FK_SeriesQueueEntry_SeriesQueueEntryStatus];

ALTER TABLE [DataSeries].[SeriesQueueEntry] WITH CHECK CHECK CONSTRAINT [FK_SeriesQueueEntry_SeriesQueueEntryType];

ALTER TABLE [DataSeries].[SeriesPoint] WITH CHECK CHECK CONSTRAINT [FK_SeriesPoint_Series];

ALTER TABLE [DataSeries].[SeriesTypeAttribute] WITH CHECK CHECK CONSTRAINT [FK_SeriesTypeAttribute_SeriesType];

ALTER TABLE [DataSeries].[SeriesTypeGroupMembership] WITH CHECK CHECK CONSTRAINT [FK_SeriesTypeGroupMembership_SeriesTypeGroup];

ALTER TABLE [DataSeries].[SeriesTypeGroupMembership] WITH CHECK CHECK CONSTRAINT [FK_SeriesTypeGroupMembership_SeriesType];

ALTER TABLE [DataSeries].[SeriesAttribute] WITH CHECK CHECK CONSTRAINT [FK_SeriesAttribute_Series];

ALTER TABLE [DataSeries].[Series] WITH CHECK CHECK CONSTRAINT [FK_Series_Series];

ALTER TABLE [DataSeries].[SeriesQueueEntryTrigger] WITH CHECK CHECK CONSTRAINT [FK_SeriesQueueEntryTrigger_TriggerQueueEntryTypeId];

ALTER TABLE [DataSeries].[SeriesQueueEntryTrigger] WITH CHECK CHECK CONSTRAINT [FK_SeriesQueueEntryTrigger_RaiseQueueEntryTypeId];

ALTER TABLE [DataSeries].[SeriesQueueEntryTrigger] WITH CHECK CHECK CONSTRAINT [FK_SeriesQueueEntryTrigger_TriggerSeriesTypeGroupId];


GO
PRINT N'Update complete.';

