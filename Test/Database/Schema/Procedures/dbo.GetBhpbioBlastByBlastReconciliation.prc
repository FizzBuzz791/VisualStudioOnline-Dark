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


	DECLARE @BlastSummary TABLE
	(
		MaterialTypeId INT NOT NULL,
		BlockModelId INT NOT NULL,
		ModelBlockId INT NOT NULL,
		SequenceNo INT NOT NULL,
		ProductSize VARCHAR(5) NOT NULL,
		[Percent] DECIMAL(5,4) NOT NULL,
		Tonnes FLOAT NOT NULL,
		Density FLOAT NOT NULL,
		PRIMARY KEY (BlockModelId, ModelBlockId, SequenceNo, ProductSize)
	)

	DECLARE @Result TABLE
	(
		Section VARCHAR(10) COLLATE DATABASE_DEFAULT NOT NULL,
		Type VARCHAR(11) COLLATE DATABASE_DEFAULT NOT NULL,
		Designation VARCHAR(31) COLLATE DATABASE_DEFAULT NULL,
		ModelName VARCHAR(255) COLLATE DATABASE_DEFAULT NULL,
		ProductSize VARCHAR(5) COLLATE DATABASE_DEFAULT NULL,
		Tonnes FLOAT NULL,
		Volume FLOAT NULL
	)
	
	DECLARE @GradeResult TABLE
	(
		Designation VARCHAR(31) COLLATE DATABASE_DEFAULT NULL,
		ModelName VARCHAR(255) COLLATE DATABASE_DEFAULT NULL,
		ProductSize VARCHAR(5) COLLATE DATABASE_DEFAULT NULL,
		GradeName VARCHAR(31) COLLATE DATABASE_DEFAULT NULL,
		GradeValue FLOAT NULL,
		Tonnes FLOAT NULL
	)

	DECLARE @ProductSize Table
	(
		ProductSize VARCHAR(5) COLLATE DATABASE_DEFAULT NOT NULL
	)

	INSERT INTO @ProductSize
	Select 'FINES' Union All
	Select 'LUMP'

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

		-- retrieve model block data with 
		INSERT INTO @BlastSummary
			(BlockModelId, MaterialTypeId, ModelBlockId, SequenceNo, defaultlf.ProductSize, [Percent], Tonnes, Density)
		SELECT mb.Block_Model_Id, mbp.Material_Type_Id, mb.Model_Block_Id, mbp.Sequence_No, defaultlf.ProductSize, 
			ISNULL(
				CASE 
					WHEN defaultlf.ProductSize = 'LUMP' THEN blocklf.[LumpPercent] 
					WHEN defaultlf.ProductSize = 'FINES' THEN 1 - blocklf.[LumpPercent] 
					ELSE NULL 
				END, 
				defaultlf.[Percent]) As [Percent],
			mbp.Tonnes, 
			mbpg.Grade_Value AS Density
		FROM dbo.Location AS l
			INNER JOIN dbo.ModelBlockLocation AS mbl
				ON (mbl.Location_Id = l.Location_Id)
			INNER JOIN dbo.ModelBlock AS mb
				ON (mbl.Model_Block_Id = mb.Model_Block_Id)
			INNER JOIN dbo.ModelBlockPartial AS mbp
				ON (mb.Model_Block_Id = mbp.Model_Block_Id)
			CROSS JOIN dbo.Grade AS g
			INNER JOIN dbo.ModelBlockPartialGrade AS mbpg
				ON (mbp.Model_Block_Id = mbpg.Model_Block_Id
					AND mbp.Sequence_No = mbpg.Sequence_No
					AND g.Grade_Id = mbpg.Grade_Id)
			INNER JOIN Location blast 
				ON blast.Location_Id = l.Parent_Location_Id
			INNER JOIN Location bench 
				ON bench.Location_Id = blast.Parent_Location_Id
			INNER JOIN Location pit 
				ON pit.Location_Id = bench.Parent_Location_Id
			INNER JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf
				ON pit.Location_Id = defaultlf.LocationId
			LEFT JOIN dbo.BhpbioBlastBlockLumpPercent blocklf
				ON mbp.Model_Block_Id = blocklf.ModelBlockId
				AND mbp.Sequence_No = blocklf.SequenceNo
				AND GeometType = 'As-Shipped'
		WHERE l.Parent_Location_Id = @iBlastLocationId
		AND g.Grade_Type_Id = 'Density'


		-- return the Material Designation/Model summary
		INSERT INTO @Result
		(
			Section, Type, Designation, ModelName, ProductSize, Tonnes, Volume
		)
		SELECT 'Absolute', 'Designation', materialRollup.Designation, bm.Name, materialRollup.ProductSize,
			ISNULL(SUM(m.[Percent] * m.Tonnes), 0.0) AS Tonnes,
			ISNULL(SUM(m.[Percent] * m.Tonnes / m.Density), 0.0) AS Volume
		FROM dbo.BlockModel AS bm
			CROSS JOIN
				(
					-- supply a rollup of the Designation
					-- that is specific to the HUB selected
					-- also, roll up the waste material types
					SELECT oreType.Material_Type_Id, designation.Abbreviation AS Designation, p.ProductSize
					FROM dbo.MaterialType AS oreType
						INNER JOIN dbo.MaterialTypeLocation AS mtl
							ON (oreType.Material_Type_Id = mtl.Material_Type_Id)
						INNER JOIN dbo.GetLocationSubtree(@HubLocationId) AS ls
							ON (ls.Location_Id = mtl.Location_Id)
						INNER JOIN dbo.MaterialType AS designation
							ON (oreType.Parent_Material_Type_Id = designation.Material_Type_Id)
						CROSS JOIN @ProductSize AS p
					WHERE oreType.Material_Category_Id = 'OreType'
						AND designation.Material_Category_Id = 'Designation'
				) AS materialRollup
			LEFT JOIN @BlastSummary m
				ON (m.MaterialTypeId = materialRollup.Material_Type_Id
					AND m.BlockModelId = bm.Block_Model_Id
					AND m.ProductSize = materialRollup.ProductSize)
		GROUP BY materialRollup.Designation, bm.Name, materialRollup.ProductSize

		INSERT INTO @Result
		(
			Section, Type, Designation, ModelName, ProductSize, Tonnes, Volume
		)
		SELECT Section, Type, Designation, ModelName, 'TOTAL', SUM(Tonnes), SUM(Volume)
		FROM @Result
		WHERE Section = 'Absolute'
			AND Type = 'Designation'
		GROUP BY Section, Type, Designation, ModelName

		INSERT INTO @Result
		(
			Section, Type, Designation, ModelName, ProductSize, Tonnes, Volume
		)
		SELECT 'Absolute', 'Total', NULL, ModelName, ProductSize, SUM(Tonnes), SUM(Volume)
		FROM @Result
		WHERE Section = 'Absolute'
			AND Type = 'Designation'
		GROUP BY ModelName, ProductSize

		-- calculate the differences
		INSERT INTO @Result
		(
			Section, Type, Designation, ModelName, ProductSize, Tonnes, Volume
		)
		SELECT 'Difference', r1.Type, r1.Designation, r2.ModelName + ' - ' + r1.ModelName, r1.ProductSize,
			r2.Tonnes - r1.Tonnes, r2.Volume - r1.Volume
		FROM @Result AS r1
			INNER JOIN @Result AS r2
				ON (ISNULL(r1.Designation, '') = ISNULL(r2.Designation, '')
					AND r1.Type = r2.Type
					AND r1.Section = r2.Section
					AND r1.ProductSize = r2.ProductSize)
		WHERE r1.Type IN ('Designation', 'Total')
			AND
			(
				(r1.ModelName = 'Geology' AND r2.ModelName = 'Mining')
				OR (r1.ModelName = 'Geology' AND r2.ModelName = 'Grade Control')
				OR (r1.ModelName = 'Mining' AND r2.ModelName = 'Grade Control')
				OR (r1.ModelName = 'Short Term Geology' AND r2.ModelName = 'Grade Control')
			)	

		-- calculate the recoveries
		INSERT INTO @Result
		(
			Section, Type, Designation, ModelName, ProductSize, Tonnes, Volume
		)
		SELECT 'Recovery', r1.Type, r1.Designation, r2.ModelName + ' - ' + r1.ModelName, r1.ProductSize,
			r2.Tonnes / (CASE WHEN r1.Tonnes = 0.0 THEN NULL ELSE r1.Tonnes END),
			r2.Volume / (CASE WHEN r1.Volume = 0.0 THEN NULL ELSE r1.Volume END)
		FROM @Result AS r1
			INNER JOIN @Result AS r2
				ON (ISNULL(r1.Designation, '') = ISNULL(r2.Designation, '')
					AND r1.Type = r2.Type
					AND r1.Section = r2.Section
					AND r1.ProductSize = r2.ProductSize)
		WHERE r1.Type IN ('Designation', 'Total')
			AND
			(
				(r1.ModelName = 'Geology' AND r2.ModelName = 'Grade Control')
				OR (r1.ModelName = 'Mining' AND r2.ModelName = 'Grade Control')
				OR (r1.ModelName = 'Short Term Geology' AND r2.ModelName = 'Grade Control')
			)	

		SELECT Section, Type, Designation, ModelName, ProductSize, Tonnes, Volume
		FROM @Result
		Where ModelName <> 'Grade Control STGM'


		-- return the Material Designation/Quality summary
		INSERT INTO @GradeResult
		(
			Designation, ModelName, ProductSize, GradeName, GradeValue, Tonnes
		)
		SELECT mt.Abbreviation AS Designation, bm.Name AS ModelName, m.ProductSize, g.Grade_Name AS GradeName,
			SUM(m.[Percent] * m.Tonnes * 
				ISNULL(
					CASE 
						WHEN m.ProductSize = 'LUMP' THEN LFG.LumpValue 
						WHEN m.ProductSize = 'FINES' THEN LFG.FinesValue 
						ELSE NULL 
					END, MBPG.Grade_Value)
			)
			/ 
			(
				CASE 
					WHEN SUM(m.[Percent] * m.Tonnes) = 0.0 THEN NULL 
					ELSE SUM(m.[Percent] * m.Tonnes) 
				END
			) AS GradeValue, 
			Sum(m.[Percent] * m.Tonnes) As Tonnes
		FROM dbo.GetMaterialsByCategory('Designation') AS mc
			INNER JOIN dbo.MaterialType AS mt
				ON (mt.Material_Type_Id = mc.RootMaterialTypeId)
			INNER JOIN @BlastSummary m
				ON (m.MaterialTypeId = mc.MaterialTypeId)
			INNER JOIN BlockModel bm
				ON bm.Block_Model_Id = m.BlockModelId
			INNER JOIN dbo.ModelBlockPartialGrade AS mbpg
				ON (m.ModelBlockId = mbpg.Model_Block_Id
					AND m.SequenceNo = mbpg.Sequence_No)
			INNER JOIN dbo.Grade AS g
				ON (mbpg.Grade_Id = g.Grade_Id
				And g.Is_Visible = 1)
			LEFT JOIN dbo.BhpbioBlastBlockLumpFinesGrade lfg
				ON mbpg.Model_Block_Id = lfg.ModelBlockId
				and mbpg.Sequence_No = lfg.SequenceNo
				and mbpg.Grade_Id = lfg.GradeId
				and lfg.GeometType = 'As-Shipped'
		GROUP BY mt.Abbreviation, bm.Name, g.Grade_Name, m.ProductSize

		INSERT INTO @GradeResult
		(
			Designation, ModelName, ProductSize, GradeName, GradeValue, Tonnes
		)
		SELECT Designation, ModelName, 'TOTAL', GradeName,
			SUM(GradeValue * Tonnes) / (CASE WHEN SUM(Tonnes) = 0.0 THEN NULL ELSE SUM(Tonnes) END) AS GradeValue, SUM(Tonnes)
		FROM @GradeResult
		GROUP BY Designation, ModelName, GradeName

		SELECT Designation, ModelName, ProductSize, GradeName, GradeValue
		FROM @GradeResult

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
	@iBlastLocationId = 141394

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
