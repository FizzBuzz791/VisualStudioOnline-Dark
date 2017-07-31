--------------------------------------------------------------------------------------------
-- This script inserts all data needed to run Block import tests and is safe to rerun
--
-- All data is inserted with Ids in the range 10,000 to 10,999
--
-- 2 Blocks are used
--
--		A01 inserted 2014-07-05
--		A02 inserted 2014-07-06
--		A01 updated 2014-07-15		(grade values and model tonnes changed)
--		A02 deleted 2014-07-26
--
-- update an existing block (outside of this test set)
--------------------------------------------------------------------------------------------

DELETE FROM [dbo].[ModelGrades] WHERE [GradeId] BETWEEN 10000 AND 10999
DELETE FROM [dbo].[Models] WHERE [BlockId] BETWEEN 10000 AND 10999
DELETE FROM [dbo].[Movements] WHERE [BlockId] BETWEEN 10000 AND 10999
DELETE FROM [dbo].[Blocks] WHERE [Id] BETWEEN 10000 AND 10999
DELETE FROM [dbo].[Patterns] WHERE [Id] BETWEEN 10000 AND 10999
DELETE FROM [dbo].[Points] WHERE [Id] BETWEEN 10000 AND 10999
DELETE FROM [dbo].[Polygons] WHERE [Id] BETWEEN 10000 AND 10999
DELETE FROM [dbo].[Grades] WHERE [Id] BETWEEN 10000 AND 10999

---

DECLARE @modifiedDate as DateTime
DECLARE @blockA01InsertionDate as DateTime 
DECLARE @blockA02InsertionDate as DateTime
DECLARE @blockA01UpdateDate as DateTime 
DECLARE @blockA02DeletionDate as DateTime 
DECLARE @blockExistingModifyDate as DateTime
DECLARE @blockExistingModify2Date as DateTime
DECLARE @blockExistingDeleteDate as DateTime 

SET @blockA01InsertionDate= '2014-07-05'
SET @blockA02InsertionDate = '2014-07-06'
SET @blockA01UpdateDate  = '2014-07-15'
SET @blockA02DeletionDate  = '2014-07-26'
SET @blockExistingModifyDate  = '2014-08-03'
SET @blockExistingModify2Date  = '2014-09-03'
SET @blockExistingDeleteDate= '2014-09-13'
-----------------------------------------------------------------------------------------------
--- BLOCK A01   -- INSERTION
-----------------------------------------------------------------------------------------------
SET @modifiedDate = @blockA01InsertionDate

-- Insert Polygon data
SET IDENTITY_INSERT [Polygons] ON
INSERT INTO [dbo].[Polygons] (Id, [CentroidEasting] ,[CentroidNorthing] ,[CentroidRL])
			VALUES (10000, 31100 ,32100 ,33100) 
SET IDENTITY_INSERT [Polygons] OFF

-- Insert Point data
SET IDENTITY_INSERT [Points] ON
INSERT INTO [dbo].[Points] (Id, [Number] ,[PolygonId] ,[Easting] ,[Northing] ,[RL])
			Values (10001, '1' ,10000 ,41 ,51 ,61)
INSERT INTO [dbo].[Points] (Id, [Number] ,[PolygonId] ,[Easting] ,[Northing] ,[RL])
			Values (10002, '2' ,10000 ,51 ,51 ,61)
INSERT INTO [dbo].[Points] (Id, [Number] ,[PolygonId] ,[Easting] ,[Northing] ,[RL])
			Values (10003, '3' ,10000 ,51 ,51 ,41)
SET IDENTITY_INSERT [Points] OFF

-- Insert Pattern for Block
SET IDENTITY_INSERT [Patterns] ON
INSERT INTO [dbo].[Patterns] (Id, [Bench] ,[Number] ,[Orebody] ,[Pit] ,[Site])
			VALUES (10000, '0599' ,'0820' ,'18' ,'SP' ,'OB18') 
SET IDENTITY_INSERT [Patterns] OFF

-- Insert Block
SET IDENTITY_INSERT [Blocks] ON
INSERT INTO [dbo].[Blocks] (Id, [BlastedDate] ,[BlockedDate] ,[GeoType] ,[LastModifiedDate] ,[LastModifiedUser] ,[MQ2PitCode] ,[Name] ,[Number] ,[PatternId] ,[PolygonId])
			VALUES (10000, '2014-07-03' ,'2014-07-04' ,'D1' ,@modifiedDate ,'UserTest20characters' ,'18SP' ,'A01' ,1 ,10000 ,10000)
SET IDENTITY_INSERT [Blocks] OFF

-- Insert Model Data for Block
SET IDENTITY_INSERT [Models] ON
INSERT INTO [dbo].[Models] (Id, [BlockId] ,[Density] ,[Filename] ,[LastModifiedDate] ,[LastModifiedUser] ,[LumpPercent] ,[Name] ,[OreType] ,[Tonnes] ,[Volume])
			Values (10001, 10000, 2.7 ,'File101' ,'2014-07-09' ,'UserTest20characters' ,41 ,'Geology' ,'HG' ,100 ,270)

INSERT INTO [dbo].[Models] (Id, [BlockId] ,[Density] ,[Filename] ,[LastModifiedDate] ,[LastModifiedUser] ,[LumpPercent] ,[Name] ,[OreType] ,[Tonnes] ,[Volume])
			Values (10011, 10000, 2.69 ,'File102' ,'2014-07-09' ,'UserTest20characters' ,42 ,'Mining' ,'HG' ,101 ,273)

INSERT INTO [dbo].[Models] (Id, [BlockId] ,[Density] ,[Filename] ,[LastModifiedDate] ,[LastModifiedUser] ,[LumpPercent] ,[Name] ,[OreType] ,[Tonnes] ,[Volume])
			Values (10021, 10000, 2.71 ,'File102' ,'2014-07-09' ,'UserTest20characters' ,43 ,'Block' ,'HG' ,102 ,276)

INSERT INTO [dbo].[Models] (Id, [BlockId] ,[Density] ,[Filename] ,[LastModifiedDate] ,[LastModifiedUser] ,[LumpPercent] ,[Name] ,[OreType] ,[Tonnes] ,[Volume])
			Values (10031, 10000, 2.73 ,'File103' ,'2014-07-09' ,'UserTest20characters' ,43 ,'STGM' ,'HG' ,102 ,276)
SET IDENTITY_INSERT [Models] OFF

-- Insert Grades
SET IDENTITY_INSERT [Grades] ON
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10001, 58.1 ,58.3 , 58.4, 'Fe') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10002, 6.0 ,6.1 ,6.2, 'P') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10003, 1.0 ,1.1 ,1.2, 'SiO2') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10004, 1.0 ,1.1 ,1.2, 'Al2O3') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10005, 1.0 ,1.1 ,1.2, 'LOI') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10006, 1.0 ,1.1 ,1.2, 'Density') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10007, 8.2 ,8.3 ,8.4, 'H2O') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10008, 7.9 ,7.8 ,7.8, 'H2O-As-Dropped') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10009, 7.7 ,7.8 ,7.9, 'H2O-As-Shipped') 

INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10011, 57.1 ,57.3 , 57.4, 'Fe') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10012, 5.0 ,5.1 ,5.2, 'P') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10013, 1.0 ,1.1 ,1.2, 'SiO2') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10014, 1.0 ,1.1 ,1.2, 'Al2O3') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10015, 1.0 ,1.1 ,1.2, 'LOI') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10016, 1.0 ,1.1 ,1.2, 'Density') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10017, 7.79 ,7.79 ,7.68, 'H2O') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10018, 7.8 ,7.7 ,7.6, 'H2O-As-Dropped') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10019, 7.6 ,7.7 ,7.8, 'H2O-As-Shipped') 

INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10021, 59.1 ,59.3 , 59.4, 'Fe') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10022, 7.0 ,7.1 ,7.2, 'P') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10023, 1.0 ,1.1 ,1.2, 'SiO2') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10024, 1.0 ,1.1 ,1.2, 'Al2O3') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10025, 1.0 ,1.1 ,1.2, 'LOI') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10026, 1.0 ,1.1 ,1.2, 'Density') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10027, 8.11 ,8.1 ,8.1, 'H2O') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10028, 8.2 ,8.1 ,8.1, 'H2O-As-Dropped') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10029, 8.3 ,8.2 ,8.2, 'H2O-As-Shipped') 

INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10031, 59.1 ,61.3 , 59.5, 'Fe') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10032, 7.0 ,7.1 ,7.2, 'P') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10033, 1.0 ,1.1 ,1.2, 'SiO2') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10034, 1.0 ,1.1 ,1.2, 'Al2O3') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10035, 1.0 ,1.1 ,1.2, 'LOI') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10036, 1.0 ,1.1 ,1.2, 'Density') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10037, 8.57 ,8.7 ,8.7, 'H2O') 

SET IDENTITY_INSERT [Grades] OFF

-- Insert Model Grade links
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10001, 10001)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10002, 10001)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10003, 10001)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10004, 10001)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10005, 10001)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10006, 10001)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10007, 10001)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10008, 10001)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10009, 10001)

INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10011, 10011)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10012, 10011)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10013, 10011)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10014, 10011)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10015, 10011)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10016, 10011)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10017, 10011)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10018, 10011)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10019, 10011)

INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10021, 10021)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10022, 10021)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10023, 10021)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10024, 10021)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10025, 10021)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10026, 10021)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10027, 10021)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10028, 10021)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10029, 10021)

INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10031, 10031)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10032, 10031)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10033, 10031)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10034, 10031)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10035, 10031)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10036, 10031)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10037, 10031)

-----------------------------------------------------------------------------------------------
--- BLOCK A02   -- INSERTION
-----------------------------------------------------------------------------------------------

SET @modifiedDate = @blockA02InsertionDate

-- Insert Polygon data
SET IDENTITY_INSERT [Polygons] ON
INSERT INTO [dbo].[Polygons] (Id, [CentroidEasting] ,[CentroidNorthing] ,[CentroidRL])
			VALUES (10100, 31101 ,32101 ,33101) 
SET IDENTITY_INSERT [Polygons] OFF

-- Insert Point data
SET IDENTITY_INSERT [Points] ON
INSERT INTO [dbo].[Points] (Id, [Number] ,[PolygonId] ,[Easting] ,[Northing] ,[RL])
			Values (10101, '1' ,10100 ,42 ,52 ,62)
INSERT INTO [dbo].[Points] (Id, [Number] ,[PolygonId] ,[Easting] ,[Northing] ,[RL])
			Values (10102, '2' ,10100 ,52 ,52 ,62)
INSERT INTO [dbo].[Points] (Id, [Number] ,[PolygonId] ,[Easting] ,[Northing] ,[RL])
			Values (10103, '3' ,10100 ,52 ,52 ,42)
SET IDENTITY_INSERT [Points] OFF

-- Insert Pattern for Block
SET IDENTITY_INSERT [Patterns] ON
INSERT INTO [dbo].[Patterns] (Id, [Bench] ,[Number] ,[Orebody] ,[Pit] ,[Site])
			VALUES (10100, '0599' ,'0820' ,'18' ,'SP' ,'OB18') 
SET IDENTITY_INSERT [Patterns] OFF

-- Insert Block
SET IDENTITY_INSERT [Blocks] ON
INSERT INTO [dbo].[Blocks] (Id, [BlastedDate] ,[BlockedDate] ,[GeoType] ,[LastModifiedDate] ,[LastModifiedUser] ,[MQ2PitCode] ,[Name] ,[Number] ,[PatternId] ,[PolygonId])
			VALUES (10100, '2014-07-03' ,'2014-07-04' ,'D2' ,@modifiedDate ,'UserTest20characters' ,'18SP' ,'A02' ,2 ,10100 ,10100)
SET IDENTITY_INSERT [Blocks] OFF

-- Insert Model Data for Block
SET IDENTITY_INSERT [Models] ON
INSERT INTO [dbo].[Models] (Id, [BlockId] ,[Density] ,[Filename] ,[LastModifiedDate] ,[LastModifiedUser] ,[LumpPercent] ,[Name] ,[OreType] ,[Tonnes] ,[Volume])
			Values (10101, 10100, 2.7 ,'File201' ,'2014-07-09' ,'UserTest20characters' ,41 ,'Geology' ,'HG' ,120 ,270)

INSERT INTO [dbo].[Models] (Id, [BlockId] ,[Density] ,[Filename] ,[LastModifiedDate] ,[LastModifiedUser] ,[LumpPercent] ,[Name] ,[OreType] ,[Tonnes] ,[Volume])
			Values (10111, 10100, 2.69 ,'File202' ,'2014-07-09' ,'UserTest20characters' ,42 ,'Mining' ,'HG' ,121 ,273)

INSERT INTO [dbo].[Models] (Id, [BlockId] ,[Density] ,[Filename] ,[LastModifiedDate] ,[LastModifiedUser] ,[LumpPercent] ,[Name] ,[OreType] ,[Tonnes] ,[Volume])
			Values (10121, 10100, 2.71 ,'File202' ,'2014-07-09' ,'UserTest20characters' ,43 ,'Block' ,'HG' ,122 ,276)

INSERT INTO [dbo].[Models] (Id, [BlockId] ,[Density] ,[Filename] ,[LastModifiedDate] ,[LastModifiedUser] ,[LumpPercent] ,[Name] ,[OreType] ,[Tonnes] ,[Volume])
			Values (10131, 10100, 2.73 ,'File103' ,'2014-07-09' ,'UserTest20characters' ,43 ,'STGM' ,'HG' ,102 ,276)
SET IDENTITY_INSERT [Models] OFF

