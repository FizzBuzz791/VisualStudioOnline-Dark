CREATE TABLE [dbo].[Models](
	[Id] [int] NOT NULL identity(1,1),
	[BlockId] [int] NULL,
	[Density] real NULL,
	[Filename] [nvarchar](200) NULL,
	[LastModifiedDate] [datetime] NULL,
	[LastModifiedUser] [nvarchar](50) NULL,
	[LumpPercent] real NULL,
	[Name] [nvarchar](50) NULL,
	[OreType] [nvarchar](50) NULL,
	[Tonnes] real NULL,
	[Volume] real NULL,
 CONSTRAINT [PK_Models] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Models]  WITH CHECK ADD  CONSTRAINT [FK_Models_Blocks] FOREIGN KEY([BlockId])
REFERENCES [dbo].[Blocks] ([Id])
GO
ALTER TABLE [dbo].[Models] CHECK CONSTRAINT [FK_Models_Blocks]
GO
