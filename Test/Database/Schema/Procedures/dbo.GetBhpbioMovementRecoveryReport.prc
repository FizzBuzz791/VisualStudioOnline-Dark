IF Object_Id('dbo.GetBhpbioMovementRecoveryReport') IS NOT NULL
	DROP PROCEDURE dbo.GetBhpbioMovementRecoveryReport
GO

CREATE PROCEDURE dbo.GetBhpbioMovementRecoveryReport
(
	@iDateTo DATETIME,
	@iLocationId INT,
	@iComparison1IsActual BIT,
	@iComparison1BlockModelId INT,
	@iComparison2IsActual BIT,
	@iComparison2BlockModelId INT,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT
)
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @BlockModels XML
	DECLARE @IncludeActuals BIT
	DECLARE @IncludeBlockModels BIT

	DECLARE @Comparison TINYINT
	DECLARE @MaterialCategory VARCHAR(31)
	DECLARE @RollingPeriod TINYINT
	DECLARE @DateFrom DATETIME

	DECLARE @Tonnes TABLE
	(
		Compare1Or2 TINYINT NOT NULL,
		RollingPeriod TINYINT NOT NULL,
		MaterialCategory VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		CalendarDate DATETIME NOT NULL,
		Material VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialTypeId INT,
		ProductSize VARCHAR(5) NOT NULL,
		Tonnes FLOAT,
		PRIMARY KEY CLUSTERED (CalendarDate, Material, Compare1Or2, RollingPeriod, MaterialCategory, ProductSize)
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

	DECLARE @Material TABLE
	(
		MaterialCategory VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		Material VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialClassificationOrder VARCHAR(31) COLLATE DATABASE_DEFAULT,
		PRIMARY KEY CLUSTERED (MaterialCategory, Material)
	)

	SET NOCOUNT ON

	SELECT @TransactionName = 'GetBhpbioMovementRecoveryReport',
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
		-- loop on:
		-- Comparison1, Comparison2
		-- Designation, Classification
		-- 12 Month, 3 Month

		-- loop on Comparison1, Comparison2
		SET @Comparison = 1
		WHILE @Comparison IN (1, 2)
		BEGIN
			IF (@Comparison = 1 AND @iComparison1IsActual = 1)
				OR (@Comparison = 2 AND @iComparison2IsActual = 1)
			BEGIN	
				SET @IncludeActuals = 1
				SET @IncludeBlockModels = 0
			END
			ELSE
			BEGIN
				SET @IncludeActuals = 0
				SET @IncludeBlockModels = 1
			END

			SET @BlockModels =
				(
					SELECT [@id]
					FROM
						(
							SELECT @iComparison1BlockModelId AS [@id]
							WHERE @iComparison1IsActual = 0
								AND @Comparison = 1
							UNION ALL
							SELECT @iComparison2BlockModelId AS [@id]
							WHERE @iComparison2IsActual = 0
								AND @Comparison = 2
						) AS sub
					FOR XML PATH ('BlockModel'), ELEMENTS, ROOT('BlockModels')
				)

			-- loop on Designation, Classification
			SET @MaterialCategory = 'Designation'
			WHILE @MaterialCategory IS NOT NULL
			BEGIN
				-- loop on 12 Month, 3 Month
				SET @RollingPeriod = 12
				WHILE @RollingPeriod IN (12, 3)
				BEGIN
					SET @DateFrom =
						(
							CASE @RollingPeriod
								WHEN 3 THEN DateAdd(Month, -3, (@iDateTo + 1))
								WHEN 12 THEN DateAdd(Month, -12, (@iDateTo + 1))
								ELSE NULL
							END
						)

					INSERT INTO @TempTonnes
					(
						Type, BlockModelId, CalendarDate, Material, MaterialTypeId, ProductSize, Tonnes, Volume
					)
					EXEC dbo.GetBhpbioReportBaseDataAsTonnes
						@iDateFrom = @DateFrom,
						@iDateTo = @iDateTo,
						@iDateBreakdown = NULL,
						@iLocationId = @iLocationId,
						@iIncludeBlockModels = @IncludeBlockModels,
						@iBlockModels = @BlockModels,
						@iIncludeActuals = @IncludeActuals,
						@iMaterialCategoryId = @MaterialCategory,
						@iRootMaterialTypeId = NULL,
						@iIncludeLiveData = @iIncludeLiveData,
						@iIncludeApprovedData = @iIncludeApprovedData

					INSERT INTO @Tonnes
					(
						Compare1Or2, RollingPeriod, MaterialCategory, CalendarDate, Material, MaterialTypeId, ProductSize, Tonnes
					)
					SELECT @Comparison, @RollingPeriod, @MaterialCategory, CalendarDate, Material, MaterialTypeId, ProductSize, Sum(Tonnes)
					FROM @TempTonnes
					Group By CalendarDate, Material, MaterialTypeId, ProductSize

					DELETE
					FROM @TempTonnes

					-- load the next rolling period
					SET @RollingPeriod =
						(
							SELECT
								CASE @RollingPeriod
									WHEN 12 THEN 3
									WHEN 3 THEN NULL
									ELSE NULL
								END
						)
				END

				-- load the next material category
				SET @MaterialCategory = 
					(
						SELECT
							CASE @MaterialCategory
								WHEN 'Designation' THEN 'Classification'
								WHEN 'Classification' THEN NULL
								ELSE NULL
							END
					)
			END
					
			-- load the next comparison
			SET @Comparison = @Comparison + 1
		END

		-- load materials
		INSERT INTO @Material
		(MaterialCategory, Material, MaterialClassificationOrder)
		SELECT DISTINCT MaterialCategory, Material, MT.Order_No
		FROM @Tonnes T
			INNER JOIN dbo.MaterialType MT
				ON dbo.GetMaterialCategoryMaterialType(T.MaterialTypeId, 'Classification') = MT.Material_Type_Id

		-- create the summary table
		SELECT rp.RollingPeriod, c.Compare1Or2, sub.MaterialCategory, sub.Material, sub.MaterialClassificationOrder, sub.ProductSize, sub.Tonnes
		FROM
			(
				SELECT 3 AS RollingPeriod
				UNION ALL
				SELECT 12
			) AS rp
			CROSS JOIN
			(
				SELECT 1 AS Compare1Or2
				UNION ALL
				SELECT 2
				UNION ALL
				SELECT 3  -- this is the total line
			) AS c
			LEFT OUTER JOIN
			(
				-- return the underlying data
				SELECT t.RollingPeriod, t.Compare1Or2, t.MaterialCategory, t.Material, MC.MaterialClassificationOrder, t.ProductSize,
					SUM(Tonnes) AS Tonnes
				FROM @Tonnes t
					INNER JOIN @Material AS mc
						ON (mc.MaterialCategory = t.MaterialCategory
							AND MC.Material = t.Material)
				GROUP BY t.RollingPeriod, t.Compare1Or2, t.MaterialCategory, t.Material, MC.MaterialClassificationOrder, t.ProductSize

				UNION ALL

				-- return the total movement line
				SELECT t.RollingPeriod, t.Compare1Or2, 'Total Movement', NULL, MAX(MC.MaterialClassificationOrder) + 1, t.ProductSize,
					SUM(t.Tonnes) AS Tonnes
				FROM @Tonnes AS t
					INNER JOIN @Material AS mc
						ON (mc.MaterialCategory = t.MaterialCategory
							AND mc.Material = t.Material)
				WHERE t.MaterialCategory = 'Classification'
				GROUP BY t.RollingPeriod, t.Compare1Or2, t.ProductSize

				UNION ALL

				-- return the % variance line
				SELECT COALESCE(t1.RollingPeriod, t2.RollingPeriod),
					3, mc.MaterialCategory, mc.Material AS Material, MC.MaterialClassificationOrder, t1.ProductSize, 
					CASE
						WHEN SUM(t2.Tonnes) <> 0 AND SUM(t1.Tonnes) <> 0
							THEN SUM(t1.Tonnes) / SUM(t2.Tonnes)
						ELSE NULL
					END AS Tonnes
				FROM @Material AS mc
					LEFT JOIN @Tonnes AS t1
						ON (mc.MaterialCategory = t1.MaterialCategory
							AND mc.Material = t1.Material
							AND t1.Compare1Or2 = 1)
					LEFT JOIN @Tonnes AS t2
						ON (mc.MaterialCategory = t2.MaterialCategory
							AND mc.Material = t2.Material
							AND t2.Compare1Or2 = 2
							AND t1.RollingPeriod = t2.RollingPeriod
							AND t1.ProductSize = t2.ProductSize)
				WHERE (t2.CalendarDate = t1.CalendarDate
						OR t1.CalendarDate Is Null
						OR t2.CalendarDate Is Null)
				GROUP BY COALESCE(t1.RollingPeriod, t2.RollingPeriod),
					mc.MaterialCategory, mc.Material, mc.MaterialClassificationOrder, t1.ProductSize

				UNION ALL

				SELECT COALESCE(t1.RollingPeriod, t2.RollingPeriod),
					3, 'Total Movement', NULL AS Material, Max(mc.MaterialClassificationOrder) + 1, t1.ProductSize,
					CASE
						WHEN SUM(t2.Tonnes) <> 0 AND SUM(t1.Tonnes) <> 0
							THEN SUM(t1.Tonnes) / Sum(t2.Tonnes)
						ELSE NULL
					END AS Tonnes
				FROM @Material AS mc
					LEFT JOIN @Tonnes AS t1
						ON (mc.MaterialCategory = t1.MaterialCategory
							AND MC.Material = t1.Material
							AND t1.Compare1Or2 = 1)
					LEFT JOIN @Tonnes AS t2
						ON (mc.MaterialCategory = t2.MaterialCategory
							AND mc.Material = t2.Material
							AND t2.Compare1Or2 = 2
							AND t2.RollingPeriod = t1.RollingPeriod
							AND t2.ProductSize = t1.ProductSize)
				WHERE (t2.CalendarDate = t1.CalendarDate
						Or t1.CalendarDate Is Null
						Or t2.CalendarDate Is Null)
					AND mc.MaterialCategory = 'Classification'
				GROUP BY COALESCE(t1.RollingPeriod, t2.RollingPeriod), t1.ProductSize
			) AS sub
			ON (rp.RollingPeriod = sub.RollingPeriod
				AND c.Compare1Or2 = sub.Compare1Or2)
		ORDER BY rp.RollingPeriod, c.Compare1Or2,
			CASE MaterialCategory
				WHEN 'Designation' THEN 1
				WHEN 'Classification' THEN 2
				ELSE 3 END,
			Material

		-- create the graph data
		SELECT rp.RollingPeriod, sub.MaterialCategory, sub.Material, sub.MaterialClassificationOrder, sub.ProductSize, sub.Tonnes
		FROM
			(
				SELECT 3 AS RollingPeriod
				UNION ALL
				SELECT 12
			) AS rp
			LEFT OUTER JOIN
			(
				SELECT COALESCE(t1.RollingPeriod, t2.RollingPeriod) AS RollingPeriod,
					mc.MaterialCategory, mc.Material AS Material, mc.MaterialClassificationOrder, t1.ProductSize, 
					CASE
						WHEN SUM(t2.Tonnes) <> 0 AND SUM(t1.Tonnes) <> 0
							THEN SUM(t1.Tonnes) / Sum(t2.Tonnes)
						ELSE NULL
					END AS Tonnes
				FROM @Material AS mc
					LEFT JOIN @Tonnes AS t1
						ON (mc.MaterialCategory = t1.MaterialCategory
							AND mc.Material = t1.Material
							AND t1.Compare1Or2 = 1)
					LEFT JOIN @Tonnes AS t2
						ON (mc.MaterialCategory = t2.MaterialCategory
							AND mc.Material = t2.Material
							AND t2.Compare1Or2 = 2
							AND t2.RollingPeriod = t1.RollingPeriod
							AND t2.ProductSize = t1.ProductSize)
					WHERE (t2.CalendarDate = t1.CalendarDate
						OR t1.CalendarDate Is Null
						OR t2.CalendarDate Is Null)
				GROUP BY COALESCE(t1.RollingPeriod, t2.RollingPeriod),
					mc.MaterialCategory, mc.Material, mc.MaterialClassificationOrder, t1.ProductSize

				UNION ALL

				SELECT COALESCE(t1.RollingPeriod, t2.RollingPeriod) AS RollingPeriod,
					'Total Movement', NULL AS Material, MAX(MC.MaterialClassificationOrder) + 1, t1.ProductSize, 
					CASE
						WHEN SUM(t2.Tonnes) <> 0 AND SUM(t1.Tonnes) <> 0
							THEN SUM(t1.Tonnes) / Sum(t2.Tonnes)
						ELSE NULL
					END AS Tonnes
				FROM @Material AS mc
					LEFT JOIN @Tonnes AS t1
						ON (mc.MaterialCategory = t1.MaterialCategory
							AND mc.Material = t1.Material
							AND t1.Compare1Or2 = 1)
					LEFT JOIN @Tonnes AS t2
						ON (mc.MaterialCategory = t2.MaterialCategory
							AND mc.Material = t2.Material
							AND t2.Compare1Or2 = 2
							AND t2.RollingPeriod = t1.RollingPeriod
							AND t2.ProductSize = t1.ProductSize)
					WHERE (t2.CalendarDate = t1.CalendarDate
						Or t1.CalendarDate Is Null
						Or t2.CalendarDate Is Null)
					AND mc.MaterialCategory = 'Classification'
				GROUP BY COALESCE(t1.RollingPeriod, t2.RollingPeriod), t1.ProductSize
			) AS sub
			ON (sub.RollingPeriod = rp.RollingPeriod)

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

GRANT EXECUTE ON dbo.GetBhpbioMovementRecoveryReport TO BhpbioGenericManager
GO

/* testing
EXEC dbo.GetBhpbioMovementRecoveryReport
	@iDateTo = '30-JUN-2009',
	@iLocationId = 1,
	@iComparison1IsActual = 0,
	@iComparison1BlockModelId = 1,
	@iComparison2IsActual = 0,
	@iComparison2BlockModelId = 2,
	@iIncludeLiveData = 0,
	@iIncludeApprovedData = 1
*/