-- Insert Grades
SET IDENTITY_INSERT [Grades] ON
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10101, 48.1 ,48.3 , 48.4, 'Fe') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10102, 9.0 ,9.1 ,9.2, 'P') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10103, 1.0 ,1.1 ,1.2, 'SiO2') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10104, 1.0 ,1.1 ,1.2, 'Al2O3') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10105, 1.0 ,1.1 ,1.2, 'LOI') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10106, 1.0 ,1.1 ,1.2, 'Density') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10107, 8.1 ,8.2 ,8.3, 'H2O') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10108, 7.9 ,7.8 ,7.8, 'H2O-As-Dropped') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10109, 7.7 ,7.8 ,7.9, 'H2O-As-Shipped') 

INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10111, 47.1 ,47.3 , 47.4, 'Fe') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10112, 8.0 ,8.1 ,8.2, 'P') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10113, 1.0 ,1.1 ,1.2, 'SiO2') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10114, 1.0 ,1.1 ,1.2, 'Al2O3') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10115, 1.0 ,1.1 ,1.2, 'LOI') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10116, 1.0 ,1.1 ,1.2, 'Density') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10117, 8.05 ,8.1 ,8.2, 'H2O') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10118, 7.8 ,7.6 ,7.5, 'H2O-As-Dropped') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10119, 7.7 ,7.8 ,7.9, 'H2O-As-Shipped') 

INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10121, 49.1 ,49.3 , 49.4, 'Fe') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10122, 4.0 ,4.1 ,4.2, 'P') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10123, 1.0 ,1.1 ,1.2, 'SiO2') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10124, 1.0 ,1.1 ,1.2, 'Al2O3') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10125, 1.0 ,1.1 ,1.2, 'LOI') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10126, 1.0 ,1.1 ,1.2, 'Density') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10127, 8.03 ,8.1 ,8.2, 'H2O') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10128, 7.1 ,7.2 ,7.3, 'H2O-As-Dropped') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10129, 7.7 ,7.8 ,7.9, 'H2O-As-Shipped') 

INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10131, 59.1 ,61.3 , 59.5, 'Fe') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10132, 7.0 ,7.1 ,7.2, 'P') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10133, 1.0 ,1.1 ,1.2, 'SiO2') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10134, 1.0 ,1.1 ,1.2, 'Al2O3') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10135, 1.0 ,1.1 ,1.2, 'LOI') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10136, 1.0 ,1.1 ,1.2, 'Density') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10137, 8.02 ,8.3 ,8.4, 'H2O') 

SET IDENTITY_INSERT [Grades] OFF

-- Insert Model Grade links
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10101, 10101)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10102, 10101)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10103, 10101)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10104, 10101)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10105, 10101)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10106, 10101)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10107, 10101)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10108, 10101)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10109, 10101)

INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10111, 10111)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10112, 10111)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10113, 10111)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10114, 10111)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10115, 10111)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10116, 10111)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10117, 10111)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10118, 10111)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10119, 10111)

INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10121, 10121)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10122, 10121)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10123, 10121)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10124, 10121)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10125, 10121)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10126, 10121)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10127, 10121)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10128, 10121)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10129, 10121)

INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10131, 10131)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10132, 10131)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10133, 10131)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10134, 10131)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10135, 10131)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10136, 10131)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10137, 10131)


-----------------------------------------------------------------------------------------------
--- BLOCK A01   -- UPDATE
-----------------------------------------------------------------------------------------------

SET @modifiedDate = @blockA01UpdateDate

-- Insert Polygon data
SET IDENTITY_INSERT [Polygons] ON
INSERT INTO [dbo].[Polygons] (Id, [CentroidEasting] ,[CentroidNorthing] ,[CentroidRL])
			VALUES (10200, 31100 ,32100 ,33100) 
SET IDENTITY_INSERT [Polygons] OFF

-- Insert Point data
SET IDENTITY_INSERT [Points] ON
INSERT INTO [dbo].[Points] (Id, [Number] ,[PolygonId] ,[Easting] ,[Northing] ,[RL])
			Values (10201, '1' ,10200 ,43 ,53 ,63)
INSERT INTO [dbo].[Points] (Id, [Number] ,[PolygonId] ,[Easting] ,[Northing] ,[RL])
			Values (10202, '2' ,10200 ,53 ,53 ,63)
INSERT INTO [dbo].[Points] (Id, [Number] ,[PolygonId] ,[Easting] ,[Northing] ,[RL])
			Values (10203, '3' ,10200 ,53 ,53 ,43)
SET IDENTITY_INSERT [Points] OFF

-- Insert Pattern for Block
SET IDENTITY_INSERT [Patterns] ON
INSERT INTO [dbo].[Patterns] (Id, [Bench] ,[Number] ,[Orebody] ,[Pit] ,[Site])
			VALUES (10200, '0599' ,'0820' ,'18' ,'SP' ,'OB18') 
SET IDENTITY_INSERT [Patterns] OFF

-- Insert Block
SET IDENTITY_INSERT [Blocks] ON
INSERT INTO [dbo].[Blocks] (Id, [BlastedDate] ,[BlockedDate] ,[GeoType] ,[LastModifiedDate] ,[LastModifiedUser] ,[MQ2PitCode] ,[Name] ,[Number] ,[PatternId] ,[PolygonId])
			VALUES (10200, '2014-07-03' ,'2014-07-04' ,'D1' ,@modifiedDate ,'UserTest20characters' ,'18SP' ,'A01' ,1 ,10200 ,10200)
SET IDENTITY_INSERT [Blocks] OFF

-- Insert Model Data for Block
SET IDENTITY_INSERT [Models] ON
INSERT INTO [dbo].[Models] (Id, [BlockId] ,[Density] ,[Filename] ,[LastModifiedDate] ,[LastModifiedUser] ,[LumpPercent] ,[Name] ,[OreType] ,[Tonnes] ,[Volume])
			Values (10201, 10200, 2.7 ,'File101' ,'2014-07-09' ,'UserTest20characters' ,41 ,'Geology' ,'HG' ,150 ,270)

INSERT INTO [dbo].[Models] (Id, [BlockId] ,[Density] ,[Filename] ,[LastModifiedDate] ,[LastModifiedUser] ,[LumpPercent] ,[Name] ,[OreType] ,[Tonnes] ,[Volume])
			Values (10211, 10200, 2.69 ,'File102' ,'2014-07-09' ,'UserTest20characters' ,42 ,'Mining' ,'HG' ,151 ,273)

INSERT INTO [dbo].[Models] (Id, [BlockId] ,[Density] ,[Filename] ,[LastModifiedDate] ,[LastModifiedUser] ,[LumpPercent] ,[Name] ,[OreType] ,[Tonnes] ,[Volume])
			Values (10221, 10200, 2.71 ,'File102' ,'2014-07-09' ,'UserTest20characters' ,43 ,'Block' ,'HG' ,152 ,276)

