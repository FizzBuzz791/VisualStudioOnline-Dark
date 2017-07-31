IF OBJECT_ID('dbo.GetBhpbioApprovalOtherMaterial') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioApprovalOtherMaterial  
GO 
  
CREATE PROCEDURE dbo.GetBhpbioApprovalOtherMaterial 
(
	@iMonthFilter DATETIME,
	@iLocationId INT,
	@iChildLocations BIT
)
AS 
BEGIN 

--DECLARE	@iMonthFilter DATETIME
--DECLARE	@iLocationId INT
--DECLARE	@iChildLocations BIT
--SET @iMonthFilter = '2014-01-01'
--SET @iLocationId = 8
--SET @iChildLocations = 0


	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	
	DECLARE @ActualId INT
	SET @ActualId = 88
	DECLARE @ActualName VARCHAR(40)
	SET @ActualName = 'Actual'

	DECLARE @BlockModelXml VARCHAR(500)
	SET @BlockModelXml = ''
	
	DECLARE @MaterialCategoryId VARCHAR(31)
	SET @MaterialCategoryId = 'Designation'
	
	DECLARE @DateFrom DATETIME
	DECLARE @DateTo DATETIME
	SET @DateFrom = dbo.GetDateMonth(@iMonthFilter)
	SET @DateTo = DateAdd(Day, -1, DateAdd(Month, 1, @DateFrom))
		

	DECLARE @Tonnes TABLE
	(
		Type VARCHAR(255) COLLATE DATABASE_DEFAULT NOT NULL,
		LocationId INT NOT NULL,
		BlockModelId INT NULL,
		CalendarDate DATETIME NOT NULL,
		Material VARCHAR(65) COLLATE DATABASE_DEFAULT NULL,
		MaterialTypeId INT NOT NULL,
		Tonnes FLOAT,
		PRIMARY KEY CLUSTERED (CalendarDate, MaterialTypeId, Type, LocationId)
	)
	
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		ParentLocationId INT NULL,
		LocationType VARCHAR(255) NOT NULL,
		LocationName VARCHAR(31) NOT NULL,
		PRIMARY KEY (LocationId)
	)
		
	DECLARE @MaterialType TABLE
	(
		RootMaterialTypeId INT NOT NULL,
		RootAbbreviation VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialTypeId INT NOT NULL,
		PRIMARY KEY CLUSTERED (MaterialTypeId, RootMaterialTypeId)
	)
	
	DECLARE @HaulageType TABLE
	(
		HaulageType VARCHAR(30) NOT NULL,
		PRIMARY KEY (HaulageType)
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioApprovalOtherMaterial',
		@TransactionCount = @@TranCount 

	 --if there are no transactions available then start a new one
	 --if there is already a transaction then only mark a savepoint
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
		 --Create Pivot Tables
		CREATE TABLE dbo.#Record
		(
			TagId VARCHAR(63) COLLATE DATABASE_DEFAULT NULL,
			LocationId INT NOT NULL,
			LocationType VARCHAR(255) NOT NULL,
			LocationName VARCHAR(31) NOT NULL,
			MaterialTypeId INT NULL,
			MaterialName VARCHAR(65) COLLATE DATABASE_DEFAULT NOT NULL,
			OrderNo INT NOT NULL,
			ParentMaterialTypeId INT NULL,
			Approved BIT NULL,
			SignOff VARCHAR(65) COLLATE DATABASE_DEFAULT NULL,
			
			PRIMARY KEY (MaterialName, LocationId)
		)

		CREATE TABLE dbo.#RecordTonnes
		(
			MaterialTypeId INT NULL,
			LocationId INT NOT NULL,
			MaterialName VARCHAR(65) COLLATE DATABASE_DEFAULT NULL,
			ModelName VARCHAR(500) COLLATE DATABASE_DEFAULT NULL,
			Tonnes FLOAT NULL,
			OrderNo INT NULL,
			RootNode INT NULL
		)
		
		-- load the material data
		INSERT INTO @MaterialType
		(
			RootMaterialTypeId, RootAbbreviation, MaterialTypeId
		)
		SELECT mc.RootMaterialTypeId, mt.Abbreviation, mc.MaterialTypeId
		FROM dbo.GetMaterialsByCategory('Designation') AS mc
			INNER JOIN dbo.MaterialType AS mt
				ON (mc.RootMaterialTypeId = mt.Material_Type_Id)
		WHERE mc.RootMaterialTypeId = mc.RootMaterialTypeId
		
		-- load Haulage Type
		Insert Into @HaulageType
		Select Name
		From BhpbioSummaryEntryType
		Where Name like 'Hauled%'
	
		-- setup the Locations
		INSERT INTO @Location
		(
			LocationId, ParentLocationId, LocationName, LocationType
		)
		SELECT L.Location_Id, L.Parent_Location_Id, Loc.Name, LT.Description
		FROM dbo.BhpbioLocationDate L
			INNER JOIN dbo.Location Loc
				ON L.Location_Id = Loc.Location_Id
			INNER JOIN dbo.LocationType AS LT
				ON L.Location_Type_Id = LT.Location_Type_Id
		WHERE ((@iChildLocations = 0 AND L.Location_Id = @iLocationId)
			OR (@iChildLocations = 1 AND L.Parent_Location_Id = @iLocationId))
			AND @DateFrom BETWEEN L.Start_Date AND L.End_Date

		-- Taken from dbo.GetBhpbioReportBaseDataAsTonnes so children can be collected
		INSERT INTO @Tonnes
		(
			Type, CalendarDate, MaterialTypeId, Tonnes, LocationId
		)
		SELECT 'Actual', sub.CalendarDate, mc.RootMaterialTypeId, SUM(Coalesce(Tonnes, 0.0)), 
			CASE WHEN @iChildLocations = 0 
				THEN @iLocationId
				ELSE LocationId
			END
		FROM
			(	-- C - z + y
				-- '+C' - all crusher removals
				SELECT CalendarDate, DesignationMaterialTypeId, SUM(Value) AS Tonnes, LocationId
				FROM dbo.GetBhpbioReportActualC(@DateFrom, @DateTo, NULL, @iLocationId, @iChildLocations, 1, 1)
				WHERE Attribute = 0
					AND ProductSize = 'TOTAL'
				GROUP BY CalendarDate, DesignationMaterialTypeId, LocationId
				
				UNION ALL
				
				-- '-z' - pre crusher stockpiles to crusher
				SELECT CalendarDate, DesignationMaterialTypeId, -SUM(Value) AS Tonnes, LocationId
				FROM dbo.GetBhpbioReportActualZ(@DateFrom, @DateTo, NULL, @iLocationId, @iChildLocations, 1, 1)
				WHERE Attribute = 0
					AND ProductSize = 'TOTAL'
				GROUP BY CalendarDate, DesignationMaterialTypeId, LocationId
				
				UNION ALL
				
				-- '+y' - pit to pre-crusher stockpiles
				SELECT CalendarDate, DesignationMaterialTypeId, SUM(Value), LocationId
				FROM dbo.GetBhpbioReportActualY(@DateFrom, @DateTo, NULL, @iLocationId, @iChildLocations, 1, 1)
				WHERE Attribute = 0
					AND ProductSize = 'TOTAL'
				GROUP BY CalendarDate, DesignationMaterialTypeId, LocationId
			) AS sub
			INNER JOIN @MaterialType AS mc
				ON (mc.MaterialTypeId = sub.DesignationMaterialTypeId)
		GROUP BY sub.CalendarDate, mc.RootMaterialTypeId, 
			CASE WHEN @iChildLocations = 0
				THEN @iLocationId
				ELSE LocationId
			END

		-- Taken from dbo.GetBhpbioReportBaseDataAsTonnes so children can be collected
		INSERT INTO @Tonnes
		(
			Type, BlockModelId, CalendarDate, MaterialTypeId, Tonnes, LocationId
		)
		SELECT bm.Name, bm.Block_Model_Id, m.CalendarDate, mc.RootMaterialTypeId, SUM(m.Value),
			CASE WHEN @iChildLocations = 0
				THEN @iLocationId
				ELSE LocationId
			END
		FROM dbo.GetBhpbioReportModel(@DateFrom, @DateTo, NULL, @iLocationId, @iChildLocations, 1, 1, 'As-Dropped') AS m
			INNER JOIN dbo.BlockModel AS bm
				ON (m.BlockModelId = bm.Block_Model_Id)
			INNER JOIN @MaterialType AS mc
				ON (mc.MaterialTypeId = m.DesignationMaterialTypeId)
		WHERE m.Attribute = 0
			AND ProductSize = 'TOTAL'
		GROUP BY bm.Name,
			bm.Block_Model_Id,
			m.CalendarDate,
			mc.RootMaterialTypeId,
			CASE WHEN @iChildLocations = 0
				THEN @iLocationId
				ELSE LocationId
			END

		-- Get the Haulage destination breakdown
		INSERT INTO @Tonnes
		(
			Type, CalendarDate, MaterialTypeId, Tonnes, LocationId
		)
		Select  ht.HaulageType, CalendarDate, DesignationMaterialTypeId, SUM(Coalesce(Value,0.0)), 
			CASE WHEN @iChildLocations = 0 
				THEN @iLocationId
				ELSE LocationId
			END
		From @HaulageType ht
			Left Join dbo.GetBhpbioReportHaulageBreakdown(@DateFrom, @DateTo, NULL, @iLocationId, @iChildLocations, 1, 1) hb
				on ht.HaulageType = hb.HaulageType
		Where ProductSize = 'TOTAL'
		Group By ht.HaulageType, CalendarDate, DesignationMaterialTypeId,
			CASE WHEN @iChildLocations = 0
				THEN @iLocationId
				ELSE LocationId
			END

		-- Modified version from dbo.GetBhpbioReportBaseDataAsTonnes so children can be collected
		-- Put the block model tonnes in.
		
		--Is only gets the NON Ore breakdown
		INSERT INTO dbo.#RecordTonnes
		(
			MaterialName, ModelName, Tonnes, LocationId, OrderNo
		)
		SELECT mt.RootAbbreviation AS Material, t.Type, r.Tonnes, r.LocationId, Coalesce(T.BlockModelId, @ActualId)
		-- Get all types
		FROM
			(
				SELECT DISTINCT [Type], BlockModelId
				FROM @Tonnes
			) AS t
			-- Cross joined with all material types
			CROSS JOIN
			(
				SELECT DISTINCT mt2.RootMaterialTypeId, mt2.RootAbbreviation, mt2.MaterialTypeId
				FROM @MaterialType AS mt2
					INNER JOIN @Tonnes AS r2
						ON (r2.MaterialTypeId = mt2.MaterialTypeId)
			) AS mt
			-- Joined on tonnes
			INNER JOIN @Tonnes AS r
				ON (r.MaterialTypeId = mt.MaterialTypeId
					AND r.Type = t.Type)
		WHERE mt.RootAbbreviation NOT IN (SELECT Description FROM dbo.GetBhpbioReportHighGrade()) 
			AND mt.RootAbbreviation IS NOT NULL

		---- Add up the total waste.
		INSERT INTO dbo.#RecordTonnes
		(
			MaterialTypeId, MaterialName, ModelName, Tonnes, LocationId, OrderNo, RootNode
		)
		SELECT CMT.Parent_Material_Type_Id, 'Total ' + MT.Description, 
			ModelName, Sum(Tonnes), RT.LocationId, RT.OrderNo, CMT.Parent_Material_Type_Id
		FROM dbo.#RecordTonnes AS RT
			INNER JOIN dbo.MaterialType AS CMT
				ON (RT.MaterialName = CMT.Description
					AND CMT.Material_Category_Id = @MaterialCategoryId)
			INNER JOIN dbo.MaterialType AS MT
				ON CMT.Parent_Material_Type_Id = MT.Material_Type_Id
		WHERE CMT.Parent_Material_Type_Id IS NOT NULL
		GROUP BY ModelName, CMT.Parent_Material_Type_Id, MT.Description, RT.OrderNo, RT.LocationId
		
		-- Add up the total ore.
		INSERT INTO dbo.#RecordTonnes
		(
			MaterialTypeId, MaterialName, ModelName, Tonnes, LocationId, OrderNo, RootNode
		)
		Select mt2.Parent_Material_Type_Id, 'Total ' + mt3.Description,
			t.type, sum(t.tonnes), t.locationId, Coalesce(t.BlockModelId, @ActualId), mt2.Parent_Material_Type_Id
		FROM @Tonnes AS t
			INNER JOIN @MaterialType AS mt
				ON (mt.MaterialTypeId = t.MaterialTypeId)
			Inner Join dbo.MaterialType As mt2
				on mt2.Material_Type_Id = mt.MaterialTypeId
			Inner Join dbo.MaterialType as mt3
				on mt2.Parent_Material_Type_Id = mt3.Material_Type_Id
		WHERE mt.RootAbbreviation IN (SELECT Description FROM dbo.GetBhpbioReportHighGrade()) 
			AND mt.RootAbbreviation IS NOT NULL
		GROUP BY t.type, mt2.Parent_Material_Type_Id, mt3.Description, Coalesce(t.BlockModelId, @ActualId), t.LocationId

		---- Add up the total.
		INSERT INTO dbo.#RecordTonnes
		(
			MaterialTypeId, MaterialName, ModelName, Tonnes, LocationId, OrderNo, RootNode
		)
		SELECT NULL, 'TOTAL:', ModelName, SUM(Tonnes), LocationId, OrderNo, 3
		FROM dbo.#RecordTonnes AS RT
		WHERE MaterialName like 'Total%'
		GROUP BY ModelName, LocationId, OrderNo
		
		-- Insert the required unpivoted rows based on the rows.
		INSERT INTO dbo.#Record
		(
			TagId, MaterialTypeId, MaterialName, OrderNo, ParentMaterialTypeId, LocationId, LocationName, LocationType
		)
		SELECT 
			CASE WHEN Parent_Material_Type_Id IS NULL THEN 
				NULL 
			ELSE 
				'OtherMaterial_' + REPLACE(MT.Description, ' ', '_')
			END,
			Coalesce(Material_Type_Id, RT.MaterialTypeId), 
			CASE WHEN Parent_Material_Type_Id IS NULL
				THEN 'Total ' + MT.Description
				ELSE MT.Description
			END,
			CASE WHEN Parent_Material_Type_Id IS NULL
				THEN ((MT.Material_Type_Id * 2) + 1) * 1000
				ELSE Coalesce(Parent_Material_Type_Id*2, RootNode*2 + 1) * 1000 + Coalesce(Material_Type_Id, 0)
			END,
			Parent_Material_Type_Id , L.LocationId, L.LocationName, L.LocationType
		FROM dbo.MaterialType AS MT
			CROSS JOIN @Location AS L
			LEFT JOIN dbo.#RecordTonnes AS RT
				ON (MT.Material_Type_Id = RT.MaterialTypeId
					AND L.LocationId = RT.LocationId)
		WHERE MT.Material_Category_Id IN ('Designation', 'Classification')
			AND MT.Description NOT IN (SELECT Description FROM dbo.GetBhpbioReportHighGrade()) 
		GROUP BY Material_Type_Id, RT.MaterialName, MT.Description, Material_Type_Id, RT.MaterialTypeId, RootNode, 
			Parent_Material_Type_Id, L.LocationId, L.LocationName, L.LocationType

		-- Insert the required unpivoted rows based on the rows.
		INSERT INTO dbo.#Record
		(
			TagId, MaterialTypeId, MaterialName, OrderNo, ParentMaterialTypeId, LocationId, LocationName, LocationType
		)
		SELECT NULL,NULL, 'TOTAL:', (RootNode * 2 + 1) * 1000, NULL, L.LocationId, L.LocationName, L.LocationType
		FROM @Location AS L
			LEFT JOIN dbo.#RecordTonnes AS RT
				ON L.LocationId = RT.LocationId
		WHERE RootNode = 3
		GROUP BY RootNode, L.LocationId, L.LocationName, L.LocationType
			
		-- Ensure all models/actual column show up. This will stop the pivoting from failing if some
		-- modenames/measures are missing
		INSERT INTO dbo.#RecordTonnes
		(
			LocationId, ModelName, OrderNo
		)
		SELECT -1, Name, Block_Model_Id
		FROM dbo.BlockModel
		WHERE Is_Displayed = 1
		UNION
		SELECT -1, @ActualName, @ActualId
		UNION
		SELECT -1, HaulageType, @ActualId -- this Id has the be the same as any other uses or the pivot will fuck up
		FROM @HaulageType
		
		-- Ensure all models/actual column values are not null.
		INSERT INTO dbo.#RecordTonnes
		(
			ModelName, LocationId, MaterialName, Tonnes, OrderNo
		)
		SELECT STUB.ModelName, L.LocationId, MT.MaterialName, 0, STUB.OrderNo -- MUST INSERT SAME ORDER NO HERE
		FROM
			(
				SELECT DISTINCT ModelName, OrderNo
				FROM dbo.#RecordTonnes
				WHERE MaterialName IS NULL
			) AS STUB
			CROSS JOIN @Location AS L
			CROSS JOIN
			(
				SELECT DISTINCT MaterialName
				FROM dbo.#Record
			) AS MT
			LEFT JOIN dbo.#RecordTonnes AS RT
				ON (RT.LocationId = L.LocationId
					AND RT.ModelName = STUB.ModelName
					AND RT.MaterialName = MT.MaterialName)
		WHERE RT.LocationId IS NULL
		ORDER BY L.LocationId
		
		-- Display zeros when a value is not present.
		UPDATE dbo.#RecordTonnes
		SET Tonnes = 0
		WHERE Tonnes IS NULL
					
		-- Pivot the blockmodel/actual tonnes into the material types
		EXEC dbo.PivotTable
			@iTargetTable = '#Record',
			@iPivotTable = '#RecordTonnes',
			@iJoinColumns = '#Record.MaterialName = #RecordTonnes.MaterialName AND #Record.LocationId = #RecordTonnes.LocationId',
			@iPivotColumn = 'ModelName',
			@iPivotValue = 'Tonnes',
			@iPivotType = 'FLOAT',
			@iPivotOrderColumn = 'OrderNo'
		
		SELECT TagId,
				LocationId,
				LocationType,
				LocationName,
				MaterialTypeId,
				MaterialName,
				OrderNo,
				ParentMaterialTypeId,
				Approved,
				SignOff,
				Geology,
				Mining,
				[Short Term Geology],
				[Grade Control],
				ISNULL(HauledToOreStockpile,0) As HauledToOreStockpile,
				ISNULL(HauledToNonOreStockpile,0) As HauledToNonOreStockpile,
				ISNULL(HauledToCrusher,0) AS HauledToCrusher,
				ISNULL(HauledToOreStockpile,0) + ISNULL(HauledToNonOreStockpile,0) + ISNULL(HauledToCrusher,0) As HaulageTotal,
				Actual
		FROM dbo.#Record
		ORDER BY LocationName, OrderNo
		
		DROP TABLE dbo.#Record
		DROP TABLE dbo.#RecordTonnes

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
		-- if we are part of an existing transaction and 
		ELSE IF (XAct_State() = 1) AND (@TransactionCount > 0)
		BEGIN
			ROLLBACK TRANSACTION @TransactionName
		END

		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON dbo.GetBhpbioApprovalOtherMaterial TO BhpbioGenericManager
GO

----exec dbo.GetBhpbioApprovalOtherMaterial '1-nov-2009', 8, 1
