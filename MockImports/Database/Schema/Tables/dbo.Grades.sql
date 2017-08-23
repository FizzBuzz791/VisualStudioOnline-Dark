CREATE TABLE [dbo].[Grades](
	[Id] [int] NOT NULL identity(1,1),
	[FinesValue] decimal(12,6) NULL,
	[HeadValue] decimal(12,6) NULL,
	[LumpValue] decimal(12,6) NULL,
	[Name] [nvarchar](50) NULL,
	[SampleValue] decimal(12,6) NULL,
 CONSTRAINT [PK_Grades] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

