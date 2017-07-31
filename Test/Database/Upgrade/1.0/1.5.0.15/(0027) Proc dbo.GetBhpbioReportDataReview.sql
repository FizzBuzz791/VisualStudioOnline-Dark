IF OBJECT_ID('dbo.GetBhpbioReportDataReview') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportDataReview
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReportDataReview 
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iLocationId INT,
	@iTagId VARCHAR(124)
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

	DECLARE @StockpileDeltaHub TABLE
	(
		StockpileId INT NOT NULL,
		WeightometerSampleId INT NOT NULL,
		Tonnes FLOAT NOT NULL,
		LocationId INT NULL,
		Addition BIT NOT NULL,
		Hub VARCHAR(31) COLLATE DATABASE_DEFAULT
	)
	
	DECLARE @StockpileDeltaSite TABLE
	(
		StockpileId INT NOT NULL,
		WeightometerSampleId INT NOT NULL,
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
	
	SET @SampleTonnesField = 'SampleTonnes'
	SET @SampleSourceField = 'SampleSource'
	
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		ParentLocationId INT NULL,
		PRIMARY KEY (LocationId)
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

		INSERT INTO @Location
			(LocationId)
		SELECT LocationId
		FROM dbo.GetBhpbioReportLocation(@iLocationId)
		
		INSERT INTO @HighGradeStockpileGroup
			(StockpileGroupId, MaterialTypeId)
		SELECT SGD.StockpileGroupId, MT.Material_Type_Id
		FROM dbo.MaterialType AS MT
			INNER JOIN dbo.BhpbioStockpileGroupDesignation AS SGD
				ON (MT.Material_Type_Id = SGD.MaterialTypeId)
		WHERE MT.Material_Category_Id = @MaterialCategory
			AND MT.Material_Type_Id IN (Select MaterialTypeId FROM dbo.GetBhpbioReportHighGrade())
			

		IF @iTagId LIKE '%MODEL'
		BEGIN
			SELECT BM.Name,  
				RM.DateFrom, RM.DateTo, MT.Description As MaterialType, MinedPercentage, MBP.Tonnes As BlockTonnes, 
				MBP.Tonnes * MinedPercentage As TonnesMoved, 
				Fe.Grade_Value As Fe, P.Grade_Value As P, SiO2.Grade_Value As SiO2, 
				Al2O3.Grade_Value As Al2O3, LOI.Grade_Value As LOI,
				RM.BlockNumber, RM.BlockName, RM.Site, RM.OreBody, RM.Pit, RM.Bench, RM.PatternNumber
			FROM dbo.BhpbioImportReconciliationMovement AS RM
				INNER JOIN @Location AS L
					ON (L.LocationId = RM.BlockLocationId)
				INNER JOIN dbo.ModelBlockLocation AS MBL
					ON (L.LocationId = MBL.Location_Id)
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
			WHERE (RM.DateFrom >= @iDateFrom
				AND RM.DateTo <= @iDateTo)
				AND (CASE WHEN @iTagId Like '%GeologyModel%' AND BM.Name <> 'Geology' THEN 0
					 WHEN @iTagId Like '%MiningModel%' AND BM.Name <> 'Mining' THEN 0
					 WHEN @iTagId Like '%GradeControlModel%' AND BM.Name <> 'Grade Control' THEN 0
					 ELSE 1 END = 1)
		END
		ELSE IF @iTagId LIKE '%MineProductionActuals' --C
		BEGIN
		
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
				PRIMARY KEY (WeightometerSampleId, CalendarDate)
			)
		
		
		-- retrieve the list of Weightometer Records to be used in the calculations
		INSERT INTO @Weightometer
			(CalendarDate, DateFrom, DateTo, WeightometerSampleId, ParentLocationId, RealTonnes, SampleTonnes, DesignationMaterialTypeId)
		SELECT b.CalendarDate, b.DateFrom, b.DateTo, w.WeightometerSampleId, LocationId,
			-- calculate the REAL tonnes
			CASE
				WHEN w.UseAsRealTonnes = 1
					THEN ISNULL(ws.Corrected_Tonnes, ws.Tonnes)
				ELSE 0.0
			END AS RealTonnes,
			-- calculate the SAMPLE tonnes
			-- if a sample tonnes hasn't been provided then use the actual tonnes recorded for the transaction
			-- not all flows will have this recorded (in particular CVF corrected plant balanced records)
			CASE BeneFeed
				WHEN 1 THEN ISNULL(ws.Corrected_Tonnes, ws.Tonnes)
				ELSE ISNULL(wsv.Field_Value, 0.0)
			END AS SampleTonnes,
			-- return the Material Type based on whether it is bene feed
			CASE w.BeneFeed
				WHEN 1 THEN @BeneFeedMaterialTypeId
				WHEN 0 THEN @HighGradeMaterialTypeId
			END AS MaterialTypeId
		FROM dbo.GetBhpbioReportBreakdown(NULL, @iDateFrom, @iDateTo, 1) AS b
			INNER JOIN dbo.WeightometerSample AS ws
				ON (ws.Weightometer_Sample_Date BETWEEN b.DateFrom AND b.DateTo)
			INNER JOIN
				(
					-- collect the weightometer sample id's for all movements from the crusher
					-- these are used to ease lookup and ensure uniqueness of the weightometer_sample_ids returned
					SELECT dttf.Weightometer_Sample_Id AS WeightometerSampleId, 1 AS UseAsRealTonnes,
						CASE
							WHEN m.Mill_Id IS NOT NULL
								THEN 1
							ELSE 0
						END AS BeneFeed
					FROM dbo.DataTransactionTonnes AS dtt
						INNER JOIN dbo.DataTransactionTonnesFlow AS dttf
							ON (dttf.Data_Transaction_Tonnes_Id = dtt.Data_Transaction_Tonnes_Id)
						INNER JOIN dbo.CrusherLocation AS cl
							ON (dttf.Source_Crusher_Id = cl.Crusher_Id)
						LEFT JOIN dbo.Mill AS m
							ON (dttf.Destination_Stockpile_Id = m.Stockpile_Id)
						INNER JOIN @Location AS l
							ON (cl.Location_Id = l.LocationId)
					WHERE dtt.Data_Transaction_Tonnes_Date BETWEEN @iDateFrom AND @iDateTo
						AND dttf.Destination_Crusher_Id IS NULL  -- ignore crusher to crusher feeds
					GROUP BY dttf.Weightometer_Sample_Id, m.Mill_Id
					UNION 
					-- collect weightometer sample id's for all movements to train rakes
					-- (by definition it's always delivers to train rake stockpiles...
					--  the grades (but not the tonnes) from these weightometers samples are important to us)
					SELECT dttf.Weightometer_Sample_Id, 0, 0
					FROM dbo.DataTransactionTonnes AS dtt
						INNER JOIN dbo.DataTransactionTonnesFlow AS dttf
							ON (dttf.Data_Transaction_Tonnes_Id = dtt.Data_Transaction_Tonnes_Id)
						INNER JOIN dbo.WeightometerSample AS ws
							ON (dttf.Weightometer_Sample_Id = ws.Weightometer_Sample_Id)
						INNER JOIN dbo.StockpileGroupStockpile AS sgs
							ON (sgs.Stockpile_Id = dttf.Destination_Stockpile_Id)
						INNER JOIN dbo.WeightometerLocation AS wl
							ON (ws.Weightometer_Id = wl.Weightometer_Id)
						INNER JOIN @Location AS l
							ON (wl.Location_Id = l.LocationId)
					WHERE dtt.Data_Transaction_Tonnes_Date BETWEEN @iDateFrom AND @iDateTo
						AND sgs.Stockpile_Group_Id = 'Port Train Rake'
					GROUP BY dttf.Weightometer_Sample_Id
				  ) AS w
				ON (ws.Weightometer_Sample_Id = w.WeightometerSampleId)
				-- ensure the weightometer belongs to the required location
			INNER JOIN dbo.WeightometerLocation AS wl
				ON (wl.Weightometer_Id = ws.Weightometer_Id)
			INNER JOIN @Location AS l
				ON (l.LocationId = wl.Location_Id)
			LEFT OUTER JOIN dbo.WeightometerSampleValue AS wsv
				ON (ws.Weightometer_Sample_Id = wsv.Weightometer_Sample_Id
					AND wsv.Weightometer_Sample_Field_Id = @SampleTonnesField)


		SELECT WS.Weightometer_Id, WeightometerSampleId, Weightometer_Sample_Date, MT.Description, WFP.Source_Crusher_Id,
			SampleTonnes, RealTonnes, SampleSource, Fe, P, SiO2, Al2O3, LOI, ParentLocationId, S.Stockpile_Name AS Destination_Stockpile
		FROM (
			SELECT WeightometerSampleId, DesignationMaterialTypeId, ParentLocationId, NULL As SampleTonnes, RealTonnes, NULL As SampleSource, NULL AS Fe, NULL AS P, NULL AS SiO2, NULL As Al2O3, NULL As LOI
			FROM @Weightometer
			WHERE RealTonnes <> 0
			UNION ALL
			SELECT W.WeightometerSampleId, w.DesignationMaterialTypeId,
				w.ParentLocationId, w.SampleTonnes, NULL, sSource.SampleSource, 
				Fe.Grade_Value As Fe, P.Grade_Value As P, SiO2.Grade_Value As SiO2, Al2O3.Grade_Value As Al2O3, LOI.Grade_Value As LOI
				
				
			FROM @Weightometer AS w
				-- check the membership with the Sample Source
				LEFT OUTER JOIN
					(
						SELECT ws.Weightometer_Sample_Id, ss.SampleSource
						FROM dbo.WeightometerSample AS ws
							INNER JOIN dbo.WeightometerLocation AS wl
								ON (ws.Weightometer_Id = wl.Weightometer_Id)
							INNER JOIN dbo.WeightometerSampleNotes AS wsn
								ON (wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
									AND wsn.Weightometer_Sample_Field_Id = @SampleSourceField)
							INNER JOIN dbo.GetBhpbioWeightometerSampleSource(@iLocationId, @iDateFrom, @iDateTo) AS ss
								ON (dbo.GetDateMonth(ws.Weightometer_Sample_Date) = ss.MonthPeriod
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
				LEFT JOIN dbo.WeightometerFlowPeriod AS WFP
					ON (WFP.Weightometer_Id = WS.Weightometer_Id)
				LEFT JOIN dbo.Stockpile AS S
					ON (S.Stockpile_Id = ws.Destination_Stockpile_Id)
					
		END
		ELSE IF @iTagId LIKE '%ExPitToOreStockpile' --y
		BEGIN
			SELECT H.Haulage_Id, H.Haulage_Date, H.Tonnes, S.Stockpile_Name As Destination_Stockpile, 
				Fe.Grade_Value As Fe, P.Grade_Value As P, SiO2.Grade_Value As SiO2, Al2O3.Grade_Value As Al2O3, LOI.Grade_Value As LOI,
				SGS.Stockpile_Group_Id AS Destination_Stockpile_Group, H.Source_Digblock_Id,
				L.LocationId As Location_Id --, '--' As [--], *
			FROM dbo.Haulage AS H
				INNER JOIN dbo.DigblockLocation AS DL
					ON (DL.Digblock_Id = H.Source_Digblock_Id)
				INNER JOIN @Location AS L
					ON (L.LocationId = DL.Location_Id)
				INNER JOIN dbo.Stockpile AS S
					ON (H.Destination_Stockpile_Id = S.Stockpile_Id)
				INNER JOIN dbo.StockpileGroupStockpile AS SGS
					ON (SGS.Stockpile_Id = S.Stockpile_Id)
				INNER JOIN @HighGradeStockpileGroup AS HGSG
					ON (SGS.Stockpile_Group_Id = HGSG.StockpileGroupId)
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
				WHERE H.Haulage_Date >= @iDateFrom AND H.Haulage_Date <= @iDateTo
					AND H.Source_Digblock_Id IS NOT NULL
					AND h.Haulage_State_Id IN ('N', 'A')
					AND h.Child_Haulage_Id IS NULL
		END
		ELSE IF @iTagId LIKE '%StockpileToCrusher' -- z
		BEGIN
			SELECT H.Haulage_Id, H.Haulage_Date, H.Tonnes, 
				Fe.Grade_Value As Fe, P.Grade_Value As P, SiO2.Grade_Value As SiO2, Al2O3.Grade_Value As Al2O3, LOI.Grade_Value As LOI,
				H.Destination_Crusher_Id, MT.Material_Type_Id, MT.Description,
				L.LocationId As Location_Id, WFPV.Destination_Mill_Id
			FROM dbo.Haulage AS H
				INNER JOIN dbo.Crusher AS C
					ON (C.Crusher_Id = H.Destination_Crusher_Id)
				INNER JOIN dbo.CrusherLocation AS CL
					ON (CL.Crusher_Id = C.Crusher_Id)
				INNER JOIN @Location AS L
					ON (L.LocationId = CL.Location_Id)
				LEFT JOIN dbo.WeightometerFlowPeriodView AS WFPV
					ON (WFPV.Source_Crusher_Id = c.Crusher_Id
						AND WFPV.Destination_Mill_Id IS NOT NULL
						AND (@iDateTo > WFPV.Start_Date Or WFPV.Start_Date IS NULL)
						AND (@iDateFrom < WFPV.End_Date Or WFPV.End_Date IS NULL))
				LEFT JOIN dbo.Weightometer AS W
					ON (W.Weightometer_Id = WFPV.Weightometer_Id)
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
			WHERE H.Haulage_Date >= @iDateFrom AND H.Haulage_Date <= @iDateTo
				AND h.Haulage_State_Id IN ('N', 'A')
				AND h.Child_Haulage_Id IS NULL
				AND (W.Weightometer_Type_Id LIKE '%L1%' OR W.Weightometer_Type_Id IS NULL)
				AND h.Source_Stockpile_Id IS NOT NULL
				
		END
		ELSE IF @iTagId LIKE '%OreShipped'
		BEGIN
			Select L.Name As LocationName, S.OfficialFinishTime AS CalendarDate, S.Tonnes, S.ProductCode, 
			S.CustomerNo, L.Location_Id, Fe.GradeValue As Fe, P.GradeValue As P, SiO2.GradeValue As SiO2, 
			Al2O3.GradeValue As Al2O3, LOI.GradeValue As LOI --, '--' As [--], *
			From dbo.BhpbioShippingTransactionNomination AS S
				INNER JOIN dbo.Location AS L
					ON L.Location_Id = S.HubLocationId
				INNER JOIN @Location AS FL
					ON L.Location_Id = FL.LocationId
				LEFT JOIN dbo.BhpbioShippingTransactionNominationGrade AS FE
					ON (FE.GradeId = 1 AND FE.BhpbioShippingTransactionNominationId = S.BhpbioShippingTransactionNominationId)
				LEFT JOIN dbo.BhpbioShippingTransactionNominationGrade AS P
					ON (P.GradeId = 2 AND P.BhpbioShippingTransactionNominationId = S.BhpbioShippingTransactionNominationId)
				LEFT JOIN dbo.BhpbioShippingTransactionNominationGrade AS SiO2
					ON (SiO2.GradeId = 3 AND SiO2.BhpbioShippingTransactionNominationId = S.BhpbioShippingTransactionNominationId)
				LEFT JOIN dbo.BhpbioShippingTransactionNominationGrade AS Al2O3
					ON (Al2O3.GradeId = 4 AND Al2O3.BhpbioShippingTransactionNominationId = S.BhpbioShippingTransactionNominationId)
				LEFT JOIN dbo.BhpbioShippingTransactionNominationGrade AS LOI
					ON (LOI.GradeId = 5 AND LOI.BhpbioShippingTransactionNominationId = S.BhpbioShippingTransactionNominationId)
			WHERE S.OfficialFinishTime BETWEEN @iDateFrom AND DateAdd(Second, 59, DateAdd(Minute, 59, DateAdd(Hour, 23, @iDateTo)))
			Order By S.OfficialFinishTime
		END
		ELSE IF @iTagId LIKE '%HubPostCrusherStockpileDelta'
		BEGIN
			
			DELETE FROM @Location
		
			INSERT INTO @Location
				(LocationId, ParentLocationId)
			SELECT LocationId, ParentLocationId
			FROM dbo.GetBhpbioReportLocationBreakdown(@iLocationId, 0, 'site')
		
			SELECT @HubLocationTypeId = Location_Type_Id
			FROM dbo.LocationType
			WHERE Description = 'Hub'
			SELECT @SiteLocationTypeId = Location_Type_Id
			FROM dbo.LocationType
			WHERE Description = 'Site'

			SET @StockpileGroupId = 'Post Crusher'
			-- Get Removals
			INSERT INTO @StockpileDeltaHub
				(StockpileId, WeightometerSampleId, Addition, Tonnes,Hub)		
			SELECT S.Stockpile_Id, WS.Weightometer_Sample_Id, 0, WS.Tonnes, LL.Description
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
				LEFT JOIN dbo.BhpbioLocationStockpileConfiguration AS BSLC
					ON (BSLC.LocationId = SL.Location_Id)
				INNER JOIN dbo.Location AS LL
					ON (LL.Location_Id = L.LocationId)
				LEFT JOIN dbo.StockpileGroupStockpile SGS_D
					ON (SGS_D.Stockpile_Id = WS.Destination_Stockpile_Id
						AND SGS_D.Stockpile_Group_Id = @StockpileGroupId)
			WHERE Coalesce(WS.Source_Stockpile_Id, -1) <> Coalesce(WS.Destination_Stockpile_Id, -1)
				AND SGS.Stockpile_Group_Id = @StockpileGroupId
				AND SGS_D.Stockpile_Group_Id IS NULL
				AND WS.Weightometer_Sample_Date BETWEEN @iDateFrom AND @iDateTo
							AND (LL.Location_Type_Id = @HubLocationTypeId OR
			(BSLC.PromoteStockpiles = 1 AND LL.Location_Type_Id = @SiteLocationTypeId))
			-- Get Additions
			INSERT INTO @StockpileDeltaHub
				(StockpileId, WeightometerSampleId, Addition, Tonnes,Hub)		
			SELECT S.Stockpile_Id, WS.Weightometer_Sample_ID, 1, WS.Tonnes, LL.Description
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
				LEFT JOIN dbo.BhpbioLocationStockpileConfiguration AS BSLC
					ON (BSLC.LocationId = SL.Location_Id)
				INNER JOIN dbo.Location AS LL
					ON (LL.Location_Id = L.LocationId)
				LEFT JOIN dbo.StockpileGroupStockpile SGS_S
					ON (SGS_S.Stockpile_Id = WS.Source_Stockpile_Id
						AND SGS_S.Stockpile_Group_Id = @StockpileGroupId)
			WHERE Coalesce(WS.Source_Stockpile_Id, -1) <> Coalesce(WS.Destination_Stockpile_Id, -1)
				AND SGS.Stockpile_Group_Id = @StockpileGroupId
				AND WS.Weightometer_Sample_Date BETWEEN @iDateFrom AND @iDateTo
				AND SGS_S.Stockpile_Group_Id IS NULL
							AND (LL.Location_Type_Id = @HubLocationTypeId OR
			(BSLC.PromoteStockpiles = 1 AND LL.Location_Type_Id = @SiteLocationTypeId))

			SELECT SD.WeightometerSampleId, WS.Weightometer_Sample_Date, CASE WHEN SD.Addition = 1 THEN SD.Tonnes ELSE -SD.Tonnes END AS MovementTonnes, 
				NULL As SampleTonnes, NULL As Fe, NULL As P, NULL As SiO2, NULL As Al2O3, NULL As LOI,
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
			UNION ALL
			SELECT ws.Weightometer_Sample_Id, WS.Weightometer_Sample_Date, NULL AS MovementTonnes, WSV.Field_Value As SampleTonnes,
				Fe.Grade_Value As Fe, P.Grade_Value As P, SiO2.Grade_Value As SiO2, Al2O3.Grade_Value As Al2O3, LOI.Grade_Value As LOI,
				NULL, LL.Description, WFPV.Source_Crusher_Id, WFPV.Source_Mill_Id As SourcePlant, SS.Stockpile_Name AS SourceStockpile, WFPV.Destination_Crusher_Id As DestinationCrusher, WFPV.Destination_Mill_Id As DestinationPlant, DS.Stockpile_Name AS DestinationStockpile
			FROM dbo.WeightometerSample AS ws
				INNER JOIN dbo.WeightometerLocation AS wl
					ON (ws.Weightometer_Id = wl.Weightometer_Id)
				INNER JOIN @Location AS L
					ON (L.LocationId = wl.Location_Id)
				INNER JOIN dbo.WeightometerSampleNotes AS wsn
					ON (wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
						AND wsn.Weightometer_Sample_Field_Id = @SampleSourceField)
			INNER JOIN dbo.WeightometerSampleValue AS wsv
				ON (wsv.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
					AND wsv.Weightometer_Sample_Field_Id = @SampleTonnesField)
				INNER JOIN dbo.GetBhpbioWeightometerSampleSource(@iLocationId, @iDateFrom, @iDateTo) AS wss
					ON (dbo.GetDateMonth(ws.Weightometer_Sample_Date) = wss.MonthPeriod
						AND L.LocationId = wss.LocationId
							AND wsn.Notes = wss.SampleSource)
				INNER JOIN dbo.Location AS LL
					ON (LL.Location_Id = L.LocationId)
				LEFT JOIN dbo.BhpbioLocationStockpileConfiguration AS BSLC
					ON (BSLC.LocationId = L.LocationId)
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
				LEFT JOIN dbo.WeightometerFlowPeriodView AS WFPV
					ON (WFPV.Weightometer_Id = WS.Weightometer_Id
						AND (WS.Weightometer_Sample_Date > WFPV.Start_Date Or WFPV.Start_Date IS NULL)
						AND (WS.Weightometer_Sample_Date < WFPV.End_Date Or WFPV.End_Date IS NULL))	
				LEFT JOIN dbo.Stockpile AS SS
					ON (WS.Source_Stockpile_Id = SS.Stockpile_Id)
				LEFT JOIN dbo.Stockpile AS DS
					ON (WS.Destination_Stockpile_Id = DS.Stockpile_Id)
			WHERE (LL.Location_Type_Id = @HubLocationTypeId OR 
				(BSLC.PromoteStockpiles = 1 AND LL.Location_Type_Id = @SiteLocationTypeId))
				AND Fe.Grade_Value IS NOT NULL
					
		END
		ELSE IF @iTagId LIKE '%SitePostCrusherStockpileDelta'
		BEGIN
			SET @StockpileGroupId = 'Post Crusher'
			SELECT @HubLocationTypeId = Location_Type_Id
			FROM dbo.LocationType
			WHERE Description = 'Hub'
			SELECT @SiteLocationTypeId = Location_Type_Id
			FROM dbo.LocationType
			WHERE Description = 'Site'
			
			-- Get Removals
			INSERT INTO @StockpileDeltaSite
				(StockpileId, WeightometerSampleId, Addition, Tonnes,Site)		
			SELECT S.Stockpile_Id, WS.Weightometer_Sample_Id, 0, WS.Tonnes, LL.Description
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
				LEFT JOIN dbo.BhpbioLocationStockpileConfiguration AS BSLC
					ON (BSLC.LocationId = SL.Location_Id)
				INNER JOIN dbo.Location AS LL
					ON (LL.Location_Id = L.LocationId)
				LEFT JOIN dbo.StockpileGroupStockpile SGS_D
					ON (SGS_D.Stockpile_Id = WS.Destination_Stockpile_Id
						AND SGS_D.Stockpile_Group_Id = @StockpileGroupId)
			WHERE Coalesce(WS.Source_Stockpile_Id, -1) <> Coalesce(WS.Destination_Stockpile_Id, -1)
				AND SGS.Stockpile_Group_Id = @StockpileGroupId
				AND SGS_D.Stockpile_Group_Id IS NULL
				AND WS.Weightometer_Sample_Date BETWEEN @iDateFrom AND @iDateTo			
				AND (LL.Location_Type_Id = @SiteLocationTypeId AND
			(BSLC.PromoteStockpiles = 0 OR BSLC.PromoteStockpiles IS NULL))
				AND WS.Weightometer_Id NOT LIKE '%Raw%'
			
			-- Get Additions
			INSERT INTO @StockpileDeltaSite
				(StockpileId, WeightometerSampleId, Addition, Tonnes, Site)		
			SELECT S.Stockpile_Id, WS.Weightometer_Sample_ID, 1, WS.Tonnes, LL.Description
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
				LEFT JOIN dbo.BhpbioLocationStockpileConfiguration AS BSLC
					ON (BSLC.LocationId = SL.Location_Id)
				INNER JOIN dbo.Location AS LL
					ON (LL.Location_Id = L.LocationId)
				LEFT JOIN dbo.StockpileGroupStockpile SGS_S
					ON (SGS_S.Stockpile_Id = WS.Source_Stockpile_Id
						AND SGS_S.Stockpile_Group_Id = @StockpileGroupId)
			WHERE Coalesce(WS.Source_Stockpile_Id, -1) <> Coalesce(WS.Destination_Stockpile_Id, -1)
				AND SGS.Stockpile_Group_Id = @StockpileGroupId
				AND WS.Weightometer_Sample_Date BETWEEN @iDateFrom AND @iDateTo
				AND SGS_S.Stockpile_Group_Id IS NULL				
				AND (LL.Location_Type_Id = @SiteLocationTypeId AND
				(BSLC.PromoteStockpiles = 0 OR BSLC.PromoteStockpiles IS NULL))
				AND WS.Weightometer_Id NOT LIKE '%Raw%'

			SELECT SD.WeightometerSampleId, WS.Weightometer_Sample_Date, CASE WHEN SD.Addition = 1 THEN SD.Tonnes ELSE -SD.Tonnes END AS MovementTonnes, 
				Fe.Grade_Value As Fe, P.Grade_Value As P, SiO2.Grade_Value As SiO2, Al2O3.Grade_Value As Al2O3, LOI.Grade_Value As LOI,
				SD.Addition, SD.Site, WFPV.Source_Crusher_Id, DS.Stockpile_Name AS DestinationStockpile, SS.Stockpile_Name AS SourceStockpile --, DS.Stockpile_Name AS DestinationStockpile, S.Stockpile_Name, DTTF.Source_Crusher_Id, NULL AS Source_Stockpile_Name
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
				LEFT JOIN dbo.WeightometerFlowPeriodView AS WFPV
					ON (WFPV.Weightometer_Id = WS.Weightometer_Id
						AND (WS.Weightometer_Sample_Date > WFPV.Start_Date Or WFPV.Start_Date IS NULL)
						AND (WS.Weightometer_Sample_Date < WFPV.End_Date Or WFPV.End_Date IS NULL))	
				LEFT JOIN dbo.Stockpile AS SS
					ON (WS.Source_Stockpile_Id = SS.Stockpile_Id)
				LEFT JOIN dbo.Stockpile AS DS
					ON (WS.Destination_Stockpile_Id = DS.Stockpile_Id)
					
		END
		ELSE IF @iTagId LIKE '%PortBlendedAdjustment'
		BEGIN
			Select BPB.StartDate, BPB.EndDate, --Tonnes,
				CASE WHEN LPOINT.LocationId = BPB.DestinationHubLocationId THEN Tonnes ELSE -Tonnes END AS Tonnes,
				Fe.GradeValue As Fe, P.GradeValue As P, SiO2.GradeValue As SiO2, Al2O3.GradeValue As Al2O3, LOI.GradeValue As LOI,
				LS.Name As LoadSite, DH.Name As DestinationHub, MH.Name As MoveHub, RH.Name AS RakeHub--, '--' As [--], *
			FROM dbo.BhpbioPortBlending AS BPB
				INNER JOIN @Location AS LPOINT
					ON (LPOINT.LocationId = BPB.DestinationHubLocationId
						OR LPOINT.LocationId = BPB.LoadSiteLocationId)
				INNER JOIN dbo.Location AS MH
					ON (MH.Location_Id = BPB.MoveHubLocationId)
				INNER JOIN dbo.Location AS DH
					ON (DH.Location_Id = BPB.DestinationHubLocationId)
				INNER JOIN dbo.Location AS RH
					ON (RH.Location_Id = BPB.RakeHubLocationId)
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
			--	AND (BPB.MoveHubLocationId <> BPB.DestinationHubLocationId)
		END
		ELSE IF @iTagId LIKE '%PortStockpileDelta'
		BEGIN
			SELECT HL.Name As HubLocation, BPB.Tonnes, BPB.BalanceDate, 
			 BPBPREV.Tonnes As PreviousTonnes, BPBPREV.BalanceDate As PreviousDate,
			 BPB.Tonnes - BPBPREV.Tonnes As DeltaTonnes
			FROM dbo.BhpbioPortBalance AS BPB
			 INNER JOIN dbo.Location AS HL
			  ON HL.Location_Id = BPB.HubLocationId
			INNER JOIN @Location AS FL
				ON HL.Location_Id = FL.LocationId
			LEFT JOIN dbo.BhpbioPortBalance AS BPBPREV
				ON (BPBPREV.BalanceDate = DateAdd(Day, -1, Cast(Year(BPB.BalanceDate) AS Varchar) + '-' + Cast(Month(BPB.BalanceDate) AS Varchar) + '-1' )
					And BPB.HubLocationId = BPBPREV.HubLocationId)
			WHERE BPB.BalanceDate BETWEEN @iDateFrom AND @iDateTo
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

--EXEC dbo.GetBhpbioReportDataReview '1-may-2008', '31-may-2008', null, 'PostCrusherStockpileDelta'
--EXEC dbo.GetBhpbioReportDataReview '1-may-2008', '31-may-2008', null, 'ExPitToOreStockpile'
--EXEC dbo.GetBhpbioReportDataReview '1-may-2005', '31-may-2008', null, 'PortBlendedAdjustment'
--EXEC dbo.GetBhpbioReportDataReview '1-apr-2005', '30-apr-2008', 6, 'StockpileToCrusher'

--EXEC dbo.GetBhpbioReportDataReview '1-may-2005', '31-may-2008', 3, 'MineProductionActuals'