INSERT INTO [dbo].[Models] (Id, [BlockId] ,[Density] ,[Filename] ,[LastModifiedDate] ,[LastModifiedUser] ,[LumpPercent] ,[Name] ,[OreType] ,[Tonnes] ,[Volume])
			Values (10231, 10200, 2.73 ,'File103' ,'2014-07-09' ,'UserTest20characters' ,43 ,'STGM' ,'HG' ,152 ,276)
SET IDENTITY_INSERT [Models] OFF

-- Insert Grades	
SET IDENTITY_INSERT [Grades] ON
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10201, 56.1 ,56.3 , 56.4, 'Fe') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10202, 6.0 ,6.1 ,6.2, 'P') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10203, 1.0 ,1.1 ,1.2, 'SiO2') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10204, 1.0 ,1.1 ,1.2, 'Al2O3') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10205, 1.0 ,1.1 ,1.2, 'LOI') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10206, 1.0 ,1.1 ,1.2, 'Density') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10207, 8.1 ,8.1 ,8.2, 'H2O') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10208, 7.9 ,7.8 ,7.8, 'H2O-As-Dropped') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10209, 7.7 ,7.8 ,7.9, 'H2O-As-Shipped') 

INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10211, 58.1 ,58.3 , 58.4, 'Fe') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10212, 5.0 ,5.1 ,5.2, 'P') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10213, 1.0 ,1.1 ,1.2, 'SiO2') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10214, 1.0 ,1.1 ,1.2, 'Al2O3') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10215, 1.0 ,1.1 ,1.2, 'LOI') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10216, 1.0 ,1.1 ,1.2, 'Density') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10217, 8.2 ,8.1 ,8.2, 'H2O') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10218, 7.9 ,7.8 ,7.8, 'H2O-As-Dropped') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10219, 7.7 ,7.8 ,7.9, 'H2O-As-Shipped') 

INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10221, 59.1 ,60.3 , 59.4, 'Fe') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10222, 7.0 ,7.1 ,7.2, 'P') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10223, 1.0 ,1.1 ,1.2, 'SiO2') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10224, 1.0 ,1.1 ,1.2, 'Al2O3') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10225, 1.0 ,1.1 ,1.2, 'LOI') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10226, 1.0 ,1.1 ,1.2, 'Density') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10227, 8.4 ,8.1 ,8.2, 'H2O') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10228, 7.9 ,7.8 ,7.8, 'H2O-As-Dropped') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10229, 7.7 ,7.8 ,7.9, 'H2O-As-Shipped') 

INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10231, 59.1 ,60.3 , 59.4, 'Fe') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10232, 7.0 ,7.1 ,7.2, 'P') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10233, 1.0 ,1.1 ,1.2, 'SiO2') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10234, 1.0 ,1.1 ,1.2, 'Al2O3') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10235, 1.0 ,1.1 ,1.2, 'LOI') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10236, 1.0 ,1.1 ,1.2, 'Density')
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10237, 8.04 ,8.1 ,8.2, 'H2O') 

SET IDENTITY_INSERT [Grades] OFF

-- Insert Model Grade links
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10201, 10201)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10202, 10201)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10203, 10201)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10204, 10201)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10205, 10201)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10206, 10201)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10207, 10201)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10208, 10201)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10209, 10201)

INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10211, 10211)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10212, 10211)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10213, 10211)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10214, 10211)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10215, 10211)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10216, 10211)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10217, 10211)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10218, 10211)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10219, 10211)

INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10221, 10221)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10222, 10221)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10223, 10221)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10224, 10221)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10225, 10221)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10226, 10221)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10227, 10221)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10228, 10221)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10229, 10221)

INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10231, 10231)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10232, 10231)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10233, 10231)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10234, 10231)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10235, 10231)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10236, 10231)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10237, 10231)

-----------------------------------------------------------------------------------------------
--- BLOCK A02   -- DELETE
-----------------------------------------------------------------------------------------------

SET @modifiedDate = @blockA02DeletionDate

-- Insert Polygon data
SET IDENTITY_INSERT [Polygons] ON
INSERT INTO [dbo].[Polygons] (Id, [CentroidEasting] ,[CentroidNorthing] ,[CentroidRL])
			VALUES (10300, 31101 ,32101 ,33101) 
SET IDENTITY_INSERT [Polygons] OFF

-- Insert Point data
SET IDENTITY_INSERT [Points] ON
INSERT INTO [dbo].[Points] (Id, [Number] ,[PolygonId] ,[Easting] ,[Northing] ,[RL])
			Values (10301, '1' ,10300 ,44 ,54 ,64)
INSERT INTO [dbo].[Points] (Id, [Number] ,[PolygonId] ,[Easting] ,[Northing] ,[RL])
			Values (10302, '2' ,10300 ,54 ,54 ,64)
INSERT INTO [dbo].[Points] (Id, [Number] ,[PolygonId] ,[Easting] ,[Northing] ,[RL])
			Values (10303, '3' ,10300 ,54 ,54 ,44)
SET IDENTITY_INSERT [Points] OFF

-- Insert Pattern for Block
SET IDENTITY_INSERT [Patterns] ON
INSERT INTO [dbo].[Patterns] (Id, [Bench] ,[Number] ,[Orebody] ,[Pit] ,[Site])
			VALUES (10300, '0599' ,'0820' ,'18' ,'SP' ,'OB18') 
SET IDENTITY_INSERT [Patterns] OFF

-- Insert Block
SET IDENTITY_INSERT [Blocks] ON
INSERT INTO [dbo].[Blocks] (Id, [BlastedDate] ,[BlockedDate] ,[GeoType] ,[LastModifiedDate] ,[LastModifiedUser] ,[MQ2PitCode] ,[Name] ,[Number] ,[PatternId] ,[PolygonId], IsDelete)
			VALUES (10300, '2014-07-03' ,'2014-07-04' ,'D1' ,@modifiedDate ,'UserTest20characters' ,'18SP' ,'A02' ,2 , 10300, 10300, 1)
SET IDENTITY_INSERT [Blocks] OFF

-- Insert Model Data for Block
SET IDENTITY_INSERT [Models] ON
INSERT INTO [dbo].[Models] (Id, [BlockId] ,[Density] ,[Filename] ,[LastModifiedDate] ,[LastModifiedUser] ,[LumpPercent] ,[Name] ,[OreType] ,[Tonnes] ,[Volume])
			Values (10301, 10300, 2.7 ,'File101' ,'2013-07-09' ,'UserTest20characters' ,41 ,'Geology' ,'HG' ,100 ,270)

INSERT INTO [dbo].[Models] (Id, [BlockId] ,[Density] ,[Filename] ,[LastModifiedDate] ,[LastModifiedUser] ,[LumpPercent] ,[Name] ,[OreType] ,[Tonnes] ,[Volume])
			Values (10311, 10300, 2.69 ,'File102' ,'2013-07-09' ,'UserTest20characters' ,42 ,'Mining' ,'HG' ,101 ,273)

