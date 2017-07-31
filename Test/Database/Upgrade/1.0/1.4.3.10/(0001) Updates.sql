
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
	@iRootMaterialTypeId INT
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
		Tonnes FLOAT,
		PRIMARY KEY CLUSTERED (CalendarDate, MaterialTypeId, Type)
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


		-- generate the actual + model data
		IF @iIncludeActuals = 1
		BEGIN
			INSERT INTO @Tonnes
			(
				Type, CalendarDate, MaterialTypeId, Tonnes
			)
			SELECT 'Actual', sub.CalendarDate, mc.RootMaterialTypeId, SUM(NULLIF(Tonnes, 0.0))
			FROM
				(
					-- C - z + y

					-- '+C' - all crusher removals
					SELECT CalendarDate, DesignationMaterialTypeId, SUM(Value) AS Tonnes
					FROM dbo.GetBhpbioReportActualC(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, NULL)
					WHERE Attribute = 0
					GROUP BY CalendarDate, DesignationMaterialTypeId
					
					UNION ALL

					-- '-z' - pre crusher stockpiles to crusher
					SELECT CalendarDate, DesignationMaterialTypeId, -SUM(Value) AS Tonnes
					FROM dbo.GetBhpbioReportActualZ(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, NULL)
					WHERE Attribute = 0
					GROUP BY CalendarDate, DesignationMaterialTypeId

					UNION ALL

					-- '+y' - pit to pre-crusher stockpiles
					SELECT CalendarDate, DesignationMaterialTypeId, SUM(Value)
					FROM dbo.GetBhpbioReportActualY(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, NULL)
					WHERE Attribute = 0
					GROUP BY CalendarDate, DesignationMaterialTypeId
				) AS sub
				INNER JOIN @MaterialType AS mc
					ON (mc.MaterialTypeId = sub.DesignationMaterialTypeId)
			GROUP BY sub.CalendarDate, mc.RootMaterialTypeId
		END

		IF (@iIncludeBlockModels = 1)
		BEGIN
			INSERT INTO @Tonnes
			(
				Type, CalendarDate, MaterialTypeId, Tonnes
			)
			SELECT bm.Type, m.CalendarDate, mc.RootMaterialTypeId, SUM(m.Value)
			FROM dbo.GetBhpbioReportModel(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, NULL) AS m
				INNER JOIN @Type AS bm
					ON (m.BlockModelId = bm.BlockModelId)
				INNER JOIN @MaterialType AS mc
					ON (mc.MaterialTypeId = m.DesignationMaterialTypeId)
			WHERE m.Attribute = 0
			GROUP BY bm.Type, m.CalendarDate, mc.RootMaterialTypeId
		END

		-- return the result		
		SELECT t.Type, t.BlockModelId, d.CalendarDate,
			mt.RootAbbreviation AS Material, mt.RootMaterialTypeId AS MaterialTypeId,
			Sum(r.Tonnes) As Tonnes
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
			-- pivot in the results
			LEFT OUTER JOIN @Tonnes AS r
				ON (r.CalendarDate = d.CalendarDate
					AND r.MaterialTypeId = mt.MaterialTypeId
					AND r.Type = t.Type)
		GROUP BY t.Type, t.BlockModelId, d.CalendarDate,
			mt.RootAbbreviation, mt.RootMaterialTypeId
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
	@iDateFrom = '01-APR-2008',
	@iDateTo = '30-JUN-2008',
	@iDateBreakdown = NULL,
	@iLocationId = 1,
	@iIncludeBlockModels = 1,
	@iBlockModels = NULL,
	@iIncludeActuals = 1,
	@iMaterialCategoryId = 'Designation',
	@iRootMaterialTypeId = NULL
*/







IF OBJECT_ID('dbo.GetBhpbioReportBaseDataAsGrades') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportBaseDataAsGrades
GO

