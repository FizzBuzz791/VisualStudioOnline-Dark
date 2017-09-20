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

SET IDENTITY_INSERT BhpbioSampleStation ON -- Turn on ability to specify identity column value

-- Yandi
INSERT INTO BhpbioSampleStation (Id, Location_Id, Weightometer_Id, Name, Description, ProductSize)
	VALUES (1,3,'YD-Y1Outflow','SS1','Fines sample station associated with OHP1','FINES')
INSERT INTO BhpbioSampleStation (Id, Location_Id, Weightometer_Id, Name, Description, ProductSize)
	VALUES (2,3,'YD-Y2Outflow','SS2','Fines sample station associated with OHP2','FINES')
INSERT INTO BhpbioSampleStation (Id, Location_Id, Weightometer_Id, Name, Description, ProductSize)
	VALUES (3,3,'YD-Y3Outflow','SS3','Fines sample station associated with OHP3','FINES')

-- Area C
INSERT INTO BhpbioSampleStation (Id, Location_Id, Weightometer_Id, Name, Description, ProductSize)
	VALUES (4,7,'AC-C1OutFlow','SS210','Lump sample station associated with OHP1','LUMP')
INSERT INTO BhpbioSampleStation (Id, Location_Id, Weightometer_Id, Name, Description, ProductSize)
	VALUES (5,7,'AC-C1OutFlow','SS207','Fines sample station associated with OHP1','FINES')
INSERT INTO BhpbioSampleStation (Id, Location_Id, Weightometer_Id, Name, Description, ProductSize)
	VALUES (6,7,'AC-C2OutFlow','SS10','Lump sample station associated with OHP2','LUMP')
INSERT INTO BhpbioSampleStation (Id, Location_Id, Weightometer_Id, Name, Description, ProductSize)
	VALUES (7,7,'AC-C2OutFlow','SS07','Fines sample station associated with OHP2','FINES')
INSERT INTO BhpbioSampleStation (Id, Location_Id, Weightometer_Id, Name, Description, ProductSize)
	VALUES (8,7,'AC-C3OutFlow','ST02','Lump sample station associated with CSI','LUMP')
INSERT INTO BhpbioSampleStation (Id, Location_Id, Weightometer_Id, Name, Description, ProductSize)
	VALUES (9,7,'AC-C3OutFlow','ST01','Fines sample station associated with CSI','FINES')

-- Jimblebar
INSERT INTO BhpbioSampleStation (Id, Location_Id, Weightometer_Id, Name, Description, ProductSize)
	VALUES (10,12,'JB-OHP1OutFlow','SS108','Lump sample station associated with OHP','LUMP')
INSERT INTO BhpbioSampleStation (Id, Location_Id, Weightometer_Id, Name, Description, ProductSize)
	VALUES (11,12,'JB-OHP1OutFlow','SS105','Fines sample station associated with OHP','FINES')

-- Eastern Ridge
INSERT INTO BhpbioSampleStation (Id, Location_Id, Weightometer_Id, Name, Description, ProductSize)
	VALUES (12,11,'25-C1OutFlow','SS4','Lump sample station associated with OHP','LUMP')
INSERT INTO BhpbioSampleStation (Id, Location_Id, Weightometer_Id, Name, Description, ProductSize)
	VALUES (13,11,'25-C1OutFlow','SS1','Fines sample station associated with OHP','FINES')
INSERT INTO BhpbioSampleStation (Id, Location_Id, Weightometer_Id, Name, Description, ProductSize)
	VALUES (14,11,'25-PostC2ToTrainRake','SS551_ER','Virtual sample station associated with Primary Crusher at ER','ROM')

-- OB18
INSERT INTO BhpbioSampleStation (Id, Location_Id, Weightometer_Id, Name, Description, ProductSize)
	VALUES (15,10,'18-PostCrusherToTrainRake','SS551_OB18','Virtual sample station associated with Primary Crusher at OB18','ROM')

-- Newman / NJV
INSERT INTO BhpbioSampleStation (Id, Location_Id, Weightometer_Id, Name, Description, ProductSize)
	VALUES (16,9,'WB-C2OutFlow-Corrected','SS2','Decommissioned sample station associated with Primary Crusher 2','ROM')
INSERT INTO BhpbioSampleStation (Id, Location_Id, Weightometer_Id, Name, Description, ProductSize)
	VALUES (17,9,'WB-M232-Corrected','SS3','Unscreened Bene product output sample station','ROM')
