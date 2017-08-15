IF OBJECT_ID('dbo.GetBhpbioReportDataReview') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportDataReview
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReportDataReview 
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iLocationId INT,
	@iTagId VARCHAR(63),
	@iProductSize VARCHAR(5) = NULL
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	DECLARE @PostCrusherStockpileGroupId VARCHAR(31)
	SET @PostCrusherStockpileGroupId = 'Post Crusher'
	DECLARE @MaterialCategory VARCHAR(31)
	SET @MaterialCategory = 'Designation'
	
	DECLARE @HubLocationTypeId INT
	DECLARE @SiteLocationTypeId INT
	
	DECLARE @minimumSignificantTonnes INTEGER

	DECLARE @StockpileDeltaHub TABLE
	(
		StockpileId INT NOT NULL,
		WeightometerSampleId INT NOT NULL,
		ProductSize VARCHAR(5) NOT NULL,
		ProductPercent DECIMAL(5,4) NOT NULL,
		DefaultProductSize BIT NOT NULL,
		Tonnes FLOAT NOT NULL,
		LocationId INT NULL,
		Addition BIT NOT NULL,
		Hub VARCHAR(31) COLLATE DATABASE_DEFAULT
	)
	
	DECLARE @StockpileDeltaSite TABLE
	(
		StockpileId INT NOT NULL,
		WeightometerSampleId INT NOT NULL,
		ProductSize VARCHAR(5) NOT NULL,
		ProductPercent DECIMAL(5,4) NOT NULL,
		DefaultProductSize BIT NOT NULL,
		Tonnes FLOAT NOT NULL,
		LocationId INT NULL,
		Addition BIT NOT NULL,
		Site VARCHAR(31) COLLATE DATABASE_DEFAULT
	)
				
	DECLARE @StockpileGroupId VARCHAR(31)
	DECLARE @HighGradeMaterialTypeId INT
	DECLARE @BeneFeedMaterialTypeId INT
	DECLARE @SampleTonnesField VARCHAR(31)
	DECLARE @SampleSourceField VARCHAR(31)
	DECLARE @ProductSizeField VARCHAR(31)
	DECLARE @SampleCountField VARCHAR(31)

	SET @SampleTonnesField = 'SampleTonnes'
	SET @SampleSourceField = 'SampleSource'
	SET @ProductSizeField = 'ProductSize'
	SET @SampleCountField = 'SampleCount'
	
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		ParentLocationId INT NULL,
		IncludeStart DATETIME,
		IncludeEnd DATETIME,
		PRIMARY KEY (LocationId,IncludeStart,IncludeEnd)
	)
	
	DECLARE @HighGradeStockpileGroup TABLE
	(
		StockpileGroupId VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialTypeId INT NOT NULL,
		PRIMARY KEY (StockpileGroupId)
	)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioReportDataReview',
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
		
		SET @HighGradeMaterialTypeId =
			(
				SELECT Material_Type_Id
				FROM dbo.MaterialType
				WHERE Abbreviation = 'High Grade'
					AND Material_Category_Id = 'Designation'
			)

		SET @BeneFeedMaterialTypeId = 
			(
				SELECT Material_Type_Id
				FROM dbo.MaterialType
				WHERE Abbreviation = 'Bene Feed'
					AND Material_Category_Id = 'Designation'
			)

		INSERT INTO @HighGradeStockpileGroup
			(StockpileGroupId, MaterialTypeId)
		SELECT SGD.StockpileGroupId, MT.Material_Type_Id
		FROM dbo.MaterialType AS MT
			INNER JOIN dbo.BhpbioStockpileGroupDesignation AS SGD
				ON (MT.Material_Type_Id = SGD.MaterialTypeId)
		WHERE MT.Material_Category_Id = @MaterialCategory
			AND MT.Material_Type_Id IN (Select MaterialTypeId FROM dbo.GetBhpbioReportHighGrade())
		
		-- we need to get the factor name for the Mining Model H2O. When it is part of F2.5 then it should
		-- return the As-Dropped H2O, when part of F3, then it should return As-Shipped. In all other cases (ie F1)
		-- just the regular H2O
		--
		-- Some other calulations use this as well - for example the stockpile deltas do no have valid H2O values at the
		-- F3 level
		--
		-- See WREC-254 for more details.
		DECLARE @FactorName VARCHAR(16)
		SET @FactorName = CASE 
			WHEN @iTagId Like 'F15%' THEN 'F15'
			WHEN @iTagId Like 'F25%' THEN 'F25'
			WHEN @iTagId Like 'F1%' THEN 'F1'
			WHEN @iTagId Like 'F2%' THEN 'F2'
			WHEN @iTagId Like 'F3%' THEN 'F3'
			ELSE NULL
		END

		IF @iTagId LIKE '%MODEL' OR @iTagId LIKE '%STGM'
		BEGIN
			DECLARE @DefaultGeometType varchar(64) = 'As-Shipped'

			-- need these constansts to make sure that the Grade Control STGM data is pulled
			-- back correctly
			DECLARE @GradeControlModelId INT
			DECLARE @GradeControlSTGMModelId INT
			
			SELECT @GradeControlModelId = Block_Model_Id FROM BlockModel WHERE Name = 'Grade Control'
			SELECT @GradeControlSTGMModelId = Block_Model_Id FROM BlockModel WHERE Name = 'Grade Control STGM'
			
			DECLARE @BlockModelId INT
			
			SELECT @BlockModelId = Block_Model_Id
			FROM BlockModel
			WHERE 1 =
				CASE WHEN @iTagId Like '%ShortTermGeologyModel%' AND Name <> 'Short Term Geology' THEN 0 
					 WHEN @iTagId Like '%GeologyModel%' AND @iTagId Not Like '%ShortTermGeologyModel%' AND Name <> 'Geology' THEN 0
					 WHEN @iTagId Like '%MiningModel%' AND Name <> 'Mining' THEN 0
					 WHEN @iTagId Like '%GradeControlModel%' AND Name <> 'Grade Control' THEN 0
					 WHEN @iTagId Like '%GradeControlSTGM%' AND Name <> 'Grade Control STGM' THEN 0
					 ELSE 1 
				END
			
			SELECT 
				CASE WHEN @BlockModelId = @GradeControlSTGMModelId THEN BM.Name + ' STGM' ELSE BM.Name END as Name,
				RM.DateFrom, RM.DateTo, MT.Description As MaterialType, MinedPercentage,
				defaultlf.ProductSize As ProductSize, 
				CASE WHEN blocklf.[LumpPercent] IS NULL THEN 1 ELSE 0 END As DefaultProductSize,
				ISNULL(
					CASE 
						WHEN defaultlf.ProductSize = 'LUMP' THEN blocklf.[LumpPercent] 
						WHEN defaultlf.ProductSize = 'FINES' THEN 1 - blocklf.[LumpPercent] 
						ELSE NULL END, 
					defaultlf.[Percent])
				* MBP.Tonnes As BlockTonnes,
				ISNULL(
					CASE 
						WHEN defaultlf.ProductSize = 'LUMP' THEN blocklf.[LumpPercent] 
						WHEN defaultlf.ProductSize = 'FINES' THEN 1 - blocklf.[LumpPercent] 
						ELSE NULL END, 
					defaultlf.[Percent])
				* MBP.Tonnes * MinedPercentage As TonnesMoved, 
				CASE 
					WHEN defaultlf.ProductSize = 'LUMP' THEN ISNULL(Fe_LF.LumpValue, Fe.Grade_Value)
					WHEN defaultlf.ProductSize = 'FINES' THEN ISNULL(Fe_LF.FinesValue, Fe.Grade_Value)
					ELSE Fe.Grade_Value 
				END As Fe, 
				CASE 
					WHEN defaultlf.ProductSize = 'LUMP' THEN ISNULL(P_LF.LumpValue, P.Grade_Value)
					WHEN defaultlf.ProductSize = 'FINES' THEN ISNULL(P_LF.FinesValue, P.Grade_Value)
					ELSE P.Grade_Value 
				END As P, 
				CASE 
					WHEN defaultlf.ProductSize = 'LUMP' THEN ISNULL(SiO2_LF.LumpValue, SiO2.Grade_Value)
					WHEN defaultlf.ProductSize = 'FINES' THEN ISNULL(SiO2_LF.FinesValue, SiO2.Grade_Value)
					ELSE SiO2.Grade_Value 
				END As SiO2, 
				CASE 
					WHEN defaultlf.ProductSize = 'LUMP' THEN ISNULL(Al2O3_LF.LumpValue, Al2O3.Grade_Value)
					WHEN defaultlf.ProductSize = 'FINES' THEN ISNULL(Al2O3_LF.FinesValue, Al2O3.Grade_Value)
					ELSE Al2O3.Grade_Value 
				END As Al2O3, 
				CASE 
					WHEN defaultlf.ProductSize = 'LUMP' THEN ISNULL(LOI_LF.LumpValue, LOI.Grade_Value)
					WHEN defaultlf.ProductSize = 'FINES' THEN ISNULL(LOI_LF.FinesValue, LOI.Grade_Value)
					ELSE LOI.Grade_Value 
				END As LOI,
				
				CASE WHEN @iTagId Like '%MiningModel%' AND @FactorName = 'F25' THEN
					(CASE
						WHEN defaultlf.ProductSize = 'LUMP' THEN ISNULL(H2ODropped_LF.LumpValue, H2ODropped.Grade_Value)
						WHEN defaultlf.ProductSize = 'FINES' THEN ISNULL(H2ODropped_LF.FinesValue, H2ODropped.Grade_Value)
						ELSE H2ODropped.Grade_Value 
					END)
				WHEN @iTagId Like '%MiningModel%' AND @FactorName = 'F3' THEN
					(CASE
						WHEN defaultlf.ProductSize = 'LUMP' THEN ISNULL(H2OShipped_LF.LumpValue, H2OShipped.Grade_Value)
						WHEN defaultlf.ProductSize = 'FINES' THEN ISNULL(H2OShipped_LF.FinesValue, H2OShipped.Grade_Value)
						ELSE H2OShipped.Grade_Value
					END)
				ELSE
					(CASE
						WHEN defaultlf.ProductSize = 'LUMP' THEN ISNULL(H2O_LF.LumpValue, H2O.Grade_Value)
						WHEN defaultlf.ProductSize = 'FINES' THEN ISNULL(H2O_LF.FinesValue, H2O.Grade_Value)
						ELSE H2O.Grade_Value
					END)
				END As H2O,
				RM.BlockNumber, RM.BlockName, RM.Site, RM.OreBody, RM.Pit, RM.Bench, RM.PatternNumber
			FROM dbo.GetBhpbioReportReconBlockLocations(@iLocationId, @iDateFrom, @iDateTo, 0) AS RM
				INNER JOIN [dbo].[GetBhpbioReportModelBlockLocations](@BlockModelId) AS MBL
					ON (RM.BlockLocationId = MBL.Location_Id)
				INNER JOIN dbo.ModelBlock AS MB
					ON (MBL.Model_Block_Id = MB.Model_Block_Id)
				INNER JOIN dbo.BlockModel AS BM
					ON (BM.Block_Model_Id = MB.Block_Model_Id)
				INNER JOIN dbo.ModelBlockPartial AS MBP
					ON (MB.Model_Block_Id = MBP.Model_Block_Id)
				INNER JOIN dbo.GetMaterialsByCategory('Designation') AS MC
					ON (MC.MaterialTypeId = MBP.Material_Type_Id)
				INNER JOIN dbo.MaterialType AS MT
					ON (MC.RootMaterialTypeId = MT.Material_Type_Id)
				INNER JOIN dbo.GetBhpbioReportHighGrade() AS BRHG
					ON (BRHG.MaterialTypeId = MT.Material_Type_Id)
				INNER JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf
					ON RM.PitLocationId = defaultlf.LocationId
					AND RM.DateFrom BETWEEN defaultlf.StartDate AND defaultlf.EndDate
				LEFT JOIN dbo.BhpbioBlastBlockLumpPercent blocklf
					ON MBP.Model_Block_Id = blocklf.ModelBlockId
					AND MBP.Sequence_No = blocklf.SequenceNo
					AND blocklf.GeometType = @DefaultGeometType
				-- grade data
				LEFT JOIN dbo.ModelBlockPartialGrade AS FE
					ON (FE.Grade_Id = 1 AND FE.Model_Block_Id = MBP.Model_Block_Id AND FE.Sequence_No = MBP.Sequence_No)
				LEFT JOIN dbo.ModelBlockPartialGrade AS P
					ON (P.Grade_Id = 2 AND P.Model_Block_Id = MBP.Model_Block_Id AND P.Sequence_No = MBP.Sequence_No)
				LEFT JOIN dbo.ModelBlockPartialGrade AS SiO2
					ON (SiO2.Grade_Id = 3 AND SiO2.Model_Block_Id = MBP.Model_Block_Id AND SiO2.Sequence_No = MBP.Sequence_No)
				LEFT JOIN dbo.ModelBlockPartialGrade AS Al2O3
					ON (Al2O3.Grade_Id = 4 AND Al2O3.Model_Block_Id = MBP.Model_Block_Id AND Al2O3.Sequence_No = MBP.Sequence_No)
				LEFT JOIN dbo.ModelBlockPartialGrade AS LOI
					ON (LOI.Grade_Id = 5 AND LOI.Model_Block_Id = MBP.Model_Block_Id AND LOI.Sequence_No = MBP.Sequence_No)
				LEFT JOIN dbo.ModelBlockPartialGrade AS H2O
					ON (H2O.Grade_Id = 7 AND H2O.Model_Block_Id = MBP.Model_Block_Id AND H2O.Sequence_No = MBP.Sequence_No)
				LEFT JOIN dbo.ModelBlockPartialGrade AS H2ODropped
					ON (H2ODropped.Grade_Id = 8 AND H2ODropped.Model_Block_Id = MBP.Model_Block_Id AND H2ODropped.Sequence_No = MBP.Sequence_No)
				LEFT JOIN dbo.ModelBlockPartialGrade AS H2OShipped
					ON (H2OShipped.Grade_Id = 9 AND H2OShipped.Model_Block_Id = MBP.Model_Block_Id AND H2OShipped.Sequence_No = MBP.Sequence_No)
				
				-- lump/fine grade data
				LEFT JOIN BhpbioBlastBlockLumpFinesGrade AS FE_LF
					ON (FE_LF.GradeId = 1 AND FE_LF.ModelBlockId = MBP.Model_Block_Id AND FE_LF.SequenceNo = MBP.Sequence_No AND FE_LF.GeometType = @DefaultGeometType)
				LEFT JOIN BhpbioBlastBlockLumpFinesGrade AS P_LF
					ON (P_LF.GradeId = 2 AND P_LF.ModelBlockId = MBP.Model_Block_Id AND P_LF.SequenceNo = MBP.Sequence_No AND P_LF.GeometType = @DefaultGeometType)
				LEFT JOIN BhpbioBlastBlockLumpFinesGrade AS SiO2_LF
					ON (SiO2_LF.GradeId = 3 AND SiO2_LF.ModelBlockId = MBP.Model_Block_Id AND SiO2_LF.SequenceNo = MBP.Sequence_No AND SiO2_LF.GeometType = @DefaultGeometType)
				LEFT JOIN BhpbioBlastBlockLumpFinesGrade AS Al2O3_LF
					ON (Al2O3_LF.GradeId = 4 AND Al2O3_LF.ModelBlockId = MBP.Model_Block_Id AND Al2O3_LF.SequenceNo = MBP.Sequence_No AND Al2O3_LF.GeometType = @DefaultGeometType)
				LEFT JOIN BhpbioBlastBlockLumpFinesGrade AS LOI_LF
					ON (LOI_LF.GradeId = 5 AND LOI_LF.ModelBlockId = MBP.Model_Block_Id AND LOI_LF.SequenceNo = MBP.Sequence_No AND LOI_LF.GeometType = @DefaultGeometType)
				LEFT JOIN BhpbioBlastBlockLumpFinesGrade AS H2O_LF
					ON (H2O_LF.GradeId = 7 AND H2O_LF.ModelBlockId = MBP.Model_Block_Id AND H2O_LF.SequenceNo = MBP.Sequence_No AND H2O_LF.GeometType = @DefaultGeometType)
				LEFT JOIN BhpbioBlastBlockLumpFinesGrade AS H2ODropped_LF
					ON (H2ODropped_LF.GradeId = 8 AND H2ODropped_LF.ModelBlockId = MBP.Model_Block_Id AND H2ODropped_LF.SequenceNo = MBP.Sequence_No AND H2ODropped_LF.GeometType = @DefaultGeometType)
				LEFT JOIN BhpbioBlastBlockLumpFinesGrade AS H2OShipped_LF
					ON (H2OShipped_LF.GradeId = 9 AND H2OShipped_LF.ModelBlockId = MBP.Model_Block_Id AND H2OShipped_LF.SequenceNo = MBP.Sequence_No AND H2OShipped_LF.GeometType = @DefaultGeometType)
					
			WHERE BM.Block_Model_Id = (CASE WHEN @BlockModelId = @GradeControlSTGMModelId THEN @GradeControlModelId ELSE @BlockModelId END)
			AND (@iProductSize IS NULL OR defaultlf.ProductSize = @iProductSize)
		END
		ELSE IF @iTagId LIKE '%MineProductionActuals' --C
		BEGIN
		
			-- determine the minimum movement tonnages to be considered significant (used to trigger 'No Tonnes Moved' messages)
			SELECT @minimumSignificantTonnes = convert(INTEGER, value)
			FROM Setting
			WHERE Setting_Id = 'WEIGHTOMETER_MINIMUM_TONNES_SIGNIFICANT'
			
			IF @minimumSignificantTonnes IS NULL
			BEGIN
				SET @minimumSignificantTonnes = 1
			END
		
			DECLARE @DataExceptionTypeId_MissingSamples INT
			
			-- Grab the missing sample exception type
			SELECT @DataExceptionTypeId_MissingSamples = Data_Exception_Type_Id
			FROM dbo.DataExceptionType
			WHERE [Name] = 'No sample information over a 24-hour period'
		
			INSERT INTO @Location
				(LocationId, ParentLocationId, IncludeStart,IncludeEnd)
			SELECT LocationId, ParentLocationId, IncludeStart, IncludeEnd
			FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 0, 'SITE', @iDateFrom,@iDateTo)
		
			DECLARE @Weightometer TABLE
			(
				CalendarDate DATETIME NOT NULL,
				WeightometerSampleId INT NOT NULL,
				DateFrom DATETIME NOT NULL,
				DateTo DATETIME NOT NULL,
				ParentLocationId INT NULL,
				RealTonnes FLOAT NOT NULL,
				SampleTonnes FLOAT NOT NULL,
				DesignationMaterialTypeId INT NOT NULL,
				ProductSize VARCHAR(5) NOT NULL,
				DefaultProductSize BIT NOT NULL,
				SampleCount INT NULL,
				PRIMARY KEY (WeightometerSampleId, ProductSize)
			)
		
			-- retrieve the list of Weightometer Records to be used in the calculations
			INSERT INTO @Weightometer
				(CalendarDate, DateFrom, DateTo, WeightometerSampleId, ParentLocationId, ProductSize, DefaultProductSize, RealTonnes, SampleTonnes, DesignationMaterialTypeId, SampleCount)
			SELECT b.CalendarDate, b.DateFrom, b.DateTo, w.WeightometerSampleId, l.LocationId, ISNULL(wsn.Notes, defaultlf.ProductSize) As ProductSize,
				CASE WHEN wsn.Notes IS NULL THEN 1 ELSE 0 END As DefaultProductSize,
				-- calculate the REAL tonnes
				CASE
					WHEN w.UseAsRealTonnes = 1 
						THEN ISNULL(ISNULL(defaultlf.[Percent], 1) * ws.Corrected_Tonnes, ISNULL(defaultlf.[Percent], 1) * ws.Tonnes)
					ELSE 0.0
				END AS RealTonnes,
				-- calculate the SAMPLE tonnes
				-- if a sample tonnes hasn't been provided then use the actual tonnes recorded for the transaction
				-- not all flows will have this recorded (in particular CVF corrected plant balanced records)
				CASE w.BeneFeed
					WHEN 1 THEN ISNULL(ISNULL(defaultlf.[Percent], 1) * ws.Corrected_Tonnes, ISNULL(defaultlf.[Percent], 1) * ws.Tonnes)
					ELSE ISNULL(ISNULL(defaultlf.[Percent], 1) * wsv.Field_Value, 0.0)
				END AS SampleTonnes,
				-- return the Material Type based on whether it is bene feed
				CASE w.BeneFeed
					WHEN 1 THEN @BeneFeedMaterialTypeId
					WHEN 0 THEN @HighGradeMaterialTypeId
				END AS MaterialTypeId,
				wsv2.Field_Value
			FROM dbo.GetBhpbioReportBreakdown(NULL, @iDateFrom, @iDateTo, 1) AS b
				INNER JOIN dbo.WeightometerSample AS ws
					ON (ws.Weightometer_Sample_Date BETWEEN b.DateFrom AND b.DateTo)
				INNER JOIN
					(
						-- collect the weightometer sample id's for all movements from the crusher
						-- these are used to ease lookup and ensure uniqueness of the weightometer_sample_ids returned
						SELECT DISTINCT dttf.Weightometer_Sample_Id AS WeightometerSampleId, 1 AS UseAsRealTonnes,
							CASE
								WHEN m.Mill_Id IS NOT NULL
									THEN 1
								ELSE 0
							END AS BeneFeed
						FROM dbo.DataTransactionTonnes AS dtt
							INNER JOIN dbo.DataTransactionTonnesFlow AS dttf
								ON (dttf.Data_Transaction_Tonnes_Id = dtt.Data_Transaction_Tonnes_Id)
							INNER JOIN dbo.GetBhpbioCrusherLocationWithOverride(@iDateFrom, @iDateTo) AS cl
								ON (dttf.Source_Crusher_Id = cl.Crusher_Id)
								AND (dtt.Data_Transaction_Tonnes_Date BETWEEN cl.IncludeStart AND cl.IncludeEnd)
							LEFT JOIN dbo.Mill AS m
								ON (dttf.Destination_Stockpile_Id = m.Stockpile_Id)
							INNER JOIN @Location AS l
								ON (cl.Location_Id = l.LocationId
								AND dtt.Data_Transaction_Tonnes_Date BETWEEN l.IncludeStart AND l.IncludeEnd)
							LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('ActualC') xs
								ON xs.StockpileId = dttf.Source_Stockpile_Id
								OR xs.StockpileId = dttf.Destination_Stockpile_Id
						WHERE dtt.Data_Transaction_Tonnes_Date BETWEEN @iDateFrom AND @iDateTo
							AND dttf.Destination_Crusher_Id IS NULL  -- ignore crusher to crusher feeds
							AND xs.StockpileId IS NULL -- No movements to or from excluded groups.
						GROUP BY dttf.Weightometer_Sample_Id, m.Mill_Id
						UNION 
						-- collect weightometer sample id's for all movements to train rakes
						-- (by definition it's always delivers to train rake stockpiles...
						--  the grades (but not the tonnes) from these weightometers samples are important to us)
						SELECT DISTINCT dttf.Weightometer_Sample_Id, 0, 0
						FROM dbo.DataTransactionTonnes AS dtt
							INNER JOIN dbo.DataTransactionTonnesFlow AS dttf
								ON (dttf.Data_Transaction_Tonnes_Id = dtt.Data_Transaction_Tonnes_Id)
							INNER JOIN dbo.WeightometerSample AS ws
								ON (dttf.Weightometer_Sample_Id = ws.Weightometer_Sample_Id)
							INNER JOIN dbo.StockpileGroupStockpile AS sgs
								ON (sgs.Stockpile_Id = dttf.Destination_Stockpile_Id)
							INNER JOIN dbo.GetBhpbioWeightometerLocationWithOverride(@iDateFrom, @iDateTo) AS wl
								ON (ws.Weightometer_Id = wl.Weightometer_Id)
                                AND (ws.Weightometer_Sample_Date BETWEEN wl.IncludeStart and wl.IncludeEnd)
							INNER JOIN @Location AS l
								ON (wl.Location_Id = l.LocationId
								AND dtt.Data_Transaction_Tonnes_Date BETWEEN l.IncludeStart AND l.IncludeEnd)
							LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('ActualC') xs
								ON xs.StockpileId = dttf.Source_Stockpile_Id
								OR xs.StockpileId = dttf.Destination_Stockpile_Id
						WHERE dtt.Data_Transaction_Tonnes_Date BETWEEN @iDateFrom AND @iDateTo
							AND sgs.Stockpile_Group_Id = 'Port Train Rake'
							AND xs.StockpileId IS NULL -- No movements to or from excluded groups.
						GROUP BY dttf.Weightometer_Sample_Id
					  ) AS w
					ON (ws.Weightometer_Sample_Id = w.WeightometerSampleId)
					-- ensure the weightometer belongs to the required location
				INNER JOIN dbo.GetBhpbioWeightometerLocationWithOverride(@iDateFrom, @iDateTo) AS wl
					ON (ws.Weightometer_Id = wl.Weightometer_Id)
                    AND (ws.Weightometer_Sample_Date BETWEEN wl.IncludeStart AND wl.IncludeEnd)
				INNER JOIN @Location AS l
					ON (l.LocationId = wl.Location_Id
					AND ws.Weightometer_Sample_Date BETWEEN l.IncludeStart AND l.IncludeEnd)
				LEFT OUTER JOIN dbo.WeightometerSampleValue AS wsv
					ON (ws.Weightometer_Sample_Id = wsv.Weightometer_Sample_Id
					AND wsv.Weightometer_Sample_Field_Id = @SampleTonnesField)
				LEFT JOIN dbo.WeightometerSampleNotes wsn
					ON (ws.Weightometer_Sample_Id = wsn.Weightometer_Sample_Id
					AND wsn.Weightometer_Sample_Field_Id = @ProductSizeField)
				LEFT JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf
					ON wsn.Notes IS NULL
					AND wl.Location_Id = defaultlf.LocationId
					AND ws.Weightometer_Sample_Date BETWEEN defaultlf.StartDate AND defaultlf.EndDate
				LEFT JOIN dbo.WeightometerSampleValue as wsv2
					ON ws.Weightometer_Sample_Id = wsv2.Weightometer_Sample_Id
					AND wsv2.Weightometer_Sample_Field_Id = @SampleCountField

			SELECT WS.Weightometer_Id, SS.Name AS [Sample Station], WeightometerSampleId, WS.Weightometer_Sample_Date, MT.Description, WFP.Source_Crusher_Id,
				VALUE.ProductSize, DefaultProductSize,
				RealTonnes AS [Tonnes Moved], ROUND(SampleTonnes, 2, 0) AS [Tonnes Sampled], SampleCount AS [Sample Count], 
				CAST(ROUND((SampleTonnes/RealTonnes)*100, 2, 0) AS VARCHAR) + '%' AS [Sample Coverage], 
				CASE
					WHEN SampleCount = 0 THEN NULL
					WHEN SampleCount IS NULL THEN NULL
					ELSE CAST(RealTonnes/SampleCount AS INT) 
				END AS [Sample Ratio], 
				SampleSource, Fe, P, SiO2, Al2O3, LOI, H2O, ParentLocationId, S.Stockpile_Name AS Destination_Stockpile
			FROM (
				SELECT WeightometerSampleId, DesignationMaterialTypeId, ParentLocationId, ProductSize, DefaultProductSize,
					NULL As SampleTonnes, RealTonnes, 
					(CASE WHEN wc.Weightometer_Id IS NULL AND (DesignationMaterialTypeId != @BeneFeedMaterialTypeId) 
						THEN 
							CASE WHEN RealTonnes >= @minimumSignificantTonnes THEN 'No Sample Available' ELSE 'Less than threshold tonnes moved' END
						ELSE 
							NULL 
						END) As SampleSource, 
					NULL AS Fe, NULL AS P, NULL AS SiO2, NULL As Al2O3, NULL As LOI, NULL As H2O, w.SampleCount
				FROM @Weightometer As w
				INNER JOIN dbo.WeightometerSample As ws
					ON w.WeightometerSampleId = ws.Weightometer_Sample_Id
				LEFT OUTER JOIN (
					SELECT DISTINCT ws.Weightometer_Id, ws.Weightometer_Sample_Date
					FROM dbo.WeightometerSample ws
					INNER JOIN dbo.GetBhpbioWeightometerLocationWithOverride(@iDateFrom, @iDateTo) AS wl
						ON (ws.Weightometer_Id = wl.Weightometer_Id)
							AND (ws.Weightometer_Sample_Date BETWEEN wl.IncludeStart AND wl.IncludeEnd)					
					INNER JOIN dbo.WeightometerSampleNotes wsn						
						ON wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
							AND wsn.Weightometer_Sample_Field_Id = @SampleSourceField
					INNER JOIN dbo.GetBhpbioWeightometerSampleSourceActualC(@iLocationId, @iDateFrom, @iDateTo, 0) AS ss
						ON (dbo.GetDateMonth(ws.Weightometer_Sample_Date) = ss.MonthPeriod
							AND ws.Weightometer_Id = ss.Weightometer_Id
							AND wl.Location_Id = ss.LocationId
							AND wsn.Notes = ss.SampleSource)
				) As wc
					ON wc.Weightometer_Id = ws.Weightometer_Id
						AND wc.Weightometer_Sample_Date = ws.Weightometer_Sample_Date
				WHERE w.RealTonnes <> 0 and w.sampletonnes=0
				
				UNION ALL
				
				-- Include a row for all weightometers for which we do expect a sample, but of a type other than CRUSHER ACTUAL and BACK_CALCULATED Actual for which there is no such sample on a day and shift (even if RealTonnes is 0 which is the case for Port Actuals)
				
				SELECT ws.Weightometer_Sample_Id, DesignationMaterialTypeId, ParentLocationId, Null, DefaultProductSize, NULL As SampleTonnes, Null As RealTonnes, 
					(CASE WHEN DesignationMaterialTypeId != @BeneFeedMaterialTypeId THEN 'No Sample Available' ELSE NULL END) As SampleSource, NULL AS Fe, NULL AS P, NULL AS SiO2, NULL As Al2O3, NULL As LOI, NULL As H2O, NULL AS SampleCount
				FROM @Weightometer As w
					INNER JOIN dbo.WeightometerSample As ws
						ON w.WeightometerSampleId = ws.Weightometer_Sample_Id
					INNER JOIN dbo.GetBhpbioWeightometerLocationWithOverride(@iDateFrom, @iDateTo) AS wl
							ON (ws.Weightometer_Id = wl.Weightometer_Id)
								AND (ws.Weightometer_Sample_Date BETWEEN wl.IncludeStart AND wl.IncludeEnd)	
					LEFT JOIN dbo.GetBhpbioWeightometerSampleSourceActualC(@iLocationId, @iDateFrom, @iDateTo, 0) AS ss
							ON (dbo.GetDateMonth(ws.Weightometer_Sample_Date) = ss.MonthPeriod
								AND ws.Weightometer_Id = ss.Weightometer_Id
								AND wl.Location_Id = ss.LocationId
								)
				WHERE NOT EXISTS (
						-- determine whether there are samples of the required type for this weightometer and day at all
						SELECT TOP 1 1 
						FROM dbo.WeightometerSample ws2
						INNER JOIN dbo.WeightometerSampleNotes wsn2						
							ON wsn2.Weightometer_Sample_Id = ws2.Weightometer_Sample_Id
								AND wsn2.Weightometer_Sample_Field_Id = @SampleSourceField
						WHERE ws2.Weightometer_Id = ws.Weightometer_Id
							  AND ws2.Weightometer_Sample_Date = ws.Weightometer_Sample_Date
							  AND wsn2.Notes = ss.SampleSource
					) 
					AND IsNull(w.RealTonnes,0) = 0  -- target 0s as is the case for Port Actuals (NOTE non-zeros are covered in the previous query)
					AND ss.SampleSource IS NOT NULL 
					AND ss.SampleSource NOT IN ('CRUSHER ACTUALS', 'BACK-CALCULATED GRADES')
					AND ws.Weightometer_Sample_ID = (SELECT TOP 1 ws3.Weightometer_Sample_ID 
														FROM WeightometerSample ws3 
														WHERE ws3.Weightometer_Id = ws.Weightometer_Id 
															AND ws3.Weightometer_Sample_DAte = ws.Weightometer_Sample_Date
													)
				UNION ALL
				
				SELECT DISTINCT W.WeightometerSampleId, w.DesignationMaterialTypeId, w.ParentLocationId, w.ProductSize, DefaultProductSize,
					w.SampleTonnes, w.realtonnes, sSource.SampleSource, 
					Fe.Grade_Value As Fe, P.Grade_Value As P, SiO2.Grade_Value As SiO2, Al2O3.Grade_Value As Al2O3, LOI.Grade_Value As LOI, H2O.Grade_Value As H2O, w.SampleCount
				FROM @Weightometer AS w
				-- check the membership with the Sample Source
				LEFT OUTER JOIN
					(
						SELECT ws.Weightometer_Sample_Id, ss.SampleSource
						FROM dbo.WeightometerSample AS ws
							INNER JOIN dbo.GetBhpbioWeightometerLocationWithOverride(@iDateFrom, @iDateTo) AS wl
								ON (ws.Weightometer_Id = wl.Weightometer_Id)
									AND (ws.Weightometer_Sample_Date BETWEEN wl.IncludeStart AND wl.IncludeEnd)
							INNER JOIN dbo.WeightometerSampleNotes AS wsn
								ON (wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
									AND wsn.Weightometer_Sample_Field_Id = @SampleSourceField)
							INNER JOIN dbo.GetBhpbioWeightometerSampleSourceActualC(@iLocationId, @iDateFrom, @iDateTo, 0) AS ss
								ON (dbo.GetDateMonth(ws.Weightometer_Sample_Date) = ss.MonthPeriod
									AND ws.Weightometer_Id = ss.Weightometer_Id
									AND wl.Location_Id = ss.LocationId
									AND wsn.Notes = ss.SampleSource)
					) AS sSource
					ON (sSource.Weightometer_Sample_Id = w.WeightometerSampleId)
					-- add the grades
					LEFT JOIN dbo.WeightometerSampleGrade AS FE
						ON (FE.Grade_Id = 1 AND FE.Weightometer_Sample_Id = W.WeightometerSampleId)
					LEFT JOIN dbo.WeightometerSampleGrade AS P
						ON (P.Grade_Id = 2 AND P.Weightometer_Sample_Id = W.WeightometerSampleId)
					LEFT JOIN dbo.WeightometerSampleGrade AS SiO2
						ON (SiO2.Grade_Id = 3 AND SiO2.Weightometer_Sample_Id = W.WeightometerSampleId)
					LEFT JOIN dbo.WeightometerSampleGrade AS Al2O3
						ON (Al2O3.Grade_Id = 4 AND Al2O3.Weightometer_Sample_Id = W.WeightometerSampleId)
					LEFT JOIN dbo.WeightometerSampleGrade AS LOI
						ON (LOI.Grade_Id = 5 AND LOI.Weightometer_Sample_Id = W.WeightometerSampleId)
					LEFT JOIN dbo.WeightometerSampleGrade AS H2O
						ON (H2O.Grade_Id = 7 AND H2O.Weightometer_Sample_Id = W.WeightometerSampleId)			
					WHERE
					-- only include if:
					-- 1. the Material Type is Bene Feed and there is no Sample Source
					-- 2. the Material Type is High Grade and there is a matching SampleSource
					CASE
						WHEN (DesignationMaterialTypeId = @BeneFeedMaterialTypeId) AND (sSource.Weightometer_Sample_Id IS NULL) THEN 1
						WHEN (DesignationMaterialTypeId = @HighGradeMaterialTypeId) AND (sSource.Weightometer_Sample_Id IS NOT NULL) THEN 1
						ELSE 0
					END = 1
					
				) AS VALUE
				
			INNER JOIN dbo.WeightometerSample AS WS
				ON (WS.Weightometer_Sample_Id = VALUE.WeightometerSampleId)
			INNER JOIN dbo.MaterialType AS MT
				ON (MT.Material_Type_Id = VALUE.DesignationMaterialTypeId)
			LEFT JOIN dbo.BhpbioSampleStation AS SS
				ON SS.Weightometer_Id = WS.Weightometer_Id AND SS.ProductSize = VALUE.ProductSize
			LEFT JOIN dbo.WeightometerFlowPeriod AS WFP
				ON (WFP.Weightometer_Id = WS.Weightometer_Id)
			LEFT JOIN dbo.Stockpile AS S
				ON (S.Stockpile_Id = ws.Destination_Stockpile_Id)
			LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('ActualC') xs
				ON xs.StockpileId = ws.Source_Stockpile_Id
				OR xs.StockpileId = ws.Destination_Stockpile_Id
			WHERE xs.StockpileId IS NULL -- No movements to or from excluded groups.
			AND (@iProductSize IS NULL OR VALUE.ProductSize = @iProductSize)			
			
			UNION
			
			-- Find any weightometer/date combinations that had no samples during the report period (and are not on the exemption list for missing samples)
			SELECT w.Weightometer_Id, SS.Name AS [Sample Station], NULL AS WeightometerSampleId, d.This_Date, NULL AS Description, NULL AS Source_Crusher_Id,
				NULL AS ProductSize, NULL AS DefaultProductSize,
				0 AS [Tonnes Moved], NULL AS [Tonnes Sampled], NULL AS SampleCount, NULL AS [Sample Coverage], NULL AS [Sample Ratio], 
				'No Tonnes Moved' AS SampleSource, NULL AS Fe, NULL AS P, NULL AS SiO2, NULL AS Al2O3, NULL AS LOI, NULL as H2O, NULL AS ParentLocationId, NULL AS Destination_Stockpile
			FROM dbo.Weightometer w
			CROSS JOIN dbo.GetDateList(@iDateFrom, @iDateTo, 'DAY', 1) d	
			INNER JOIN dbo.GetBhpbioWeightometerLocationWithOverride(@iDateFrom, @iDateTo) AS wl
				ON (w.Weightometer_Id = wl.Weightometer_Id)
				    AND (d.This_Date BETWEEN wl.IncludeStart AND wl.IncludeEnd)
			INNER JOIN @Location AS l
				ON (l.LocationId = wl.Location_Id
					AND d.This_Date BETWEEN l.IncludeStart AND l.IncludeEnd)
			LEFT JOIN dbo.BhpbioSampleStation SS ON SS.Weightometer_Id = w.Weightometer_Id	
			LEFT OUTER JOIN dbo.BhpbioWeightometerDataExceptionExemption e
				ON w.Weightometer_Id = e.Weightometer_Id
					AND @DataExceptionTypeId_MissingSamples = e.Data_Exception_Type_Id
					AND e.Start_Date <= d.This_Date
					AND (e.End_Date IS NULL OR e.End_Date >= d.This_Date)
			WHERE e.Weightometer_Id IS NULL
				AND NOT EXISTS (
					SELECT TOP 1 1
					FROM dbo.WeightometerSample ws
					WHERE ws.Weightometer_Sample_Date = d.This_Date
						AND ws.Weightometer_Id = w.Weightometer_Id
				)
			
			ORDER BY Weightometer_Id, Weightometer_Sample_Date
				
		END
		ELSE IF @iTagId LIKE '%ExPitToOreStockpile' --y
		BEGIN
			INSERT INTO @Location
				(LocationId, ParentLocationId, IncludeStart,IncludeEnd)
			SELECT LocationId, ParentLocationId, IncludeStart, IncludeEnd
			FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 0, 'PIT', @iDateFrom, @iDateTo)
		
			SELECT DISTINCT H.Haulage_Id, H.Haulage_Date, defaultlf.ProductSize, 
				CASE WHEN haulagelf.[Percent] IS NULL THEN 1 ELSE 0 END AS DefaultProductSize,
				ISNULL(haulagelf.[Percent], defaultlf.[Percent])* H.Tonnes as Tonnes, 
				S.Stockpile_Name As Destination_Stockpile, 
				ISNULL(Fe_LF.GradeValue, Fe.Grade_Value) As Fe, 
				ISNULL(P_LF.GradeValue, P.Grade_Value) As P, 
				ISNULL(SiO2_LF.GradeValue, SiO2.Grade_Value) As SiO2, 
				ISNULL(Al2O3_LF.GradeValue, Al2O3.Grade_Value) As Al2O3, 
				ISNULL(LOI_LF.GradeValue, LOI.Grade_Value) As LOI,
				SGS.Stockpile_Group_Id AS Destination_Stockpile_Group, H.Source_Digblock_Id,
				L.LocationId As Location_Id 
			FROM dbo.Haulage AS H
				INNER JOIN dbo.GetBhpbioReportHauledBlockLocations(@iDateFrom, @iDateTo) dl
					ON (dl.DigblockId = h.Source_Digblock_Id)
				INNER JOIN @Location AS l
					ON (l.LocationId = dl.PitLocationId)
				INNER JOIN dbo.Stockpile AS S
					ON (H.Destination_Stockpile_Id = S.Stockpile_Id)
				INNER JOIN dbo.StockpileGroupStockpile AS SGS
					ON (SGS.Stockpile_Id = S.Stockpile_Id)
				INNER JOIN @HighGradeStockpileGroup AS HGSG
					ON (SGS.Stockpile_Group_Id = HGSG.StockpileGroupId)
				INNER JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf
					ON dl.PitLocationId = defaultlf.LocationId
					AND h.Haulage_Date BETWEEN defaultlf.StartDate AND defaultlf.EndDate
				LEFT JOIN dbo.GetBhpbioHaulageLumpFinesPercent(@iDateFrom, @iDateTo) haulagelf
					ON H.Haulage_Id = haulagelf.HaulageId
					AND defaultlf.ProductSize = haulagelf.ProductSize
				LEFT JOIN dbo.HaulageGrade AS FE
					ON (FE.Grade_Id = 1 AND FE.Haulage_Id = H.Haulage_Id)
				LEFT JOIN dbo.HaulageGrade AS P
					ON (P.Grade_Id = 2 AND P.Haulage_Id = H.Haulage_Id)
				LEFT JOIN dbo.HaulageGrade AS SiO2
					ON (SiO2.Grade_Id = 3 AND SiO2.Haulage_Id = H.Haulage_Id)
				LEFT JOIN dbo.HaulageGrade AS Al2O3
					ON (Al2O3.Grade_Id = 4 AND Al2O3.Haulage_Id = H.Haulage_Id)
				LEFT JOIN dbo.HaulageGrade AS LOI
					ON (LOI.Grade_Id = 5 AND LOI.Haulage_Id = H.Haulage_Id)
				LEFT JOIN dbo.GetBhpbioHaulageLumpFinesGrade(@iDateFrom, @iDateTo) AS FE_LF
					ON (FE_LF.GradeId = 1 AND FE_LF.HaulageRawId = H.Haulage_Raw_Id)
					AND FE_LF.ProductSize = defaultlf.ProductSize
				LEFT JOIN dbo.GetBhpbioHaulageLumpFinesGrade(@iDateFrom, @iDateTo) AS P_LF
					ON (P_LF.GradeId = 2 AND P_LF.HaulageRawId = H.Haulage_Raw_Id)
					AND P_LF.ProductSize = defaultlf.ProductSize
				LEFT JOIN dbo.GetBhpbioHaulageLumpFinesGrade(@iDateFrom, @iDateTo) AS SiO2_LF
					ON (SiO2_LF.GradeId = 3 AND SiO2_LF.HaulageRawId = H.Haulage_Raw_Id)
					AND SiO2_LF.ProductSize = defaultlf.ProductSize
				LEFT JOIN dbo.GetBhpbioHaulageLumpFinesGrade(@iDateFrom, @iDateTo) AS Al2O3_LF
					ON (Al2O3_LF.GradeId = 4 AND Al2O3_LF.HaulageRawId = H.Haulage_Raw_Id)
					AND Al2O3_LF.ProductSize = defaultlf.ProductSize
				LEFT JOIN dbo.GetBhpbioHaulageLumpFinesGrade(@iDateFrom, @iDateTo) AS LOI_LF
					ON (LOI_LF.GradeId = 5 AND LOI_LF.HaulageRawId = H.Haulage_Raw_Id)					
					AND LOI_LF.ProductSize = defaultlf.ProductSize
				LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('ActualY') xs
					ON xs.StockpileId = h.Source_Stockpile_Id
					OR xs.StockpileId = h.Destination_Stockpile_Id
				WHERE H.Haulage_Date >= @iDateFrom AND H.Haulage_Date <= @iDateTo
					AND H.Source_Digblock_Id IS NOT NULL
					AND h.Haulage_State_Id IN ('N', 'A')
					AND h.Child_Haulage_Id IS NULL
					AND xs.StockpileId IS NULL -- No movements to or from excluded groups.
					AND (@iProductSize IS NULL OR defaultlf.ProductSize = @iProductSize)
		END
		ELSE IF @iTagId LIKE '%StockpileToCrusher' -- z
		BEGIN
			INSERT INTO @Location
				(LocationId, ParentLocationId, IncludeStart,IncludeEnd)
			SELECT LocationId, ParentLocationId, IncludeStart, IncludeEnd
			FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 0, 'SITE', @iDateFrom,@iDateTo)
		
			SELECT DISTINCT 
				H.Haulage_Id, 
				H.Haulage_Date, 
				ISNULL(haulagelf.[Percent], 
				defaultlf.[Percent]) * H.Tonnes as Tonnes, 
				defaultlf.ProductSize, 
				CASE WHEN haulagelf.[Percent] IS NULL THEN 1 ELSE 0 END AS DefaultProductSize,			
				ISNULL(Fe_LF.GradeValue, Fe.Grade_Value) As Fe, 
				ISNULL(P_LF.GradeValue, P.Grade_Value) As P,
				ISNULL(SiO2_LF.GradeValue, SiO2.Grade_Value) As SiO2, 
				ISNULL(Al2O3_LF.GradeValue, Al2O3.Grade_Value) As Al2O3, 
				ISNULL(LOI_LF.GradeValue, LOI.Grade_Value) As LOI,
				H.Destination_Crusher_Id, MT.Material_Type_Id, MT.Description,
				L.LocationId As Location_Id, WFPV.Destination_Mill_Id
			FROM dbo.Haulage AS H
				INNER JOIN dbo.Crusher AS C
					ON (C.Crusher_Id = H.Destination_Crusher_Id)
				INNER JOIN dbo.GetBhpbioCrusherLocationWithOverride(@iDateFrom, @iDateTo) AS cl
					ON (c.Crusher_Id = cl.Crusher_Id) 
					AND (h.Haulage_Date  BETWEEN cl.IncludeStart AND cl.IncludeEnd)
				INNER JOIN @Location AS L
					ON (L.LocationId = CL.Location_Id)
					AND (H.Haulage_Date BETWEEN L.IncludeStart AND L.IncludeEnd)
				LEFT JOIN dbo.WeightometerFlowPeriodView AS WFPV
					ON (WFPV.Source_Crusher_Id = c.Crusher_Id
						AND WFPV.Destination_Mill_Id IS NOT NULL
						AND (@iDateTo > WFPV.Start_Date Or WFPV.Start_Date IS NULL)
						AND (@iDateFrom < WFPV.End_Date Or WFPV.End_Date IS NULL))
				LEFT JOIN dbo.Weightometer AS W
					ON (W.Weightometer_Id = WFPV.Weightometer_Id)
				INNER JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf
					ON cl.Location_Id = defaultlf.LocationId
					AND h.Haulage_Date BETWEEN defaultlf.StartDate AND defaultlf.EndDate
				
				-- Only Include Grouped Stockpiles to match with Actual Z calculation
				 INNER JOIN dbo.Stockpile AS s
				 	ON (h.Source_Stockpile_Id = s.Stockpile_Id)
				 INNER JOIN dbo.StockpileGroupStockpile AS sgs
				 	ON (sgs.Stockpile_Id = s.Stockpile_Id)
				 INNER JOIN dbo.BhpbioStockpileGroupDesignation AS sgd
					ON (sgd.StockpileGroupId = sgs.Stockpile_Group_Id)
				--

				LEFT JOIN dbo.GetBhpbioHaulageLumpFinesPercent(@iDateFrom, @iDateTo) haulagelf
					ON H.Haulage_Id = haulagelf.HaulageId
					AND defaultlf.ProductSize = haulagelf.ProductSize
				LEFT JOIN dbo.MaterialType AS MT
					ON (MT.Material_Type_Id = CASE WHEN W.Weightometer_Id IS NOT NULL THEN @BeneFeedMaterialTypeId ELSE @HighGradeMaterialTypeId END)
				LEFT JOIN dbo.HaulageGrade AS FE
					ON (FE.Grade_Id = 1 AND FE.Haulage_Id = H.Haulage_Id)
				LEFT JOIN dbo.HaulageGrade AS P
					ON (P.Grade_Id = 2 AND P.Haulage_Id = H.Haulage_Id)
				LEFT JOIN dbo.HaulageGrade AS SiO2
					ON (SiO2.Grade_Id = 3 AND SiO2.Haulage_Id = H.Haulage_Id)
				LEFT JOIN dbo.HaulageGrade AS Al2O3
					ON (Al2O3.Grade_Id = 4 AND Al2O3.Haulage_Id = H.Haulage_Id)
				LEFT JOIN dbo.HaulageGrade AS LOI
					ON (LOI.Grade_Id = 5 AND LOI.Haulage_Id = H.Haulage_Id)
				LEFT JOIN dbo.GetBhpbioHaulageLumpFinesGrade(@iDateFrom, @iDateTo) AS FE_LF
					ON (FE_LF.GradeId = 1 AND FE_LF.HaulageRawId = H.Haulage_Raw_Id)
					AND FE_LF.ProductSize = defaultlf.ProductSize
				LEFT JOIN dbo.GetBhpbioHaulageLumpFinesGrade(@iDateFrom, @iDateTo) AS P_LF
					ON (P_LF.GradeId = 2 AND P_LF.HaulageRawId = H.Haulage_Raw_Id)
					AND P_LF.ProductSize = defaultlf.ProductSize
				LEFT JOIN dbo.GetBhpbioHaulageLumpFinesGrade(@iDateFrom, @iDateTo) AS SiO2_LF
					ON (SiO2_LF.GradeId = 3 AND SiO2_LF.HaulageRawId = H.Haulage_Raw_Id)
					AND SiO2_LF.ProductSize = defaultlf.ProductSize
				LEFT JOIN dbo.GetBhpbioHaulageLumpFinesGrade(@iDateFrom, @iDateTo) AS Al2O3_LF
					ON (Al2O3_LF.GradeId = 4 AND Al2O3_LF.HaulageRawId = H.Haulage_Raw_Id)
					AND Al2O3_LF.ProductSize = defaultlf.ProductSize
				LEFT JOIN dbo.GetBhpbioHaulageLumpFinesGrade(@iDateFrom, @iDateTo) AS LOI_LF
					ON (LOI_LF.GradeId = 5 AND LOI_LF.HaulageRawId = H.Haulage_Raw_Id)					
					AND LOI_LF.ProductSize = defaultlf.ProductSize
				LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('ActualZ') xs
					ON xs.StockpileId = h.Source_Stockpile_Id
					OR xs.StockpileId = h.Destination_Stockpile_Id
			WHERE H.Haulage_Date >= @iDateFrom AND H.Haulage_Date <= @iDateTo
				AND h.Haulage_State_Id IN ('N', 'A')
				AND h.Child_Haulage_Id IS NULL
				AND (W.Weightometer_Type_Id LIKE '%L1%' OR W.Weightometer_Type_Id IS NULL)
				AND h.Source_Stockpile_Id IS NOT NULL
				AND xs.StockpileId IS NULL -- No movements to or from excluded groups.
				AND (@iProductSize IS NULL OR defaultlf.ProductSize = @iProductSize)
		END
		ELSE IF @iTagId LIKE '%OreShipped'
		BEGIN
			INSERT INTO @Location
				(LocationId, ParentLocationId, IncludeStart,IncludeEnd)
			SELECT LocationId, ParentLocationId, IncludeStart, IncludeEnd
			FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 0, 'HUB', @iDateFrom,@iDateTo)
		
			Select L.Name As LocationName, S.OfficialFinishTime AS CalendarDate, 
			ISNULL(S.ShippedProductSize, defaultlf.ProductSize) As ProductSize,
			CASE WHEN S.ShippedProductSize IS NULL THEN 1 ELSE 0 END As DefaultProductSize,
			ISNULL(defaultlf.[Percent], 1) * SP.Tonnes AS Tonnes, 
			S.ShippedProduct, 
			S.CustomerNo, L.Location_Id, Fe.GradeValue As Fe, P.GradeValue As P, SiO2.GradeValue As SiO2, 
			Al2O3.GradeValue As Al2O3, LOI.GradeValue As LOI, H2O.GradeValue as H2O
			From dbo.BhpbioShippingNominationItem AS S
				INNER JOIN dbo.BhpbioShippingNominationItemParcel AS SP
					ON (S.BhpbioShippingNominationItemId = SP.BhpbioShippingNominationItemId)
				INNER JOIN dbo.Location AS L
					ON (L.Location_Id = SP.HubLocationId)
					AND SP.HubLocationId NOT IN (SELECT LocationId FROM GetBhpbioExcludeHubLocation('ShippingTransaction'))
				INNER JOIN @Location AS FL
					ON L.Location_Id = FL.LocationId
					AND S.OfficialFinishTime BETWEEN FL.IncludeStart AND DateAdd(Second, 59, DateAdd(Minute, 59, DateAdd(Hour, 23, FL.IncludeEnd)))
				LEFT JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf
					ON S.ShippedProductSize IS NULL
					AND SP.HubLocationId = defaultlf.LocationId
					AND S.OfficialFinishTime BETWEEN defaultlf.StartDate AND defaultlf.EndDate
				LEFT JOIN dbo.BhpbioShippingNominationItemParcelGrade AS FE
					ON (FE.GradeId = 1 AND FE.BhpbioShippingNominationItemParcelId = SP.BhpbioShippingNominationItemParcelId)
				LEFT JOIN dbo.BhpbioShippingNominationItemParcelGrade AS P
					ON (P.GradeId = 2 AND P.BhpbioShippingNominationItemParcelId = SP.BhpbioShippingNominationItemParcelId)
				LEFT JOIN dbo.BhpbioShippingNominationItemParcelGrade AS SiO2
					ON (SiO2.GradeId = 3 AND SiO2.BhpbioShippingNominationItemParcelId = SP.BhpbioShippingNominationItemParcelId)
				LEFT JOIN dbo.BhpbioShippingNominationItemParcelGrade AS Al2O3
					ON (Al2O3.GradeId = 4 AND Al2O3.BhpbioShippingNominationItemParcelId = SP.BhpbioShippingNominationItemParcelId)
				LEFT JOIN dbo.BhpbioShippingNominationItemParcelGrade AS LOI
					ON (LOI.GradeId = 5 AND LOI.BhpbioShippingNominationItemParcelId = SP.BhpbioShippingNominationItemParcelId)
				LEFT JOIN dbo.BhpbioShippingNominationItemParcelGrade AS H2O
					ON (H2O.GradeId = 7 AND H2O.BhpbioShippingNominationItemParcelId = SP.BhpbioShippingNominationItemParcelId)
			WHERE S.OfficialFinishTime BETWEEN @iDateFrom AND DateAdd(Second, 59, DateAdd(Minute, 59, DateAdd(Hour, 23, @iDateTo)))
				AND (@iProductSize IS NULL OR ISNULL(S.ShippedProductSize, defaultlf.ProductSize) = @iProductSize)
			Order By S.OfficialFinishTime
		END
		ELSE IF @iTagId LIKE '%HubPostCrusherStockpileDelta' OR @iTagId LIKE '%OreForRail'
		BEGIN
			DECLARE @OreForRailGradesOnly BIT
			IF @iTagId LIKE '%OreForRail'
			BEGIN
				SET @OreForRailGradesOnly = 1
			END
			ELSE
			BEGIN
				SET @OreForRailGradesOnly = 0
			END
		
			INSERT INTO @Location
				(LocationId, ParentLocationId,IncludeStart,IncludeEnd)
			SELECT LocationId, ParentLocationId,IncludeStart,IncludeEnd
			FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 0, 'SITE',@iDateFrom,@iDateTo)
		
			SELECT @HubLocationTypeId = Location_Type_Id
			FROM dbo.LocationType
			WHERE Description = 'Hub'
			SELECT @SiteLocationTypeId = Location_Type_Id
			FROM dbo.LocationType
			WHERE Description = 'Site'

			SET @StockpileGroupId = 'Post Crusher'
			
			-- Get Removals
			INSERT INTO @StockpileDeltaHub
				(StockpileId, WeightometerSampleId, Addition, ProductSize, ProductPercent, DefaultProductSize, Tonnes,Hub)		
			SELECT DISTINCT S.Stockpile_Id, WS.Weightometer_Sample_Id, 0, 
				ISNULL(wsn.Notes, defaultlf.ProductSize), 
				ISNULL(defaultlf.[Percent], 1),
				CASE WHEN wsn.Notes IS NULL THEN 1 ELSE 0 END,
				ISNULL(defaultlf.[Percent], 1) * ws.Tonnes,
				LL.Description
			FROM dbo.WeightometerSample AS WS
				INNER JOIN dbo.Stockpile AS S
					ON (S.Stockpile_Id = WS.Source_Stockpile_Id)
				LEFT JOIN dbo.StockpileGroupStockpile AS SGS
					ON (SGS.Stockpile_Id = S.Stockpile_Id)
					AND SGS.Stockpile_Group_Id = @StockpileGroupId
				INNER JOIN dbo.BhpbioStockpileLocationDate AS SL
					ON (SL.Stockpile_Id = S.Stockpile_Id)
					AND	(sl.[Start_Date] BETWEEN @iDateFrom AND @iDateTo
						OR sl.End_Date BETWEEN @iDateFrom AND @iDateTo
						OR (sl.[Start_Date] < @iDateFrom AND sl.End_Date >@iDateTo))
				INNER JOIN @Location AS L
					ON (L.LocationId = SL.Location_Id)
					AND	(L.[IncludeStart] BETWEEN @iDateFrom AND @iDateTo
					OR L.IncludeEnd BETWEEN @iDateFrom AND @iDateTo
					OR (L.[IncludeStart] < @iDateFrom AND L.IncludeEnd >@iDateTo))
				LEFT JOIN dbo.BhpbioLocationStockpileConfiguration AS BSLC
					ON (BSLC.LocationId = SL.Location_Id)
				INNER JOIN dbo.Location AS LL
					ON (LL.Location_Id = L.LocationId)
				LEFT JOIN dbo.StockpileGroupStockpile SGS_D
					ON (SGS_D.Stockpile_Id = WS.Destination_Stockpile_Id
						AND SGS_D.Stockpile_Group_Id = @StockpileGroupId)
				LEFT JOIN dbo.WeightometerSampleNotes wsn
					ON (ws.Weightometer_Sample_Id = wsn.Weightometer_Sample_Id
						AND wsn.Weightometer_Sample_Field_Id = @ProductSizeField)
				LEFT JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf
					ON wsn.Notes IS NULL
					AND l.LocationId = defaultlf.LocationId
					AND ws.Weightometer_Sample_Date BETWEEN defaultlf.StartDate AND defaultlf.EndDate					
				LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('PostCrusher') xs
					ON xs.StockpileId = ws.Source_Stockpile_Id
					OR xs.StockpileId = ws.Destination_Stockpile_Id
				LEFT JOIN BhpbioWeightometerGroupWeightometer ei ON ei.Weightometer_Group_Id = 'ExplicitlyIncludeInOreForRail' AND ei.Weightometer_Id =	ws.Weightometer_Id
					AND ei.[Start_Date] <= ws.Weightometer_Sample_Date AND ((ei.End_Date IS NULL) OR ei.End_Date >= ws.Weightometer_Sample_Date)
			WHERE
				( 
					(
						Coalesce(WS.Source_Stockpile_Id, -1) <> Coalesce(WS.Destination_Stockpile_Id, -1)
						AND SGS.Stockpile_Group_Id = @StockpileGroupId
						AND SGS_D.Stockpile_Group_Id IS NULL
									AND (LL.Location_Type_Id = @HubLocationTypeId OR
							(BSLC.PromoteStockpiles = 1 AND LL.Location_Type_Id = @SiteLocationTypeId AND 
								(BSLC.PromoteStockpilesFromDate IS NULL OR @iDateFrom >= BSLC.PromoteStockpilesFromDate)))
					)
					OR
					(
						@iTagId like '%OreForRail'
						AND NOT ei.Weightometer_Group_Id IS NULL
					)
				)
				AND xs.StockpileId IS NULL -- No movements to or from excluded groups.
				AND WS.Weightometer_Id NOT LIKE '%Raw%'
				AND WS.Weightometer_Sample_Date BETWEEN @iDateFrom AND @iDateTo
				
			IF @iTagId LIKE '%HubPostCrusherStockpileDelta'
			BEGIN
				-- Get Additions
				INSERT INTO @StockpileDeltaHub
					(StockpileId, WeightometerSampleId, Addition, ProductSize, ProductPercent, DefaultProductSize, Tonnes,Hub)		
				SELECT DISTINCT S.Stockpile_Id, WS.Weightometer_Sample_ID, 1, 
					ISNULL(wsn.Notes, defaultlf.ProductSize), 
					ISNULL(defaultlf.[Percent], 1),
					CASE WHEN wsn.Notes IS NULL THEN 1 ELSE 0 END,
					ISNULL(defaultlf.[Percent], 1) * ws.Tonnes,
					LL.Description
				FROM dbo.WeightometerSample AS WS
					INNER JOIN dbo.Stockpile AS S
						ON (S.Stockpile_Id = WS.Destination_Stockpile_Id)
					INNER JOIN dbo.StockpileGroupStockpile AS SGS
						ON (SGS.Stockpile_Id = S.Stockpile_Id)
					INNER JOIN dbo.BhpbioStockpileLocationDate AS SL
						ON (SL.Stockpile_Id = S.Stockpile_Id)
						AND	(sl.[Start_Date] BETWEEN @iDateFrom AND @iDateTo
							OR sl.End_Date BETWEEN @iDateFrom AND @iDateTo
							OR (sl.[Start_Date] < @iDateFrom AND sl.End_Date >@iDateTo))
					INNER JOIN @Location AS L
						ON (L.LocationId = SL.Location_Id)
						AND	(L.[IncludeStart] BETWEEN @iDateFrom AND @iDateTo
							OR L.IncludeEnd BETWEEN @iDateFrom AND @iDateTo
							OR (L.[IncludeStart] < @iDateFrom AND L.IncludeEnd >@iDateTo))
					LEFT JOIN dbo.BhpbioLocationStockpileConfiguration AS BSLC
						ON (BSLC.LocationId = SL.Location_Id)
					INNER JOIN dbo.Location AS LL
						ON (LL.Location_Id = L.LocationId)
					LEFT JOIN dbo.StockpileGroupStockpile SGS_S
						ON (SGS_S.Stockpile_Id = WS.Source_Stockpile_Id
							AND SGS_S.Stockpile_Group_Id = @StockpileGroupId)
					LEFT JOIN dbo.WeightometerSampleNotes wsn
						ON (ws.Weightometer_Sample_Id = wsn.Weightometer_Sample_Id
							AND wsn.Weightometer_Sample_Field_Id = @ProductSizeField)
					LEFT JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf
						ON wsn.Notes IS NULL
						AND l.LocationId = defaultlf.LocationId
						AND ws.Weightometer_Sample_Date BETWEEN defaultlf.StartDate AND defaultlf.EndDate					
					LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('PostCrusher') xs
						ON xs.StockpileId = ws.Source_Stockpile_Id
						OR xs.StockpileId = ws.Destination_Stockpile_Id
				WHERE Coalesce(WS.Source_Stockpile_Id, -1) <> Coalesce(WS.Destination_Stockpile_Id, -1)
					AND SGS.Stockpile_Group_Id = @StockpileGroupId
					AND WS.Weightometer_Sample_Date BETWEEN @iDateFrom AND @iDateTo
					AND SGS_S.Stockpile_Group_Id IS NULL
					AND WS.Weightometer_Id NOT LIKE '%Raw%'
					AND (LL.Location_Type_Id = @HubLocationTypeId OR
						(BSLC.PromoteStockpiles = 1 AND LL.Location_Type_Id = @SiteLocationTypeId AND 
							(BSLC.PromoteStockpilesFromDate IS NULL OR @iDateFrom >= BSLC.PromoteStockpilesFromDate)))
					AND xs.StockpileId IS NULL -- No movements to or from excluded groups.
			END
			
			SELECT DISTINCT WS.Weightometer_Id,SD.WeightometerSampleId, WS.Weightometer_Sample_Date, ProductSize, DefaultProductSize,
				CASE WHEN SD.Addition = 1 THEN SD.Tonnes ELSE -SD.Tonnes END AS MovementTonnes, 
				NULL As SampleTonnes, NULL As Fe, NULL As P, NULL As SiO2, NULL As Al2O3, NULL As LOI, NULL as H2O,
				SD.Addition, SD.Hub,WFPV.Source_Crusher_Id, WFPV.Source_Mill_Id As SourcePlant, SS.Stockpile_Name AS SourceStockpile, WFPV.Destination_Crusher_Id As DestinationCrusher, WFPV.Destination_Mill_Id As DestinationPlant, DS.Stockpile_Name AS DestinationStockpile
			FROM @StockpileDeltaHub AS SD
				INNER JOIN dbo.WeightometerSample AS WS
					ON (WS.Weightometer_Sample_Id = SD.WeightometerSampleId)
				LEFT JOIN dbo.WeightometerFlowPeriodView AS WFPV
					ON (WFPV.Weightometer_Id = WS.Weightometer_Id
						AND (WS.Weightometer_Sample_Date > WFPV.Start_Date Or WFPV.Start_Date IS NULL)
						AND (WS.Weightometer_Sample_Date < WFPV.End_Date Or WFPV.End_Date IS NULL))	
				LEFT JOIN dbo.Stockpile AS SS
					ON (Coalesce(WFPV.Source_Stockpile_ID, WS.Source_Stockpile_Id) = SS.Stockpile_Id)
				LEFT JOIN dbo.Stockpile AS DS
					ON (Coalesce(WFPV.Destination_Stockpile_ID, WS.Destination_Stockpile_Id) = DS.Stockpile_Id)
				LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('PostCrusher') xs
					ON xs.StockpileId = WFPV.Source_Stockpile_Id
					OR xs.StockpileId = WFPV.Destination_Stockpile_Id
				WHERE xs.StockpileId IS NULL -- No movements to or from excluded groups.
				AND (@iProductSize IS NULL OR SD.ProductSize = @iProductSize)
			UNION ALL
			SELECT DISTINCT ws.Weightometer_Id,ws.Weightometer_Sample_Id, WS.Weightometer_Sample_Date, ProductSize, DefaultProductSize,
				NULL AS MovementTonnes, 
				ProductPercent * WSV.Field_Value As SampleTonnes,
				Fe.Grade_Value As Fe, P.Grade_Value As P, SiO2.Grade_Value As SiO2, Al2O3.Grade_Value As Al2O3, LOI.Grade_Value As LOI, 
				CASE WHEN @FactorName = 'F3' THEN NULL ELSE H2O.Grade_Value END As H2O, -- No H2O grades for F3
				NULL, LL.Description, WFPV.Source_Crusher_Id, WFPV.Source_Mill_Id As SourcePlant, SS.Stockpile_Name AS SourceStockpile, 
				WFPV.Destination_Crusher_Id As DestinationCrusher, WFPV.Destination_Mill_Id As DestinationPlant, 
				DS.Stockpile_Name AS DestinationStockpile
			FROM @StockpileDeltaHub AS SD
				INNER JOIN dbo.WeightometerSample AS WS
					ON (WS.Weightometer_Sample_Id = SD.WeightometerSampleId)
				INNER JOIN dbo.GetBhpbioWeightometerLocationWithOverride(@iDateFrom, @iDateTo) AS wl
					ON (WS.Weightometer_Id = wl.Weightometer_Id)
                    AND (ws.Weightometer_Sample_Date BETWEEN wl.IncludeStart AND wl.IncludeEnd)
                INNER JOIN @Location L
                    ON (L.LocationId = wl.Location_ID)
                    AND (ws.Weightometer_Sample_Date BETWEEN L.[IncludeStart] AND L.IncludeEnd)
				INNER JOIN dbo.WeightometerSampleNotes AS wsn
					ON (wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
						AND wsn.Weightometer_Sample_Field_Id = @SampleSourceField)
				INNER JOIN dbo.WeightometerSampleValue AS wsv
					ON (wsv.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
					AND wsv.Weightometer_Sample_Field_Id = @SampleTonnesField)
				INNER JOIN dbo.GetBhpbioWeightometerSampleSource(@iLocationId, @iDateFrom, @iDateTo, @OreForRailGradesOnly) AS wss
					ON (dbo.GetDateMonth(ws.Weightometer_Sample_Date) = wss.MonthPeriod
						AND wl.Location_Id = wss.LocationId
							AND wsn.Notes = wss.SampleSource)
				INNER JOIN dbo.Location AS LL
					ON (wl.Location_Id = LL.Location_Id)
				LEFT JOIN dbo.BhpbioLocationStockpileConfiguration AS BSLC
					ON (BSLC.LocationId = wl.Location_Id)
				LEFT JOIN dbo.WeightometerSampleGrade AS FE
					ON (FE.Grade_Id = 1 AND FE.Weightometer_Sample_Id = WS.Weightometer_Sample_Id)
				LEFT JOIN dbo.WeightometerSampleGrade AS P
					ON (P.Grade_Id = 2 AND P.Weightometer_Sample_Id = WS.Weightometer_Sample_Id)
				LEFT JOIN dbo.WeightometerSampleGrade AS SiO2
					ON (SiO2.Grade_Id = 3 AND SiO2.Weightometer_Sample_Id = WS.Weightometer_Sample_Id)
				LEFT JOIN dbo.WeightometerSampleGrade AS Al2O3
					ON (Al2O3.Grade_Id = 4 AND Al2O3.Weightometer_Sample_Id = WS.Weightometer_Sample_Id)
				LEFT JOIN dbo.WeightometerSampleGrade AS LOI
					ON (LOI.Grade_Id = 5 AND LOI.Weightometer_Sample_Id = WS.Weightometer_Sample_Id)
				LEFT JOIN dbo.WeightometerSampleGrade AS H2O
					ON (H2O.Grade_Id = 7 AND H2O.Weightometer_Sample_Id = WS.Weightometer_Sample_Id)
				LEFT JOIN dbo.WeightometerFlowPeriodView AS WFPV
					ON (WFPV.Weightometer_Id = WS.Weightometer_Id
						AND (WS.Weightometer_Sample_Date > WFPV.Start_Date Or WFPV.Start_Date IS NULL)
						AND (WS.Weightometer_Sample_Date < WFPV.End_Date Or WFPV.End_Date IS NULL))	
				LEFT JOIN dbo.Stockpile AS SS
					ON (WS.Source_Stockpile_Id = SS.Stockpile_Id)
				LEFT JOIN dbo.Stockpile AS DS
					ON (WS.Destination_Stockpile_Id = DS.Stockpile_Id)
				LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('PostCrusher') xs
					ON xs.StockpileId = WS.Source_Stockpile_Id
					OR xs.StockpileId = WS.Destination_Stockpile_Id
				LEFT JOIN BhpbioWeightometerGroupWeightometer ei ON ei.Weightometer_Group_Id = 'ExplicitlyIncludeInOreForRail' AND ei.Weightometer_Id =	ws.Weightometer_Id
					AND ei.[Start_Date] <= ws.Weightometer_Sample_Date AND ((ei.End_Date IS NULL) OR ei.End_Date >= ws.Weightometer_Sample_Date)
			WHERE 
				(
					(
						(LL.Location_Type_Id = @HubLocationTypeId OR 
						(BSLC.PromoteStockpiles = 1 AND LL.Location_Type_Id = @SiteLocationTypeId AND 
						(BSLC.PromoteStockpilesFromDate IS NULL OR @iDateFrom >= BSLC.PromoteStockpilesFromDate)))
					)	
					OR
					(
						@iTagId like '%OreForRail'
						AND NOT (ei.Weightometer_Group_Id IS NULL)
					)
				)
				AND Fe.Grade_Value IS NOT NULL
				AND xs.StockpileId IS NULL -- No movements to or from excluded groups.
				AND (@iProductSize IS NULL OR SD.ProductSize = @iProductSize)
		END
		ELSE IF @iTagId LIKE '%SitePostCrusherStockpileDelta'
		BEGIN
			INSERT INTO @Location
				(LocationId, ParentLocationId,IncludeStart,IncludeEnd)
			SELECT LocationId, ParentLocationId,IncludeStart,IncludeEnd
			FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 0, 'SITE',@iDateFrom,@iDateTo)
		
			SET @StockpileGroupId = 'Post Crusher'
			SELECT @HubLocationTypeId = Location_Type_Id
			FROM dbo.LocationType
			WHERE Description = 'Hub'
			SELECT @SiteLocationTypeId = Location_Type_Id
			FROM dbo.LocationType
			WHERE Description = 'Site'
			
			-- Get Removals
			INSERT INTO @StockpileDeltaSite
				(StockpileId, WeightometerSampleId, Addition, ProductSize, ProductPercent, DefaultProductSize, Tonnes, Site)		
			SELECT DISTINCT S.Stockpile_Id, WS.Weightometer_Sample_Id, 0, 
				ISNULL(wsn.Notes, defaultlf.ProductSize), 
				ISNULL(defaultlf.[Percent], 1),
				CASE WHEN wsn.Notes IS NULL THEN 1 ELSE 0 END,
				ISNULL(defaultlf.[Percent], 1) * ws.Tonnes,
				LL.Description
			FROM dbo.WeightometerSample AS WS
				INNER JOIN dbo.Stockpile AS S
					ON (S.Stockpile_Id = WS.Source_Stockpile_Id)
				INNER JOIN dbo.StockpileGroupStockpile AS SGS
					ON (SGS.Stockpile_Id = S.Stockpile_Id)
				INNER JOIN dbo.BhpbioStockpileLocationDate AS SL
					ON (SL.Stockpile_Id = S.Stockpile_Id)
					AND	(sl.[Start_Date] BETWEEN @iDateFrom AND @iDateTo
						OR sl.End_Date BETWEEN @iDateFrom AND @iDateTo
						OR (sl.[Start_Date] < @iDateFrom AND sl.End_Date >@iDateTo))
				INNER JOIN @Location AS L
					ON (L.LocationId = SL.Location_Id)
					AND (WS.Weightometer_Sample_Date BETWEEN L.IncludeStart AND L.IncludeEnd)
				LEFT JOIN dbo.BhpbioLocationStockpileConfiguration AS BSLC
					ON (BSLC.LocationId = SL.Location_Id)
				INNER JOIN dbo.Location AS LL
					ON (LL.Location_Id = L.LocationId)
				LEFT JOIN dbo.StockpileGroupStockpile SGS_D
					ON (SGS_D.Stockpile_Id = WS.Destination_Stockpile_Id
						AND SGS_D.Stockpile_Group_Id = @StockpileGroupId)
				LEFT JOIN dbo.WeightometerSampleNotes wsn
					ON (ws.Weightometer_Sample_Id = wsn.Weightometer_Sample_Id
						AND wsn.Weightometer_Sample_Field_Id = @ProductSizeField)
				LEFT JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf
					ON wsn.Notes IS NULL
					AND l.LocationId = defaultlf.LocationId
					AND ws.Weightometer_Sample_Date BETWEEN defaultlf.StartDate AND defaultlf.EndDate					
				LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('PostCrusher') xs
					ON xs.StockpileId = WS.Source_Stockpile_Id
					OR xs.StockpileId = WS.Destination_Stockpile_Id
			WHERE Coalesce(WS.Source_Stockpile_Id, -1) <> Coalesce(WS.Destination_Stockpile_Id, -1)
				AND SGS.Stockpile_Group_Id = @StockpileGroupId
				AND SGS_D.Stockpile_Group_Id IS NULL
				AND WS.Weightometer_Sample_Date BETWEEN @iDateFrom AND @iDateTo			
				AND (LL.Location_Type_Id = @SiteLocationTypeId AND
			(BSLC.PromoteStockpiles = 0 OR BSLC.PromoteStockpiles IS NULL))
				AND WS.Weightometer_Id NOT LIKE '%Raw%'
				AND xs.StockpileId IS NULL -- No movements to or from excluded groups.
			
			-- Get Additions
			INSERT INTO @StockpileDeltaSite
				(StockpileId, WeightometerSampleId, Addition, ProductSize, ProductPercent, DefaultProductSize, Tonnes, Site)		
			SELECT DISTINCT S.Stockpile_Id, WS.Weightometer_Sample_Id, 1,
				ISNULL(wsn.Notes, defaultlf.ProductSize), 
				ISNULL(defaultlf.[Percent], 1),
				CASE WHEN wsn.Notes IS NULL THEN 1 ELSE 0 END,
				ISNULL(defaultlf.[Percent], 1) * ws.Tonnes,
				LL.Description
			FROM dbo.WeightometerSample AS WS
				INNER JOIN dbo.Stockpile AS S
					ON (S.Stockpile_Id = WS.Destination_Stockpile_Id)
				INNER JOIN dbo.StockpileGroupStockpile AS SGS
					ON (SGS.Stockpile_Id = S.Stockpile_Id)
				INNER JOIN dbo.BhpbioStockpileLocationDate AS SL
					ON (SL.Stockpile_Id = S.Stockpile_Id)
					AND	(sl.[Start_Date] BETWEEN @iDateFrom AND @iDateTo
						OR sl.End_Date BETWEEN @iDateFrom AND @iDateTo
						OR (sl.[Start_Date] < @iDateFrom AND sl.End_Date >@iDateTo))
				INNER JOIN @Location AS L
					ON (L.LocationId = SL.Location_Id)
					AND (WS.Weightometer_Sample_Date BETWEEN L.IncludeStart AND L.IncludeEnd)
				LEFT JOIN dbo.BhpbioLocationStockpileConfiguration AS BSLC
					ON (BSLC.LocationId = SL.Location_Id)
				INNER JOIN dbo.Location AS LL
					ON (LL.Location_Id = L.LocationId)
				LEFT JOIN dbo.StockpileGroupStockpile SGS_S
					ON (SGS_S.Stockpile_Id = WS.Source_Stockpile_Id
						AND SGS_S.Stockpile_Group_Id = @StockpileGroupId)
				LEFT JOIN dbo.WeightometerSampleNotes wsn
					ON (ws.Weightometer_Sample_Id = wsn.Weightometer_Sample_Id
						AND wsn.Weightometer_Sample_Field_Id = @ProductSizeField)
				LEFT JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf
					ON wsn.Notes IS NULL
					AND l.LocationId = defaultlf.LocationId
					AND ws.Weightometer_Sample_Date BETWEEN defaultlf.StartDate AND defaultlf.EndDate					
				LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('PostCrusher') xs
					ON xs.StockpileId = WS.Source_Stockpile_Id
					OR xs.StockpileId = WS.Destination_Stockpile_Id
			WHERE Coalesce(WS.Source_Stockpile_Id, -1) <> Coalesce(WS.Destination_Stockpile_Id, -1)
				AND SGS.Stockpile_Group_Id = @StockpileGroupId
				AND WS.Weightometer_Sample_Date BETWEEN @iDateFrom AND @iDateTo
				AND SGS_S.Stockpile_Group_Id IS NULL				
				AND (LL.Location_Type_Id = @SiteLocationTypeId AND
				(BSLC.PromoteStockpiles = 0 OR BSLC.PromoteStockpiles IS NULL))
				AND WS.Weightometer_Id NOT LIKE '%Raw%'
				AND xs.StockpileId IS NULL -- No movements to or from excluded groups.

			SELECT DISTINCT WS.Weightometer_Id,SD.WeightometerSampleId, WS.Weightometer_Sample_Date, SD.ProductSize, SD.DefaultProductSize,
				CASE WHEN SD.Addition = 1 THEN SD.Tonnes ELSE -SD.Tonnes END AS MovementTonnes, 
				Fe.Grade_Value As Fe, P.Grade_Value As P, SiO2.Grade_Value As SiO2, Al2O3.Grade_Value As Al2O3, LOI.Grade_Value As LOI,
				CASE WHEN @FactorName = 'F3' THEN NULL ELSE H2O.Grade_Value END As H2O, -- No H2O grades for F3
				SD.Addition, SD.Site, WFPV.Source_Crusher_Id, DS.Stockpile_Name AS DestinationStockpile, SS.Stockpile_Name AS SourceStockpile 
			FROM @StockpileDeltaSite AS SD
				INNER JOIN dbo.WeightometerSample AS WS
					ON (WS.Weightometer_Sample_Id = SD.WeightometerSampleId)
				LEFT JOIN dbo.WeightometerSampleGrade AS FE
					ON (FE.Grade_Id = 1 AND FE.Weightometer_Sample_Id = WS.Weightometer_Sample_Id)
				LEFT JOIN dbo.WeightometerSampleGrade AS P
					ON (P.Grade_Id = 2 AND P.Weightometer_Sample_Id = WS.Weightometer_Sample_Id)
				LEFT JOIN dbo.WeightometerSampleGrade AS SiO2
					ON (SiO2.Grade_Id = 3 AND SiO2.Weightometer_Sample_Id = WS.Weightometer_Sample_Id)
				LEFT JOIN dbo.WeightometerSampleGrade AS Al2O3
					ON (Al2O3.Grade_Id = 4 AND Al2O3.Weightometer_Sample_Id = WS.Weightometer_Sample_Id)
				LEFT JOIN dbo.WeightometerSampleGrade AS LOI
					ON (LOI.Grade_Id = 5 AND LOI.Weightometer_Sample_Id = WS.Weightometer_Sample_Id)
				LEFT JOIN dbo.WeightometerSampleGrade AS H2O
					ON (H2O.Grade_Id = 7 AND H2O.Weightometer_Sample_Id = WS.Weightometer_Sample_Id)
				LEFT JOIN dbo.WeightometerFlowPeriodView AS WFPV
					ON (WFPV.Weightometer_Id = WS.Weightometer_Id
						AND (WS.Weightometer_Sample_Date > WFPV.Start_Date Or WFPV.Start_Date IS NULL)
						AND (WS.Weightometer_Sample_Date < WFPV.End_Date Or WFPV.End_Date IS NULL))	
				LEFT JOIN dbo.Stockpile AS SS
					ON (WS.Source_Stockpile_Id = SS.Stockpile_Id)
				LEFT JOIN dbo.Stockpile AS DS
					ON (WS.Destination_Stockpile_Id = DS.Stockpile_Id)
				LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('PostCrusher') xs
					ON xs.StockpileId = WS.Source_Stockpile_Id
					OR xs.StockpileId = WS.Destination_Stockpile_Id
				WHERE xs.StockpileId IS NULL -- No movements to or from excluded groups.
				AND (@iProductSize IS NULL OR SD.ProductSize = @iProductSize)
		END
		ELSE IF @iTagId LIKE '%PortBlendedAdjustment'
		BEGIN
			INSERT INTO @Location
				(LocationId, ParentLocationId,IncludeStart,IncludeEnd)
			SELECT LocationId, ParentLocationId,IncludeStart,IncludeEnd
			FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 0, 'SITE',@iDateFrom,@iDateTo)
		
			Select BPB.StartDate, BPB.EndDate,
				ISNULL(CASE WHEN BPB.DestinationHubLocationId = LPOINT.LocationId THEN BPB.SourceProductSize ELSE BPB.SourceProductSize END, defaultlf.ProductSize) As SourceProductSize, 
				ISNULL(CASE WHEN BPB.DestinationHubLocationId = LPOINT.LocationId THEN BPB.DestinationProductSize ELSE BPB.DestinationProductSize END, defaultlf.ProductSize) As DestProductSize, 
				CASE
					WHEN LPOINT.LocationId = BPB.DestinationHubLocationId AND BPB.DestinationProductSize IS NULL THEN 1
					WHEN LPOINT.LocationId = BPB.LoadSiteLocationId AND BPB.SourceProductSize IS NULL THEN 1
					ELSE 0
				END As DefaultProductSize,
				CASE 
					WHEN LPOINT.LocationId = BPB.DestinationHubLocationId THEN ISNULL(defaultlf.[Percent], 1) * Tonnes 
					ELSE ISNULL(defaultlf.[Percent], 1) * -Tonnes 
				END AS Tonnes,
				Fe.GradeValue As Fe, P.GradeValue As P, SiO2.GradeValue As SiO2, Al2O3.GradeValue As Al2O3, LOI.GradeValue As LOI,
				LS.Name As LoadSite, DH.Name As DestinationHub, MH.Name As MoveHub,
				BPB.GeometMovementType as IsIntegral
			FROM dbo.GetBhpbioPortBlendingForGeomet(@iDateFrom, @iDateTo) AS BPB
				INNER JOIN @Location AS LPOINT
					ON (LPOINT.LocationId = BPB.DestinationHubLocationId
						OR LPOINT.LocationId = BPB.LoadSiteLocationId)
					AND (BPB.StartDate BETWEEN LPOINT.IncludeStart AND LPOINT.IncludeEnd)
					AND LPOINT.LocationId NOT IN (SELECT LocationId FROM GetBhpbioExcludeHubLocation('PortBlending'))
				INNER JOIN dbo.Location AS MH
					ON (MH.Location_Id = BPB.SourceHubLocationId)
					AND MH.Location_Id NOT IN (SELECT LocationId FROM GetBhpbioExcludeHubLocation('PortBlending'))
				INNER JOIN dbo.Location AS DH
					ON (DH.Location_Id = BPB.DestinationHubLocationId)
					AND DH.Location_Id NOT IN (SELECT LocationId FROM GetBhpbioExcludeHubLocation('PortBlending'))
				LEFT JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf
					ON BPB.SourceProductSize IS NULL
					AND BPB.LoadSiteLocationId = defaultlf.LocationId
					AND BPB.EndDate BETWEEN defaultlf.StartDate AND defaultlf.EndDate
				INNER JOIN dbo.Location AS LS
					ON (LS.Location_Id = BPB.LoadSiteLocationId)
				LEFT JOIN dbo.BhpbioPortBlendingGrade AS FE
					ON (FE.GradeId = 1 AND FE.BhpbioPortBlendingId = BPB.BhpbioPortBlendingId)
				LEFT JOIN dbo.BhpbioPortBlendingGrade AS P
					ON (P.GradeId = 2 AND P.BhpbioPortBlendingId = BPB.BhpbioPortBlendingId)
				LEFT JOIN dbo.BhpbioPortBlendingGrade AS SiO2
					ON (SiO2.GradeId = 3 AND SiO2.BhpbioPortBlendingId = BPB.BhpbioPortBlendingId)
				LEFT JOIN dbo.BhpbioPortBlendingGrade AS Al2O3
					ON (Al2O3.GradeId = 4 AND Al2O3.BhpbioPortBlendingId = BPB.BhpbioPortBlendingId)
				LEFT JOIN dbo.BhpbioPortBlendingGrade AS LOI
					ON (LOI.GradeId = 5 AND LOI.BhpbioPortBlendingId = BPB.BhpbioPortBlendingId)
			WHERE (BPB.StartDate >= @iDateFrom AND BPB.EndDate <= DateAdd(Second, 59, DateAdd(Minute, 59, DateAdd(Hour, 23, @iDateTo))))
				AND (@iProductSize IS NULL 
					OR ISNULL(CASE WHEN BPB.DestinationHubLocationId = LPOINT.LocationId THEN BPB.DestinationProductSize ELSE BPB.SourceProductSize END, defaultlf.ProductSize) = @iProductSize)
		END
		ELSE IF @iTagId LIKE '%PortStockpileDelta'
		BEGIN
			INSERT INTO @Location
				(LocationId, ParentLocationId,IncludeStart,IncludeEnd)
			SELECT LocationId, ParentLocationId,IncludeStart,IncludeEnd
			FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 0, 'HUB',@iDateFrom,@iDateTo)
		
			SELECT	HL.Name As HubLocation, 
					ISNULL(defaultlf.[Percent], 1) * BPB.Tonnes As Tonnes, 
					BPB.BalanceDate, 
					ISNULL(BPB.ProductSize, defaultlf.ProductSize) As ProductSize,
					CASE WHEN BPB.ProductSize IS NULL THEN 1 ELSE 0 END As DefaultProductSize,
					ISNULL(defaultlfprev.[Percent], 1) * BPBPREV.Tonnes As PreviousTonnes,
					BPBPREV.BalanceDate As PreviousDate,
					(ISNULL(defaultlf.[Percent], 1) * BPB.Tonnes) - (ISNULL(defaultlfprev.[Percent], 1) * BPBPREV.Tonnes) As DeltaTonnes
			FROM	dbo.BhpbioPortBalance AS BPB
			INNER JOIN dbo.Location AS HL
				ON	HL.Location_Id = BPB.HubLocationId
				AND BPB.HubLocationId NOT IN (SELECT LocationId FROM GetBhpbioExcludeHubLocation('PortBalance'))
			INNER JOIN @Location AS FL
				ON	HL.Location_Id = FL.LocationId
				AND BPB.BalanceDate BETWEEN FL.IncludeStart AND FL.IncludeEnd
			LEFT JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf
				ON BPB.ProductSize IS NULL
				AND BPB.HubLocationId = defaultlf.LocationId
				AND BPB.BalanceDate BETWEEN defaultlf.StartDate AND defaultlf.EndDate
			LEFT JOIN dbo.BhpbioPortBalance AS BPBPREV
				ON BPBPREV.BalanceDate = DateAdd(Day, -1, Cast(Year(BPB.BalanceDate) AS Varchar) + '-' + Cast(Month(BPB.BalanceDate) AS Varchar) + '-1' )
				AND BPB.HubLocationId = BPBPREV.HubLocationId
				AND	(BPBPREV.ProductSize = ISNULL(BPB.ProductSize, defaultlf.ProductSize) OR BPBPREV.ProductSize IS NULL)
			LEFT JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlfprev
				ON BPBPREV.ProductSize IS NULL
				AND BPBPREV.HubLocationId = defaultlfprev.LocationId
				AND BPBPREV.BalanceDate BETWEEN defaultlfprev.StartDate AND defaultlfprev.EndDate
				AND defaultlfprev.ProductSize = ISNULL(BPB.ProductSize, defaultlf.ProductSize)
			WHERE BPB.BalanceDate BETWEEN @iDateFrom AND @iDateTo
				AND (@iProductSize IS NULL OR ISNULL(BPB.ProductSize, defaultlf.ProductSize) = @iProductSize)
			
		END
		
		-- SElect * from dbo.BhpbioReportDataTags
		-- select * from grade

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

GRANT EXECUTE ON dbo.GetBhpbioReportDataReview TO BhpbioGenericManager
GO
