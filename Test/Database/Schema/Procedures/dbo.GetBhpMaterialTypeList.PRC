 IF OBJECT_ID('dbo.GetBhpMaterialTypeList') IS NOT NULL 
     DROP PROCEDURE dbo.GetBhpMaterialTypeList
GO 
  
CREATE PROCEDURE dbo.GetBhpMaterialTypeList
( 
    @iIs_Digblock_Group BIT = NULL,
	@iIs_Stockpile_Group BIT = NULL,
	@iLocation_Id INT = NULL,
	@iMaterial_Category_Id VARCHAR(31) = NULL,
	@iParent_Material_Type_Id INT = NULL
) 
AS 
BEGIN 
    SET NOCOUNT ON 
  
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ 
    BEGIN TRANSACTION 
    
    CREATE TABLE dbo.#MaterialTypeList
    (
		Material_Type_Id INT,
		Description VARCHAR(255) COLLATE Database_Default,
		Order_No INT,
		Abbreviation VARCHAR(31) COLLATE Database_Default,
		Parent_Material_Type_Id INT,
		Is_Waste BIT,
		Density_Conversion_Factor REAL,
		Material_Type_Group_Id INT,
		Material_Type_Group_Name VARCHAR(63) COLLATE Database_Default,
		Material_Category_Id VARCHAR(63) COLLATE Database_Default,
		Parent_Material_Category_Id VARCHAR(63) COLLATE Database_Default,
		Children INT,
		Is_Processed BIT
    )
    
  
	CREATE TABLE dbo.#MaterialType
	(
		Material_Type_Group_Id INT,
		Material_Type_Group_Name VARCHAR(63) COLLATE Database_Default,
		Material_Type_Id INT
	)

	CREATE TABLE dbo.#WasteType
	(
		Material_Type_Id INT,
		Waste_Type_Id VARCHAR(63) COLLATE Database_Default,
		Is_Waste BIT
	)

	INSERT INTO dbo.#MaterialType
	(
		Material_Type_Group_Id, Material_Type_Group_Name, Material_Type_Id
	)
	SELECT mtg.Material_Type_Group_Id, mtg.Name, mt.Material_Type_Id
	FROM dbo.MaterialType AS mt
		INNER JOIN dbo.MaterialTypeGroup AS mtg
			ON (mt.Material_Type_Group_Id = mtg.Material_Type_Group_Id)
		LEFT OUTER JOIN 
		(
			SELECT m.Material_Type_Id, IsNull(ml.Location_Id, 0) AS Location_Id
			FROM dbo.MaterialType AS m
				LEFT OUTER JOIN dbo.MaterialTypeLocation AS ml 
					ON (m.Material_Type_Id = ml.Material_Type_Id)		
		) AS l
			ON mt.Material_Type_Id = l.Material_Type_Id
	WHERE mtg.Is_Stockpile_Group = IsNull(@iIs_Stockpile_Group, Is_Stockpile_Group)
		AND mtg.Is_Digblock_Group = IsNull(@iIs_Digblock_Group, Is_Digblock_Group)
		AND 
		(
			@iLocation_Id IS NULL
				OR l.Location_Id in 
				(
					SELECT Location_Id 
					FROM dbo.GetLocationSubtree(@iLocation_Id)
				)
		)
	GROUP BY mtg.Material_Type_Group_Id, mtg.Name, mt.Material_Type_Id

	INSERT INTO dbo.#WasteType	
	(
		Material_Type_Id, Waste_Type_Id, Is_Waste
	)
	SELECT mt.Material_Type_Id, 'Is_Waste_' + wt.Waste_Type_Id, mtwtp.Is_Waste
	FROM dbo.WasteType AS wt	
		CROSS JOIN dbo.MaterialType AS mt
		LEFT OUTER JOIN dbo.MaterialTypeWasteTypePeriod AS mtwtp
			ON (mt.Material_Type_Id = mtwtp.Material_Type_Id
				AND wt.Waste_Type_Id = mtwtp.Waste_Type_Id
				AND mtwtp.End_Date IS NULL)

	EXEC dbo.PivotTable
		@iTargetTable = '#MaterialType',
		@iPivotTable = '#WasteType',
		@iJoinColumns = 'dbo.#MaterialType.Material_Type_Id = dbo.#WasteType.Material_Type_Id',
		@iPivotColumn = 'Waste_Type_Id',
		@iPivotValue = 'Is_Waste',
		@iPivotType = 'BIT'

	INSERT INTO dbo.#MaterialTypeList
	(
		Material_Type_Id,
		Description,
		Order_No,
		Abbreviation,
		Parent_Material_Type_Id,
		Is_Waste,
		Density_Conversion_Factor,
		Material_Type_Group_Id,
		Material_Type_Group_Name,
		Material_Category_Id,
		Parent_Material_Category_Id,
		Children,
		Is_Processed
	)
	SELECT mt.Material_Type_Id, mt2.Description, mt2.Order_No, mt2.Abbreviation,
		mt2.Parent_Material_Type_Id, mt2.Is_Waste,
		mt2.Density_Conversion_Factor, mt.Material_Type_Group_Id, mt.Material_Type_Group_Name,
		mc.MaterialCategoryId As Material_Category_Id, 
		mc.ParentMaterialCategoryId As Parent_Material_Category_Id,
		Coalesce(c.Children,0) As Children,
		CASE WHEN mc.ParentMaterialCategoryId IS NULL THEN 1 ELSE 0 END
	FROM dbo.#MaterialType AS mt
		INNER JOIN dbo.MaterialType AS mt2
			ON (mt.Material_Type_Id = mt2.Material_Type_Id)
		LEFT JOIN dbo.MaterialCategory AS mc
			ON (mc.MaterialCategoryId = mt2.Material_Category_Id)
		LEFT JOIN
			(
			SELECT Parent_Material_Type_Id, Count(*) AS Children
			FROM dbo.MaterialType
			GROUP BY Parent_Material_Type_Id
			) AS c
			ON c.Parent_Material_Type_Id = mt2.Material_Type_Id
	WHERE (mt2.Parent_Material_Type_Id = @iParent_Material_Type_Id OR @iParent_Material_Type_Id IS NULL)
		AND (mt2.Material_Category_Id = @iMaterial_Category_Id OR @iMaterial_Category_Id IS NULL)

	--Append all the parents.
	/*
	WHILE EXISTS (SELECT TOP 1 1 FROM dbo.#MaterialTypeList WHERE Is_Processed = 0)
	BEGIN
	UPDATE CL
	SET CL.Abbreviation = PL.Abbreviation + '\' + CL.Abbreviation,
		CL.Is_Processed = 1
	FROM dbo.#MaterialTypeList AS CL
		INNER JOIN dbo.#MaterialTypeList AS PL
			ON CL.Parent_Material_Type_Id = PL.Material_Type_Id
			AND PL.Is_Processed = 1
	WHERE CL.Is_Processed = 0
	END
	*/
				
	SELECT * FROM dbo.#MaterialTypeList
	WHERE Children = 0
	
	DROP TABLE dbo.#MaterialType
	DROP TABLE dbo.#WasteType

    COMMIT TRANSACTION 
END 
GO 
GRANT EXECUTE ON dbo.GetBhpMaterialTypeList TO BhpbioGenericManager
GO
GO
/*
<TAG Name="Data Dictionary" ProcedureName="GetBhpMaterialTypeList">
 <Procedure>
	Returns a list of material types.
 </Procedure>
</TAG>
*/
