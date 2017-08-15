CREATE TABLE [dbo].[ShippingNomination](
	[Id] [int] NOT NULL identity(1,1),
	[NominationKey] [nvarchar](50) NULL,
	[VesselName] [nvarchar](50) NULL,
 CONSTRAINT [PK_ShippingNomination] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

