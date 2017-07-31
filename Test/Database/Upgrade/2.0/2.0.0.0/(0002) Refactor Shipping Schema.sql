-- create new re-factored shipping schema that uses a naming convention consisten with the source system
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BhpbioShippingNomination]') AND type in (N'U'))
BEGIN
	CREATE TABLE dbo.BhpbioShippingNomination
	(
		NominationKey INT NOT NULL,
		VesselName VARCHAR(63) COLLATE DATABASE_DEFAULT NOT NULL,

		CONSTRAINT PK_BhpbioShippingNomination
			PRIMARY KEY (NominationKey)
	)
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BhpbioShippingNominationItem]') AND type in (N'U'))
BEGIN
	CREATE TABLE dbo.BhpbioShippingNominationItem
	(
		BhpbioShippingNominationItemId INT NOT NULL IDENTITY(1, 1),
		NominationKey INT NOT NULL,
		ItemNo INT NOT NULL,
		OfficialFinishTime DATETIME NOT NULL,
		LastAuthorisedDate DATETIME,
		CustomerNo INT NULL,
		CustomerName VARCHAR(63) COLLATE DATABASE_DEFAULT NULL,
		ShippedProduct VARCHAR(63) COLLATE DATABASE_DEFAULT NULL,
		ShippedProductSize VARCHAR(5) COLLATE DATABASE_DEFAULT NULL,
		COA DATETIME NULL,	
		H2O FLOAT NULL,
		Undersize FLOAT NULL,
		Oversize FLOAT NULL,

		CONSTRAINT PK_BhpbioShippingNominationItem
			PRIMARY KEY (BhpbioShippingNominationItemId),

		CONSTRAINT UQ_BhpbioShippingNominationItem_Candidate
			UNIQUE (NominationKey, ItemNo, OfficialFinishTime),

		CONSTRAINT FK_BhpbioShippingNomination_Transaction
			FOREIGN KEY (NominationKey)
			REFERENCES dbo.BhpbioShippingNomination (NominationKey)
	)
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BhpbioShippingNominationItemParcel]') AND type in (N'U'))
BEGIN
	CREATE TABLE [dbo].[BhpbioShippingNominationItemParcel]
	(
		[BhpbioShippingNominationItemParcelId] [int] IDENTITY(1,1) NOT NULL,
		[BhpbioShippingNominationItemId] [int] NOT NULL,
		[HubLocationId] [int] NOT NULL,
		HubProduct VARCHAR(63) COLLATE DATABASE_DEFAULT NULL,
		HubProductSize VARCHAR(5) COLLATE DATABASE_DEFAULT NULL,
		[Tonnes] [float] NOT NULL,
		
		CONSTRAINT [PK_BhpbioShippingNominationItemParcel]
			PRIMARY KEY NONCLUSTERED ([BhpbioShippingNominationItemParcelId] ASC),
		
		CONSTRAINT [IX__BhpbioShippingNominationItemParcel_Hub]
			UNIQUE CLUSTERED ([HubLocationId] ASC, [BhpbioShippingNominationItemId] ASC),
			
		CONSTRAINT [FK_BhpbioShippingNominationParcel_Nomination]
			FOREIGN KEY([BhpbioShippingNominationItemId])
			REFERENCES [dbo].[BhpbioShippingNominationItem] ([BhpbioShippingNominationItemId])
	)
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BhpbioShippingNominationItemParcelGrade]') AND type in (N'U'))
BEGIN
	CREATE TABLE [dbo].[BhpbioShippingNominationItemParcelGrade]
	(
		[BhpbioShippingNominationItemParcelId] [int] NOT NULL,
		[GradeId] [smallInt] NOT NULL,
		[GradeValue] [float] NOT NULL,

		CONSTRAINT [PK_BhpbioShippingNominationParcelGrade]
			PRIMARY KEY CLUSTERED ([BhpbioShippingNominationItemParcelId] ASC, [GradeId] ASC),
			
		CONSTRAINT [FK_BhpbioShippingNominationParcelGrade_NominationParcel]
			FOREIGN KEY([BhpbioShippingNominationItemParcelId])
			REFERENCES [dbo].[BhpbioShippingNominationItemParcel] ([BhpbioShippingNominationItemParcelId]),
			
		CONSTRAINT [FK_BhpbioShippingNominationItemParcelGrade_GradeId]
			FOREIGN KEY([GradeId])
			REFERENCES [dbo].[Grade] ([Grade_Id])
	)
END
GO

-- Port data over.

IF OBJECT_ID('dbo.BhpbioShippingTransaction') IS NOT NULL
BEGIN
	INSERT INTO BhpbioShippingNomination
	(
		NominationKey,
		VesselName	
	)
	SELECT NominationKey, VesselName
	FROM BhpbioShippingTransaction

	SET IDENTITY_INSERT BhpbioShippingNominationItem ON

	INSERT INTO BhpbioShippingNominationItem
	(
		[BhpbioShippingNominationItemId]
		,[NominationKey]
		,[ItemNo]
		,[OfficialFinishTime]
		,[LastAuthorisedDate]
		,[CustomerNo]
		,[CustomerName]
		,[ShippedProduct]
		,[COA]
		,[H2O]
		,[Undersize]
		,[Oversize]
	)
	SELECT [BhpbioShippingTransactionNominationId]
		,[NominationKey]
		,[Nomination]
		,[OfficialFinishTime]
		,[LastAuthorisedDate]
		,[CustomerNo]
		,[CustomerName]
		,[ProductCode]
		,[COA]
		,[H2O]
		,[Undersize]
		,[Oversize]
	FROM [BhpbioShippingTransactionNomination]
	
	SET IDENTITY_INSERT BhpbioShippingNominationItem OFF

	SET IDENTITY_INSERT BhpbioShippingNominationItemParcel ON

	INSERT INTO BhpbioShippingNominationItemParcel
	(
		[BhpbioShippingNominationItemParcelId],
		[BhpbioShippingNominationItemId],
		[HubLocationId],
		HubProduct,
		[Tonnes]
	)
	SELECT [BhpbioShippingTransactionNominationId]
		,[BhpbioShippingTransactionNominationId]
		,[HubLocationId]
		,[ProductCode]
		,[Tonnes]
	FROM [BhpbioShippingTransactionNomination]

	SET IDENTITY_INSERT BhpbioShippingNominationItemParcel OFF

	INSERT INTO [BhpbioShippingNominationItemParcelGrade]
	(
		[BhpbioShippingNominationItemParcelId],
		GradeId,
		GradeValue
	)
	SELECT [BhpbioShippingTransactionNominationId]
		,[GradeId]
		,[GradeValue]
	FROM [BhpbioShippingTransactionNominationGrade]

	DROP TABLE dbo.BhpbioShippingTransactionNominationGrade
	DROP TABLE dbo.BhpbioShippingTransactionNomination
	DROP TABLE dbo.BhpbioShippingTransaction
	
END
GO