INSERT INTO [dbo].[Models] (Id, [BlockId] ,[Density] ,[Filename] ,[LastModifiedDate] ,[LastModifiedUser] ,[LumpPercent] ,[Name] ,[OreType] ,[Tonnes] ,[Volume])
			Values (10321, 10300, 2.71 ,'File102' ,'2013-07-09' ,'UserTest20characters' ,43 ,'Block' ,'HG' ,102 ,276)

INSERT INTO [dbo].[Models] (Id, [BlockId] ,[Density] ,[Filename] ,[LastModifiedDate] ,[LastModifiedUser] ,[LumpPercent] ,[Name] ,[OreType] ,[Tonnes] ,[Volume])
			Values (10331, 10300, 2.73 ,'File103' ,'2014-07-09' ,'UserTest20characters' ,43 ,'STGM' ,'HG' ,102 ,276)
SET IDENTITY_INSERT [Models] OFF

-- Insert Grades
SET IDENTITY_INSERT [Grades] ON
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10301, 58.1 ,58.3 , 58.4, 'Fe') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10302, 6.0 ,6.1 ,6.2, 'P') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10303, 1.0 ,1.1 ,1.2, 'SiO2') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10304, 1.0 ,1.1 ,1.2, 'Al2O3') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10305, 1.0 ,1.1 ,1.2, 'LOI') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10306, 1.0 ,1.1 ,1.2, 'Density') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10307, 8.02 ,8.1 ,8.2, 'H2O') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10308, 7.9 ,7.8 ,7.8, 'H2O-As-Dropped') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10309, 7.7 ,7.8 ,7.9, 'H2O-As-Shipped') 

INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10311, 57.1 ,57.3 , 57.4, 'Fe') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10312, 5.0 ,5.1 ,5.2, 'P') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10313, 1.0 ,1.1 ,1.2, 'SiO2') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10314, 1.0 ,1.1 ,1.2, 'Al2O3') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10315, 1.0 ,1.1 ,1.2, 'LOI') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10316, 1.0 ,1.1 ,1.2, 'Density') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10317, 8.01 ,8.1 ,8.2, 'H2O') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10318, 7.9 ,7.8 ,7.8, 'H2O-As-Dropped') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10319, 7.7 ,7.8 ,7.9, 'H2O-As-Shipped') 

INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10321, 59.1 ,59.3 , 59.4, 'Fe') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10322, 7.0 ,7.1 ,7.2, 'P') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10323, 1.0 ,1.1 ,1.2, 'SiO2') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10324, 1.0 ,1.1 ,1.2, 'Al2O3') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10325, 1.0 ,1.1 ,1.2, 'LOI') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10326, 1.0 ,1.1 ,1.2, 'Density') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10327, 8.01 ,8.1 ,8.2, 'H2O') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10328, 7.9 ,7.8 ,7.8, 'H2O-As-Dropped') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10329, 7.7 ,7.8 ,7.9, 'H2O-As-Shipped') 

INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10331, 59.1 ,59.3 , 59.4, 'Fe') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10332, 7.0 ,7.1 ,7.2, 'P') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10333, 1.0 ,1.1 ,1.2, 'SiO2') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10334, 1.0 ,1.1 ,1.2, 'Al2O3') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10335, 1.0 ,1.1 ,1.2, 'LOI') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10336, 1.0 ,1.1 ,1.2, 'Density') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10337, 8.09 ,8.1 ,8.2, 'H2O') 

SET IDENTITY_INSERT [Grades] OFF

-- Insert Model Grade links
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10301, 10301)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10302, 10301)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10303, 10301)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10304, 10301)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10305, 10301)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10306, 10301)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10307, 10301)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10308, 10301)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10309, 10301)

INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10311, 10311)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10312, 10311)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10313, 10311)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10314, 10311)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10315, 10311)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10316, 10311)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10317, 10311)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10318, 10311)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10319, 10311)

INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10321, 10321)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10322, 10321)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10323, 10321)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10324, 10321)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10325, 10321)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10326, 10321)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10327, 10321)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10328, 10321)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10329, 10321)

INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10331, 10331)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10332, 10331)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10333, 10331)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10334, 10331)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10335, 10331)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10336, 10331)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10337, 10331)

--------------------------------
-- EXISTING BLOCK MODIFY

SET @modifiedDate = @blockExistingModifyDate

-- Insert Polygon data
SET IDENTITY_INSERT [Polygons] ON
INSERT INTO [dbo].[Polygons] (Id, [CentroidEasting] ,[CentroidNorthing] ,[CentroidRL])
			VALUES (10400, 364731.4 ,288706.7 ,501) 
SET IDENTITY_INSERT [Polygons] OFF



-- Insert Point data
SET IDENTITY_INSERT [Points] ON
INSERT INTO [dbo].[Points] (Id, [Number] ,[PolygonId] ,[Easting] ,[Northing] ,[RL])
			Values (10401, '1' ,10400 ,45 ,55 ,65)
INSERT INTO [dbo].[Points] (Id, [Number] ,[PolygonId] ,[Easting] ,[Northing] ,[RL])
			Values (10402, '2' ,10400 ,55 ,55 ,65)
INSERT INTO [dbo].[Points] (Id, [Number] ,[PolygonId] ,[Easting] ,[Northing] ,[RL])
			Values (10403, '3' ,10400 ,55 ,55 ,45)
SET IDENTITY_INSERT [Points] OFF

-- Insert Pattern for Block
SET IDENTITY_INSERT [Patterns] ON
INSERT INTO [dbo].[Patterns] (Id, [Bench] ,[Number] ,[Orebody] ,[Pit] ,[Site])
			VALUES (10400, '0599' ,'0820' ,'18' ,'SP' ,'OB18') 
SET IDENTITY_INSERT [Patterns] OFF

-- Insert Block
SET IDENTITY_INSERT [Blocks] ON
INSERT INTO [dbo].[Blocks] (Id, [BlastedDate] ,[BlockedDate] ,[GeoType] ,[LastModifiedDate] ,[LastModifiedUser] ,[MQ2PitCode] ,[Name] ,[Number] ,[PatternId] ,[PolygonId], IsDelete)
			VALUES (10400, '2014-08-03' ,'2014-08-04' ,'D1' ,@modifiedDate ,'UserTest20characters' ,'18SP' ,'1' ,1 , 10400, 10400, 0)
SET IDENTITY_INSERT [Blocks] OFF

-- Insert Model Data for Block
SET IDENTITY_INSERT [Models] ON
INSERT INTO [dbo].[Models] (Id, [BlockId] ,[Density] ,[Filename] ,[LastModifiedDate] ,[LastModifiedUser] ,[LumpPercent] ,[Name] ,[OreType] ,[Tonnes] ,[Volume])
			Values (10401, 10400, 2.7 ,'File101' ,'2014-08-03' ,'UserTest20characters' ,41 ,'Geology' ,'HG' ,100 ,270)

