SET ANSI_NULLS ON
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[BhpbioProductType](
	[ProductTypeId] [int] IDENTITY NOT NULL,
	[ProductTypeCode] [nvarchar](50) NOT NULL,
	[Description] [nvarchar](150) NOT NULL,
	[ProductSize] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_BhpbioProductType] PRIMARY KEY CLUSTERED 
(
	[ProductTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

-----------------------------------------------------------------
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[BhpbioProductTypelocation](
	[ProductTypeId] [int] NOT NULL,
	[LocationId] [int] NOT NULL,
 CONSTRAINT [PK_BhpbioProductTypelocation] PRIMARY KEY CLUSTERED 
(
	[ProductTypeId] ASC,
	[LocationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[BhpbioProductTypelocation]  WITH CHECK ADD  CONSTRAINT [FK_BhpbioProductTypelocation_BhpbioProductType] FOREIGN KEY([ProductTypeId])
REFERENCES [dbo].[BhpbioProductType] ([ProductTypeId])
GO

ALTER TABLE [dbo].[BhpbioProductTypelocation] CHECK CONSTRAINT [FK_BhpbioProductTypelocation_BhpbioProductType]
GO

ALTER TABLE [dbo].[BhpbioProductTypelocation]  WITH CHECK ADD  CONSTRAINT [FK_BhpbioProductTypelocation_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Location] ([Location_Id])
GO

ALTER TABLE [dbo].[BhpbioProductTypelocation] CHECK CONSTRAINT [FK_BhpbioProductTypelocation_Location]
GO

