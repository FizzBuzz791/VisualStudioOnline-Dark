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


