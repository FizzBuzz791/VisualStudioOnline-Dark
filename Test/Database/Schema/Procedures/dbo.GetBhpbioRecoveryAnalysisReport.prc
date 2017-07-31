IF Object_Id('dbo.GetBhpbioRecoveryAnalysisReport') IS NOT NULL
	DROP PROCEDURE dbo.GetBhpbioRecoveryAnalysisReport
GO

CREATE PROCEDURE dbo.GetBhpbioRecoveryAnalysisReport
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iIncludeBlockModels BIT,
	@iBlockModels XML,
	@iIncludeActuals BIT,
	@iDesignationMaterialTypeId INT,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT
)
AS
BEGIN

	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @Tonnes TABLE
	(
		MaterialCategory VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		Type VARCHAR(255) COLLATE DATABASE_DEFAULT NOT NULL,
		CalendarDate DATETIME NOT NULL,
		Material VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
		ProductSize VARCHAR(5) NOT NULL,
		Tonnes FLOAT,
		PRIMARY KEY CLUSTERED (CalendarDate, Material, Type, MaterialCategory, ProductSize)
	)

	DECLARE @TempTonnes TABLE
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

	SET NOCOUNT ON

	SELECT @TransactionName = 'GetBhpbioRecoveryAnalysisReport',
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
		-- load DESIGNATION
		INSERT INTO @TempTonnes
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

		INSERT INTO @Tonnes
		(
			MaterialCategory, Type, CalendarDate, Material, ProductSize, Tonnes
		)
		SELECT 'Designation', Type, CalendarDate, Material, ProductSize, Tonnes
		FROM @TempTonnes


		DELETE
		FROM @TempTonnes


		-- load CLASSIFICATION
		INSERT INTO @TempTonnes
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
			@iMaterialCategoryId = 'Classification',
			@iRootMaterialTypeId = NULL,
			@iIncludeLiveData = @iIncludeLiveData,
			@iIncludeApprovedData = @iIncludeApprovedData

		INSERT INTO @Tonnes
		(
			MaterialCategory, Type, CalendarDate, Material, ProductSize, Tonnes
		)
		SELECT 'Classification', Type, CalendarDate, Material, ProductSize, Tonnes
		FROM @TempTonnes

		DELETE
		FROM @TempTonnes


		-- create the summary table

		-- generate the DIFFERENCES (RECOVERY) DATA
		-- this shows comparisons between all permutations
		-- this may need to be filtered out somewhere at some point!
		SELECT t1.Type + ' - ' + t2.Type AS ComparisonType, t1.MaterialCategory, t1.Material, t1.ProductSize,
			SUM(t1.Tonnes) / NULLIF(SUM(t2.Tonnes), 0.0) AS RecoveryPercent
		FROM @Tonnes AS t1
			INNER JOIN @Tonnes AS t2
				ON (t1.CalendarDate = t2.CalendarDate
					AND t1.Material = t2.Material
					AND t1.MaterialCategory = t2.MaterialCategory
					AND t1.ProductSize = t2.ProductSize				
					AND t1.Type <> t2.Type)
		WHERE (t1.Type = 'Mining' AND t2.Type = 'Geology')
			OR (t1.Type = 'Grade Control' AND t2.Type = 'Mining')
			OR (t1.Type = 'Actual' AND t2.Type = 'Mining')
			OR (t1.Type = 'Actual' AND t2.Type = 'Grade Control')
			OR (t1.Type = 'Grade Control' AND t2.Type = 'Short Term Geology')
		GROUP BY t1.Type, t2.Type, t1.Material, t1.MaterialCategory, t1.ProductSize

		-- supply the GRAPH data
		-- this is supposed to show recovery data but it doesn't make sense

		SELECT t1.Type + ' - ' + t2.Type AS ComparisonType, t1.Material AS Designation, t1.CalendarDate,t1.ProductSize,
			SUM(t1.Tonnes) / NULLIF(SUM(t2.Tonnes), 0.0) AS RecoveryPercent
		FROM @Tonnes AS t1
			INNER JOIN @Tonnes AS t2
				ON (t1.CalendarDate = t2.CalendarDate
					AND t1.Material = t2.Material
					AND t1.MaterialCategory = t2.MaterialCategory
					AND t1.ProductSize = t2.ProductSize
					AND t1.Type <> t2.Type)
		WHERE t1.MaterialCategory = 'Designation'
			AND
			(
				(t1.Type = 'Mining' AND t2.Type = 'Geology')
				OR (t1.Type = 'Grade Control' AND t2.Type = 'Mining')
				OR (t1.Type = 'Actual' AND t2.Type = 'Mining')
				OR (t1.Type = 'Actual' AND t2.Type = 'Grade Control')
				OR (t1.Type = 'Grade Control' AND t2.Type = 'Short Term Geology')
			)
		GROUP BY t1.Type, t2.Type, t1.Material, t1.CalendarDate, t1.ProductSize
			
				
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

GRANT EXECUTE ON dbo.GetBhpbioRecoveryAnalysisReport TO BhpbioGenericManager
GO

/*
testing

EXEC dbo.GetBhpbioRecoveryAnalysisReport
	@iDateFrom = '01-APR-2009',
	@iDateTo = '30-JUN-2009',
	@iDateBreakdown = 'MONTH',
	@iLocationId = 1,
	@iIncludeBlockModels = 1,
	@iBlockModels = '<BlockModels><BlockModel id="1"></BlockModel><BlockModel id="2"></BlockModel><BlockModel id="3"></BlockModel><BlockModel id="4"></BlockModel></BlockModels>',
	@iIncludeActuals = 1,
	@iDesignationMaterialTypeId = NULL,
	@iIncludeLiveData = 1,
	@iIncludeApprovedData =0
	
*/