INSERT INTO BhpbioSampleStation (Id, Location_Id, Weightometer_Id, Name, Description, ProductSize)
	VALUES (18,8,'NJV-OHP4OutflowCorrected','SS661','Lump sample station post COS associated with Primary Crusher 2','LUMP')
INSERT INTO BhpbioSampleStation (Id, Location_Id, Weightometer_Id, Name, Description, ProductSize)
	VALUES (19,8,'NJV-OHP4OutflowCorrected','SS651','Fines sample station post COS associated with Primary Crusher 2','FINES')
INSERT INTO BhpbioSampleStation (Id, Location_Id, Weightometer_Id, Name, Description, ProductSize)
	VALUES (20,9,'WB-C9DOutFlow','M231','Bene output conveyor to post crusher stockpiles sample station','ROM')
INSERT INTO BhpbioSampleStation (Id, Location_Id, Weightometer_Id, Name, Description, ProductSize)
	VALUES (21,9,'NJV-OHP5Outflow','ST01','Fines sample station associated with OHP5','FINES')
INSERT INTO BhpbioSampleStation (Id, Location_Id, Weightometer_Id, Name, Description, ProductSize)
	VALUES (22,9,'NJV-OHP5Outflow','CV10','Lump sample station associated with OHP5','LUMP')

SET IDENTITY_INSERT BhpbioSampleStation OFF -- Turn off ability to specify identity column value

INSERT INTO BhpbioSampleStationTarget
	VALUES (1,'2014-09-01',NULL,0.9,0.8,5000,6000)
INSERT INTO BhpbioSampleStationTarget
	VALUES (2,'2014-09-01',NULL,0.9,0.8,5000,6000)
INSERT INTO BhpbioSampleStationTarget
	VALUES (3,'2014-09-01',NULL,0.9,0.8,5000,6000)
INSERT INTO BhpbioSampleStationTarget
	VALUES (4,'2014-09-01',NULL,0.9,0.8,5000,6000)
INSERT INTO BhpbioSampleStationTarget
	VALUES (5,'2014-09-01',NULL,0.9,0.8,5000,6000)
INSERT INTO BhpbioSampleStationTarget
	VALUES (6,'2014-09-01',NULL,0.9,0.8,5000,6000)
INSERT INTO BhpbioSampleStationTarget
	VALUES (7,'2014-09-01',NULL,0.9,0.8,5000,6000)
INSERT INTO BhpbioSampleStationTarget
	VALUES (8,'2014-09-01',NULL,0.9,0.8,5000,6000)
INSERT INTO BhpbioSampleStationTarget
	VALUES (9,'2014-09-01',NULL,0.9,0.8,5000,6000)
INSERT INTO BhpbioSampleStationTarget
	VALUES (10,'2014-09-01',NULL,0.9,0.8,5000,6000)
INSERT INTO BhpbioSampleStationTarget
	VALUES (11,'2014-09-01',NULL,0.9,0.8,5000,6000)
INSERT INTO BhpbioSampleStationTarget
	VALUES (12,'2014-09-01',NULL,0.9,0.8,5000,6000)
INSERT INTO BhpbioSampleStationTarget
	VALUES (13,'2014-09-01',NULL,0.9,0.8,5000,6000)
INSERT INTO BhpbioSampleStationTarget
	VALUES (14,'2014-09-01',NULL,0.9,0.8,5000,6000)
INSERT INTO BhpbioSampleStationTarget
	VALUES (15,'2014-09-01',NULL,0.9,0.8,5000,6000)
INSERT INTO BhpbioSampleStationTarget
	VALUES (16,'2014-09-01',NULL,0.9,0.8,5000,6000)
INSERT INTO BhpbioSampleStationTarget
	VALUES (17,'2014-09-01',NULL,0.9,0.8,5000,6000)
INSERT INTO BhpbioSampleStationTarget
	VALUES (18,'2014-09-01',NULL,0.9,0.8,5000,6000)
INSERT INTO BhpbioSampleStationTarget
	VALUES (19,'2014-09-01',NULL,0.9,0.8,5000,6000)
INSERT INTO BhpbioSampleStationTarget
	VALUES (20,'2014-09-01',NULL,0.9,0.8,5000,6000)
INSERT INTO BhpbioSampleStationTarget
	VALUES (21,'2014-09-01',NULL,0.9,0.8,5000,6000)
INSERT INTO BhpbioSampleStationTarget
	VALUES (22,'2014-09-01',NULL,0.9,0.8,5000,6000)