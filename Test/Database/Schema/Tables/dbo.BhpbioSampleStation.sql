IF OBJECT_ID('dbo.BhpbioSampleStation') IS NOT NULL 
     DROP TABLE dbo.BhpbioSampleStation
GO 

CREATE TABLE [dbo].[BhpbioSampleStation](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Location_Id] [int] NOT NULL,
	[Weightometer_Id] [varchar](31) NOT NULL,
	[Name] [nvarchar](max) NOT NULL,
	[Description] [nvarchar](max) NOT NULL,
	[ProductSize] [varchar](5) NOT NULL,
 CONSTRAINT [PK_BhpbioSampleStation] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[BhpbioSampleStation]  WITH CHECK ADD  CONSTRAINT [FK_BhpbioSampleStation_Location] FOREIGN KEY([Location_Id])
REFERENCES [dbo].[Location] ([Location_Id])
GO

ALTER TABLE [dbo].[BhpbioSampleStation] CHECK CONSTRAINT [FK_BhpbioSampleStation_Location]
GO

ALTER TABLE [dbo].[BhpbioSampleStation]  WITH CHECK ADD  CONSTRAINT [FK_BhpbioSampleStation_Weightometer] FOREIGN KEY([Weightometer_Id])
REFERENCES [dbo].[Weightometer] ([Weightometer_Id])
GO

ALTER TABLE [dbo].[BhpbioSampleStation] CHECK CONSTRAINT [FK_BhpbioSampleStation_Weightometer]
GO