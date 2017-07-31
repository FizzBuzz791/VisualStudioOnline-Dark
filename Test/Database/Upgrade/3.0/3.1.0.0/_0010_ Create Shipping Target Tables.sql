SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[BhpbioShippingTargetPeriod] (
	[ShippingTargetPeriodId] INT IDENTITY(1,1) NOT NULL,
	[ProductTypeId] INT NOT NULL,
	[EffectiveFromDateTime] DATETIME NOT NULL,
	[LastModifiedDateTime] DATETIME NULL,
	[LastModifiedUserId] INT NULL

    CONSTRAINT [PK_BhpbioShippingTargetPeriod] PRIMARY KEY NONCLUSTERED (ShippingTargetPeriodId),

	CONSTRAINT FK_BhpbioShippingTargetPeriod_ProductTypeId
		FOREIGN KEY (ProductTypeId)
		REFERENCES dbo.BhpbioProductType (ProductTypeId)

) ON [PRIMARY]
GO



SET ANSI_PADDING OFF
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[BhpbioShippingTargetPeriodValue] (
	[ShippingTargetPeriodValueId] INT IDENTITY(1,1) NOT NULL,
	[ShippingTargetPeriodId] INT NOT NULL,
	[AttributeId] INT NOT NULL,
	[UpperControl] FLOAT NOT NULL,
	[Target] FLOAT NULL,
	[LowerControl] FLOAT NULL

    CONSTRAINT [PK_BhpbioShippingTargetPeriodValue] PRIMARY KEY NONCLUSTERED (ShippingTargetPeriodValueId),

	CONSTRAINT FK_BhpbioShippingTargetPeriodValue_ShippingTargetPeriodId
		FOREIGN KEY (ShippingTargetPeriodId)
		REFERENCES dbo.BhpbioShippingTargetPeriod (ShippingTargetPeriodId)

) ON [PRIMARY]
GO

SET ANSI_PADDING OFF
GO

