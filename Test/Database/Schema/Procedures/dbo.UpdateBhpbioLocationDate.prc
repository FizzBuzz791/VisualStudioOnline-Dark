IF Object_Id('dbo.UpdateBhpbioLocationDate') IS NOT NULL 
     DROP PROCEDURE dbo.UpdateBhpbioLocationDate
GO

CREATE PROCEDURE dbo.UpdateBhpbioLocationDate
AS
BEGIN

	DECLARE @rebuildMinutes INTEGER
	
	SELECT @rebuildMinutes = convert(int,Value) FROM Setting WHERE Setting_Id = 'BHPBIO_LOCATION_DATE_REBUILD_MINUTES'
	if @rebuildMinutes IS NULL
	BEGIN
		SET @rebuildMinutes = 0
	END

	DECLARE @supportLogRecordDescription VARCHAR(50)
	SET @supportLogRecordDescription = 'UpdateBhpbioLocationDate execution'


	IF @rebuildMinutes > 0
	BEGIN
		-- check if the data already built is reusable
		DECLARE @checkDate DATETIME
		SET @checkDate = DATEADD(minute, -1 * @rebuildMinutes, GETDATE())

		IF EXISTS (SELECT * 
			FROM SupportLog sl WITH (NOLOCK)
			WHERE sl.Added >= @checkDate AND Description = @supportLogRecordDescription)
		BEGIN
			-- don't execute more than once in 30 mins
			RETURN
		END
	END

	INSERT INTO SupportLog(LogTypeId,Added,Component,Description)
	VALUES(1,GetDate(),'UpdateBhpbioLocationDate',@supportLogRecordDescription)

	Declare @GlobalStartDate DateTime
	Declare @GlobalEndDate DateTime
	Declare @CreateDate DateTime
		
	SET NOCOUNT ON

	SET @GlobalStartDate = '1900-01-01'
	SET @GlobalEndDate = '2050-12-31'   --GETDATE()
	SET @CreateDate = GETDATE()


	IF Object_Id('#BhpbioLocationDateRebuild') IS NOT NULL
	BEGIN
		DROP TABLE #BhpbioLocationDateRebuild
	END 
	
	CREATE TABLE #BhpbioLocationDateRebuild(
		[Location_Id] [int] NOT NULL,
		[Period_Order] [int] NOT NULL,
		[Location_Type_Id] [tinyint] NOT NULL,
		[Parent_Location_Id] [int] NULL,
		[Start_Date] [datetime] NOT NULL,
		[End_Date] [datetime] NULL,
		[Is_Override] [bit] NOT NULL,
		[Date_Created] [datetime] NOT NULL,
	CONSTRAINT [PK_LOCATION_DATE] PRIMARY KEY CLUSTERED 
	(
		[Location_Id] ASC,
		[Period_Order] ASC
	))

	INSERT INTO #BhpbioLocationDateRebuild
	(
		Period_Order,Location_Id,Location_Type_Id,Parent_Location_Id,[Start_Date],End_Date,Is_Override, Date_Created
	)
	SELECT	0 AS Period_Order, Location_Id, Location_Type_Id, Parent_Location_Id
	,		@GlobalStartDate AS [Start_Date], @GlobalEndDate AS End_Date, 0 AS Is_Override
	,		@CreateDate AS Date_Created
	FROM	Location WITH (NOLOCK)
	UNION ALL
	SELECT	DISTINCT ROW_NUMBER() OVER (PARTITION BY Location_Id ORDER BY FromMonth) AS Period_Order
	,		Location_Id, Location_Type_Id, Parent_Location_Id, FromMonth AS [Start_Date], ToMonth AS [End_Date], 1 AS Is_Override
	,		@CreateDate AS Date_Created
	FROM	BhpbioLocationOverride WITH (NOLOCK)

	CREATE NONCLUSTERED INDEX [IX_BhpbioLocationDate_LocationDate] ON #BhpbioLocationDateRebuild
	(
		[Location_Id] ASC,
		[Start_Date] ASC,
		[End_Date] ASC
	)
	INCLUDE ( 	[Location_Type_Id],
		[Parent_Location_Id]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80)

	INSERT INTO #BhpbioLocationDateRebuild
	(
	  Period_Order,Location_Id,Location_Type_Id,Parent_Location_Id,[Start_Date],End_Date,Is_Override, Date_Created
	)
	SELECT	CLH.Period_Order + 1 , CLH.Location_Id, CLH.Location_Type_Id, CLH3.Parent_Location_Id
	,		DATEADD(DAY, 1, FD.End_Date) AS [Start_Date], @GlobalEndDate AS End_Date, 1 AS Is_Override
	,		@CreateDate AS Date_Created
	FROM	#BhpbioLocationDateRebuild  CLH 
	INNER JOIN #BhpbioLocationDateRebuild CLH3 
		ON	CLH.Location_Id = CLH3.Location_Id
		AND CLH3.Period_Order = 0
	CROSS APPLY 
	(
		SELECT	TOP 1 End_Date
		FROM	#BhpbioLocationDateRebuild CLH2
		WHERE	CLH.Period_Order = CLH2.Period_Order
		AND		CLH.Location_Id = CLH2.Location_Id
		ORDER BY Period_Order DESC  
	) FD
	WHERE CLH.Period_Order > 0
	AND FD.End_Date <  @GlobalEndDate

	DELETE	CLH1
	FROM	#BhpbioLocationDateRebuild CLH1
	INNER JOIN #BhpbioLocationDateRebuild CLH2 
		ON	CLH2.Location_Id = CLH1.Location_Id
		AND	CLH2.Period_Order = CLH1.Period_Order + 1
		AND	CLH2.[Start_Date] = CLH1.[Start_Date]
		
	DELETE	CLH1
	FROM	#BhpbioLocationDateRebuild CLH1
	INNER JOIN #BhpbioLocationDateRebuild CLH2 
		ON	CLH2.Location_Id = CLH1.Location_Id
		AND CLH2.Parent_Location_Id = CLH1.Parent_Location_Id
		AND	CLH2.Period_Order = CLH1.Period_Order + 1

	UPDATE	CLH1 SET End_Date = DATEADD(DAY, -1, CLH2.[Start_Date])
	FROM	#BhpbioLocationDateRebuild CLH1
	INNER JOIN #BhpbioLocationDateRebuild CLH2 
		ON	CLH2.Location_Id = CLH1.Location_Id
		AND	CLH2.Period_Order = CLH1.Period_Order + 1

	TRUNCATE TABLE BhpbioLocationDate

	INSERT INTO BhpbioLocationDate SELECT * FROM #BhpbioLocationDateRebuild

	DROP TABLE #BhpbioLocationDateRebuild
END
GO

GRANT EXECUTE ON dbo.UpdateBhpbioLocationDate TO CommonImportManager
GO

/*
EXEC dbo.UpdateBhpbioLocationDate
select * from BhpbioLocationDate
*/