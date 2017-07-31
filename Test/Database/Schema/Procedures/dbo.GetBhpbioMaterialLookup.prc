IF OBJECT_ID('dbo.GetBhpbioMaterialLookup') IS NOT NULL
	DROP PROCEDURE dbo.GetBhpbioMaterialLookup  
GO 
  
CREATE PROCEDURE dbo.GetBhpbioMaterialLookup 
(
	@iMaterialCategoryId VARCHAR(31),
	@iLocationTypeId TINYINT
)
AS 
BEGIN 
	SET NOCOUNT ON 

	BEGIN TRY
		-- this should later be extended to look for:
		-- (1) ANY child material types of existing material types (not required at this point)
		-- (2) ANY child category of the category provided (also not required at this point)
	
		SELECT mt.Material_Type_Id AS MaterialTypeId, mt.Abbreviation,
			l.Location_Type_Id AS LocationTypeId, l.Location_Id AS LocationId
		FROM dbo.MaterialType AS mt
			LEFT OUTER JOIN dbo.MaterialTypeLocation AS mtl
				ON (mt.Material_Type_Id = mtl.Material_Type_Id)
			LEFT OUTER JOIN dbo.Location AS l
				ON (mtl.Location_Id = l.Location_Id
					AND l.Location_Type_Id = ISNULL(@iLocationTypeId, l.Location_Type_Id))
			INNER JOIN dbo.MaterialCategory AS mc
				ON (mt.Material_Category_Id = mc.MaterialCategoryId)
		WHERE mc.MaterialCategoryId = ISNULL(@iMaterialCategoryId, mc.MaterialCategoryId)
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON dbo.GetBhpbioMaterialLookup TO BhpbioGenericManager
GO
