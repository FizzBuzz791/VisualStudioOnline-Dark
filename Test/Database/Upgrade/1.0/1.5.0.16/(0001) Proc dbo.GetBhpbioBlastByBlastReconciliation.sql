IF OBJECT_ID('dbo.GetBhpbioBlastByBlastReconciliation') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioBlastByBlastReconciliation
GO 
  
CREATE PROCEDURE dbo.GetBhpbioBlastByBlastReconciliation
(
	@iBlastLocationId INT
)
WITH ENCRYPTION
AS
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @HubLocationId INT
	DECLARE @HubLocationTypeId SMALLINT

	DECLARE @Result TABLE
	(
		Section VARCHAR(10) COLLATE DATABASE_DEFAULT NOT NULL,
		Type VARCHAR(11) COLLATE DATABASE_DEFAULT NOT NULL,
		Designation VARCHAR(31) COLLATE DATABASE_DEFAULT NULL,
		ModelName VARCHAR(255) COLLATE DATABASE_DEFAULT NULL,
		Tonnes FLOAT NULL,
		Volume FLOAT NULL
	)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioBlastByBlastReconciliation',
		@TransactionCount = @@TranCount 

	-- if there are no transactions available then start a new one
	-- if there is already a transaction then only mark a savepoint
	IF @TransactionCount = 0
	BEGIN
		SET TRANSACTION ISOLATION LEVEL REPEATABLE READ 
		BEGIN TRANSACTION
	END
	ELSE
	BEGIN
		SAVE TRANSACTION @TransactionName
	END
  
	BEGIN TRY
		-- calculate the HUB location information
		-- this is used for the material lookups
		SET @HubLocationTypeId = 
			(
				SELECT Location_Type_Id
				FROM dbo.LocationType
				WHERE Description = 'Site'	--'Hub'
			)
		SET @HubLocationId = dbo.GetLocationTypeLocationId(@iBlastLocationId, @HubLocationTypeId)

		-- return the Material Designation/Model summary
		INSERT INTO @Result
		(
			Section, Type, Designation, ModelName, Tonnes, Volume
		)
		SELECT 'Absolute', 'Designation', materialRollup.Designation, bm.Name,
			ISNULL(SUM(m.Tonnes), 0.0) AS Tonnes,
			ISNULL(SUM(m.Tonnes / m.Density), 0.0) AS Volume
		FROM dbo.BlockModel AS bm
			CROSS JOIN
				(
					-- supply a rollup of the Designation
					-- that is specific to the HUB selected
					-- also, roll up the waste material types
					SELECT oreType.Material_Type_Id, designation.Abbreviation AS Designation
					FROM dbo.MaterialType AS oreType
						INNER JOIN dbo.MaterialTypeLocation AS mtl
							ON (oreType.Material_Type_Id = mtl.Material_Type_Id)
						INNER JOIN dbo.GetLocationSubtree(@HubLocationId) AS ls
							ON (ls.Location_Id = mtl.Location_Id)
						INNER JOIN dbo.MaterialType AS designation
							ON (oreType.Parent_Material_Type_Id = designation.Material_Type_Id)
					WHERE oreType.Material_Category_Id = 'OreType'
						AND designation.Material_Category_Id = 'Designation'
				) AS materialRollup
			LEFT OUTER JOIN
				(
					SELECT mb.Block_Model_Id, mbp.Tonnes, mbp.Material_Type_Id,
						mbpg.Grade_Value AS Density
					FROM dbo.ModelBlock AS mb
						CROSS JOIN dbo.Grade AS g
						INNER JOIN dbo.ModelBlockPartial AS mbp
							ON (mb.Model_Block_Id = mbp.Model_Block_Id)
						INNER JOIN dbo.ModelBlockPartialGrade AS mbpg
							ON (mbp.Model_Block_Id = mbpg.Model_Block_Id
								AND mbp.Sequence_No = mbpg.Sequence_No
								AND g.Grade_Id = mbpg.Grade_Id)
						INNER JOIN dbo.ModelBlockLocation AS mbl
							ON (mbl.Model_Block_Id = mbp.Model_Block_Id)
						INNER JOIN dbo.Location AS l
							ON (mbl.Location_Id = l.Location_Id
								AND l.Parent_Location_Id = @iBlastLocationId)
					WHERE g.Grade_Type_Id = 'Density'
				) AS m
				ON (m.Material_Type_Id = materialRollup.Material_Type_Id
					AND m.Block_Model_Id = bm.Block_Model_Id)
		GROUP BY materialRollup.Designation, bm.Name

		INSERT INTO @Result
		(
			Section, Type, Designation, ModelName, Tonnes, Volume
		)
		SELECT 'Absolute', 'Total', NULL, ModelName, SUM(Tonnes), SUM(Volume)
		FROM @Result
		WHERE Section = 'Absolute'
			AND Type = 'Designation'
		GROUP BY ModelName

		-- calculate the differences
		INSERT INTO @Result
		(
			Section, Type, Designation, ModelName, Tonnes, Volume
		)
		SELECT 'Difference', r1.Type, r1.Designation, r2.ModelName + ' - ' + r1.ModelName,
			r2.Tonnes - r1.Tonnes, r2.Volume - r1.Volume
		FROM @Result AS r1
			INNER JOIN @Result AS r2
				ON (ISNULL(r1.Designation, '') = ISNULL(r2.Designation, '')
					AND r1.Type = r2.Type
					AND r1.Section = r2.Section)
		WHERE r1.Type IN ('Designation', 'Total')
			AND
			(
				(r1.ModelName = 'Geology' AND r2.ModelName = 'Mining')
				OR (r1.ModelName = 'Geology' AND r2.ModelName = 'Grade Control')
				OR (r1.ModelName = 'Mining' AND r2.ModelName = 'Grade Control')
			)	

		-- calculate the recoveries
		INSERT INTO @Result
		(
			Section, Type, Designation, ModelName, Tonnes, Volume
		)
		SELECT 'Recovery', r1.Type, r1.Designation, r2.ModelName + ' - ' + r1.ModelName,
			r2.Tonnes / (CASE WHEN r1.Tonnes = 0.0 THEN NULL ELSE r1.Tonnes END),
			r2.Volume / (CASE WHEN r1.Volume = 0.0 THEN NULL ELSE r1.Volume END)
		FROM @Result AS r1
			INNER JOIN @Result AS r2
				ON (ISNULL(r1.Designation, '') = ISNULL(r2.Designation, '')
					AND r1.Type = r2.Type
					AND r1.Section = r2.Section)
		WHERE r1.Type IN ('Designation', 'Total')
			AND
			(
				(r1.ModelName = 'Geology' AND r2.ModelName = 'Grade Control')
				OR (r1.ModelName = 'Mining' AND r2.ModelName = 'Grade Control')
			)	

		SELECT Section, Type, Designation, ModelName, Tonnes, Volume
		FROM @Result

		-- return the Material Designation/Quality summary
		SELECT mt.Abbreviation AS Designation, bm.Name AS ModelName, g.Grade_Name AS GradeName,
			SUM(mbpg.Grade_Value * mbp.Tonnes) / (CASE WHEN SUM(mbp.Tonnes) = 0.0 THEN NULL ELSE SUM(mbp.Tonnes) END) AS GradeValue
		FROM dbo.GetMaterialsByCategory('Designation') AS mc
			INNER JOIN dbo.MaterialType AS mt
				ON (mt.Material_Type_Id = mc.RootMaterialTypeId)
			INNER JOIN dbo.ModelBlockPartial AS mbp
				ON (mbp.Material_Type_Id = mc.MaterialTypeId)
			INNER JOIN dbo.ModelBlockLocation AS mbl
				ON (mbl.Model_Block_Id = mbp.Model_Block_Id)
			INNER JOIN dbo.Location AS l
				ON (mbl.Location_Id = l.Location_Id
					AND l.Parent_Location_Id = @iBlastLocationId)
			INNER JOIN dbo.ModelBlockPartialGrade AS mbpg
				ON (mbp.Model_Block_Id = mbpg.Model_Block_Id
					AND mbp.Sequence_No = mbpg.Sequence_No)
			INNER JOIN dbo.Grade AS g
				ON (mbpg.Grade_Id = g.Grade_Id)
			INNER JOIN dbo.ModelBlock AS mb
				ON (mb.Model_Block_Id = mbp.Model_Block_Id)
			INNER JOIN dbo.BlockModel AS bm
				ON (mb.Block_Model_Id = bm.Block_Model_Id)
		GROUP BY mt.Abbreviation, bm.Name, g.Grade_Name

		-- if we started a new transaction that is still valid then commit the changes
		IF (@TransactionCount = 0) AND (XAct_State() = 1)
		BEGIN
			COMMIT TRANSACTION
		END
	END TRY
	BEGIN CATCH
		-- if we started a transaction then roll it back
		IF (@TransactionCount = 0)
		BEGIN
			ROLLBACK TRANSACTION
		END
		-- if we are part of an existing transaction and all's well
		ELSE IF (XAct_State() = 1) AND (@TransactionCount > 0)
		BEGIN
			ROLLBACK TRANSACTION @TransactionName
		END

		EXEC dbo.StandardCatchBlock
	END CATCH