INSERT INTO [dbo].[Models] (Id, [BlockId] ,[Density] ,[Filename] ,[LastModifiedDate] ,[LastModifiedUser] ,[LumpPercent] ,[Name] ,[OreType] ,[Tonnes] ,[Volume])
			Values (10411, 10400, 2.69 ,'File102' ,'2014-08-09' ,'UserTest20characters' ,42 ,'Mining' ,'HG' ,101 ,273)

INSERT INTO [dbo].[Models] (Id, [BlockId] ,[Density] ,[Filename] ,[LastModifiedDate] ,[LastModifiedUser] ,[LumpPercent] ,[Name] ,[OreType] ,[Tonnes] ,[Volume])
			Values (10421, 10400, 2.71 ,'File102' ,'2014-08-09' ,'UserTest20characters' ,43 ,'Block' ,'HG' ,102 ,276)

INSERT INTO [dbo].[Models] (Id, [BlockId] ,[Density] ,[Filename] ,[LastModifiedDate] ,[LastModifiedUser] ,[LumpPercent] ,[Name] ,[OreType] ,[Tonnes] ,[Volume])
			Values (10431, 10400, 2.73 ,'File103' ,'2014-08-09' ,'UserTest20characters' ,43 ,'STGM' ,'HG' ,102 ,276)
SET IDENTITY_INSERT [Models] OFF

-- Insert Grades
SET IDENTITY_INSERT [Grades] ON
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10401, 58.1 ,58.3 , 58.4, 'Fe') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10402, 6.0 ,6.1 ,6.2, 'P') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10403, 1.0 ,1.1 ,1.2, 'SiO2') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10404, 1.0 ,1.1 ,1.2, 'Al2O3') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10405, 1.0 ,1.1 ,1.2, 'LOI') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10406, 1.0 ,1.1 ,1.2, 'Density') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10407, 8.07 ,8.1 ,8.2, 'H2O') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10408, 7.9 ,7.8 ,7.8, 'H2O-As-Dropped') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10409, 7.7 ,7.8 ,7.9, 'H2O-As-Shipped') 

INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10411, 57.1 ,57.3 , 57.4, 'Fe') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10412, 5.0 ,5.1 ,5.2, 'P') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10413, 1.0 ,1.1 ,1.2, 'SiO2') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10414, 1.0 ,1.1 ,1.2, 'Al2O3') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10415, 1.0 ,1.1 ,1.2, 'LOI') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10416, 1.0 ,1.1 ,1.2, 'Density') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10417, 8.02 ,8.1 ,8.2, 'H2O') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10418, 7.9 ,7.8 ,7.8, 'H2O-As-Dropped') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10419, 7.7 ,7.8 ,7.9, 'H2O-As-Shipped') 

INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10421, 59.1 ,59.3 , 59.4, 'Fe') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10422, 7.0 ,7.1 ,7.2, 'P') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10423, 1.0 ,1.1 ,1.2, 'SiO2') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10424, 1.0 ,1.1 ,1.2, 'Al2O3') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10425, 1.0 ,1.1 ,1.2, 'LOI') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10426, 1.0 ,1.1 ,1.2, 'Density') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10427, 8.02 ,8.1 ,8.2, 'H2O') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10428, 7.9 ,7.8 ,7.8, 'H2O-As-Dropped') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10429, 7.7 ,7.8 ,7.9, 'H2O-As-Shipped') 

INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10431, 59.1 ,59.3 , 59.4, 'Fe') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10432, 7.0 ,7.1 ,7.2, 'P') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10433, 1.0 ,1.1 ,1.2, 'SiO2') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10434, 1.0 ,1.1 ,1.2, 'Al2O3') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10435, 1.0 ,1.1 ,1.2, 'LOI') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10436, 1.0 ,1.1 ,1.2, 'Density') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10437, 8.03 ,8.1 ,8.2, 'H2O') 
SET IDENTITY_INSERT [Grades] OFF

-- Insert Model Grade links
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10401, 10401)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10402, 10401)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10403, 10401)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10404, 10401)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10405, 10401)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10406, 10401)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10407, 10401)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10408, 10401)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10409, 10401)

INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10411, 10411)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10412, 10411)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10413, 10411)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10414, 10411)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10415, 10411)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10416, 10411)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10417, 10411)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10418, 10411)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10419, 10411)

INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10421, 10421)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10422, 10421)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10423, 10421)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10424, 10421)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10425, 10421)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10426, 10421)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10427, 10421)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10428, 10421)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10429, 10421)

INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10431, 10431)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10432, 10431)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10433, 10431)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10434, 10431)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10435, 10431)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10436, 10431)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10437, 10431)
--------------------------------
-- EXISTING BLOCK MODIFY 2

SET @modifiedDate = @blockExistingModify2Date

-- Insert Polygon data
SET IDENTITY_INSERT [Polygons] ON
INSERT INTO [dbo].[Polygons] (Id, [CentroidEasting] ,[CentroidNorthing] ,[CentroidRL])
			VALUES (10600, 364731.4 ,288706.7 ,501) 
SET IDENTITY_INSERT [Polygons] OFF

-- Insert Point data
SET IDENTITY_INSERT [Points] ON
INSERT INTO [dbo].[Points] (Id, [Number] ,[PolygonId] ,[Easting] ,[Northing] ,[RL])
			Values (10601, '1' ,10600 ,46 ,56 ,66)
INSERT INTO [dbo].[Points] (Id, [Number] ,[PolygonId] ,[Easting] ,[Northing] ,[RL])
			Values (10602, '2' ,10600 ,56 ,56 ,66)
INSERT INTO [dbo].[Points] (Id, [Number] ,[PolygonId] ,[Easting] ,[Northing] ,[RL])
			Values (10603, '3' ,10600 ,56 ,56 ,46)
SET IDENTITY_INSERT [Points] OFF

-- Insert Pattern for Block
SET IDENTITY_INSERT [Patterns] ON
INSERT INTO [dbo].[Patterns] (Id, [Bench] ,[Number] ,[Orebody] ,[Pit] ,[Site])
			VALUES (10600, '0599' ,'0820' ,'18' ,'SP' ,'OB18') 
SET IDENTITY_INSERT [Patterns] OFF

-- Insert Block
SET IDENTITY_INSERT [Blocks] ON
INSERT INTO [dbo].[Blocks] (Id, [BlastedDate] ,[BlockedDate] ,[GeoType] ,[LastModifiedDate] ,[LastModifiedUser] ,[MQ2PitCode] ,[Name] ,[Number] ,[PatternId] ,[PolygonId], IsDelete)
			VALUES (10600, '2014-09-03' ,'2014-09-04' ,'D1' ,@modifiedDate ,'UserTest20characters' ,'18SP' ,'1' ,1 , 10600, 10600, 1)
