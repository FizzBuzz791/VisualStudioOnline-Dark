IF OBJECT_ID('dbo.GetBhpbioDigblockPolygonList') IS NOT NULL 
     DROP PROCEDURE dbo.GetBhpbioDigblockPolygonList 
GO
  
CREATE PROCEDURE dbo.GetBhpbioDigblockPolygonList 
( 
	@iLocationId INT,
	@iMaterialCategoryId VARCHAR(31),
	@iRootMaterialTypeId INT
) 
WITH ENCRYPTION 
AS
BEGIN 
    SET NOCOUNT ON 
  
	BEGIN TRY
		-- Returns the Digblock Polygon co-ordinates for a specified Digblock
		SELECT dp.Digblock_Id, dp.Order_No, dp.X, dp.Y, dp.Z
		FROM dbo.DigblockPolygon AS dp	
			INNER JOIN dbo.Digblock AS d
				ON (dp.Digblock_Id = d.Digblock_Id)
			-- collect the location hierarchy
			INNER JOIN dbo.DigblockLocation AS dl
				ON (dl.Digblock_Id = d.Digblock_Id)
			-- filter optionally by the material
			INNER JOIN dbo.GetMaterialsByCategory(@iMaterialCategoryId) AS mc
				ON (mc.MaterialTypeId = d.Material_Type_Id)
			INNER JOIN dbo.MaterialType AS mt
				ON (mc.RootMaterialTypeId = mt.Material_Type_Id)
		WHERE mc.RootMaterialTypeId = ISNULL(@iRootMaterialTypeId, mc.RootMaterialTypeId)
			AND dl.Location_Id IN
				(
					SELECT LocationId
					FROM dbo.GetBhpbioReportLocation(@iLocationId)
				)
		ORDER BY dp.Digblock_Id, dp.Order_No
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON dbo.GetBhpbioDigblockPolygonList TO BhpbioGenericManager
GO
 