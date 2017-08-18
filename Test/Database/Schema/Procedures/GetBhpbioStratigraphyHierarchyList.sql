IF OBJECT_ID('dbo.GetBhpbioStratigraphyHierarchyList') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioSampleStationList
GO 

CREATE PROCEDURE [dbo].[GetBhpbioStratigraphyHierarchyList]
AS
BEGIN
	SELECT	[Id],
			[Parentid],
			[Stratigraphy],
			[StratigraphyHierarchyTypeId],
			[Description],
			[StratNum],
			[Colour],
			[SortOrder]
  FROM [dbo].[BhpbioStratigraphyHierarchy]
END 
GO

GRANT EXECUTE ON [dbo].[GetBhpbioStratigraphyHierarchyList] TO BhpbioGenericManager
GO
