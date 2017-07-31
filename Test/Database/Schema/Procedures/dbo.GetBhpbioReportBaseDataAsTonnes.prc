IF OBJECT_ID('dbo.GetBhpbioReportBaseDataAsTonnes') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportBaseDataAsTonnes
GO

CREATE PROCEDURE dbo.GetBhpbioReportBaseDataAsTonnes
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iIncludeBlockModels BIT,
	@iBlockModels XML,
	@iIncludeActuals BIT,
	@iMaterialCategoryId VARCHAR(31),
	@iRootMaterialTypeId INT,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT
)
AS 
BEGIN
	-- for internal consumption only

	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @Tonnes TABLE
	(
		Type VARCHAR(255) COLLATE DATABASE_DEFAULT NOT NULL,
		CalendarDate DATETIME NOT NULL,
		MaterialTypeId INT NOT NULL,
		ProductSize VARCHAR(5) NOT NULL,
		Tonnes FLOAT,
		Volume FLOAT,
		PRIMARY KEY CLUSTERED (CalendarDate, MaterialTypeId, Type, ProductSize)
	)
	
	DECLARE @Type TABLE
	(
		Type VARCHAR(255) COLLATE DATABASE_DEFAULT NOT NULL,
		BlockModelId INT NULL,
		PRIMARY KEY CLUSTERED (Type)
	)

	DECLARE @MaterialType TABLE
	(
		RootMaterialTypeId INT NOT NULL,
		RootAbbreviation VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialTypeId INT NOT NULL,
		PRIMARY KEY CLUSTERED (MaterialTypeId, RootMaterialTypeId)
	)

	DECLARE @Date TABLE
	(
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		CalendarDate DATETIME NOT NULL,
		PRIMARY KEY NONCLUSTERED (CalendarDate),
		UNIQUE CLUSTERED (DateFrom, DateTo, CalendarDate)
	)

	DECLARE @ProductSize TABLE
	(
		ProductSize VARCHAR(5),
		PRIMARY KEY (ProductSize)
	)

	DECLARE @Location Table
	(
		LocationId INT NOT NULL,
		PRIMARY KEY CLUSTERED (LocationId)
	)

	DECLARE @Crusher Table
	(
		CrusherId VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		PRIMARY KEY CLUSTERED (CrusherId)
	)

	DECLARE @HighGradeMaterialTypeId INT
	DECLARE @BeneFeedMaterialTypeId INT

	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioReportBaseDataAsTonnes',
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
		-- perform checks
		IF dbo.GetDateMonth(@iDateFrom) <> @iDateFrom
		BEGIN
			RAISERROR('The @iDateFrom parameter must be the first day of the month.', 16, 1)
		END

		IF (dbo.GetDateMonth(@iDateTo + 1) - 1) <> @iDateTo
		BEGIN
			RAISERROR('The @iDateTo parameter must be the last day of the month.', 16, 1)
		END

		IF NOT @iMaterialCategoryId IN ('Classification', 'Designation')
		BEGIN
			RAISERROR('The Material Category parameter can only be Classification/Designation.', 16, 1)
		END

		IF @iMaterialCategoryId NOT IN ('Classification', 'Designation')
		BEGIN
			RAISERROR('Only "Classification" and "Designation" are supported as material categories.', 16, 1)
		END

		-- load Block Model
		IF @iIncludeActuals = 1
		BEGIN
			INSERT INTO @Type
				(Type, BlockModelId)
			VALUES
				('Actual', NULL)
		END

		IF (@iIncludeBlockModels = 1) AND (@iBlockModels IS NULL)
		BEGIN
			INSERT INTO @Type
				(Type, BlockModelId)
			SELECT Name, Block_Model_Id
			FROM dbo.BlockModel
		END
		ELSE IF (@iIncludeBlockModels = 1)
		BEGIN
			INSERT INTO @Type
				(Type, BlockModelId)
			SELECT bm.Name, b.BlockModel.value('./@id', 'INT')
			FROM @iBlockModels.nodes('/BlockModels/BlockModel') AS b(BlockModel)
				INNER JOIN dbo.BlockModel AS bm
					ON (bm.Block_Model_Id = b.BlockModel.value('./@id', 'INT'))
		END
		
		-- load the material data
		INSERT INTO @MaterialType
			(RootMaterialTypeId, RootAbbreviation, MaterialTypeId)
		SELECT mc.RootMaterialTypeId, mt.Abbreviation, mc.MaterialTypeId
		FROM dbo.GetMaterialsByCategory(@iMaterialCategoryId) AS mc
			INNER JOIN dbo.MaterialType AS mt
				ON (mc.RootMaterialTypeId = mt.Material_Type_Id)
		WHERE mc.RootMaterialTypeId = ISNULL(@iRootMaterialTypeId, mc.RootMaterialTypeId)

		-- load the date range
		INSERT INTO @Date
			(DateFrom, DateTo, CalendarDate)
		SELECT DateFrom, DateTo, CalendarDate
		FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1)
		
		-- load the product sizes
		INSERT INTO @ProductSize VALUES ('FINES')
		INSERT INTO @ProductSize VALUES ('LUMP')
		INSERT INTO @ProductSize VALUES ('TOTAL')

		-- generate the actual + model data
		IF @iIncludeActuals = 1
		BEGIN
			INSERT INTO @Tonnes
			(
				Type, CalendarDate, MaterialTypeId, ProductSize, Tonnes
			)
			SELECT 'Actual', sub.CalendarDate, mc.RootMaterialTypeId, sub.ProductSize, SUM(NULLIF(Tonnes, 0.0))
			FROM
				(
					-- C - z + y

					-- '+C' - all crusher removals
					SELECT CalendarDate, DesignationMaterialTypeId, ProductSize, SUM(Value) AS Tonnes
					FROM dbo.GetBhpbioReportActualC(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, NULL, @iIncludeLiveData, @iIncludeApprovedData)
					WHERE Attribute = 0
					GROUP BY CalendarDate, DesignationMaterialTypeId, ProductSize
					
					UNION ALL

					-- '-z' - pre crusher stockpiles to crusher
					SELECT CalendarDate, DesignationMaterialTypeId, ProductSize, -SUM(Value) AS Tonnes
					FROM dbo.GetBhpbioReportActualZ(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, NULL, @iIncludeLiveData, @iIncludeApprovedData)
					WHERE Attribute = 0
					GROUP BY CalendarDate, DesignationMaterialTypeId, ProductSize

					UNION ALL

					-- '+y' - pit to pre-crusher stockpiles
					SELECT CalendarDate, DesignationMaterialTypeId, ProductSize, SUM(Value)
					FROM dbo.GetBhpbioReportActualY(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, NULL, @iIncludeLiveData, @iIncludeApprovedData)
					WHERE Attribute = 0
					GROUP BY CalendarDate, DesignationMaterialTypeId, ProductSize
				) AS sub
				INNER JOIN @MaterialType AS mc
					ON (mc.MaterialTypeId = sub.DesignationMaterialTypeId)
			GROUP BY sub.CalendarDate, mc.RootMaterialTypeId, sub.ProductSize
		END

		IF (@iIncludeBlockModels = 1)
		BEGIN
			INSERT INTO @Tonnes
			(
				Type, CalendarDate, MaterialTypeId, ProductSize, Tonnes, Volume
			)
			SELECT bm.Type, m.CalendarDate, mc.RootMaterialTypeId, m.ProductSize, 
					SUM(CASE WHEN m.Attribute = 0 THEN m.Value ELSE 0 END), -- tonnes
					SUM(CASE WHEN m.Attribute = -1 THEN m.Value ELSE 0 END) -- volume
			FROM dbo.GetBhpbioReportModel(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, NULL, @iIncludeLiveData, @iIncludeApprovedData,'As-Dropped') AS m
				INNER JOIN @Type AS bm
					ON (m.BlockModelId = bm.BlockModelId)
				INNER JOIN @MaterialType AS mc
					ON (mc.MaterialTypeId = m.DesignationMaterialTypeId)
			WHERE m.Attribute IN (-1,0)
			GROUP BY bm.Type, m.CalendarDate, mc.RootMaterialTypeId, m.ProductSize
		END

		-- return the result		
		SELECT t.Type, t.BlockModelId, d.CalendarDate,
			mt.RootAbbreviation AS Material, mt.RootMaterialTypeId AS MaterialTypeId, ps.ProductSize,
			Sum(r.Tonnes) As Tonnes,
			Sum(r.Volume) As Volume
		FROM
			-- display all dates
			@Date AS d
			-- display all elisted types (block models + actual)
			CROSS JOIN @Type AS t
			-- ensure material types are represented uniformly
			CROSS JOIN
				(
					SELECT DISTINCT mt2.RootMaterialTypeId, mt2.RootAbbreviation, mt2.MaterialTypeId
					FROM @MaterialType AS mt2
					INNER JOIN @Tonnes AS tonnes ON (tonnes.MaterialTypeId = mt2.MaterialTypeId)
				) AS mt
			CROSS JOIN @ProductSize AS ps
			-- pivot in the results
			LEFT OUTER JOIN @Tonnes AS r
				ON (r.CalendarDate = d.CalendarDate
					AND r.MaterialTypeId = mt.MaterialTypeId
					AND r.Type = t.Type
					AND r.ProductSize = ps.ProductSize)
		GROUP BY t.Type, t.BlockModelId, d.CalendarDate,
			mt.RootAbbreviation, mt.RootMaterialTypeId, ps.ProductSize
		ORDER BY d.CalendarDate, mt.RootAbbreviation, t.Type

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

/* testing

EXEC dbo.GetBhpbioReportBaseDataAsTonnes
	@iDateFrom = '01-JUN-2009',
	@iDateTo = '30-JUN-2009',
	@iDateBreakdown = NULL,
	@iLocationId = 1,
	@iIncludeBlockModels = 1,
	@iBlockModels = NULL,
	@iIncludeActuals = 1,
	@iMaterialCategoryId = 'Designation',
	@iRootMaterialTypeId = NULL,
	@iIncludeLiveData = 1,
	@iIncludeApprovedData = 0
*/


