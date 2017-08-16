CREATE TABLE [dbo].[ShippingNominationItemHubGrade](
	[ShippingNominationItemHubId] [int] NOT NULL,
	[GradeName] [nvarchar](50) NOT NULL,
	[FinesValue] decimal(12,6) NULL,
	[HeadValue] decimal(12,6) NULL,
	[LumpValue] decimal(12,6) NULL,
	[SampleValue] decimal(12,6) NULL,

	CONSTRAINT [PK_ShippingNominationItemHubGrade] PRIMARY KEY CLUSTERED 
	(
		[ShippingNominationItemHubId] ASC,
		[GradeName] ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ShippingNominationItemHubGrade]  WITH CHECK ADD  CONSTRAINT [FK_ShippingNominationItemHubGrade_ShippingNominationItemHub] FOREIGN KEY([ShippingNominationItemHubId])
REFERENCES [dbo].[ShippingNominationItemHub] ([Id])
GO
ALTER TABLE [dbo].[ShippingNominationItemHubGrade] CHECK CONSTRAINT [FK_ShippingNominationItemHubGrade_ShippingNominationItemHub]
GO
