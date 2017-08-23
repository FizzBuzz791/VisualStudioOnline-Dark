CREATE TABLE [dbo].[BhpbioStratigraphyHierarchyType]
(
	[Id] INT NOT NULL, 
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