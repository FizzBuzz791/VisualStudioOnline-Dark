IF OBJECT_ID('dbo.GetBhpbioReportDataBlockModel') IS NOT NULL
	DROP PROCEDURE dbo.GetBhpbioReportDataBlockModel
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReportDataBlockModel
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iChildLocations BIT,
	@iBlockModelName VARCHAR(250),
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT,
	@iIncludeInactiveChildLocations BIT = 0,
	@iIncludeLumpFines BIT = 1,
	@iHighGradeOnly BIT = 1,
	@iIncludeResourceClassification Bit = 0,
	@iUseRemainingMaterialAtDateFrom BIT = 0,
	@iOverrideChildLocationType VARCHAR(31) = NULL,
	@iGeometType Varchar(63) = 'As-Shipped',
	@iLowestStratLevel Int = 0, -- 0 is equivalent to no stratigraphy grouping
	@iIncludeWeathering Bit = 0
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	
	DECLARE @modelApprovalTagId VARCHAR(63)
	DECLARE @BlockModelId INT
	DECLARE @MaterialCategory VARCHAR(31)
	SET @MaterialCategory = 'Designation'
	
	DECLARE @DigblockNoteField_Strat VARCHAR(31) = 'StratId'
	DECLARE @DigblockNoteField_Weathering VARCHAR(31) = 'Weathering'
	
	CREATE TABLE #TonnesTable
	(
		BlockModelId INT NULL,
		BlockModelName VARCHAR(31) NULL,
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		MaterialTypeId INT NOT NULL,
		ParentLocationId INT NULL,
		ProductSize VARCHAR(5) NULL,
		ResourceClassification VARCHAR(32) NULL,
		Tonnes FLOAT NOT NULL,
		Volume FLOAT NULL,
		Strat VARCHAR(7) NULL,
		StratLevel INT NULL,
		StratLevelName VARCHAR(20) NULL,
		Weathering INT NULL
	)
	
	CREATE TABLE #GradesTable
	(
		BlockModelId INT NULL,
		BlockModelName VARCHAR(31) NULL,
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		MaterialTypeId INT NOT NULL,
		ParentLocationId INT NULL,
		GradeId INT NOT NULL,
		GradeValue FLOAT NOT NULL,
		ProductSize VARCHAR(5) NULL,
		ResourceClassification VARCHAR(32) NULL,
		Tonnes FLOAT NOT NULL,
		Strat VARCHAR(7) NULL,
		StratLevel INT NULL,
		StratLevelName VARCHAR(20) NULL,
		Weathering INT NULL
	)
	
	CREATE TABLE #productsize
	(
		ProductSize VARCHAR(5) PRIMARY KEY
	)
	
	CREATE TABLE #BlockWithSummary(
		BlockModelId INTEGER,
		ModelName VARCHAR(31),
		CalendarDate DATETIME,
		DateFrom DATETIME,
		DateTo DATETIME,
		SummaryEntryId INTEGER,
		MaterialTypeID INTEGER,
		UnderlyingMaterialTypeId INTEGER,
		ParentLocationId iNTEGER,
		LocationId INTEGER,
		ProductSize VARCHAR(31),
		Tonnes FLOAT,
		Volume FLOAT,
	)
	
	/* This has been added due to Strat & Weathering support. Speed is atrocious without this. */
	CREATE NONCLUSTERED INDEX IX_SummaryEntryId ON #BlockWithSummary (SummaryEntryId)
	
	CREATE TABLE #FlatStratTable
	(
		StratId INT NOT NULL,
		GroupId INT NOT NULL
	); -- DO NOT drop this semicolon or the CTE below won't work.
	
	WITH CTE AS (
		SELECT S.Id, S.Id AS UltimateParent
		FROM BhpbioStratigraphyHierarchy S
		UNION ALL
		SELECT Child.Id, Parent.UltimateParent
		FROM BhpbioStratigraphyHierarchy AS Child
		JOIN CTE AS Parent ON Child.Parent_Id = Parent.Id
	)
	
	INSERT INTO #FlatStratTable
	SELECT CTE.*
	FROM CTE
	INNER JOIN BhpbioStratigraphyHierarchy S ON S.Id = CTE.UltimateParent
	INNER JOIN BhpbioStratigraphyHierarchyType T ON T.Id = S.StratigraphyHierarchyType_Id
	ORDER BY UltimateParent, CTE.Id -- Not sure if this is strictly necessary, can't hurt though
	
	INSERT INTO #productsize VALUES ('FINES')
	INSERT INTO #productsize VALUES ('LUMP')
	INSERT INTO #productsize VALUES ('TOTAL')
	
	DECLARE @GradeControlModelId INT
	DECLARE @GradeControlSTGMModelId INT
	
	SELECT @GradeControlModelId = Block_Model_Id from BlockModel where Name = 'Grade Control'
	SELECT @GradeControlSTGMModelId = Block_Model_Id from BlockModel where Name = 'Grade Control STGM'
	
	IF @GradeControlModelId IS NULL OR @GradeControlSTGMModelId IS NULL BEGIN
		RAISERROR('Could not find Grade Control or Grade Control STGM Block Model Ids', 16, 1)
		RETURN		
	END
	
	SET NOCOUNT ON 
	
	SELECT @TransactionName = 'GetBhpbioReportDataBlockModel',
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
	
	DECLARE curBlockModelCursor CURSOR FOR	
	SELECT DISTINCT Block_Model_Id, Name 
	FROM dbo.BlockModel bm
	WHERE (Name = @iBlockModelName 
			OR 	@iBlockModelName IS NULL
			OR CHARINDEX(','+Name+',', @iBlockModelName) > 0  -- a model within the delimited list
			OR CHARINDEX(Name+',', @iBlockModelName) = 1 -- a model at the start of a delimited list
			OR CHARINDEX(',' + Name, @iBlockModelName) = (Len(@iBlockModelName) - Len(Name)) -- a model name at the end of a delimited list
		 ) 
		AND bm.Is_Default = 1
	
	DECLARE @currentBlockModelName VARCHAR(31)
			
	BEGIN TRY
	
		OPEN curBlockModelCursor
		
		CREATE TABLE #ModelMovement
		(
			CalendarDate DATETIME NOT NULL,
			DateFrom DATETIME NOT NULL,
			DateTo DATETIME NOT NULL,
			MaterialTypeId INT NOT NULL,
			BlockModelId INT NOT NULL,
			ParentLocationId INT NULL,
			ModelBlockId INT NOT NULL,
			SequenceNo INT NOT NULL,
			MinedPercentage FLOAT NOT NULL,
			ProductSize VARCHAR(5) NOT NULL,
			ResourceClassification VARCHAR(32) NOT NULL,
			ResourceClassificationPct FLOAT NULL,
			Tonnes FLOAT NOT NULL,
			Volume FLOAT NULL,
			PRIMARY KEY (CalendarDate, DateFrom, DateTo, MaterialTypeId, BlockModelId, ModelBlockId, SequenceNo, ProductSize, ResourceClassification)
		)
		
		CREATE TABLE #ModelMovementInterim
		(
			CalendarDate DATETIME NOT NULL,
			DateFrom DATETIME NOT NULL,
			DateTo DATETIME NOT NULL,
			MaterialTypeId INT NOT NULL,
			UnderlyingMaterialTypeId INT NOT NULL,
			BlockModelId INT NOT NULL,
			ParentLocationId INT NULL,
			BlockLocationId INT NULL,
			ModelBlockId INT NOT NULL,
			SequenceNo INT NOT NULL,
			MinedPercentage FLOAT NOT NULL,
			ProductSize VARCHAR(5) NOT NULL,
			Tonnes FLOAT NOT NULL,
			Volume FLOAT NULL,
			PRIMARY KEY (CalendarDate, DateFrom, DateTo, MaterialTypeId, BlockModelId, ModelBlockId, SequenceNo, ProductSize)
		)
	
		CREATE TABLE #BlockLocation
		(
			BlockLocationId INT NOT NULL,
			BlastLocationId INT NULL,
			BenchLocationId INT NULL,
			PitLocationId INT NULL,
			SiteLocationId INT NULL,
			HubLocationId INT NULL,
			CompanyLocationId INT NULL,
			DateFrom DATETIME NOT NULL,
			DateTo DATETIME NOT NULL,
			MinedPercentage FLOAT,
			BlockNumber VARCHAR(4) NULL,
			BlockName VARCHAR(5),
			Site VARCHAR(31),
			OreBody VARCHAR(2) NULL,
			Pit VARCHAR(10),
			Bench VARCHAR(4),
			PatternNumber VARCHAR(4),
			ParentLocationId INT NULL,
			SummaryId INT NOT NULL,
			
			PRIMARY KEY (BlockLocationId, SummaryId, Pit, BlockName)
		)
		
		CREATE NONCLUSTERED INDEX IX_BlockLocation2 ON #BlockLocation(DateFrom, DateTo, SummaryId, ParentLocationId, PitLocationId, BlockLocationId)
		
		CREATE TABLE #partialRCPercentages  (
				CalendarDate DATETIME,
				DateFrom DATETIME,
				DateTo DATETIME,
				LocationId INTEGER,
				SequenceNo INTEGER,
				MaterialTypeId INTEGER,
				PartialTonnes FLOAT,
				ResourceClassification VARCHAR(31),
				Percentage FLOAT,
				IsBackFilledFromBlock BIT DEFAULT(0)
				PRIMARY KEY(LocationId, CalendarDate, DateFrom, DateTo, SequenceNo, MaterialTypeId, ResourceClassification)
			)
			
		CREATE TABLE #blockRCPercentages  (
					CalendarDate DATETIME,
					DateFrom DATETIME,
					DateTo DATETIME,
					LocationId INTEGER,
					ResourceClassification VARCHAR(31),
					Percentage FLOAT,
					PRIMARY KEY(LocationId, CalendarDate, DateFrom, DateTo, ResourceClassification)
				)
				
		
		IF @iUseRemainingMaterialAtDateFrom =0
		BEGIN
	
			INSERT INTO #BlockLocation
			(
				BlockLocationId, BlastLocationId, BenchLocationId, PitLocationId, SiteLocationId, HubLocationId, CompanyLocationId, DateFrom, 
				DateTo, MinedPercentage, BlockNumber, BlockName, [Site], OreBody, Pit, Bench, PatternNumber, ParentLocationId, SummaryId
			)
			SELECT BlockLocationId, BlastLocationId, BenchLocationId, PitLocationId, SiteLocationId, HubLocationId, CompanyLocationId, BL.DateFrom, 
				BL.DateTo, MinedPercentage, BlockNumber, BlockName, [Site], OreBody, Pit, Bench, PatternNumber, ParentLocationId, IsNull(s.SummaryId,-1)
			FROM dbo.GetBhpbioReportReconBlockLocations(@iLocationId, @iDateFrom, @iDateTo, @iChildLocations) BL
			LEFT JOIN dbo.BhpbioSummary s
				ON s.SummaryMonth BETWEEN BL.DateFrom AND BL.DateTo
		END
		ELSE
		BEGIN
			INSERT INTO #BlockLocation
			(
				BlockLocationId, BlastLocationId, BenchLocationId, PitLocationId, SiteLocationId, HubLocationId, CompanyLocationId, DateFrom, 
				DateTo, MinedPercentage, BlockNumber, BlockName, [Site], OreBody, Pit, Bench, PatternNumber, ParentLocationId, SummaryId
			)
			SELECT BlockLocationId, BlastLocationId, BenchLocationId, PitLocationId, SiteLocationId, HubLocationId, CompanyLocationId, @iDateFrom, 
				@iDateFrom, RemainingPercentage, null, BlockName, [Site], null, Pit, Bench, PatternNumber, ParentLocationId, IsNull(s.SummaryId,-1)
			FROM dbo.GetBhpbioReportRemainingReconBlockLocations(@iLocationId, @iDateFrom, @iChildLocations) BL
			LEFT JOIN dbo.BhpbioSummary s
				ON s.SummaryMonth = BL.DateTo
			WHERE BL.RemainingPercentage > 0
		END
	
		IF @iChildLocations = 1 AND NOT (@iOverrideChildLocationType IS NULL)
		BEGIN
			UPDATE #BlockLocation
			SET ParentLocationId = 
				CASE
					WHEN @iOverrideChildLocationType = 'BLAST' THEN BlastLocationId 
					WHEN @iOverrideChildLocationType = 'BENCH' THEN BenchLocationId 
					WHEN @iOverrideChildLocationType = 'PIT' THEN PitLocationId 
					WHEN @iOverrideChildLocationType = 'SITE' THEN SiteLocationId 
					WHEN @iOverrideChildLocationType = 'HUB' THEN HubLocationId 
					WHEN @iOverrideChildLocationType = 'COMPANY' THEN CompanyLocationId 
					ELSE NULL 
				END
		END
	
		FETCH NEXT FROM curBlockModelCursor INTO @BlockModelId, @currentBlockModelName
		
		WHILE @@FETCH_STATUS = 0
		BEGIN
			
			DELETE FROM #ModelMovement
			DELETE FROM #ModelMovementInterim
			DELETE FROM #partialRCPercentages 
			DELETE FROM #blockRCPercentages 
			DELETE FROM #BlockWithSummary
			
			DECLARE @modelName VARCHAR(128)
			SET @modelName = REPLACE(@currentBlockModelName,' ','') + 'Model'
			
			IF @modelName = 'GradeControlSTGMModel'
				-- this special model is approved when the STGM data is approved
				SET @modelApprovalTagId = 'F15ShortTermGeologyModel'
			ELSE IF @modelName = 'ShortTermGeologyModel'
				-- The STGM is approved as part of the F1.5 factor, so be sure to use the correct prefix
				SET @modelApprovalTagId = 'F15' + @modelName
			ELSE
				-- F1 prefix for everything else - all the other models get approved as part of the F1
				-- process (I think?)
				SET @modelApprovalTagId = 'F1' + @modelName
			
			DECLARE @resourceClassificationPercentageModelName VARCHAR(31)
			DECLARE @resourceClassificationPercentageModelId INTEGER								
			
			IF @iIncludeResourceClassification = 1
			BEGIN
				-- DETERMINE THE SOURCE MODEL FOR RESOURCE CLASSIFICATION PERCENTAGES
				-- Default to the current model name
				SET @resourceClassificationPercentageModelName = @currentBlockModelName
				
				IF @modelName = 'GradeControlSTGMModel'
				BEGIN
					-- For GradeControlSTGM.. the Resource Classification percentages must come from the Short Term Geology Model
					SET @resourceClassificationPercentageModelName = 'Short Term Geology'
				END
				
				IF @modelName = 'GradeControlModel'
				BEGIN
					-- For GradeControl.. the Resource Classification percentages must come from the Mining Model
					SET @resourceClassificationPercentageModelName = 'Mining'
				END
			
				SELECT @resourceClassificationPercentageModelId = Block_Model_Id
				FROM BlockModel
				WHERE Name = @resourceClassificationPercentageModelName
			END
			
			IF @iIncludeLiveData  = 1
			BEGIN
				IF @iIncludeResourceClassification = 1
				BEGIN
					-- calculate the resource classification percentages for each partial
					INSERT INTO #partialRCPercentages 
						(
							CalendarDate, DateFrom, DateTo,
							LocationId, 
							SequenceNo, 
							PartialTonnes,
							ResourceClassification, 
							MaterialTypeId,
							Percentage
						)
					SELECT B.CalendarDate, B.DateFrom, B.DateTo, RM.BlockLocationId, 
						mbp.Sequence_No, 
						MBP.Tonnes,
						ISNULL(mbrc.Model_Block_Partial_Field_Id, 'ResourceClassificationUnknown'),
						MBP.Material_Type_Id,
						ISNULL(mbrc.Field_Value, 100)
					FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
						INNER JOIN #BlockLocation AS RM
							ON (RM.DateFrom >= b.DateFrom
							AND RM.DateTo <= b.DateTo)
						INNER JOIN [dbo].[GetBhpbioReportModelBlockLocations](@resourceClassificationPercentageModelId) AS MBL
							ON (RM.BlockLocationId = MBL.Location_Id)
						INNER JOIN dbo.ModelBlock AS MB
							ON (MBL.Model_Block_Id = MB.Model_Block_Id)
						INNER JOIN dbo.ModelBlockPartial AS MBP
							ON (MB.Model_Block_Id = MBP.Model_Block_Id)
						LEFT JOIN dbo.BhpbioBlastBlockLumpPercent blocklf
							ON MBP.Model_Block_Id = blocklf.ModelBlockId
								AND MBP.Sequence_No = blocklf.SequenceNo
								AND blocklf.GeometType = @iGeometType
						LEFT JOIN dbo.ModelBlockPartialValue mbrc
							On mbrc.Model_Block_Id = mbp.Model_Block_Id
								And mbrc.Sequence_No = mbp.Sequence_No
								And mbrc.Model_Block_Partial_Field_Id like 'ResourceClassification%'
						LEFT JOIN dbo.BhpbioApprovalData a
							ON a.LocationId = RM.PitLocationId
							AND a.TagId = @modelApprovalTagId
							AND a.ApprovedMonth = dbo.GetDateMonth(RM.DateFrom)
					WHERE	(	
								MB.Block_Model_Id = @resourceClassificationPercentageModelId
							)
							AND
							(
								@iIncludeApprovedData = 0
								OR 
								a.LocationId IS NULL
							)
					
					IF NOT @resourceClassificationPercentageModelName = @currentBlockModelName
					BEGIN
						-- WHERE A DIFFERENT MODEL IS BEING USED FOR RC Percentage retrieval than for output
						-- Ensure that all Blocks in the output model are represented in #partialRCPercentages
						-- Given that there is a chance that some Blocks are missing data in the other model... these should be treated as unknown
						INSERT INTO #partialRCPercentages 
							(
								CalendarDate, DateFrom, DateTo,
								LocationId, 
								SequenceNo, 
								PartialTonnes,
								ResourceClassification, 
								MaterialTypeId,
								Percentage
							)
						SELECT B.CalendarDate, B.DateFrom, B.DateTo, RM.BlockLocationId, 
							mbp.Sequence_No, 
							MBP.Tonnes,
							'ResourceClassificationUnknown',
							mbp.Material_Type_Id, 
							100
						FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
							INNER JOIN #BlockLocation AS RM
								ON (RM.DateFrom >= b.DateFrom
								AND RM.DateTo <= b.DateTo)
							INNER JOIN [dbo].[GetBhpbioReportModelBlockLocations](@BlockModelId) AS MBL
								ON (RM.BlockLocationId = MBL.Location_Id)
							INNER JOIN dbo.ModelBlock AS MB
								ON (MBL.Model_Block_Id = MB.Model_Block_Id)
							INNER JOIN dbo.ModelBlockPartial AS MBP
								ON (MB.Model_Block_Id = MBP.Model_Block_Id)
							LEFT JOIN dbo.BhpbioBlastBlockLumpPercent blocklf
								ON MBP.Model_Block_Id = blocklf.ModelBlockId
									AND MBP.Sequence_No = blocklf.SequenceNo
									AND blocklf.GeometType = @iGeometType
							LEFT JOIN dbo.BhpbioApprovalData a
								ON a.LocationId = RM.PitLocationId
								AND a.TagId = @modelApprovalTagId
								AND a.ApprovedMonth = dbo.GetDateMonth(RM.DateFrom)
						WHERE	(	
									MB.Block_Model_Id = @BlockModelId
								)
								AND
								(
									@iIncludeApprovedData = 0
									OR 
									a.LocationId IS NULL
								)
								AND NOT EXISTS (SELECT * FROM #partialRCPercentages pp WHERE pp.LocationId = RM.BlockLocationId)
					END
				
				
					-- ENSURE FOR EVERY PARTIAL THERE IS ALSO A Blank entry (for the total values)
					INSERT INTO #partialRCPercentages
					(
							CalendarDate, DateFrom, DateTo,
							LocationId, 
							PartialTonnes, 
							SequenceNo, 
							ResourceClassification, 
							MaterialTypeId,
							Percentage
					)
					SELECT DISTINCT pp.CalendarDate, pp.DateFrom, pp.DateTo, pp.LocationId, pp.PartialTonnes, pp.SequenceNo, '', 
						pp.MaterialTypeId,
						100
					FROM #partialRCPercentages pp
					
					-- calculate the resource classification percentages for each block
					INSERT INTO #blockRCPercentages (
						CalendarDate, DateFrom, DateTo,
						LocationId,ResourceClassification,Percentage
					)
					SELECT pp.CalendarDate, pp.DateFrom, pp.DateTo, pp.LocationId,  pp.ResourceClassification, SUM(pp.Percentage * pp.PartialTonnes) / SUM(pp.PartialTonnes)
					FROM #partialRCPercentages pp
					GROUP BY pp.CalendarDate, pp.DateFrom, pp.DateTo, pp.LocationId, pp.ResourceClassification
				END
				
				INSERT INTO #ModelMovementInterim  (
						CalendarDate, DateFrom, DateTo, 
						BlockModelId, MaterialTypeId, UnderlyingMaterialTypeId, ParentLocationId, BlockLocationId, ModelBlockId, SequenceNo, 
						MinedPercentage, defaultlf.ProductSize, 
						Tonnes,
						Volume
					)
				SELECT B.CalendarDate, B.DateFrom, B.DateTo, @BlockModelId, MT.Material_Type_Id, MBP.Material_Type_Id, case when @iChildLocations=0 then null else RM.ParentLocationId end as ParentLocationId , 
					RM.BlockLocationId, MBP.Model_Block_Id, MBP.Sequence_No, 
					RM.MinedPercentage, 
					defaultlf.ProductSize,
					ISNULL(
						CASE 
							WHEN defaultlf.ProductSize = 'LUMP' THEN blocklf.[LumpPercent] 
							WHEN defaultlf.ProductSize = 'FINES' THEN 1 - blocklf.[LumpPercent] 
							ELSE NULL END, 
						defaultlf.[Percent])
					* RM.MinedPercentage * MBP.Tonnes as Tonnes,
					-- calculate a volume for lump and fines even though Volume won't eventually be output for Lump and Fines
					ISNULL(
						CASE 
							WHEN defaultlf.ProductSize = 'LUMP' THEN blocklf.[LumpPercent] 
							WHEN defaultlf.ProductSize = 'FINES' THEN 1 - blocklf.[LumpPercent] 
							ELSE NULL END, 
						defaultlf.[Percent])
					* RM.MinedPercentage * MBPV.Field_Value as Volume
				FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
					INNER JOIN #BlockLocation AS RM
						ON (RM.DateFrom >= b.DateFrom
						AND RM.DateTo <= b.DateTo)
					INNER JOIN [dbo].[GetBhpbioReportModelBlockLocations](@BlockModelId) AS MBL
						ON (RM.BlockLocationId = MBL.Location_Id)
					INNER JOIN dbo.ModelBlock AS MB
						ON (MBL.Model_Block_Id = MB.Model_Block_Id)
					INNER JOIN dbo.ModelBlockPartial AS MBP
						ON (MB.Model_Block_Id = MBP.Model_Block_Id)
					INNER JOIN dbo.GetMaterialsByCategory(@MaterialCategory) AS MC
						ON (MC.MaterialTypeId = MBP.Material_Type_Id)
					INNER JOIN dbo.MaterialType AS MT
						ON (MC.RootMaterialTypeId = MT.Material_Type_Id)
					LEFT JOIN dbo.GetBhpbioReportHighGrade() AS BRHG
						ON (BRHG.MaterialTypeId = MT.Material_Type_Id)
					INNER JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, null) defaultlf
						ON RM.PitLocationId = defaultlf.LocationId
						AND RM.DateFrom BETWEEN defaultlf.StartDate AND defaultlf.EndDate
					LEFT JOIN dbo.BhpbioBlastBlockLumpPercent blocklf
						ON MBP.Model_Block_Id = blocklf.ModelBlockId
							AND MBP.Sequence_No = blocklf.SequenceNo
							AND blocklf.GeometType = @iGeometType
					LEFT JOIN dbo.ModelBlockPartialValue AS MBPV
						ON MBP.Model_Block_Id = MBPV.Model_Block_Id
						AND MBP.Sequence_No = MBPV.Sequence_No
						AND MBPV.Model_Block_Partial_Field_Id = 'ModelVolume'
					LEFT JOIN dbo.BhpbioApprovalData a
						ON a.LocationId = RM.PitLocationId
						AND a.TagId = @modelApprovalTagId
						AND a.ApprovedMonth = dbo.GetDateMonth(RM.DateFrom)
				WHERE	(	
							MB.Block_Model_Id = (CASE WHEN @BlockModelId = @GradeControlSTGMModelId THEN @GradeControlModelId ELSE @BlockModelId END)
						)
						AND
						(
							@iIncludeApprovedData = 0
							OR 
							a.LocationId IS NULL
						)
				
				IF @resourceClassificationPercentageModelName = @currentBlockModelName
				BEGIN
					-- Populate model movements using resource classification data at the Partial level
					INSERT INTO #ModelMovement (
						CalendarDate, DateFrom, DateTo, 
						BlockModelId, MaterialTypeId, ParentLocationId, ModelBlockId, SequenceNo, 
						MinedPercentage, defaultlf.ProductSize, 
						ResourceClassification,
						Tonnes,
						Volume
					)
					SELECT mmi.CalendarDate, mmi.DateFrom, mmi.DateTo, mmi.BlockModelId, mmi.MaterialTypeId, mmi.ParentLocationId, mmi.ModelBlockId, mmi.SequenceNo,
						Sum(mmi.MinedPercentage), 
						mmi.ProductSize, 
						IsNull(per.ResourceClassification, ''), 
						Sum(mmi.Tonnes * (ISNULL(per.Percentage,100) / 100)), 
						Sum(mmi.Volume * (ISNULL(per.Percentage,100) / 100))
					FROM #ModelMovementInterim mmi
						LEFT JOIN #partialRCPercentages per -- join the partial perecentages
							
						On per.LocationId = mmi.BlockLocationId
							And per.MaterialTypeId = mmi.UnderlyingMaterialTypeId
							And @iIncludeResourceClassification = 1
							AND per.DateFrom = mmi.DateFrom
							AND per.DateTo = mmi.DateTo
					WHERE (@iIncludeResourceClassification = 0 OR NOT (per.ResourceClassification IS NULL))
					GROUP BY mmi.CalendarDate, mmi.DateFrom, mmi.DateTo, mmi.BlockModelId, mmi.MaterialTypeId
					, mmi.ParentLocationId	
					, mmi.ModelBlockId, mmi.SequenceNo, mmi.ProductSize
					, IsNull(per.ResourceClassification, '')
					
				END
				ELSE
				BEGIN
					-- Populate model movements using resource classification data at the Block level
	
					INSERT INTO #ModelMovement (
						CalendarDate, DateFrom, DateTo, 
						BlockModelId, MaterialTypeId, RM.ParentLocationId, ModelBlockId, SequenceNo, 
						MinedPercentage, defaultlf.ProductSize, 
						ResourceClassification,
						Tonnes,
						Volume
					)
					SELECT mmi.CalendarDate, mmi.DateFrom, mmi.DateTo, mmi.BlockModelId, mmi.MaterialTypeId, mmi.ParentLocationId, mmi.ModelBlockId, mmi.SequenceNo,
						SUM(mmi.MinedPercentage), 
						mmi.ProductSize, 
						IsNull(per.ResourceClassification, ''), 
						Sum(mmi.Tonnes * (ISNULL(per.Percentage,100) / 100)), 
						Sum(mmi.Volume * (ISNULL(per.Percentage,100) / 100))
					FROM #ModelMovementInterim mmi
						LEFT JOIN #blockRCPercentages per -- join the overall Block percentages (where no partials OR where the partial resource classification matches)
						ON per.LocationId = mmi.BlockLocationId
						AND per.DateFrom = mmi.DateFrom
						AND per.DateTo = mmi.DateTo
					WHERE (@iIncludeResourceClassification = 0 OR NOT (per.ResourceClassification IS NULL))
					GROUP BY mmi.CalendarDate, mmi.DateFrom, mmi.DateTo, mmi.BlockModelId, mmi.MaterialTypeId
					, mmi.ParentLocationId	
					, mmi.ModelBlockId, mmi.SequenceNo, mmi.ProductSize
					, IsNull(per.ResourceClassification, '')
				END
	
				-- Retrieve Tonnes for LUMP and FINES
				INSERT INTO #TonnesTable
				(
					BlockModelId,
					BlockModelName,
					CalendarDate,
					DateFrom,
					DateTo,
					MaterialTypeId,
					ParentLocationId,
					ProductSize,
					ResourceClassification,
					Tonnes,
					Volume,
					Strat,
					StratLevel,
					StratLevelName,
					Weathering
				)
				SELECT MM.BlockModelId, BM.Name AS ModelName, 
					MM.CalendarDate, MM.DateFrom, MM.DateTo, MM.MaterialTypeId,
					MM.ParentLocationId, MM.ProductSize,
					MM.ResourceClassification,
					SUM(MM.Tonnes) AS Tonnes,
					SUM(MM.Volume) AS Volume,
					BSH2.StratNum AS Strat,
					MAX(BSHT.Level) AS StratLevel,
					MAX(BSHT.Type) AS StratLevelName,
					DBNWeathering.Notes AS Weathering
				FROM #ModelMovement AS MM
				INNER JOIN dbo.BlockModel AS BM
					ON BM.Block_Model_Id = MM.BlockModelId
				INNER JOIN dbo.ModelBlock MB
					ON MB.Model_Block_Id = MM.ModelBlockId AND (@iLowestStratLevel > 0 OR @iIncludeWeathering = 1)
				INNER JOIN dbo.Digblock DB
					ON DB.Digblock_Id = MB.Code
				LEFT JOIN DigblockNotes DBNStrat 
					ON DBNStrat.Digblock_Id = DB.Digblock_Id AND DBNStrat.Digblock_Field_Id = @DigblockNoteField_Strat AND @iLowestStratLevel > 0
				LEFT JOIN BhpbioStratigraphyHierarchy BSH1 -- Used to pull out StratNum or whatever we finally decide to display.
					ON BSH1.StratNum = DBNStrat.Notes AND @iLowestStratLevel > 0
				LEFT JOIN #FlatStratTable FST
					ON FST.StratId = BSH1.Id AND @iLowestStratLevel > 0
				LEFT JOIN BhpbioStratigraphyHierarchy BSH2 -- Used to filter to only the relevant Groupings.
					ON BSH2.Id = FST.GroupId AND @iLowestStratLevel > 0
				LEFT JOIN BhpbioStratigraphyHierarchyType BSHT
					ON BSHT.Id = BSH2.StratigraphyHierarchyType_Id AND (BSHT.Level <= @iLowestStratLevel OR @iLowestStratLevel = 0)
				LEFT JOIN DigblockNotes DBNWeathering
					ON DBNWeathering.Digblock_Id = DB.Digblock_Id AND DBNWeathering.Digblock_Field_Id = @DigblockNoteField_Weathering AND @iIncludeWeathering = 1
				WHERE ((@iLowestStratLevel > 0 AND BSHT.Level <= @iLowestStratLevel) 
					OR (@iLowestStratLevel = 0 AND BSHT.Level IS NULL))
				GROUP BY MM.CalendarDate, MM.DateFrom, MM.DateTo, 
					MM.MaterialTypeId, MM.ParentLocationId, 
					MM.BlockModelId, BM.Name, 
					MM.ResourceClassification,
					MM.ProductSize, 
					BSH2.StratNum, -- The "grouping" stratigraphy
					DBNWeathering.Notes
				
				UNION
				
				-- aggregate to TOTAL
				SELECT MM.BlockModelId, BM.Name AS ModelName, 
					MM.CalendarDate, MM.DateFrom, MM.DateTo, MM.MaterialTypeId,
					MM.ParentLocationId, 'TOTAL' As ProductSize, 
					MM.ResourceClassification, 
					SUM(MM.Tonnes) AS Tonnes,
					SUM(MM.Volume) AS Volume,
					BSH2.StratNum AS Strat,
					MAX(BSHT.Level) AS StratLevel,
					MAX(BSHT.Type) AS StratLevelName,
					DBNWeathering.Notes AS Weathering
				FROM #ModelMovement AS MM
				INNER JOIN dbo.BlockModel AS BM
					ON BM.Block_Model_Id = MM.BlockModelId
				INNER JOIN dbo.ModelBlock MB
					ON MB.Model_Block_Id = MM.ModelBlockId AND (@iLowestStratLevel > 0 OR @iIncludeWeathering = 1)
				INNER JOIN dbo.Digblock DB
					ON DB.Digblock_Id = MB.Code
				LEFT JOIN DigblockNotes DBNStrat 
					ON DBNStrat.Digblock_Id = DB.Digblock_Id AND DBNStrat.Digblock_Field_Id = @DigblockNoteField_Strat AND @iLowestStratLevel > 0
				LEFT JOIN BhpbioStratigraphyHierarchy BSH1 -- Used to pull out StratNum or whatever we finally decide to display.
					ON BSH1.StratNum = DBNStrat.Notes AND @iLowestStratLevel > 0
				LEFT JOIN #FlatStratTable FST
					ON FST.StratId = BSH1.Id AND @iLowestStratLevel > 0
				LEFT JOIN BhpbioStratigraphyHierarchy BSH2 -- Used to filter to only the relevant Groupings.
					ON BSH2.Id = FST.GroupId AND @iLowestStratLevel > 0
				LEFT JOIN BhpbioStratigraphyHierarchyType BSHT
					ON BSHT.Id = BSH2.StratigraphyHierarchyType_Id AND (BSHT.Level <= @iLowestStratLevel OR @iLowestStratLevel = 0)
				LEFT JOIN DigblockNotes DBNWeathering
					ON DBNWeathering.Digblock_Id = DB.Digblock_Id AND DBNWeathering.Digblock_Field_Id = @DigblockNoteField_Weathering AND @iIncludeWeathering = 1
				WHERE ((@iLowestStratLevel > 0 AND BSHT.Level <= @iLowestStratLevel) 
					OR (@iLowestStratLevel = 0 AND BSHT.Level IS NULL))
				GROUP BY MM.CalendarDate, MM.DateFrom, MM.DateTo, 
					MM.MaterialTypeId, MM.ParentLocationId, MM.BlockModelId, 
					BM.Name, MM.ResourceClassification, 
					BSH2.StratNum, -- The "grouping" stratigraphy
					DBNWeathering.Notes
				
				-- now that the total has been calculated, clear out the volume for LUMP and FINES as these should not be output
				UPDATE #TonnesTable SET Volume = NULL WHERE NOT ProductSize = 'TOTAL'
				
				-- Retrieve Grades
				INSERT INTO #GradesTable
				(
					BlockModelId,
					BlockModelName,
					CalendarDate,
					DateFrom,
					DateTo,
					MaterialTypeId,
					ParentLocationId,
					GradeId,
					GradeValue,
					ProductSize,
					ResourceClassification,
					Tonnes,
					Strat,
					StratLevel,
					StratLevelName,
					Weathering
				)
				SELECT MM.BlockModelId, BM.Name AS ModelName, MM.CalendarDate, MM.DateFrom, MM.DateTo, MM.MaterialTypeId, MM.ParentLocationId, G.Grade_Id,
					CASE WHEN SUM(MM.Tonnes) = 0
					THEN 0
					ELSE
						SUM(MM.Tonnes * 
							ISNULL(
								CASE 
									WHEN MM.ProductSize = 'LUMP' THEN LFG.LumpValue 
									WHEN MM.ProductSize = 'FINES' THEN LFG.FinesValue 
									ELSE NULL 
								END , MBPG.Grade_Value)
						) / SUM(MM.Tonnes) 
					END As GradeValue, 
					MM.ProductSize,
					MM.ResourceClassification,
					SUM(MM.Tonnes),
					BSH2.StratNum AS Strat,
					MAX(BSHT.Level) AS StratLevel,
					MAX(BSHT.Type) AS StratLevelName,
					DBNWeathering.Notes AS Weathering
				FROM #ModelMovement AS MM
				INNER JOIN dbo.BlockModel AS BM
					ON (BM.Block_Model_Id = MM.BlockModelId)
				INNER JOIN dbo.ModelBlockPartial AS MBP
					ON (MBP.Model_Block_Id = MM.ModelBlockId
						AND MBP.Sequence_No = MM.SequenceNo)
				CROSS JOIN Grade g
				LEFT JOIN dbo.ModelBlockPartialGrade AS MBPG
					ON (MBP.Model_Block_Id = MBPG.Model_Block_Id
						AND MBP.Sequence_No = MBPG.Sequence_No)
						AND MBPG.Grade_Id = g.Grade_Id
				LEFT JOIN dbo.BhpbioBlastBlockLumpFinesGrade LFG
					ON (LFG.ModelBlockId = MM.ModelBlockId
						AND MBP.Sequence_No = LFG.SequenceNo
						AND g.Grade_Id = LFG.GradeId)
						AND MM.ProductSize IN ('LUMP','FINES')
						AND LFG.GeometType = @iGeometType
				INNER JOIN dbo.ModelBlock MB
					ON MB.Model_Block_Id = MBP.Model_Block_Id AND (@iLowestStratLevel > 0 OR @iIncludeWeathering = 1)
				INNER JOIN dbo.Digblock DB
					ON DB.Digblock_Id = MB.Code
				LEFT JOIN DigblockNotes DBNStrat 
					ON DBNStrat.Digblock_Id = DB.Digblock_Id AND DBNStrat.Digblock_Field_Id = @DigblockNoteField_Strat AND @iLowestStratLevel > 0
				LEFT JOIN BhpbioStratigraphyHierarchy BSH1 -- Used to pull out StratNum or whatever we finally decide to display.
					ON BSH1.StratNum = DBNStrat.Notes AND @iLowestStratLevel > 0
				LEFT JOIN #FlatStratTable FST
					ON FST.StratId = BSH1.Id AND @iLowestStratLevel > 0
				LEFT JOIN BhpbioStratigraphyHierarchy BSH2 -- Used to filter to only the relevant Groupings.
					ON BSH2.Id = FST.GroupId AND @iLowestStratLevel > 0
				LEFT JOIN BhpbioStratigraphyHierarchyType BSHT
					ON BSHT.Id = BSH2.StratigraphyHierarchyType_Id AND (BSHT.Level <= @iLowestStratLevel OR @iLowestStratLevel = 0)
				LEFT JOIN DigblockNotes DBNWeathering
					ON DBNWeathering.Digblock_Id = DB.Digblock_Id AND DBNWeathering.Digblock_Field_Id = @DigblockNoteField_Weathering AND @iIncludeWeathering = 1
				WHERE ((NOT MBPG.Grade_Id IS NULL) OR (NOT LFG.GradeId IS NULL)) -- include where there is some kind of grade (total, lump or fines)
					AND ((@iLowestStratLevel > 0 AND BSHT.Level <= @iLowestStratLevel) 
						OR (@iLowestStratLevel = 0 AND BSHT.Level IS NULL))
				GROUP BY MM.BlockModelId, BM.Name, MM.CalendarDate, 
					MM.ParentLocationId, MM.DateFrom, MM.DateTo, 
					MM.MaterialTypeId, G.Grade_Id, MM.ProductSize,
					MM.ResourceClassification, 
					BSH2.StratNum, -- The "grouping" stratigraphy
					DBNWeathering.Notes
				
				---- insert total grades
				INSERT INTO #GradesTable
				(
					BlockModelId,
					BlockModelName,
					CalendarDate,
					DateFrom,
					DateTo,
					MaterialTypeId,
					ParentLocationId,
					GradeId,
					GradeValue,
					ProductSize,
					ResourceClassification,
					Tonnes,
					Strat,
					StratLevel,
					StratLevelName,
					Weathering
				)
				SELECT MM.BlockModelId, BM.Name AS ModelName, MM.CalendarDate, MM.DateFrom, MM.DateTo, MM.MaterialTypeId, MM.ParentLocationId, MBPG.Grade_Id,
					CASE WHEN SUM(MM.Tonnes) = 0
					THEN 0
					ELSE
						SUM(MM.Tonnes * MBPG.Grade_Value)
						 / SUM(MM.Tonnes) 
					END As GradeValue, 
					'TOTAL',
					MM.ResourceClassification,
					SUM(MM.Tonnes),
					BSH2.StratNum AS Strat,
					MAX(BSHT.Level) AS StratLevel,
					MAX(BSHT.Type) AS StratLevelName,
					DBNWeathering.Notes AS Weathering
				FROM #ModelMovement AS MM
				INNER JOIN dbo.BlockModel AS BM
					ON (BM.Block_Model_Id = MM.BlockModelId)
				INNER JOIN dbo.ModelBlockPartial AS MBP
					ON (MBP.Model_Block_Id = MM.ModelBlockId
						AND MBP.Sequence_No = MM.SequenceNo)
				INNER JOIN dbo.ModelBlockPartialGrade AS MBPG
					ON (MBP.Model_Block_Id = MBPG.Model_Block_Id
						AND MBP.Sequence_No = MBPG.Sequence_No)
				INNER JOIN dbo.ModelBlock MB
					ON MB.Model_Block_Id = MBP.Model_Block_Id AND (@iLowestStratLevel > 0 OR @iIncludeWeathering = 1)
				INNER JOIN dbo.Digblock DB
					ON DB.Digblock_Id = MB.Code
				LEFT JOIN DigblockNotes DBNStrat 
					ON DBNStrat.Digblock_Id = DB.Digblock_Id AND DBNStrat.Digblock_Field_Id = @DigblockNoteField_Strat AND @iLowestStratLevel > 0
				LEFT JOIN BhpbioStratigraphyHierarchy BSH1 -- Used to pull out StratNum or whatever we finally decide to display.
					ON BSH1.StratNum = DBNStrat.Notes AND @iLowestStratLevel > 0
				LEFT JOIN #FlatStratTable FST
					ON FST.StratId = BSH1.Id AND @iLowestStratLevel > 0
				LEFT JOIN BhpbioStratigraphyHierarchy BSH2 -- Used to filter to only the relevant Groupings.
					ON BSH2.Id = FST.GroupId AND @iLowestStratLevel > 0
				LEFT JOIN BhpbioStratigraphyHierarchyType BSHT
					ON BSHT.Id = BSH2.StratigraphyHierarchyType_Id AND (BSHT.Level <= @iLowestStratLevel OR @iLowestStratLevel = 0)
				LEFT JOIN DigblockNotes DBNWeathering
					ON DBNWeathering.Digblock_Id = DB.Digblock_Id AND DBNWeathering.Digblock_Field_Id = @DigblockNoteField_Weathering AND @iIncludeWeathering = 1
				WHERE ((@iLowestStratLevel > 0 AND BSHT.Level <= @iLowestStratLevel) 
					OR (@iLowestStratLevel = 0 AND BSHT.Level IS NULL))
				GROUP BY MM.BlockModelId, BM.Name, MM.CalendarDate, MM.ParentLocationId, 
					MM.DateFrom, MM.DateTo, MM.MaterialTypeId, MBPG.Grade_Id,
					MM.ResourceClassification, 
					BSH2.StratNum, -- The "grouping" stratigraphy
					DBNWeathering.Notes
			END
			
			IF @iIncludeApprovedData  = 1
			BEGIN
	
				DELETE FROM #partialRCPercentages 
				DELETE FROM #blockRCPercentages 
	
				DECLARE @summaryEntryTypeId INT
				DECLARE @rcPercentageSummaryEntryTypeId INT -- summary entry type used to obtain resource classification percentages
	
				SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
				FROM dbo.BhpbioSummaryEntryType bset
				WHERE bset.Name = REPLACE(@currentBlockModelName,' ','') + 'ModelMovement'
					AND bset.AssociatedBlockModelId = @BlockModelId
	
	
				IF @iIncludeResourceClassification = 1
				BEGIN
				
					SET @rcPercentageSummaryEntryTypeId  = @summaryEntryTypeId
					
					IF NOT @currentBlockModelName = @resourceClassificationPercentageModelName
					BEGIN
						-- The resource classification percentages are to be retrieved from another model (summary type)
						SELECT @rcPercentageSummaryEntryTypeId = bset.SummaryEntryTypeId
						FROM dbo.BhpbioSummaryEntryType bset
						WHERE bset.Name = REPLACE(@resourceClassificationPercentageModelName,' ','') + 'ModelMovement'
							  AND bset.AssociatedBlockModelId = @resourceClassificationPercentageModelId
					END
					
					-- determine the RC percentages by material type
					INSERT INTO #partialRCPercentages
					(
						CalendarDate, DateFrom, DateTo,
						PartialTonnes,
						MaterialTypeId,
						LocationId,
						ResourceClassification,
						SequenceNo,
						[Percentage]
					)
					SELECT 
						B.CalendarDate AS CalendarDate, B.DateFrom, B.DateTo, 
						bse.Tonnes, 
						bse.MaterialTypeId, 
						RM.BlockLocationId, 
						RCF.Name, 
						-1, -- dummy value to satisfy primary key definition (for performance)
						RC.Value
					FROM #BlockLocation AS RM
						INNER JOIN dbo.BhpbioSummaryEntry AS bse
							ON bse.SummaryId = RM.SummaryId
							AND bse.LocationId = RM.BlockLocationId
							AND bse.SummaryEntryTypeId = @rcPercentageSummaryEntryTypeId
							AND bse.GeometType in ('NA', @iGeometType)
						INNER JOIN dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B                            
							ON RM.DateFrom = b.DateFrom
						LEFT JOIN dbo.BhpbioSummaryEntryField RCF
							ON RCF.ContextKey = 'ResourceClassification'
								AND @iIncludeResourceClassification = 1
						LEFT JOIN dbo.BhpbioSummaryEntryFieldValue RC
							ON RC.SummaryEntryId = bse.SummaryEntryId
								AND RC.SummaryEntryFieldId = RCF.SummaryEntryFieldId
					WHERE (RC.Value IS NOT NULL)
						AND bse.ProductSize = 'TOTAL'
					
					-- where no data at all for any partial of a Block insert 'ResourceClassificationUnknown'
					INSERT INTO #partialRCPercentages
					(
						CalendarDate, DateFrom, DateTo, 
						PartialTonnes, 
						MaterialTypeId, 
						LocationId, 
						ResourceClassification, 
						SequenceNo, 
						[Percentage]
					)
					SELECT 
						B.CalendarDate AS CalendarDate, B.DateFrom, B.DateTo, 
						bse.Tonnes, 
						bse.MaterialTypeId, 
						RM.BlockLocationId, 
						'ResourceClassificationUnknown', 
						-1, -- dummy value to satisfy primary key definition (for performance)
						100
					FROM #BlockLocation AS RM
						  INNER JOIN dbo.BhpbioSummaryEntry AS bse
								ON bse.SummaryId = RM.SummaryId
								AND bse.LocationId = RM.BlockLocationId
								AND bse.SummaryEntryTypeId = @summaryEntryTypeId -- always used the summary type of the output model for the Unknown insert
								AND bse.GeometType in ('NA', @iGeometType)
						  INNER JOIN dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B                            
								ON RM.DateFrom = b.DateFrom
						  LEFT JOIN (
							SELECT DISTINCT pp2.CalendarDate, pp2.LocationId, pp2.MaterialTypeId
							FROM #partialRCPercentages pp2
						  ) existing ON existing.LocationId = bse.LocationId 
							AND existing.CalendarDate = B.CalendarDate
							AND (existing.MaterialTypeId = bse.MaterialTypeId Or @BlockModelId = @GradeControlModelId Or @BlockModelId = @GradeControlSTGMModelId)
					WHERE bse.ProductSize = 'TOTAL'	AND existing.CalendarDate IS NULL
					
					-- ENSURE FOR EVERY PARTIAL THERE IS ALSO A Blank entry (for the total values)
					INSERT INTO #partialRCPercentages
					(
							CalendarDate, DateFrom, DateTo,
							LocationId, 
							PartialTonnes, 
							MaterialTypeId, 
							ResourceClassification,
							SequenceNo,
							Percentage
					)
					SELECT DISTINCT pp.CalendarDate, pp.DateFrom, pp.DateTo, pp.LocationId, pp.PartialTonnes, pp.MaterialTypeId, '', SequenceNo, 100
					FROM #partialRCPercentages pp
					
					-- Calculate the resource classification percentages for each block
					INSERT INTO #blockRCPercentages (
						CalendarDate, DateFrom, DateTo,
						LocationId,ResourceClassification,Percentage
					)
					SELECT pp.CalendarDate, pp.DateFrom, pp.DateTo, pp.LocationId,  pp.ResourceClassification, SUM(pp.Percentage * pp.PartialTonnes) / SUM(pp.PartialTonnes)
					FROM #partialRCPercentages pp
					GROUP BY pp.CalendarDate, pp.DateFrom, pp.DateTo, pp.LocationId, pp.ResourceClassification
	
					-- finally, if there are any material types not represented for a Block, populate them based on Block summary data
					INSERT INTO #partialRCPercentages
					(
						CalendarDate, DateFrom, DateTo, PartialTonnes, MaterialTypeId, LocationId, ResourceClassification, SequenceNo, Percentage, IsBackFilledFromBlock
					)
					SELECT B.CalendarDate AS CalendarDate, B.DateFrom, B.DateTo, bse.Tonnes, bse.MaterialTypeId, RM.BlockLocationId, bp.ResourceClassification, 
						-1, -- dummy value to satisfy primary key definition (for performance)
						bp.Percentage,
						1 -- flag the fact this is a back-calculated partial
					FROM #BlockLocation AS RM
						  INNER JOIN dbo.BhpbioSummaryEntry AS bse
								ON bse.SummaryId = RM.SummaryId
								AND bse.LocationId = RM.BlockLocationId
								AND bse.SummaryEntryTypeId = @summaryEntryTypeId -- always used the summary type of the output model for the Unknown insert
								AND bse.GeometType in ('NA', @iGeometType)
						  INNER JOIN dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B                            
								ON RM.DateFrom = b.DateFrom
						  LEFT JOIN (
								SELECT DISTINCT pp2.CalendarDate, pp2.LocationId, pp2.MaterialTypeId FROM #partialRCPercentages pp2
							) existing ON existing.LocationId = bse.LocationId AND existing.CalendarDate = B.CalendarDate AND existing.MaterialTypeId = bse.MaterialTypeId
						  INNER JOIN #blockRCPercentages bp ON bp.CalendarDate = B.CalendarDate AND bp.LocationId = bse.LocationId
					WHERE bse.ProductSize = 'TOTAL'	AND existing.CalendarDate IS NULL
	
				END
				
				-- prepare interim Block and Summary entry data for the tonnes and grade output
				INSERT INTO #BlockWithSummary
				(BlockModelId,	ModelName, CalendarDate, DateFrom, DateTo, SummaryEntryId,	MaterialTypeID,	UnderlyingMaterialTypeId, ParentLocationId,
					LocationId,	ProductSize, Tonnes, Volume)
				SELECT 
					@BlockModelId AS BlockModelId, 
					@currentBlockModelName AS ModelName, 
					B.CalendarDate AS CalendarDate, B.DateFrom, B.DateTo, 
					bse.SummaryEntryId,
					MC.RootMaterialTypeId as MaterialTypeId,
					bse.MaterialTypeId as UnderlyingMaterialTypeId,
					case when @iChildLocations=0 then null else RM.ParentLocationId end as ParentLocationId,
					bse.LocationId, 
					bse.ProductSize,
					bse.Tonnes,
					bse.Volume
				FROM #BlockLocation AS RM
				INNER JOIN dbo.BhpbioSummaryEntry AS bse
					ON bse.SummaryId = RM.SummaryId
						AND bse.LocationId = RM.BlockLocationId
						AND bse.SummaryEntryTypeId = @summaryEntryTypeId
						AND (@iIncludeLumpFines = 1 OR ISNULL(bse.ProductSize,'TOTAL') = 'TOTAL')
						AND bse.GeometType in ('NA', @iGeometType)
				INNER JOIN dbo.GetMaterialsByCategory(@MaterialCategory) AS MC ON MC.MaterialTypeId = bse.MaterialTypeId
				INNER JOIN dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B                            
					ON RM.DateFrom = b.DateFrom
				 LEFT JOIN dbo.GetBhpbioReportHighGrade() AS BRHG
					ON (BRHG.MaterialTypeId = MC.RootMaterialTypeId)
				
				IF @rcPercentageSummaryEntryTypeId = @summaryEntryTypeId
				BEGIN
					-- Populate Tonnes and Grade data using the temporary table storing resource classification data at the partial level
	
					-- Retrieve Tonnes
					INSERT INTO #TonnesTable
					(
						  BlockModelId,
						  BlockModelName,
						  CalendarDate,
						  DateFrom,
						  DateTo,
						  MaterialTypeId,
						  ParentLocationId,
						  ProductSize,
						  ResourceClassification,
						  Tonnes,
						  Volume,
						  Strat,
						  StratLevel,
						  StratLevelName,
						  Weathering
					)
					SELECT @BlockModelId AS BlockModelId, @currentBlockModelName AS ModelName, bws.CalendarDate AS CalendarDate,
						bws.DateFrom, bws.DateTo, bws.MaterialTypeId,
						bws.ParentLocationId,
						bws.ProductSize,
						IsNull(per.ResourceClassification,'') AS ResourceClassification,
						SUM(bws.Tonnes * IsNull(per.Percentage / 100, 1)) AS Tonnes,
						SUM(bws.Volume * IsNull(per.Percentage / 100, 1)) as Volume,
						BSH2.StratNum, 
						MAX(BSHT.Level),
						MAX(BSHT.Type),
						CASE @iIncludeWeathering WHEN 1 THEN BSE.Weathering ELSE NULL END
					FROM #BlockWithSummary bws
					LEFT JOIN #partialRCPercentages per
						ON per.LocationId = bws.LocationId 
							AND per.MaterialTypeId = bws.UnderlyingMaterialTypeId
							AND per.DateFrom = bws.DateFrom
							AND per.DateTo = bws.DateTo
					LEFT JOIN dbo.BhpbioSummaryEntry BSE
						ON BSE.SummaryEntryId = BWS.SummaryEntryId AND (@iLowestStratLevel > 0 OR @iIncludeWeathering = 1)
					LEFT JOIN BhpbioStratigraphyHierarchy BSH1 -- Used to pull out StratNum or whatever we finally decide to display.
						ON BSH1.StratNum = BSE.StratNum AND @iLowestStratLevel > 0
					LEFT JOIN #FlatStratTable FST
						ON FST.StratId = BSH1.Id AND @iLowestStratLevel > 0
					LEFT JOIN BhpbioStratigraphyHierarchy BSH2 -- Used to filter to only the relevant Groupings.
						ON BSH2.Id = FST.GroupId AND @iLowestStratLevel > 0
					LEFT JOIN BhpbioStratigraphyHierarchyType BSHT
						ON BSHT.Id = BSH2.StratigraphyHierarchyType_Id AND (BSHT.Level <= @iLowestStratLevel OR @iLowestStratLevel = 0)
					WHERE (@iIncludeResourceClassification = 0 OR NOT per.ResourceClassification IS NULL)
						AND ((@iLowestStratLevel > 0 AND BSHT.Level <= @iLowestStratLevel) 
							OR (@iLowestStratLevel = 0 AND BSHT.Level IS NULL))
					GROUP BY bws.CalendarDate, bws.DateFrom, bws.DateTo, bws.MaterialTypeId,
						bws.ParentLocationId,
						bws.ProductSize,
						per.ResourceClassification,
						BSH2.StratNum, 
						BSE.Weathering
	
				-- Retrieve Grades
				INSERT INTO #GradesTable
				(
					BlockModelId,
					BlockModelName,
					CalendarDate,
					DateFrom,
					DateTo,
					ParentLocationId,
					MaterialTypeId,
					GradeId,
					GradeValue,
					ProductSize,
					ResourceClassification,
					Tonnes,
					Strat,
					StratLevel,
					StratLevelName,
					Weathering
				)
				SELECT @BlockModelId AS BlockModelId, 
					@currentBlockModelName AS ModelName, 
					bws.CalendarDate AS CalendarDate, bws.DateFrom, bws.DateTo, 
					bws.ParentLocationId, 
					bws.MaterialTypeID,--MT.Material_Type_Id, 
					bseg.GradeId,
					-- Calculate the GradeValue while avoiding potential divide by zero
					CASE WHEN SUM(bws.Tonnes * IsNull(per.Percentage / 100, 1)) > 0
						THEN SUM(bws.Tonnes * IsNull(per.Percentage / 100, 1) * bseg.GradeValue) / SUM(bws.Tonnes * IsNull(per.Percentage / 100, 1)) 
						ELSE 0 END As GradeValue, -- NOTE: Tonnes will also be 0 meaning the 0 grade value won't have a dilution effect
					bws.ProductSize,
					per.ResourceClassification AS ResourceClassification,
					SUM(bws.Tonnes * IsNull(per.Percentage / 100, 1)) AS Tonnes,
					BSH2.StratNum,
					MAX(BSHT.Level),
					MAX(BSHT.Type),
					CASE @iIncludeWeathering WHEN 1 THEN BSE.Weathering ELSE NULL END
				FROM #BlockWithSummary bws
				INNER JOIN dbo.BhpbioSummaryEntryGrade AS bseg
					ON bseg.SummaryEntryId = bws.SummaryEntryId
				LEFT JOIN #partialRCPercentages per
					ON per.LocationId = bws.LocationId 
						AND per.MaterialTypeId = bws.UnderlyingMaterialTypeId
						AND per.DateFrom = bws.DateFrom
						AND per.DateTo = bws.DateTo
						AND per.IsBackFilledFromBlock = 0 -- for consistency with previous version, do not include partial resclass values back-calculated from the overall block ResClass
				LEFT JOIN dbo.BhpbioSummaryEntry BSE
					ON BSE.SummaryEntryId = BWS.SummaryEntryId AND (@iLowestStratLevel > 0 OR @iIncludeWeathering = 1)
				LEFT JOIN BhpbioStratigraphyHierarchy BSH1 -- Used to pull out StratNum or whatever we finally decide to display.
					ON BSH1.StratNum = BSE.StratNum AND @iLowestStratLevel > 0
				LEFT JOIN #FlatStratTable FST
					ON FST.StratId = BSH1.Id AND @iLowestStratLevel > 0
				LEFT JOIN BhpbioStratigraphyHierarchy BSH2 -- Used to filter to only the relevant Groupings.
					ON BSH2.Id = FST.GroupId AND @iLowestStratLevel > 0
				LEFT JOIN BhpbioStratigraphyHierarchyType BSHT
					ON BSHT.Id = BSH2.StratigraphyHierarchyType_Id AND (BSHT.Level <= @iLowestStratLevel OR @iLowestStratLevel = 0)
			   	WHERE (@iIncludeResourceClassification = 0 OR NOT (per.ResourceClassification IS NULL))
			   		AND ((@iLowestStratLevel > 0 AND BSHT.Level <= @iLowestStratLevel) 
						OR (@iLowestStratLevel = 0 AND BSHT.Level IS NULL))
			   GROUP BY bws.CalendarDate, 
					bws.ParentLocationId, 
					bws.DateFrom, bws.DateTo, 
					bws.MaterialTypeID,--MT.Material_Type_Id, 
					bseg.GradeId, 
					bws.ProductSize,
					per.ResourceClassification,
					BSH2.StratNum,
					BSE.Weathering
	
				END
				ELSE
				BEGIN
					-- Populate Tonnes and Grade data using the temporary table storing resource classification data at the block level
	
					-- Retrieve Tonnes
					INSERT INTO #TonnesTable
					(
						BlockModelId,
						BlockModelName,
						CalendarDate,
						DateFrom,
						DateTo,
						MaterialTypeId,
						ParentLocationId,
						ProductSize,
						ResourceClassification,
						Tonnes,
						Volume,
						Strat,
						StratLevel,
						StratLevelName,
						Weathering
					)
					SELECT @BlockModelId AS BlockModelId, @currentBlockModelName AS ModelName, bws.CalendarDate AS CalendarDate,
						bws.DateFrom, bws.DateTo, bws.MaterialTypeId,
						bws.ParentLocationId,
						bws.ProductSize,
						IsNull(per.ResourceClassification,'') AS ResourceClassification,
						SUM(bws.Tonnes * IsNull(per.Percentage / 100, 1)) AS Tonnes,
						SUM(bws.Volume * IsNull(per.Percentage / 100, 1)) as Volume,
						BSH2.StratNum,
						MAX(BSHT.Level),
						MAX(BSHT.Type),
						CASE @iIncludeWeathering WHEN 1 THEN BSE.Weathering ELSE NULL END
					FROM #BlockWithSummary AS bws
					LEFT JOIN #blockRCPercentages per
						ON per.LocationId = bws.LocationId 
							AND per.DateFrom = bws.DateFrom
							AND per.DateTo = bws.DateTo
					LEFT JOIN dbo.BhpbioSummaryEntry BSE
						ON BSE.SummaryEntryId = BWS.SummaryEntryId AND (@iLowestStratLevel > 0 OR @iIncludeWeathering = 1)
					LEFT JOIN BhpbioStratigraphyHierarchy BSH1 -- Used to pull out StratNum or whatever we finally decide to display.
						ON BSH1.StratNum = BSE.StratNum AND @iLowestStratLevel > 0
					LEFT JOIN #FlatStratTable FST
						ON FST.StratId = BSH1.Id AND @iLowestStratLevel > 0
					LEFT JOIN BhpbioStratigraphyHierarchy BSH2 -- Used to filter to only the relevant Groupings.
						ON BSH2.Id = FST.GroupId AND @iLowestStratLevel > 0
					LEFT JOIN BhpbioStratigraphyHierarchyType BSHT
						ON BSHT.Id = BSH2.StratigraphyHierarchyType_Id AND BSHT.Level <= @iLowestStratLevel
					WHERE (@iIncludeResourceClassification = 0 OR NOT (per.ResourceClassification IS NULL)) 
						AND ((@iLowestStratLevel > 0 AND BSHT.Level <= @iLowestStratLevel) 
							OR (@iLowestStratLevel = 0 AND BSHT.Level IS NULL))
					GROUP BY bws.CalendarDate, bws.DateFrom, bws.DateTo, bws.MaterialTypeId,
						bws.ParentLocationId,
						bws.ProductSize,
						per.ResourceClassification,
						BSH2.StratNum, -- The "grouping" stratigraphy
						BSE.Weathering
	
				-- Retrieve Grades
				INSERT INTO #GradesTable
				(
					BlockModelId,
					BlockModelName,
					CalendarDate,
					DateFrom,
					DateTo,
					ParentLocationId,
					MaterialTypeId,
					GradeId,
					GradeValue,
					ProductSize,
					ResourceClassification,
					Tonnes,
					Strat,
					StratLevel,
					StratLevelName,
					Weathering
				)
				SELECT @BlockModelId AS BlockModelId, 
					@currentBlockModelName AS ModelName, 
					bws.CalendarDate AS CalendarDate, bws.DateFrom, bws.DateTo, 
					bws.ParentLocationId, 
					bws.MaterialTypeID,--MT.Material_Type_Id, 
					bseg.GradeId,
					-- Calculate the GradeValue while avoiding potential divide by zero
					CASE WHEN SUM(bws.Tonnes * IsNull(per.Percentage / 100, 1)) > 0
						THEN SUM(bws.Tonnes * IsNull(per.Percentage / 100, 1) * bseg.GradeValue) / SUM(bws.Tonnes * IsNull(per.Percentage / 100, 1)) 
						ELSE 0 END As GradeValue, -- NOTE: Tonnes will also be 0 meaning the 0 grade value won't have a dilution effect
					bws.ProductSize,
					per.ResourceClassification AS ResourceClassification,
					SUM(bws.Tonnes * IsNull(per.Percentage / 100, 1)) AS Tonnes,
					BSH2.StratNum,
					MAX(BSHT.Level),
					MAX(BSHT.Type),
					CASE @iIncludeWeathering WHEN 1 THEN BSE.Weathering ELSE NULL END
				FROM #BlockWithSummary bws
				INNER JOIN dbo.BhpbioSummaryEntryGrade AS bseg
					ON bseg.SummaryEntryId = bws.SummaryEntryId
				LEFT JOIN #blockRCPercentages per
					ON per.LocationId = bws.LocationId 
						AND per.DateFrom = bws.DateFrom
						AND per.DateTo = bws.DateTo
				LEFT JOIN dbo.BhpbioSummaryEntry BSE
					ON BSE.SummaryEntryId = BWS.SummaryEntryId AND (@iLowestStratLevel > 0 OR @iIncludeWeathering = 1)
				LEFT JOIN BhpbioStratigraphyHierarchy BSH1 -- Used to pull out StratNum or whatever we finally decide to display.
					ON BSH1.StratNum = BSE.StratNum AND @iLowestStratLevel > 0
				LEFT JOIN #FlatStratTable FST
					ON FST.StratId = BSH1.Id AND @iLowestStratLevel > 0
				LEFT JOIN BhpbioStratigraphyHierarchy BSH2 -- Used to filter to only the relevant Groupings.
					ON BSH2.Id = FST.GroupId AND @iLowestStratLevel > 0
				LEFT JOIN BhpbioStratigraphyHierarchyType BSHT
					ON BSHT.Id = BSH2.StratigraphyHierarchyType_Id AND BSHT.Level <= @iLowestStratLevel
				WHERE (@iIncludeResourceClassification = 0 OR NOT (per.ResourceClassification IS NULL))
					AND ((@iLowestStratLevel > 0 AND BSHT.Level <= @iLowestStratLevel) 
						OR (@iLowestStratLevel = 0 AND BSHT.Level IS NULL))
				GROUP BY bws.CalendarDate, 
					bws.ParentLocationId, 
					bws.DateFrom, bws.DateTo, 
					bws.MaterialTypeID,--MT.Material_Type_Id, 
					bseg.GradeId, 
					bws.ProductSize,
					per.ResourceClassification,
					BSH2.StratNum, -- The "grouping" stratigraphy
					BSE.Weathering
				END
			END
	
			-- include inactive child locations if required
			IF @iIncludeInactiveChildLocations = 1
			BEGIN
				-- insert zero tonnes for inactive locations
				INSERT INTO #TonnesTable
				(
					BlockModelId,
					BlockModelName,
					CalendarDate,
					DateFrom,
					DateTo,
					MaterialTypeId,
					ParentLocationId,
					ProductSize,
					ResourceClassification,
					Tonnes
				)
				SELECT BM.Block_Model_Id, BM.Name, B.CalendarDate, B.DateFrom, B.DateTo, BRHG.MaterialTypeId, L.ParentLocationId, 
					PS.ProductSize, 
					RC.ResourceClassification,
					0
				FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, @iChildLocations, 'BENCH', @iDateFrom, @iDateTo) L
					CROSS JOIN dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
					INNER JOIN dbo.BlockModel AS BM ON (BM.Block_Model_Id = @BlockModelId)
					INNER JOIN dbo.GetBhpbioReportHighGrade() AS BRHG
						ON (BRHG.Description = 'High Grade')
					CROSS JOIN #productsize PS
					LEFT JOIN (SELECT DISTINCT ParentLocationId, BlockModelId FROM #GradesTable) GT
						ON L.LocationId = GT.ParentLocationId 
						AND BM.Block_Model_ID = GT.BlockModelId
					CROSS JOIN (
						SELECT '' as ResourceClassification
						UNION SELECT 'ResourceClassificationUnknown' WHERE @iIncludeResourceClassification = 1
					) RC
					
				WHERE GT.ParentLocationId IS NULL
				GROUP BY BM.Block_Model_Id, BM.Name, B.CalendarDate, B.DateFrom, B.DateTo, BRHG.MaterialTypeId, L.ParentLocationId, 
					PS.ProductSize, RC.ResourceClassification
				
				-- insert zero grades for inactive locations
				INSERT INTO #GradesTable
				(
					BlockModelId,
					BlockModelName,
					CalendarDate,
					DateFrom,
					DateTo,
					ParentLocationId,
					MaterialTypeId,
					GradeId,
					GradeValue,
					ProductSize,
					ResourceClassification,
					Tonnes
				)
				SELECT BM.Block_Model_Id, BM.Name, B.CalendarDate, B.DateFrom, B.DateTo, L.ParentLocationId, BRHG.MaterialTypeId, G.Grade_Id, 0,
					PS.ProductSize, 
					RC.ResourceClassification,
					1
				FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, @iChildLocations, 'BENCH', @iDateFrom, @iDateTo) L
					CROSS JOIN dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
					CROSS JOIN dbo.Grade G
					INNER JOIN dbo.BlockModel AS BM ON (BM.Block_Model_Id = @BlockModelId)
					INNER JOIN dbo.GetBhpbioReportHighGrade() AS BRHG
						ON (BRHG.Description = 'High Grade')
					CROSS JOIN #productsize PS
					LEFT JOIN (SELECT DISTINCT ParentLocationId, BlockModelId FROM #GradesTable) GT
						ON L.LocationId = GT.ParentLocationId 
						AND BM.Block_Model_ID = GT.BlockModelId
					CROSS JOIN (
						SELECT '' as ResourceClassification
						UNION SELECT 'ResourceClassificationUnknown' WHERE @iIncludeResourceClassification = 1
					) RC
				WHERE GT.ParentLocationId IS NULL
				GROUP BY BM.Block_Model_Id, BM.Name, B.CalendarDate, B.DateFrom, B.DateTo, BRHG.MaterialTypeId, L.ParentLocationId, G.Grade_Id,
					PS.ProductSize, RC.ResourceClassification
			END
	
			FETCH NEXT FROM curBlockModelCursor INTO @BlockModelId, @currentBlockModelName
		END
		
		-- normalize the RC values
		Update #TonnesTable
		Set ResourceClassification = Null
		Where ResourceClassification = ''
	
		Update #GradesTable
		Set ResourceClassification = Null
		Where ResourceClassification = ''
	
		-- output combined tonnes
		SELECT t.BlockModelId, t.BlockModelName AS ModelName, t.CalendarDate, 
			t.DateFrom, t.DateTo, t.MaterialTypeId, 
			CASE WHEN BRHG.MaterialTypeId IS NULL THEN 0 ELSE 1 END as IsHighGrade,
			t.ParentLocationId, 
			t.ProductSize, t.ResourceClassification,
			Sum(t.Tonnes) as Tonnes,
			Sum(t.Volume) as Volume,
			t.Strat,
			MAX(t.StratLevel) AS StratLevel,
			MAX(t.StratLevelName) AS StratLevelName,
			t.Weathering
		FROM #TonnesTable t
			LEFT JOIN dbo.GetBhpbioReportHighGrade() AS BRHG 
				ON BRHG.MaterialTypeId = t.MaterialTypeId
		WHERE (BRHG.MaterialTypeId IS NOT NULL OR @iHighGradeOnly = 0)
		GROUP BY t.CalendarDate, t.DateFrom, t.DateTo, 
			t.MaterialTypeId, BRHG.MaterialTypeId, t.ParentLocationId, 
			t.BlockModelId, t.BlockModelName, 
			t.ProductSize, t.ResourceClassification, t.Strat, t.Weathering
	
		-- output combined grades
		SELECT gt.BlockModelId, gt.BlockModelName AS ModelName, gt.CalendarDate, 
			gt.DateFrom, gt.DateTo, gt.ParentLocationId, gt.MaterialTypeId, 
			CASE WHEN BRHG.MaterialTypeId IS NULL THEN 0 ELSE 1 END as IsHighGrade,
			gt.ResourceClassification,
			g.Grade_Name As GradeName,
			CASE WHEN SUM(gt.Tonnes) = 0
			THEN 0
			ELSE SUM(gt.Tonnes * gt.GradeValue) / SUM(gt.Tonnes) END As GradeValue, gt.ProductSize,
			gt.Strat,
			MAX(gt.StratLevel) AS StratLevel,
			MAX(gt.StratLevelName) AS StratLevelName,
			gt.Weathering
		FROM #GradesTable AS gt
			INNER JOIN dbo.Grade g
				ON (g.Grade_Id = gt.GradeId)
			LEFT JOIN dbo.GetBhpbioReportHighGrade() AS BRHG 
				ON BRHG.MaterialTypeId = gt.MaterialTypeId
		WHERE (BRHG.MaterialTypeId IS NOT NULL OR @iHighGradeOnly = 0)
		GROUP BY gt.BlockModelId, gt.BlockModelName, gt.CalendarDate, 
			gt.ParentLocationId, gt.DateFrom, gt.DateTo, 
			gt.MaterialTypeId, BRHG.MaterialTypeId, g.Grade_Name, 
			gt.ProductSize, gt.ResourceClassification, gt.Strat, gt.Weathering
	
		CLOSE curBlockModelCursor
		DEALLOCATE curBlockModelCursor
		
		-- if we started a new transaction that is still valid then commit the changes
		IF (@TransactionCount = 0) AND (XAct_State() = 1)
		BEGIN
			COMMIT TRANSACTION
		END
	END TRY
	BEGIN CATCH
		
		CLOSE curBlockModelCursor
		DEALLOCATE curBlockModelCursor
	
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

GRANT EXECUTE ON dbo.GetBhpbioReportDataBlockModel TO BhpbioGenericManager
GO

/*

EXEC dbo.GetBhpbioReportDataBlockModel
	@iDateFrom = '2015-01-01',
	@iDateTo = '2015-01-31',
	@iDateBreakdown = 'MONTH',
	@iLocationId = 7,
	@iChildLocations = 0,
	@iBlockModelName = 'Grade Control',
	@iIncludeLiveData = 0,
	@iIncludeApprovedData = 1,
	@iLowestStratLevel = 1, -- Use 0 to turn off.
	@iIncludeLumpFines = 0

*/