SET IDENTITY_INSERT [Blocks] OFF

-- Insert Model Data for Block
SET IDENTITY_INSERT [Models] ON
INSERT INTO [dbo].[Models] (Id, [BlockId] ,[Density] ,[Filename] ,[LastModifiedDate] ,[LastModifiedUser] ,[LumpPercent] ,[Name] ,[OreType] ,[Tonnes] ,[Volume])
			Values (10601, 10600, 2.7 ,'File101' ,'2014-09-03' ,'UserTest20characters' ,41 ,'Geology' ,'HG' ,100 ,270)

INSERT INTO [dbo].[Models] (Id, [BlockId] ,[Density] ,[Filename] ,[LastModifiedDate] ,[LastModifiedUser] ,[LumpPercent] ,[Name] ,[OreType] ,[Tonnes] ,[Volume])
			Values (10611, 10600, 2.69 ,'File102' ,'2014-09-09' ,'UserTest20characters' ,42 ,'Mining' ,'HG' ,101 ,273)

INSERT INTO [dbo].[Models] (Id, [BlockId] ,[Density] ,[Filename] ,[LastModifiedDate] ,[LastModifiedUser] ,[LumpPercent] ,[Name] ,[OreType] ,[Tonnes] ,[Volume])
			Values (10621, 10600, 2.71 ,'File102' ,'2014-09-09' ,'UserTest20characters' ,43 ,'Block' ,'HG' ,102 ,276)

INSERT INTO [dbo].[Models] (Id, [BlockId] ,[Density] ,[Filename] ,[LastModifiedDate] ,[LastModifiedUser] ,[LumpPercent] ,[Name] ,[OreType] ,[Tonnes] ,[Volume])
			Values (10631, 10600, 2.73 ,'File103' ,'2014-09-09' ,'UserTest20characters' ,43 ,'STGM' ,'HG' ,102 ,276)

SET IDENTITY_INSERT [Models] OFF

-- Insert Grades
SET IDENTITY_INSERT [Grades] ON
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10601, 58.1 ,58.3 , 58.4, 'Fe') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10602, 6.0 ,6.1 ,6.2, 'P') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10603, 1.0 ,1.1 ,1.2, 'SiO2') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10604, 1.0 ,1.1 ,1.2, 'Al2O3') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10605, 1.0 ,1.1 ,1.2, 'LOI') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10606, 1.0 ,1.1 ,1.2, 'Density') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10607, 8.08 ,8.1 ,8.2, 'H2O') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10608, 7.9 ,7.8 ,7.8, 'H2O-As-Dropped') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10609, 7.7 ,7.8 ,7.9, 'H2O-As-Shipped') 

INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10611, 57.1 ,57.3 , 57.4, 'Fe') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10612, 5.0 ,5.1 ,5.2, 'P') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10613, 1.0 ,1.1 ,1.2, 'SiO2') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10614, 1.0 ,1.1 ,1.2, 'Al2O3') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10615, 1.0 ,1.1 ,1.2, 'LOI') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10616, 1.0 ,1.1 ,1.2, 'Density') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10617, 8.05 ,8.1 ,8.2, 'H2O') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10618, 7.9 ,7.8 ,7.8, 'H2O-As-Dropped') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10619, 7.7 ,7.8 ,7.9, 'H2O-As-Shipped') 

INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10621, 59.1 ,59.3 , 59.4, 'Fe') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10622, 7.0 ,7.1 ,7.2, 'P') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10623, 1.0 ,1.1 ,1.2, 'SiO2') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10624, 1.0 ,1.1 ,1.2, 'Al2O3') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10625, 1.0 ,1.1 ,1.2, 'LOI') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10626, 1.0 ,1.1 ,1.2, 'Density') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10627, 8.01 ,8.1 ,8.2, 'H2O') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10628, 7.9 ,7.8 ,7.8, 'H2O-As-Dropped') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10629, 7.7 ,7.8 ,7.9, 'H2O-As-Shipped') 

INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10631, 59.1 ,59.3 , 59.4, 'Fe') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10632, 7.0 ,7.1 ,7.2, 'P') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10633, 1.0 ,1.1 ,1.2, 'SiO2') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10634, 1.0 ,1.1 ,1.2, 'Al2O3') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10635, 1.0 ,1.1 ,1.2, 'LOI') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10636, 1.0 ,1.1 ,1.2, 'Density') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10637, 8.02 ,8.1 ,8.2, 'H2O') 

SET IDENTITY_INSERT [Grades] OFF

-- Insert Model Grade links
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10601, 10601)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10602, 10601)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10603, 10601)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10604, 10601)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10605, 10601)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10606, 10601)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10607, 10601)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10608, 10601)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10609, 10601)

INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10611, 10611)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10612, 10611)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10613, 10611)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10614, 10611)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10615, 10611)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10616, 10611)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10617, 10611)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10618, 10611)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10619, 10611)

INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10621, 10621)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10622, 10621)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10623, 10621)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10624, 10621)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10625, 10621)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10626, 10621)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10627, 10621)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10628, 10621)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10629, 10621)

INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10631, 10631)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10632, 10631)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10633, 10631)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10634, 10631)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10635, 10631)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10636, 10631)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10637, 10631)


--------------------------------
-- EXISTING BLOCK DELETE

SET @modifiedDate = @blockExistingDeleteDate

-- Insert Polygon data
SET IDENTITY_INSERT [Polygons] ON
INSERT INTO [dbo].[Polygons] (Id, [CentroidEasting] ,[CentroidNorthing] ,[CentroidRL])
			VALUES (10500, 364731.4 ,288706.7 ,501) 
SET IDENTITY_INSERT [Polygons] OFF

-- Insert Point data
SET IDENTITY_INSERT [Points] ON
INSERT INTO [dbo].[Points] (Id, [Number] ,[PolygonId] ,[Easting] ,[Northing] ,[RL])
			Values (10501, '1' ,10500 ,47 ,57 ,67)
INSERT INTO [dbo].[Points] (Id, [Number] ,[PolygonId] ,[Easting] ,[Northing] ,[RL])
			Values (10502, '2' ,10500 ,57 ,57 ,67)
INSERT INTO [dbo].[Points] (Id, [Number] ,[PolygonId] ,[Easting] ,[Northing] ,[RL])
			Values (10503, '3' ,10500 ,57 ,57 ,47)
SET IDENTITY_INSERT [Points] OFF

-- Insert Pattern for Block
SET IDENTITY_INSERT [Patterns] ON
INSERT INTO [dbo].[Patterns] (Id, [Bench] ,[Number] ,[Orebody] ,[Pit] ,[Site])
			VALUES (10500, '0599' ,'0820' ,'18' ,'SP' ,'OB18') 
SET IDENTITY_INSERT [Patterns] OFF

