IF Object_Id('dbo.GetBhpbioModelComparisonReport') IS NOT NULL
	DROP PROCEDURE dbo.GetBhpbioModelComparisonReport
GO

CREATE PROCEDURE dbo.GetBhpbioModelComparisonReport
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iIncludeBlockModels BIT,
	@iBlockModels XML,
	@iIncludeActuals BIT,
	@iDesignationMaterialTypeId INT,
	@iTonnes BIT,
	@iGrades XML,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT,
	@iIncludeLumpFinesBreakdown BIT
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
		PRIMARY KEY CLUSTERED (CalendarDate, Material, Type, ProductSize)
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
		GradeValue REAL ,
		PRIMARY KEY CLUSTERED (CalendarDate, Material, GradeName, Type, ProductSize)
	)

	SET NOCOUNT ON

	SELECT @TransactionName = 'GetBhpbioModelComparisonReport',
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
		-- note: this has been split into two separate calls
		-- a new requirement (for crusher actuals) has made it such that we cannot aggregate any further beyond the base procs

		-- create the summary data
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

		--@iLumpFinesBreakdown
		--IF @iLumpFinesBreakdown=1 Only Breakdown for High Grade and Bene Feed.
		--IF @iLumpFinesBreakdown= 0 then only show TOTAL
		If (@iIncludeLumpFinesBreakdown = 0)
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


		SELECT 'Tonnes' AS TonnesGradesTag, Type AS ModelTag, Material, ProductSize, Tonnes AS Value
		FROM @Tonnes
		UNION ALL
		SELECT g.GradeName, g.Type, g.Material, t.ProductSize, g.GradeValue
		FROM @Grade AS g
			INNER JOIN @Tonnes AS t
				ON (t.Type = g.Type
					AND t.CalendarDate = g.CalendarDate
					AND t.Material = g.Material
					AND t.ProductSize = g.ProductSize)

		-- create the graph data
		DELETE FROM @Tonnes
		DELETE FROM @Grade

		INSERT INTO @Tonnes
		(
			Type, BlockModelId, CalendarDate, Material, MaterialTypeId, ProductSize, Tonnes, Volume
		)
		EXEC dbo.GetBhpbioReportBaseDataAsTonnes
			@iDateFrom = @iDateFrom,
			@iDateTo = @iDateTo,
			@iDateBreakdown = @iDateBreakdown,
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
			@iDateBreakdown = @iDateBreakdown,
			@iLocationId = @iLocationId,
			@iIncludeBlockModels = @iIncludeBlockModels,
			@iBlockModels = @iBlockModels,
			@iIncludeActuals = @iIncludeActuals,
			@iMaterialCategoryId = 'Designation',
			@iRootMaterialTypeId = @iDesignationMaterialTypeId,
			@iGrades = @iGrades,
			@iIncludeLiveData = @iIncludeLiveData,
			@iIncludeApprovedData = @iIncludeApprovedData

		--@iLumpFinesBreakdown
		--IF @iLumpFinesBreakdown=1 Only Breakdown for High Grade and Bene Feed.
		--IF @iLumpFinesBreakdown= 0 then only show TOTAL
		If (@iIncludeLumpFinesBreakdown = 0)
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

		SELECT CalendarDate, TonnesGradesTag, ModelTag, Material, ProductSize, Value
		FROM
		(
			SELECT CalendarDate, 'Tonnes' AS TonnesGradesTag, Type AS ModelTag, Material, ProductSize, Tonnes AS Value
			FROM @Tonnes
			UNION ALL
			SELECT CalendarDate, GradeName, Type, Material, ProductSize, GradeValue
			FROM @Grade
		) AS results
		ORDER BY CalendarDate Asc

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

GRANT EXECUTE ON dbo.GetBhpbioModelComparisonReport TO BhpbioGenericManager
GO

/*
testing

EXEC dbo.GetBhpbioModelComparisonReport
	@iDateFrom = '01-APR-2009',
	@iDateTo = '30-JUN-2009',
	@iDateBreakdown = 'MONTH',
	@iLocationId = 1,
	@iIncludeBlockModels = 1,
	@iBlockModels = '<BlockModels><BlockModel id="1"></BlockModel><BlockModel id="2"></BlockModel><BlockModel id="3"></BlockModel></BlockModels>',
	@iIncludeActuals = 1,
	@iDesignationMaterialTypeId = NULL,
	@iTonnes = 1,
	@iGrades = '<Grades><Grade id="1"/><Grade id="2"/><Grade id="3"/><Grade id="4"/><Grade id="5"/></Grades>',
	@iIncludeLiveData = 1,
	@iIncludeApprovedData = 0,
	@iIncludeLumpFinesBreakdown = 0

*/
