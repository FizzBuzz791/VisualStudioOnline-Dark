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

INSERT INTO [dbo].[BhpbioStratigraphyHierarchyType] ([Type], [Level]) VALUES ('Formation', 1)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchyType] ([Type], [Level]) VALUES ('Member', 2)
INSERT INTO [dbo].[BhpbioStratigraphyHierarchyType] ([Type], [Level]) VALUES ('Strat Unit', 3)

CREATE TABLE [dbo].[BhpbioStratigraphyHierarchy]
(
	[Id] INT NOT NULL IDENTITY, 
	[Parentid] INT NULL,
	[Stratigraphy] varchar(50) NOT NULL,
    [StratigraphyHierarchyTypeId] INT NOT NULL, 
    [Description] NVARCHAR(255) NOT NULL, 
    [StratNum] VARCHAR(4) NULL, 
    [Colour] VARCHAR(25) NOT NULL,
	[SortOrder] INT NOT NULL, 
    CONSTRAINT [PK_BhpbioStratigraphyHierarchy] PRIMARY KEY CLUSTERED
	(
		[Id] ASC
	),
	CONSTRAINT FK_BhpbioStratigraphyHierarchy FOREIGN KEY ([ParentId])
		REFERENCES [dbo].[BhpbioStratigraphyHierarchy] ([Id]),
	CONSTRAINT FK_BhpbioStratigraphyHierarchyType FOREIGN KEY ([StratigraphyHierarchyTypeId])
		REFERENCES [dbo].[BhpbioStratigraphyHierarchyType] ([Id])
)

GO
CREATE NONCLUSTERED INDEX idx_BhpbioStratigraphyHierarchyParent
ON dbo.[BhpbioStratigraphyHierarchy]([ParentId])
GO
CREATE NONCLUSTERED INDEX idx_BhpbioStratigraphyHierarchyStratNum
ON dbo.[BhpbioStratigraphyHierarchy]([StratNum])
GO

INSERT INTO [dbo].[SecurityOption] VALUES ('REC', 'UTILITIES_STRATIGRAPHY_HIERARCHY', 'Utilities', 'Access to Stratigraphy Reference Screen', 99)
INSERT INTO [dbo].[SecurityRoleOption] VALUES ('REC_VIEW', 'REC', 'UTILITIES_STRATIGRAPHY_HIERARCHY')
GO

