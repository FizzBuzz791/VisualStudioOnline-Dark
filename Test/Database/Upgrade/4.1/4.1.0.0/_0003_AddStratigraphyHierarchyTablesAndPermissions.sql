IF OBJECT_ID('dbo.BhpbioStratigraphyHierarchy') IS NOT NULL 
	DROP TABLE dbo.BhpbioStratigraphyHierarchy
GO 

IF OBJECT_ID('dbo.BhpbioStratigraphyHierarchyType') IS NOT NULL 
	DROP TABLE dbo.BhpbioStratigraphyHierarchyType
GO 


CREATE TABLE [dbo].[BhpbioStratigraphyHierarchyType]
(
	[Id] INT NOT NULL IDENTITY, 
	[Type] VARCHAR(100) NOT NULL, 
	[Level] INT NOT NULL,
	CONSTRAINT [PK_BhpbioStratigraphyHierarchyType] PRIMARY KEY CLUSTERED
	(
		[Id] ASC
	)
)
GO
CREATE UNIQUE NONCLUSTERED INDEX idx_BhpbioStratigraphyHierarchyType
ON [dbo].[BhpbioStratigraphyHierarchyType]([Level])
GO

INSERT INTO [dbo].[BhpbioStratigraphyHierarchyType] ([Type], [Level]) VALUES ('Group', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchyType] ([Type], [Level]) VALUES ('Formation', 2)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchyType] ([Type], [Level]) VALUES ('Member', 3)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchyType] ([Type], [Level]) VALUES ('Strat Unit', 4)

CREATE TABLE [dbo].[BhpbioStratigraphyHierarchy]
(
	[Id] INT NOT NULL IDENTITY, 
	[Parent_Id] INT NULL,
	[StratigraphyHierarchyType_Id] INT NOT NULL, 
	[Stratigraphy] varchar(50) NOT NULL,
	[Description] VARCHAR(255) NOT NULL, 
	[StratNum] VARCHAR(7) NULL, 
	[Colour] VARCHAR(25) NOT NULL,
	[SortOrder] INT NOT NULL, 
	CONSTRAINT [PK_BhpbioStratigraphyHierarchy] PRIMARY KEY CLUSTERED
	(
		[Id] ASC
	),
	CONSTRAINT FK_BhpbioStratigraphyHierarchy FOREIGN KEY ([Parent_Id])
		REFERENCES [dbo].[BhpbioStratigraphyHierarchy] ([Id]),
	CONSTRAINT FK_BhpbioStratigraphyHierarchyType FOREIGN KEY ([StratigraphyHierarchyType_Id])
		REFERENCES [dbo].[BhpbioStratigraphyHierarchyType] ([Id])
)

GO
CREATE NONCLUSTERED INDEX idx_BhpbioStratigraphyHierarchyParent
ON dbo.[BhpbioStratigraphyHierarchy]([Parent_Id])
GO
CREATE NONCLUSTERED INDEX idx_BhpbioStratigraphyHierarchyStratNum
ON dbo.[BhpbioStratigraphyHierarchy]([StratNum])
GO

CREATE FUNCTION dbo.LookupStratIdFromDescription 
(
	@description nvarchar(255)
)
RETURNS int
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Return int = null

	-- Add the T-SQL statements to compute the return value here
	IF @description is not null
	BEGIN
		SELECT	@Return = Id
		FROM	dbo.BhpbioStratigraphyHierarchy
		where	[Description] = @description
	END
	-- Return the result of the function
	RETURN @Return
END
GO
BEGIN TRANSACTION

INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription(''), 'T', 1, 'Tertiary Group', NULL, 'pink', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Tertiary Group'), 'T', 2, 'Tertiary Detritals Formation', NULL, 'crimson', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Tertiary Detritals Formation'), 'T', 3, 'Tertiary Detritals (TD1 - TD3)', '8100', 'orchid', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Tertiary Detritals (TD1 - TD3)'), 'TD3', 4, 'Tertiary Detritals 1 (includes former ROD)', '8110', 'darkmagenta', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Tertiary Detritals (TD1 - TD3)'), 'TD2', 4, 'Tertiary Detritals #2 (CID Equivalent)', '8120', 'mediumorchid', 2)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Tertiary Detritals (TD1 - TD3)'), 'TD1', 4, 'Tertiary Detritals 3 (includes former AZ, BZ, CZ, FZ, GZ, HMZ, LLZ, LZ)', '8130', 'mediumpurple', 3)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Tertiary Detritals (TD1 - TD3)'), 'SZ', 4, 'Surface Scree (Recent/Tertiary)', '8150', 'slateblue', 4)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Tertiary Detritals (TD1 - TD3)'), 'A', 4, 'Alluvial', '8160', 'mediumorchid', 5)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription(''), 'H', 1, 'Hammersley Group', NULL, 'blue', 3)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Hammersley Group'), 'HO', 2, 'Boolgeeda Iron Formation', '6210', 'royalblue', 8)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Hammersley Group'), 'HW', 2, 'Woongarra Formation', '6200', 'lightsteelblue', 7)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Hammersley Group'), 'WW', 2, 'Weeli Wolli Formation', '6100', 'seashell', 6)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Weeli Wolli Formation'), 'HJ', 3, 'Weeli Wolli Iron Formation (PHj)', '6110', 'dodgerblue', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Weeli Wolli Formation'), 'HE', 3, 'Weeli Wolli Dolerite', '6120', 'steelblue', 2)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Hammersley Group'), 'BF', 2, 'Brockman Iron Formation', NULL, 'lightskyblue', 5)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Brockman Iron Formation'), 'Y', 3, 'Yandicoogina Shale Member', '5900', 'skyblue', 4)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Brockman Iron Formation'), 'J', 3, 'Joffre Member (J1 - J6)', '5800', 'deepskyblue', 3)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Joffre Member (J1 - J6)'), 'J3J5', 4, 'Brockman Iron formation, Joffre Member (PHbj) J3 - 5 zone undifferentiated (Formerly JC)', '5870', 'powderblue', 7)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Joffre Member (J1 - J6)'), 'J6', 4, 'Brockman Iron formation, Joffre Member (PHbj) - J6', '5860', 'lavenderblush', 6)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Joffre Member (J1 - J6)'), 'J5', 4, 'Brockman Iron formation, Joffre Member (PHbj) - J5 - shaly', '5850', 'darkturquoise', 5)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Joffre Member (J1 - J6)'), 'J4', 4, 'Brockman Iron formation, Joffre Member (PHbj) - J4', '5840', 'aqua', 4)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Joffre Member (J1 - J6)'), 'J3', 4, 'Brockman Iron formation, Joffre Member (PHbj) - J3 - shaly', '5830', 'darkcyan', 3)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Joffre Member (J1 - J6)'), 'J2', 4, 'Brockman Iron formation, Joffre Member (PHbj) - J2', '5820', 'teal', 2)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Joffre Member (J1 - J6)'), 'J1', 4, 'Brockman Iron Formation, Joffre Member - J1 - shaly', '5810', 'darkslategray', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Brockman Iron Formation'), 'W', 3, 'Mt Whaleback Shale Member', '5700', 'mediumturquoise', 2)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Mt Whaleback Shale Member'), 'WL', 4, 'Brockman Iron Formation, Whaleback Shale - Lower', '5710', 'lightseagreen', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Mt Whaleback Shale Member'), 'WC', 4, 'Brockman Iron Formation, Whaleback Shale - Central Chert', '5720', 'turquoise', 2)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Mt Whaleback Shale Member'), 'WU', 4, 'Brockman Iron Formation, Whaleback Shale - Upper', '5730', 'aquamarine', 3)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Brockman Iron Formation'), 'D', 3, 'Dales Gorge Member (D1 - D4)', '5600', 'forestgreen', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Dales Gorge Member (D1 - D4)'), 'D4', 4, 'Brockman Iron Formation, Dales Gorge Member (PHbd) - D4', '5640', 'green', 4)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Dales Gorge Member (D1 - D4)'), 'D3', 4, 'Brockman Iron Formation, Dales Gorge Member (PHbd) - D3 - middle shaly', '5630', 'lime', 3)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Dales Gorge Member (D1 - D4)'), 'D2', 4, 'Brockman Iron Formation, Dales Gorge Member (PHbd) - D2', '5620', 'aliceblue', 2)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Dales Gorge Member (D1 - D4)'), 'D1', 4, 'Colonial Chert Member (Ahrc), Dales Gorge Member - D1', '5610', 'lawngreen', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Hammersley Group'), 'R', 2, 'Mt McRae Shale Formation', NULL, 'mediumspringgreen', 4)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Mt McRae Shale Formation'), 'R', 3, 'Mt McRae Shale Member', '5400', 'springgreen', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Mt McRae Shale Member'), 'RL', 4, 'Mt McRae Shale - Lower', '5410', 'mediumseagreen', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Mt McRae Shale Member'), 'RC', 4, 'Mt McRae Shale - Chert', '5420', 'seagreen', 2)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Mt McRae Shale Member'), 'RN', 4, 'Mt McRae Shale - Nodule Zone', '5430', 'darkseagreen', 3)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Mt McRae Shale Member'), 'RU', 4, 'Mt McRae Shale - Upper', '5440', 'palegreen', 4)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Hammersley Group'), 'S', 2, 'Mt Syliva Formation', NULL, 'yellow', 3)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Mt Syliva Formation'), 'S', 3, 'Mt Syliva Member (S1 - S7)', '5300', 'olive', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Mt Syliva Member (S1 - S7)'), 'S1S4', 4, 'S1 to S4', '5380', 'darkkhaki', 8)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Mt Syliva Member (S1 - S7)'), 'S1', 4, 'Mt Sylvia Formation - S1 (BIF1)', '5310', 'gold', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Mt Syliva Member (S1 - S7)'), 'S2', 4, 'Mt Sylvia Formation - S2', '5320', 'lavender', 2)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Mt Syliva Member (S1 - S7)'), 'S3', 4, 'Mt Sylvia Formation - S3 (BIF2)', '5330', 'darkgoldenrod', 3)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Mt Syliva Member (S1 - S7)'), 'S4', 4, 'Mt Sylvia Formation - S4', '5340', 'wheat', 4)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Mt Syliva Member (S1 - S7)'), 'S5', 4, 'Mt Sylvia Formation - S5 (Siltstone)', '5350', 'orange', 5)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Mt Syliva Member (S1 - S7)'), 'S6', 4, 'Mt Sylvia Formation - S6', '5360', 'moccasin', 6)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Mt Syliva Member (S1 - S7)'), 'S7', 4, 'Mt Sylvia Formation - S7 (Bruno''s Band)', '5370', 'cornsilk', 7)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Hammersley Group'), 'O', 2, 'Wittenoom Formation', '4000', 'thistle', 2)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Wittenoom Formation'), 'OD', 3, 'Bee Gorge Member', '4400', 'plum', 3)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Bee Gorge Member'), 'OC', 4, 'Wittenoom Formation, Shaley Bee Gorge Member OC - Undifferentiated', '4300', 'fuchsia', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Wittenoom Formation'), 'OB', 3, 'Paraburdoo Member', '4200', 'darkviolet', 2)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Wittenoom Formation'), 'OA', 3, 'West Angela Member (OA1 - OA2)', '4100', 'goldenrod', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('West Angela Member (OA1 - OA2)'), 'WA2', 4, 'Wittenoom Formation, West Angela Member - A2 (Shale Waste) (Formerly A2)', '4120', 'mediumslateblue', 2)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('West Angela Member (OA1 - OA2)'), 'WA1', 4, 'Wittenoom Formation, West Angela Member - A1 (Formerly A1)', '4110', 'indianred', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Hammersley Group'), 'M', 2, 'Marra Mamba Iron Formation', '3100', 'cornflowerblue', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Marra Mamba Iron Formation'), 'MN', 3, 'Mt Newman Member (N1 - N3)', '3400', 'slategray', 3)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Mt Newman Member (N1 - N3)'), 'N3', 4, 'Marra Mamba Iron Formation, Mount Newman Member - N3', '3430', 'lightblue', 3)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Mt Newman Member (N1 - N3)'), 'N2', 4, 'Marra Mamba Iron Formation, Mount Newman Member - N2 (Shaley)', '3420', 'paleturquoise', 2)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Mt Newman Member (N1 - N3)'), 'N1', 4, 'Marra Mamba Iron Formation, Mount Newman Member - N1', '3410', 'aquamarine', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Marra Mamba Iron Formation'), 'MM', 3, 'MacLeod Member', '3300', 'khaki', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Marra Mamba Iron Formation'), 'MU', 3, 'Nammuldi Member', '3200', 'greenyellow', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription(''), 'F', 1, 'Fortescue Group', NULL, 'cadetblue', 4)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Fortescue Group'), 'JN', 2, 'Jeerinah Formation', NULL, 'violet', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Jeerinah Formation'), 'JN', 3, 'Jeerinah Member', '2100', 'hotpink', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Jeerinah Member'), 'XX', 4, 'Jeerinah Formation - Undifferentiated Dolerite', '2110', 'salmon', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Jeerinah Member'), 'NX', 4, 'Jeerinah Formation (AFjr) - Undifferentiated Shale', '2120', 'chartreuse', 2)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Jeerinah Member'), 'XA', 4, 'Jeerinah Formation, Dolerite A', '2210', 'bisque', 3)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Jeerinah Member'), 'NA', 4, 'Jeerinah Formation, Shale A', '2220', 'tan', 4)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Jeerinah Member'), 'XB', 4, 'Jeerinah Formation, Dolerite B', '2310', 'mediumvioletred', 5)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Jeerinah Member'), 'NB', 4, 'Jeerinah Formation, Shale B', '2320', 'lightslategray', 6)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Jeerinah Member'), 'XC', 4, 'Jeerinah Formation, Dolerite C', '2410', 'antiquewhite', 7)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Jeerinah Member'), 'NC', 4, 'Jeerinah Formation, Shale C', '2420', 'darkgreen', 8)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription(''), 'CID', 1, 'CID', NULL, 'red', 5)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('CID'), 'MF', 2, 'Marillana Formation', NULL, 'rosybrown', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Marillana Formation'), 'M4', 3, 'Iowa Member (M4)', '7400', 'lightcoral', 4)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Iowa Member (M4)'), 'M4W', 4, 'Eastern CID Weathered', '7420', 'mistyrose', 2)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Iowa Member (M4)'), 'EK', 4, 'Marillana Formation, Iowa Member - Eastern Clay', '7410', 'tomato', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Marillana Formation'), 'M3', 3, 'Barimunya Upper Member (M3)', '7300', 'brown', 3)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Barimunya Upper Member (M3)'), 'MX', 4, 'Marillana Formation, Barimanya Member - CID- Undifferentiated', '7100', 'firebrick', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Barimunya Upper Member (M3)'), 'M3MS', 4, 'Southern Marginal zone', '7320', 'darkred', 2)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Barimunya Upper Member (M3)'), 'M3MN', 4, 'Northern Marginal Zone', '7330', 'maroon', 3)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Barimunya Upper Member (M3)'), 'M3SA', 4, 'Upper CID High Silica High Alumina', '7350', 'orangered', 4)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Barimunya Upper Member (M3)'), 'M3W', 4, 'Upper CID Weathered', '7370', 'lightsalmon', 5)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Barimunya Upper Member (M3)'), 'M3S', 4, 'Upper CID High Silica', '7380', 'coral', 6)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Marillana Formation'), 'M1-M2', 3, 'Barimunya Lower Member (M1 - M2)', NULL, 'purple', 2)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Barimunya Lower Member (M1 - M2)'), 'M1', 4, 'Marillana Formation, Barimunya Member - Lower CID', '7110', 'peachpuff', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Barimunya Lower Member (M1 - M2)'), 'M2', 4, 'Marillana Formation, Barimunya Member - Lower CID (denatured zone)', '7120', 'chocolate', 2)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Barimunya Lower Member (M1 - M2)'), 'OK', 4, 'Marillana Formation - Barimunya Member, Ochreous Clay', '7130', 'navy', 3)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Marillana Formation'), 'MUN', 3, 'Munjina Member', NULL, 'blueviolet', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Munjina Member'), 'BG', 4, 'Marillana Formation, Munjina Member - Basal Conglomerate', '7030', 'lightgoldenrodyellow', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Munjina Member'), 'BK', 4, 'Marillana Formation, Munjina Member - Basal Clay', '7050', 'lemonchiffon', 2)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription(''), 'INT', 1, 'Intrusives (G)', NULL, 'mediumaquamarine', 6)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Intrusives (G)'), 'INT', 2, 'Intrusives (F)', NULL, 'lightgreen', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Intrusives (F)'), 'INT', 3, 'Intrusives', NULL, 'limegreen', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Intrusives (F)'), 'AW', 4, 'Warrawoona Group', '1050', 'lightpink', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Intrusives (F)'), 'AG', 4, 'Granite', '1060', 'darkolivegreen', 2)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Intrusives (F)'), 'AGM', 4, 'Muccan Granite', '1070', 'sandybrown', 3)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Intrusives (F)'), 'BRD', 4, 'Black Range Dolerites', '1080', 'midnightblue', 4)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Intrusives (F)'), 'AGW', 4, 'Warrawagine Granite', '1090', 'palevioletred', 5)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Intrusives (F)'), 'K', 4, 'Dykes/Sills', '8200', 'palegoldenrod', 6)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription(''), 'UNK', 1, 'Unknown (G)', NULL, 'dimgray', 8)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Unknown (G)'), 'UNK', 2, 'Unknown (F)', NULL, 'gray', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Unknown (F)'), 'UNK', 3, 'Unknown', NULL, 'darkgray', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Unknown (F)'), 'H', 4, 'Hardcap', '8300', 'silver', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Unknown (F)'), 'F', 4, 'Fault Zone', '8400', 'lightgrey', 2)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Unknown (F)'), 'B', 4, 'Basement', '8900', 'tan', 3)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Unknown (F)'), 'FILL', 4, 'Fill', '9000', 'blanchedalmond', 4)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Unknown (F)'), 'UN', 4, 'Unknown stratigraphy (Formerly U)', '9999', 'navajowhite', 5)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription(''), 'OTH', 1, 'Other', NULL, 'sienna', 7)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Other'), 'EC', 2, 'Eel Creek Formation', '1500', 'saddlebrown', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Eel Creek Formation'), 'ECH', 3, 'Eel Creek Member', '1510', 'burlywood', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Eel Creek Member'), 'ECT', 4, 'Hematitic Shale', '1520', 'darkorange', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Eel Creek Member'), 'ECS', 4, 'Unmineralised Sediment', '1530', 'peru', 2)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Other'), 'KC', 2, 'Callawa Formation', '1800', 'papayawhip', 2)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription(''), 'G', 1, 'Gorge Creek Group', '1200', 'mediumblue', 2)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Gorge Creek Group'), 'GN', 2, 'Nimingarra Iron Formation', '1300', 'deeppink', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Nimingarra Iron Formation'), 'GN1', 3, 'Lower Member Mudstone', '1310', 'darkslateblue', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Nimingarra Iron Formation'), 'GN2', 3, 'Lower Member BIF', '1320', 'olivedrab', 2)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Nimingarra Iron Formation'), 'GN3', 3, 'Middle Member Footwall Mudstone', '1330', 'lightcyan', 3)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Nimingarra Iron Formation'), 'GN4', 3, 'Middle Member BIF', '1360', 'gainsboro', 4)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Nimingarra Iron Formation'), 'GN34', 3, 'Undifferentiated Middle', '1370', 'darksalmon', 5)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Nimingarra Iron Formation'), 'GN6', 3, 'Upper BIF - BIF', '1380', 'darkorchid', 6)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Nimingarra Iron Formation'), 'GN56', 3, 'Upper BIF Member', '1400', 'indigo', 7)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Gorge Creek Group'), 'ACS', 2, 'Cundaline Formation', '1410', 'yellowgreen', 2)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchy] ([Parent_Id], [Stratigraphy], [StratigraphyHierarchyType_Id], [Description], [StratNum], [Colour], [SortOrder]) VALUES (dbo.LookupStratIdFromDescription('Cundaline Formation'), 'ACB', 3, 'Coonieena Basalt', '1420', 'darkblue', 1)


COMMIT TRANSACTION

GO
IF OBJECT_ID('dbo.LookupStratIdFromDescription') IS NOT NULL
	DROP FUNCTION dbo.LookupStratIdFromDescription
GO

INSERT INTO [dbo].[SecurityOption] VALUES ('REC', 'UTILITIES_STRATIGRAPHY_HIERARCHY', 'Utilities', 'Access to Stratigraphy Reference Screen', 99)
INSERT INTO [dbo].[SecurityRoleOption] VALUES ('REC_VIEW', 'REC', 'UTILITIES_STRATIGRAPHY_HIERARCHY')
GO

