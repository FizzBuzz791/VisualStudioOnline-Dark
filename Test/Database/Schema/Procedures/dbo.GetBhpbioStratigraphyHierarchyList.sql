IF OBJECT_ID('dbo.GetBhpbioStratigraphyHierarchyList') IS NOT NULL
     DROP PROCEDURE [dbo].[GetBhpbioStratigraphyHierarchyList]
GO 

CREATE PROCEDURE [dbo].[GetBhpbioStratigraphyHierarchyList]
AS
BEGIN
	SELECT	[dbo].[BhpbioStratigraphyHierarchy].[Id],
			[Parent_Id],
			[Stratigraphy],
			[dbo].[BhpbioStratigraphyHierarchyType].[Id] StratTypeId,
			[Type],
			[Level],
			[dbo].[BhpbioStratigraphyHierarchy].[Description],
			[StratNum],
			[Colour],
			[SortOrder]
	FROM	[dbo].[BhpbioStratigraphyHierarchy] 
			INNER JOIN [dbo].[BhpbioStratigraphyHierarchyType] on [dbo].[BhpbioStratigraphyHierarchy].[StratigraphyHierarchyTypeId] = [dbo].[BhpbioStratigraphyHierarchyType].[Id]
END 
GO

GRANT EXECUTE ON [dbo].[GetBhpbioStratigraphyHierarchyList] TO BhpbioGenericManager
GO