CREATE PROCEDURE dbo.GetBhpbioReportBaseDataAsGrades
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
	@iGrades XML
)
AS 
BEGIN
	-- for internal consumption only
	
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	DECLARE @HighGradeMaterialTypeId INT

	DECLARE @Grade TABLE
	(
		Type VARCHAR(255) COLLATE DATABASE_DEFAULT NOT NULL,
		CalendarDate DATETIME NOT NULL,
		MaterialTypeId INT NOT NULL,
		GradeId SMALLINT NOT NULL,
		GradeValue FLOAT NULL,
		Tonnes FLOAT NULL,
		PRIMARY KEY CLUSTERED (CalendarDate, MaterialTypeId, GradeId, Type)
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

	DECLARE @GradeLookup TABLE
	(
		GradeId SMALLINT NOT NULL,
		GradeName VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		OrderNo INT NOT NULL,
		PRIMARY KEY CLUSTERED (GradeId)
	)

	DECLARE @C TABLE
	(
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		DesignationMaterialTypeId INT NOT NULL,
		LocationId INT NULL,
		Attribute SMALLINT NULL,
		Value FLOAT NULL
	)

	DECLARE @Y TABLE
	(
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		DesignationMaterialTypeId INT NOT NULL,
		LocationId INT NULL,
		Attribute SMALLINT NULL,
		Value FLOAT NULL
	) 

	DECLARE @Z TABLE
	(
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		DesignationMaterialTypeId INT NOT NULL,
		LocationId INT NULL,
		Attribute SMALLINT NULL,
		Value FLOAT NULL
	)

	DECLARE @M TABLE
	(
		CalendarDate DATETIME NOT NULL,
		BlockModelId INT NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		DesignationMaterialTypeId INT NOT NULL,
		LocationId INT NULL,
		Attribute SMALLINT NULL,
		Value FLOAT NULL
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioReportBaseDataAsGrades',
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

		-- load Grades
		IF @iGrades IS NULL
		BEGIN
			INSERT INTO @GradeLookup
				(GradeId, GradeName, OrderNo)
			SELECT Grade_Id, Grade_Name, Order_No
			FROM dbo.Grade
		END
		ELSE
		BEGIN
			INSERT INTO @GradeLookup
				(GradeId, GradeName, OrderNo)
			SELECT g.Grade.value('./@id', 'SMALLINT'), g2.Grade_Name, g2.Order_No
			FROM @iGrades.nodes('/Grades/Grade') AS g(Grade)
				INNER JOIN dbo.Grade AS g2
					ON (g2.Grade_Id = g.Grade.value('./@id', 'SMALLINT'))
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

		-- generate the actual + model data
		IF @iIncludeActuals = 1
		BEGIN
			INSERT INTO @C
				(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value)
			SELECT CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value
			FROM dbo.GetBhpbioReportActualC(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, NULL)

			INSERT INTO @Y
				(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value)
			SELECT CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value
			FROM dbo.GetBhpbioReportActualY(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, NULL)

			INSERT INTO @Z
				(CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value)
			SELECT CalendarDate, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value
			FROM dbo.GetBhpbioReportActualZ(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, NULL)

			INSERT INTO @Grade
			(
				Type, CalendarDate, MaterialTypeId, GradeId, GradeValue, Tonnes
			)
			SELECT 'Actual', CalendarDate, RootMaterialTypeId, GradeId,
				SUM(Tonnes * GradeValue) / NULLIF(SUM(Tonnes), 0.0), SUM(Tonnes)
			FROM
				(
					-- High Grade = C - z(hg) + y(hg)
					-- All Grade  = y(non-hg)

					-- '+C' - all crusher removals
					SELECT g.CalendarDate, mc.RootMaterialTypeId,
						g.Attribute As GradeId, SUM(t.Value) AS Tonnes,
						-- the following value is only valid as the data is always returned at the Site level
						-- above this level (Hub/WAIO) the aggregation will properly perform real aggregations
						SUM(g.Value * NULLIF(t.Value, 0.0)) / NULLIF(SUM(t.Value), 0.0) As GradeValue
					FROM @C AS g
						INNER JOIN @C AS t
							ON (g.DesignationMaterialTypeId = t.DesignationMaterialTypeId)
						INNER JOIN @MaterialType AS mc
							ON (mc.MaterialTypeId = t.DesignationMaterialTypeId)
					WHERE g.Attribute > 0
						AND t.Attribute = 0
					GROUP BY g.CalendarDate, mc.RootMaterialTypeId, g.Attribute

					UNION ALL

					-- '-z(all)' - pre crusher stockpiles to crusher
					SELECT g.CalendarDate, mc.RootMaterialTypeId,
						g.Attribute As GradeId,
						-SUM(t.Value) AS Tonnes, SUM(g.Value * t.Value) / NULLIF(SUM(t.Value), 0.0) As GradeValue
					FROM @Z AS g
						INNER JOIN @Z AS t
							ON (g.DesignationMaterialTypeId = t.DesignationMaterialTypeId)
						INNER JOIN @MaterialType AS mc
							ON (mc.MaterialTypeId = t.DesignationMaterialTypeId)
					WHERE g.Attribute > 0
						AND t.Attribute = 0
					GROUP BY g.CalendarDate, mc.RootMaterialTypeId, g.Attribute

					UNION ALL

					-- '+y(hg)' - pit to pre-crusher stockpiles
					SELECT g.CalendarDate, mc.RootMaterialTypeId,
						g.Attribute As GradeId,
						SUM(t.Value) AS Tonnes, SUM(g.Value * t.Value) / NULLIF(SUM(t.Value), 0.0) As GradeValue
					FROM @Y AS g
						INNER JOIN @Y AS t
							ON (g.DesignationMaterialTypeId = t.DesignationMaterialTypeId)
						INNER JOIN @MaterialType AS mc
							ON (mc.MaterialTypeId = t.DesignationMaterialTypeId)
					WHERE g.Attribute > 0
						AND t.Attribute = 0
					GROUP BY g.CalendarDate, mc.RootMaterialTypeId, g.Attribute
				) AS sub
			GROUP BY CalendarDate, RootMaterialTypeId, GradeId
		END

		IF (@iIncludeBlockModels = 1)
		BEGIN
			INSERT INTO @M
				(CalendarDate, BlockModelId, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value)
			SELECT CalendarDate, BlockModelId, DateFrom, DateTo, DesignationMaterialTypeId, LocationId, Attribute, Value
			FROM dbo.GetBhpbioReportModel(@iDateFrom, @iDateTo, @iDateBreakdown, @iLocationId, NULL)

			INSERT INTO @Grade
			(
				Type, CalendarDate, MaterialTypeId, GradeId, GradeValue, Tonnes
			)
			SELECT bm.Type, g.CalendarDate, mc.RootMaterialTypeId, g.Attribute,
				SUM(g.Value * t.Value) / SUM(t.Value), SUM(t.Value)
			FROM @M AS t
				INNER JOIN @M AS g
					ON (t.DesignationMaterialTypeId = g.DesignationMaterialTypeId
						AND t.BlockModelId = g.BlockModelId)
				INNER JOIN @MaterialType AS mc
					ON (mc.MaterialTypeId = t.DesignationMaterialTypeId)
				INNER JOIN @Type AS bm
					ON (t.BlockModelId = bm.BlockModelId)
			WHERE t.Attribute = 0
				AND g.Attribute > 0
			GROUP BY bm.Type, g.CalendarDate, mc.RootMaterialTypeId, g.Attribute
		END

		-- return the result	
		SELECT t.Type, t.BlockModelId, d.CalendarDate,
			mt.RootAbbreviation AS Material, mt.RootMaterialTypeId AS MaterialTypeId,
			g.GradeName, g.GradeId, SUM(r.GradeValue * r.Tonnes) / SUM(r.Tonnes) As GradeValue
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
					INNER JOIN @Grade AS grade ON (grade.MaterialTypeId = mt2.MaterialTypeId)
				) AS mt
			-- ensure all grades are represented
			CROSS JOIN @GradeLookup AS g
			-- pivot in the results
			LEFT OUTER JOIN @Grade AS r
				ON (r.CalendarDate = d.CalendarDate
					AND r.MaterialTypeId = mt.MaterialTypeId
					AND r.Type = t.Type
					AND g.GradeId = r.GradeId)
		GROUP BY t.Type, t.BlockModelId, d.CalendarDate,
			mt.RootAbbreviation , mt.RootMaterialTypeId ,
			g.GradeName, g.GradeId, g.OrderNo
		ORDER BY d.CalendarDate, mt.RootAbbreviation, t.Type, g.OrderNo

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

EXEC dbo.GetBhpbioReportBaseDataAsGrades
	@iDateFrom = '01-APR-2010',
	@iDateTo = '30-JUN-2010',
	@iDateBreakdown = 'QUARTER',
	@iLocationId = 4,
	@iIncludeBlockModels = 1,
	@iBlockModels = NULL,
	@iIncludeActuals = 1,
	@iMaterialCategoryId = 'Designation',
	@iRootMaterialTypeId = NULL,
	@iGrades = NULL
*/ 
