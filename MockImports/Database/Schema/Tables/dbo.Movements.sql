CREATE TABLE [dbo].[Movements](
	[Id] [int] NOT NULL identity(1,1),
	[BlockId] [int] NULL,
	[DateFrom] [datetime] NULL,
	[DateTo] [datetime] NULL,
	[LastModifiedDate] [datetime] NULL,
	[LastModifiedUser] [nvarchar](50) NULL,
	[MinedPercentage] [float] NULL,
 CONSTRAINT [PK_Movements] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Movements]  WITH CHECK ADD  CONSTRAINT [FK_Movements_Blocks] FOREIGN KEY([BlockId])
REFERENCES [dbo].[Blocks] ([Id])
GO
ALTER TABLE [dbo].[Movements] CHECK CONSTRAINT [FK_Movements_Blocks]
GO
