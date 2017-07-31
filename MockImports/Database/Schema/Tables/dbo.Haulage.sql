CREATE TABLE [dbo].[Haulage]
(
	HaulageId int not null identity(1,1), 
	TransactionDate datetime null,
	[Source] varchar(31) null,
	SourceMineSite varchar(31) null,
	DestinationMineSite varchar(31) null,
	SourceLocationType varchar(31) null,
	Destination varchar(31) null,
	DestinationType varchar(31) null,
	[Type] varchar(31) null,
	BestTonnes decimal(18,4) null,
	HauledTonnes decimal(18,4) null,
	AerialSurveyTonnes decimal(18,4) null,
	GroundSurveyTonnes decimal(18,4) null,
	LumpPercent decimal(18,4) null,
	LastModifiedTime datetime null,
	LocationId int null,

CONSTRAINT [PK_Haulage] PRIMARY KEY CLUSTERED
(
	HaulageId ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
--ALTER TABLE [dbo].[Haulage]  WITH CHECK ADD  CONSTRAINT [FK_Haulage_Locations] FOREIGN KEY([LocationId])
--REFERENCES [dbo].[Locations] ([Id])
--GO
