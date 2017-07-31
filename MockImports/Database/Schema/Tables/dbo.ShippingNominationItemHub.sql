USE [ReconcilorImportMockWS]
GO
/****** Object:  Table [dbo].[ShippingNominationItemHub]    Script Date: 07/09/2013 13:24:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ShippingNominationItemHub](
	[Id] [int] NOT NULL identity(1,1),
	[Hub] [nvarchar](50) NULL,
	[HubProduct] [nvarchar](50) NULL,
	[HubProductSize] [nvarchar](50) NULL,
	[Tonnes] decimal(18,4) NULL,
	[ShippingNominationItemId] [int] NULL,
 CONSTRAINT [PK_ShippingNominationItemHub] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ShippingNominationItemHub]  WITH CHECK ADD  CONSTRAINT [FK_ShippingNominationItemHub_ShippingNominationItem] FOREIGN KEY([ShippingNominationItemId])
REFERENCES [dbo].[ShippingNominationItem] ([Id])
GO
ALTER TABLE [dbo].[ShippingNominationItemHub] CHECK CONSTRAINT [FK_ShippingNominationItemHub_ShippingNominationItem]
GO