-- Insert Block
SET IDENTITY_INSERT [Blocks] ON
INSERT INTO [dbo].[Blocks] (Id, [BlastedDate] ,[BlockedDate] ,[GeoType] ,[LastModifiedDate] ,[LastModifiedUser] ,[MQ2PitCode] ,[Name] ,[Number] ,[PatternId] ,[PolygonId], IsDelete)
			VALUES (10500, '2014-09-13' ,'2014-09-14' ,'D1' ,@modifiedDate ,'UserTest20characters' ,'18SP' ,'1' ,1 , 10500, 10500, 1)
SET IDENTITY_INSERT [Blocks] OFF

-- Insert Model Data for Block
SET IDENTITY_INSERT [Models] ON
INSERT INTO [dbo].[Models] (Id, [BlockId] ,[Density] ,[Filename] ,[LastModifiedDate] ,[LastModifiedUser] ,[LumpPercent] ,[Name] ,[OreType] ,[Tonnes] ,[Volume])
			Values (10501, 10500, 2.7 ,'File101' ,'2014-09-13' ,'UserTest20characters' ,41 ,'Geology' ,'HG' ,100 ,270)

INSERT INTO [dbo].[Models] (Id, [BlockId] ,[Density] ,[Filename] ,[LastModifiedDate] ,[LastModifiedUser] ,[LumpPercent] ,[Name] ,[OreType] ,[Tonnes] ,[Volume])
			Values (10511, 10500, 2.69 ,'File102' ,'2014-09-19' ,'UserTest20characters' ,42 ,'Mining' ,'HG' ,101 ,273)

INSERT INTO [dbo].[Models] (Id, [BlockId] ,[Density] ,[Filename] ,[LastModifiedDate] ,[LastModifiedUser] ,[LumpPercent] ,[Name] ,[OreType] ,[Tonnes] ,[Volume])
			Values (10521, 10500, 2.71 ,'File102' ,'2014-09-19' ,'UserTest20characters' ,43 ,'Block' ,'HG' ,102 ,276)

INSERT INTO [dbo].[Models] (Id, [BlockId] ,[Density] ,[Filename] ,[LastModifiedDate] ,[LastModifiedUser] ,[LumpPercent] ,[Name] ,[OreType] ,[Tonnes] ,[Volume])
			Values (10531, 10500, 2.73 ,'File103' ,'2014-09-09' ,'UserTest20characters' ,43 ,'STGM' ,'HG' ,102 ,276)
SET IDENTITY_INSERT [Models] OFF

-- Insert Grades
SET IDENTITY_INSERT [Grades] ON
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10501, 58.1 ,58.3 , 58.4, 'Fe') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10502, 6.0 ,6.1 ,6.2, 'P') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10503, 1.0 ,1.1 ,1.2, 'SiO2') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10504, 1.0 ,1.1 ,1.2, 'Al2O3') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10505, 1.0 ,1.1 ,1.2, 'LOI') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10506, 1.0 ,1.1 ,1.2, 'Density') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10507, 8.01 ,8.1 ,8.2, 'H2O') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10508, 7.8 ,7.8 ,7.8, 'H2O-As-Dropped') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10509, 7.7 ,7.8 ,7.9, 'H2O-As-Shipped') 

INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10511, 57.1 ,57.3 , 57.4, 'Fe') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10512, 5.0 ,5.1 ,5.2, 'P') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10513, 1.0 ,1.1 ,1.2, 'SiO2') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10514, 1.0 ,1.1 ,1.2, 'Al2O3') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10515, 1.0 ,1.1 ,1.2, 'LOI') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10516, 1.0 ,1.1 ,1.2, 'Density') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10517, 8.02 ,8.1 ,8.2, 'H2O') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10518, 7.7 ,7.8 ,7.8, 'H2O-As-Dropped') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10519, 7.7 ,7.8 ,7.9, 'H2O-As-Shipped') 

INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10521, 59.1 ,59.3 , 59.4, 'Fe') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10522, 7.0 ,7.1 ,7.2, 'P') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10523, 1.0 ,1.1 ,1.2, 'SiO2') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10524, 1.0 ,1.1 ,1.2, 'Al2O3') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10525, 1.0 ,1.1 ,1.2, 'LOI') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10526, 1.0 ,1.1 ,1.2, 'Density') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10527, 8.03 ,8.1 ,8.2, 'H2O') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10528, 7.6 ,7.8 ,7.8, 'H2O-As-Dropped') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10529, 7.7 ,7.8 ,7.9, 'H2O-As-Shipped') 

INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10531, 59.1 ,59.3 , 59.4, 'Fe') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10532, 7.0 ,7.1 ,7.2, 'P') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10533, 1.0 ,1.1 ,1.2, 'SiO2') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10534, 1.0 ,1.1 ,1.2, 'Al2O3') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10535, 1.0 ,1.1 ,1.2, 'LOI') 
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10536, 1.0 ,1.1 ,1.2, 'Density')
INSERT INTO [dbo].[Grades] (Id, [FinesValue] ,[HeadValue] ,[LumpValue], [Name]) VALUES (10537, 8.03 ,8.1 ,8.2, 'H2O') 
SET IDENTITY_INSERT [Grades] OFF

-- Insert Model Grade links
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10501, 10501)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10502, 10501)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10503, 10501)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10504, 10501)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10505, 10501)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10506, 10501)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10507, 10501)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10508, 10501)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10509, 10501)

INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10511, 10511)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10512, 10511)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10513, 10511)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10514, 10511)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10515, 10511)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10516, 10511)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10517, 10511)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10518, 10511)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10519, 10511)

INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10521, 10521)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10522, 10521)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10523, 10521)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10524, 10521)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10525, 10521)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10526, 10521)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10527, 10521)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10528, 10521)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10529, 10521)

INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10531, 10531)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10532, 10531)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10533, 10531)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10534, 10531)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10535, 10531)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10536, 10531)
INSERT INTO [dbo].[ModelGrades] ([GradeId] ,[ModelId]) VALUES (10537, 10531)

----------------------------------
-- RECONCILIATION MOVEMENTS DATA--
----------------------------------
INSERT INTO dbo.Movements
(
	BlockId, DateFrom, DateTo, LastModifiedDate, LastModifiedUser, MinedPercentage
)
SELECT 10000, '2014-07-04', '2014-07-05', GETDATE(), 'UserTest20characters', 10.02 UNION ALL
SELECT 10100, '2014-07-04', '2014-07-05', GETDATE(), 'UserTest20characters', 11.02 UNION ALL
SELECT 10200, '2014-07-04', '2014-07-05', GETDATE(), 'UserTest20characters', 12.02 UNION ALL
SELECT 10300, '2014-07-04', '2014-07-05', GETDATE(), 'UserTest20characters', 13.02 UNION ALL
SELECT 10400, '2014-07-04', '2014-07-05', GETDATE(), 'UserTest20characters', 14.02

--------------------------------
-- FINALISE
--------------------------------
