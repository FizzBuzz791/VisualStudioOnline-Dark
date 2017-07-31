USE [ReconcilorImportMockWS]
GO

CREATE TABLE [dbo].[Transactions]
(
	[Id] int NOT NULL identity(1,1),
	TransactionDate datetime NULL,
	[Source] nvarchar(50) NULL,
	SourceType nvarchar(50) NULL,
	Destination nvarchar(50) NULL,
	DestinationType nvarchar(50) NULL,
	[Type] nvarchar(50) NULL,
	SourceMineSite nvarchar(50) NULL,
	DestinationMineSite nvarchar(50) NULL,
	Tonnes decimal(18,4) NULL,
	ProductSize nvarchar(50) NULL,
	SampleSource nvarchar(50) NULL,
	SampleTonnes decimal(18,4) NULL,
	LocationId int NULL,
	
 CONSTRAINT [PK_Transactions] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Transactions]  WITH CHECK ADD  CONSTRAINT [FK_Transactions_Locations] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[Transactions] CHECK CONSTRAINT [FK_Transactions_Locations]
GO
