CREATE TABLE [dbo].[ShippingNominationItem](
	[Id] [int] NOT NULL identity(1,1),
	[ShippingNominationId] [int] NULL,
	[ItemNo] [nvarchar](50) NULL,
	[CustomerNo] [nvarchar](50) NULL,
	[CustomerName] [nvarchar](50) NULL,
	[LastAuthorisedDate] [datetime] NULL,
	[OfficialFinishTime] [datetime] NULL,
	[Oversize] decimal(18,4) NULL,
	[Undersize] decimal(18,4) NULL,
	[COA] [datetime] NULL,
	[ShippedProduct] [nvarchar](50) NULL,
	[ShippedProductSize] [nvarchar](50) NULL,
 CONSTRAINT [PK_ShippingNominationItem] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ShippingNominationItem]  WITH CHECK ADD  CONSTRAINT [FK_ShippingNominationItem_ShippingNomination] FOREIGN KEY([ShippingNominationId])
REFERENCES [dbo].[ShippingNomination] ([Id])
GO
ALTER TABLE [dbo].[ShippingNominationItem] CHECK CONSTRAINT [FK_ShippingNominationItem_ShippingNomination]
GO
