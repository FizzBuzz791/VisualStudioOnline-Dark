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