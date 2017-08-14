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

IF OBJECT_ID('dbo.BhpbioSampleStationTarget') IS NOT NULL 
     DROP TABLE dbo.BhpbioSampleStationTarget
GO 

CREATE TABLE [dbo].[BhpbioSampleStationTarget](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[SampleStation_Id] [int] NOT NULL,
	[StartDate] [date] NOT NULL,
	[CoverageTarget] [decimal](18,2) NOT NULL,
	[CoverageWarning] [decimal](18,2) NOT NULL,
	[RatioTarget] [int] NOT NULL,
	[RatioWarning] [int] NOT NULL,
 CONSTRAINT [PK_BhpbioSampleStationTarget] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[BhpbioSampleStationTarget]  WITH CHECK ADD  CONSTRAINT [FK_BhpbioSampleStationTarget_BhpbioSampleStation] FOREIGN KEY([SampleStation_Id])
REFERENCES [dbo].[BhpbioSampleStation] ([Id])
GO

ALTER TABLE [dbo].[BhpbioSampleStationTarget] CHECK CONSTRAINT [FK_BhpbioSampleStationTarget_BhpbioSampleStation]
GO

INSERT INTO [dbo].[SecurityOption] VALUES ('REC', 'UTILITIES_SAMPLE_STATION_VIEW', 'Utilities', 'Access to Sample Station List', 99)
INSERT INTO [dbo].[SecurityRoleOption] VALUES ('REC_VIEW', 'REC', 'UTILITIES_SAMPLE_STATION_VIEW')