END
GO

GRANT EXECUTE ON dbo.GetBhpbioBlastByBlastReconciliation TO BhpbioGenericManager
GO

/* testing

EXEC dbo.GetBhpbioBlastByBlastReconciliation
	@iBlastLocationId = 122782

select * from dbo.location where location_id = 122782
select * from dbo.location where location_id = 114032
select * from dbo.location where location_id = 113941
select * from dbo.location where location_id = 5

-- find blasts by their model count
SELECT blast.Location_Id, COUNT(DISTINCT mb.Block_Model_Id)
FROM dbo.ModelBlock AS mb
	INNER JOIN dbo.ModelBlockPartial AS mbp
		ON (mb.Model_Block_Id = mbp.Model_Block_Id)
	INNER JOIN dbo.ModelBlockLocation AS mbl
		ON (mb.Model_Block_Id = mbl.Model_Block_Id)
	INNER JOIN dbo.Location AS block
		ON (mbl.Location_Id = block.Location_Id)
	INNER JOIN dbo.Location AS blast
		ON (block.Parent_Location_Id = blast.Location_Id)
GROUP BY blast.Location_Id
ORDER BY 2 ASC

-- find blasts by their designation count
SELECT blast.Location_Id, COUNT(DISTINCT designation.Material_Type_Id)
FROM dbo.ModelBlock AS mb
	INNER JOIN dbo.ModelBlockPartial AS mbp
		ON (mb.Model_Block_Id = mbp.Model_Block_Id)
	INNER JOIN dbo.ModelBlockLocation AS mbl
		ON (mb.Model_Block_Id = mbl.Model_Block_Id)
	INNER JOIN dbo.Location AS block
		ON (mbl.Location_Id = block.Location_Id)
	INNER JOIN dbo.Location AS blast
		ON (block.Parent_Location_Id = blast.Location_Id)
	INNER JOIN dbo.MaterialType AS oreType
		ON (mbp.Material_Type_Id = oreType.Material_Type_Id)
	INNER JOIN dbo.MaterialType AS designation
		ON (oreType.Parent_Material_Type_Id = designation.Material_Type_Id)
GROUP BY blast.Location_Id
ORDER BY 2 ASC



SELECT * FROM dbo.Digblock WHERE Digblock_Id Like '%CE-0638-0537%'
SELECT * FROM dbo.Location WHERE Name = 'CE' and location_type_id = 4
SELECT * FROM dbo.Location WHERE Name = '0638' and location_type_id = 5 and parent_location_id = 113952
SELECT * FROM dbo.Location WHERE Name = '0537' and location_type_id = 6 and parent_location_id = 114361

*/
