CREATE TABLE [dbo].[Polygons](
	[Id] [int] NOT NULL identity(1,1),
	[CentroidEasting] real NULL,
	[CentroidNorthing] real NULL,
	[CentroidRL] real NULL,
 CONSTRAINT [PK_Polygons] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
