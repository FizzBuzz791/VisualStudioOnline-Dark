IF OBJECT_ID('dbo.GetBhpbioStratigraphyHierarchyTypeList') IS NOT NULL
     DROP PROCEDURE [dbo].[GetBhpbioStratigraphyHierarchyTypeList]
GO 

CREATE PROCEDURE [dbo].[GetBhpbioStratigraphyHierarchyTypeList]
AS
BEGIN
	SELECT		[Id],
				[Type],
				[Level]
	FROM		[dbo].[BhpbioStratigraphyHierarchyType]
	ORDER BY	[Level]
END 
GO

GRANT EXECUTE ON [dbo].[GetBhpbioStratigraphyHierarchyTypeList] TO BhpbioGenericManager
GO
