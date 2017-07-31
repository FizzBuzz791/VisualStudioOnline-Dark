IF Object_Id('dbo.GetBhpbioGradeRecoveryReport') IS NOT NULL
	DROP PROCEDURE dbo.GetBhpbioGradeRecoveryReport
GO

CREATE PROCEDURE dbo.GetBhpbioGradeRecoveryReport
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iLocationId INT,
	@iIncludeBlockModels BIT,
	@iBlockModels XML,
	@iIncludeActuals BIT,
	@iDesignationMaterialTypeId	INT,
	@iTonnes BIT,
	@iVolume BIT,
	@iGrades XML,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT,
	@iLumpFinesBreakdown BIT
)
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @Tonnes TABLE
	(
		Type VARCHAR(255) COLLATE DATABASE_DEFAULT NOT NULL,
		BlockModelId INT NULL,
		CalendarDate DATETIME NOT NULL,
		Material VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialTypeId INT NOT NULL,
		ProductSize VARCHAR(5) NOT NULL,	
		Tonnes FLOAT,
		Volume FLOAT,
		PRIMARY KEY CLUSTERED (CalendarDate, Material, Type,ProductSize)
	)

	DECLARE @Grade TABLE
	(
		Type VARCHAR(255) COLLATE DATABASE_DEFAULT NOT NULL,
		BlockModelId INT NULL,
		CalendarDate DATETIME NOT NULL,
		Material VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialTypeId INT NOT NULL,
		ProductSize VARCHAR(5) NOT NULL,		
		GradeName VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		GradeId SMALLINT NOT NULL,
		GradeValue REAL,
		GradePrecision INT,
		PRIMARY KEY CLUSTERED (CalendarDate, Material, GradeName, Type,ProductSize)
	)

	SET NOCOUNT ON

	SELECT @TransactionName = 'GetBhpbioGradeRecoveryReport',
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
		-- load the base data
		INSERT INTO @Tonnes
		(
			Type, BlockModelId, CalendarDate, Material, MaterialTypeId, ProductSize, Tonnes, Volume
		)
		EXEC dbo.GetBhpbioReportBaseDataAsTonnes
			@iDateFrom = @iDateFrom,
			@iDateTo = @iDateTo,
			@iDateBreakdown = NULL,
			@iLocationId = @iLocationId,
			@iIncludeBlockModels = @iIncludeBlockModels,
			@iBlockModels = @iBlockModels,
			@iIncludeActuals = @iIncludeActuals,
			@iMaterialCategoryId = 'Designation',
			@iRootMaterialTypeId = @iDesignationMaterialTypeId,
			@iIncludeLiveData = @iIncludeLiveData,
			@iIncludeApprovedData = @iIncludeApprovedData

		INSERT INTO @Grade
		(
			Type, BlockModelId, CalendarDate, Material, MaterialTypeId, ProductSize, GradeName, GradeId, GradeValue
		)
		EXEC dbo.GetBhpbioReportBaseDataAsGrades
			@iDateFrom = @iDateFrom,
			@iDateTo = @iDateTo,
			@iDateBreakdown = NULL,
			@iLocationId = @iLocationId,
			@iIncludeBlockModels = @iIncludeBlockModels,
			@iBlockModels = @iBlockModels,
			@iIncludeActuals = @iIncludeActuals,
			@iMaterialCategoryId = 'Designation',
			@iRootMaterialTypeId = @iDesignationMaterialTypeId,
			@iGrades = @iGrades,
			@iIncludeLiveData = @iIncludeLiveData,
			@iIncludeApprovedData = @iIncludeApprovedData

			
		UPDATE BG
		SET GradePrecision = G.Display_Precision
		FROM @Grade BG
			INNER JOIN Grade G
				ON (G.Grade_Id = BG.GradeId)

		--@iLumpFinesBreakdown
		--IF @iLumpFinesBreakdown=1 Only Breakdown for High Grade and Bene Feed.
		--IF @iLumpFinesBreakdown= 0 then only show TOTAL
		If (@iLumpFinesBreakdown = 0)
		BEGIN
		
			DELETE FROM @Grade
			WHERE ProductSize <> 'TOTAL'
			
			DELETE FROM @Tonnes
			WHERE ProductSize <> 'TOTAL'
		END
		ELSE
		BEGIN
		
			DELETE FROM @Grade
			WHERE Material NOT IN ('High Grade','Bene Feed')
				AND ProductSize <> 'TOTAL'
			
			DELETE FROM @Tonnes
			WHERE Material NOT IN ('High Grade','Bene Feed')
				AND ProductSize <> 'TOTAL'

		END			
	
		-- create the summary table

		-- generate the ABSOLUTE DATA
		-- this has no recovery calculations applied

		SELECT 'Absolute' AS Section, 'Tonnes' AS TonnesGradesTag, Type AS Model, Material AS Designation, ProductSize,
			SUM(Tonnes) AS Value
		FROM @Tonnes
		GROUP BY Type, Material, ProductSize
		HAVING @iTonnes = 1

		UNION ALL
		
		SELECT 'Absolute' AS Section, 'Volume', Type AS Model, Material AS Designation, ProductSize,
			SUM(Volume) AS Value
		FROM @Tonnes
		GROUP BY Type, Material, ProductSize
		HAVING @iVolume = 1
		
		UNION ALL

		SELECT 'Absolute', g.GradeName, g.Type, g.Material, g.ProductSize,
			SUM(g.GradeValue * t.Tonnes) / SUM(t.Tonnes)
		FROM @Grade AS g
			INNER JOIN @Tonnes AS t
				ON (g.Type = t.Type
					AND g.CalendarDate = t.CalendarDate
					AND g.Material = t.Material
					AND g.ProductSize = t.ProductSize)
		GROUP BY g.GradeName, g.Type, g.Material, g.ProductSize

		UNION ALL

		-- generate the DIFFERENCES (RECOVERY) DATA
		-- this shows comparisons between all permutations
		-- this may need to be filtered out somewhere at some point!
		SELECT 'Difference', 'Tonnes', t1.Type + ' - ' + t2.Type, t1.Material, t1.ProductSize,
			ROUND(SUM(t1.Tonnes), -3) - ROUND(SUM(t2.Tonnes), -3)
		FROM @Tonnes AS t1
			INNER JOIN @Tonnes AS t2
				ON (t1.CalendarDate = t2.CalendarDate
					AND t1.Material = t2.Material
					AND t1.ProductSize = t2.ProductSize
					AND t1.Type <> t2.Type)
		WHERE (t1.Type = 'Actual' AND t2.Type = 'Mining')
			OR (t1.Type = 'Grade Control' AND t2.Type = 'Mining')
			OR (t1.Type = 'Actual' AND t2.Type = 'Grade Control')
		GROUP BY t1.Type, t2.Type, t1.Material, t1.ProductSize

		UNION ALL
		
		SELECT 'Difference', 'Volume', t1.Type + ' - ' + t2.Type, t1.Material, t1.ProductSize,
			ROUND(SUM(t1.Volume), -3) - ROUND(SUM(t2.Volume), -3)
		FROM @Tonnes AS t1
			INNER JOIN @Tonnes AS t2
				ON (t1.CalendarDate = t2.CalendarDate
					AND t1.Material = t2.Material
					AND t1.ProductSize = t2.ProductSize
					AND t1.Type <> t2.Type)
		WHERE (t1.Type = 'Actual' AND t2.Type = 'Mining')
			OR (t1.Type = 'Grade Control' AND t2.Type = 'Mining')
			OR (t1.Type = 'Actual' AND t2.Type = 'Grade Control')
		GROUP BY t1.Type, t2.Type, t1.Material, t1.ProductSize

		UNION ALL

		SELECT 'Difference', g1.GradeName, g1.Type + ' - ' + g2.Type, g1.Material, g1.ProductSize,
			ROUND(SUM(g1.GradeValue * t1.Tonnes)/SUM(t1.Tonnes), g1.GradePrecision) - ROUND(SUM(g2.GradeValue * t2.Tonnes) / SUM(t2.Tonnes), g2.GradePrecision)
		FROM @Grade AS g1
			INNER JOIN @Tonnes AS t1
				ON (t1.Type = g1.Type
					AND t1.CalendarDate = g1.CalendarDate
					AND t1.Material = g1.Material
					AND t1.ProductSize = g1.ProductSize)
			INNER JOIN @Grade AS g2
				ON (g1.CalendarDate = g2.CalendarDate
					AND g1.Material = g2.Material
					AND g1.GradeName = g2.GradeName
					AND g1.ProductSize = g2.ProductSize
					AND g1.Type <> g2.Type)
			INNER JOIN @Tonnes AS t2
				ON (t2.Type = g2.Type
					AND t2.CalendarDate = g2.CalendarDate
					AND t2.Material = g2.Material
					AND t2.ProductSize = g2.ProductSize)
		WHERE (t1.Type = 'Actual' AND t2.Type = 'Mining')
			OR (t1.Type = 'Grade Control' AND t2.Type = 'Mining')
			OR (t1.Type = 'Actual' AND t2.Type = 'Grade Control')
		GROUP BY g1.Type, g2.Type, g1.Material, g1.GradeName, g1.GradePrecision, g2.GradePrecision, g1.ProductSize

		-- supply the GRAPH data
		SELECT 'Tonnes' AS TonnesGradesTag, Type AS ModelTag, Material AS Designation, ProductSize,
			SUM(Tonnes) AS Value
		FROM @Tonnes
		GROUP BY Type, Material, ProductSize
		HAVING @iTonnes = 1

		UNION ALL
		
		SELECT 'Volume', Type AS ModelTag, Material AS Designation, ProductSize,
			SUM(Volume) AS Value
		FROM @Tonnes
		GROUP BY Type, Material, ProductSize
		HAVING @iVolume = 1

		UNION ALL

		SELECT g.GradeName, g.Type, g.Material, g.ProductSize,
			SUM(g.GradeValue * t.Tonnes) / SUM(t.Tonnes)
		FROM @Grade AS g
			INNER JOIN @Tonnes AS t
				ON (g.CalendarDate = t.CalendarDate
					AND g.Type = t.Type
					AND g.Material = t.Material
					AND g.ProductSize = t.ProductSize)
		GROUP BY g.GradeName, g.Type, g.Material, g.ProductSize
					
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

GRANT EXECUTE ON dbo.GetBhpbioGradeRecoveryReport TO BhpbioGenericManager
GO

/*
testing
EXEC dbo.GetBhpbioGradeRecoveryReport
	@iDateFrom = '01-JUN-2009',
	@iDateTo = '30-JUN-2009',
	@iLocationId = 8,
	@iIncludeBlockModels = 1,
	@iBlockModels = '<BlockModels><BlockModel id="1"/><BlockModel id="2"/><BlockModel id="3"/></BlockModels>',
	@iIncludeActuals = 1,
	@iDesignationMaterialTypeId = NULL,
	@iTonnes = 1,
	@iVolume = 1,
	@iGrades = '<Grades><Grade id="1"/><Grade id="2"/><Grade id="3"/><Grade id="4"/><Grade id="5"/></Grades>',
	@iIncludeLiveData = 1,
	@iIncludeApprovedData = 0,
	@iLumpFinesBreakdown = 1
*/
