IF OBJECT_ID('dbo.GetBhpbioBlastblockbyOreTypeDataExportReport') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioBlastblockbyOreTypeDataExportReport
GO 

CREATE PROCEDURE dbo.GetBhpbioBlastblockbyOreTypeDataExportReport
(
	@iLocationId INT,
	@iStartMonth DATETIME,
	@iEndMonth DATETIME,
	@iIncludeLumpFines BIT = 0,
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @LocationId INT
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	DECLARE @MonthDate DATETIME
	DECLARE @EndMonthDate DATETIME
	DECLARE @HauledFieldId VARCHAR(31)
	DECLARE @CurrentMonth DATETIME
	
	DECLARE @modelVolumeFieldId VARCHAR(31)  -- VOLUME to be included --
	SET @modelVolumeFieldId = 'ModelVolume'
	
	-- Create a table used to store Live Results
	DECLARE @LiveResults TABLE
	(
		DigblockId VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialTypeId INTEGER,
		GeologyTonnes FLOAT NULL,
		MiningTonnes FLOAT NULL,
		ShortTermGeologyTonnes FLOAT NULL,
		GradeControlTonnes FLOAT NULL,
		GeologyVolume FLOAT NULL,
		MiningVolume FLOAT NULL,
		ShortTermGeologyVolume FLOAT NULL,
		GradeControlVolume FLOAT NULL,
		GeologyModelFilename VARCHAR(200) NULL,
		MiningModelFilename VARCHAR(200) NULL,
		ShortTermGeologyModelFilename VARCHAR(200) NULL,
		GradeControlModelFilename VARCHAR(200) NULL,
		MonthlyMinedPercent FLOAT NULL,
		TotalMinedPercent FLOAT NULL,
		HauledTonnes FLOAT NULL,
		SurveyedTonnes FLOAT NULL,
		BestTonnes FLOAT NULL,
		RemainingTonnes FLOAT NULL,
		
		PRIMARY KEY (DigblockId)
	)
	
	-- Create a table used to store Approved Results
	DECLARE @ApprovedResults TABLE
	(
		DigblockId VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialTypeId INTEGER,
		GeologyTonnes FLOAT NULL,
		MiningTonnes FLOAT NULL,
		ShortTermGeologyTonnes FLOAT NULL,
		GradeControlTonnes FLOAT NULL,
		GeologyVolume FLOAT NULL,
		MiningVolume FLOAT NULL,
		ShortTermGeologyVolume FLOAT NULL,
		GradeControlVolume FLOAT NULL,
		GeologyModelFilename VARCHAR(200) NULL,
		MiningModelFilename VARCHAR(200) NULL,
		ShortTermGeologyModelFilename VARCHAR(200) NULL,
		GradeControlModelFilename VARCHAR(200) NULL,
		MonthlyMinedPercent FLOAT NULL,
		TotalMinedPercent FLOAT NULL,
		HauledTonnes FLOAT NULL,
		SurveyedTonnes FLOAT NULL,
		BestTonnes FLOAT NULL,
		RemainingTonnes FLOAT NULL,
		
		PRIMARY KEY (DigblockId)
	)
	
	-- Create a table used to store Distinct Digblock Ids
	DECLARE @DistinctDigblocks TABLE
	(
		DigblockId VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		
		PRIMARY KEY (DigblockId)
	)
	
	-- Create a table to store final results (to be returned)
	DECLARE @Result TABLE
	(
		Blastblock VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		ModelName VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		ProductSize VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		[Month] DATETIME,
		Approved VARCHAR(5),
		OreType VARCHAR(63),
		GeometType VARCHAR(63),
		DepletionTonnes FLOAT NULL,
		DepletionVolume FLOAT NULL,
		ModelFilename VARCHAR(200) NULL,
		MonthlyMinedPercent FLOAT NULL,
		TotalMinedPercent FLOAT NULL,
		BestHauledTonnes FLOAT NULL,--Best Tonnes
		SurveyedTonnes FLOAT NULL,
		[Total Remaining Grade Control (Grade Control Inventory - Total Hauled)] FLOAT NULL,
		ModelTonnes FLOAT NULL,
		ModelVolume FLOAT NULL,
		ModelDensity FLOAT NULL,
		ModelFe FLOAT NULL,
		ModelP FLOAT NULL,
		ModelSiO2 FLOAT NULL,
		ModelAl2O3 FLOAT NULL,
		ModelLOI FLOAT NULL,
		ModelH2O FLOAT NULL,
		ModelUltraFinesInFines FLOAT NULL,
		SignoffUser VARCHAR(64),
		SignoffDate DATETIME,
		Measured FLOAT NULL,
		Indicated FLOAT NULL,
		Inferred FLOAT NULL,
		Potential FLOAT NULL,
		High FLOAT NULL,
		Medium FLOAT NULL,
		Low FLOAT NULL,
		[Very Low] FLOAT NULL,
		[Default/Unclass] FLOAT NULL,
		[No Information] FLOAT NULL
	)

	DECLARE @ModelBlockPercentByProductSize TABLE(
		ModelBlockId Int,
		BlockModelId Int,
		SequenceNo Int, 
		ProductSize VARCHAR(31),
		GeometType VARCHAR(63),
		[Percent] float)
	
	Declare @GeometTypes TABLE (
		ProductSize varchar(32),
		GeometType varchar(32)
	)
		
	Insert Into @GeometTypes
		Select 'LUMP', 'As-Shipped' Union
		Select 'LUMP', 'As-Dropped' Union
		Select 'FINES', 'As-Shipped' Union
		Select 'FINES', 'As-Dropped'

			
	SET NOCOUNT ON 

	SELECT @TransactionName = 'dbo.GetBhpbioBlastblockDataExportReport',
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
	
		SET @CurrentMonth = @iStartMonth
		
		WHILE @CurrentMonth <= @iEndMonth
		BEGIN
		
			DELETE FROM @LiveResults
			DELETE FROM @ApprovedResults
			DELETE FROM @DistinctDigblocks
			DELETE FROM @ModelBlockPercentByProductSize
			
			IF @iIncludeLiveData = 1
			BEGIN
				-- Get Live Data Results
				INSERT INTO @LiveResults
				(
					DigblockId, MaterialTypeId, GeologyTonnes, MiningTonnes, ShortTermGeologyTonnes, GradeControlTonnes,
					GeologyVolume, MiningVolume, ShortTermGeologyVolume, GradeControlVolume, 
					HauledTonnes, SurveyedTonnes, BestTonnes, RemainingTonnes, GeologyModelFilename, MiningModelFilename,
					ShortTermGeologyModelFilename, GradeControlModelFilename, MonthlyMinedPercent, TotalMinedPercent
				)
				EXEC dbo.GetBhpbioApprovalDigblockListLiveData
					@iLocationId = @iLocationId, @iMonthFilter = @CurrentMonth, @iRecordLimit = NULL
			END
		
			IF @iIncludeApprovedData = 1
			BEGIN												
				-- Get Approved Data Results
				INSERT INTO @ApprovedResults
				(
					DigblockId, MaterialTypeId, GeologyTonnes, MiningTonnes, ShortTermGeologyTonnes, GradeControlTonnes, 
					GeologyVolume, MiningVolume, ShortTermGeologyVolume, GradeControlVolume, 
					HauledTonnes, SurveyedTonnes, BestTonnes, RemainingTonnes, GeologyModelFilename, MiningModelFilename,
					ShortTermGeologyModelFilename, GradeControlModelFilename
				)
				EXEC dbo.GetBhpbioApprovalDigblockListApprovedData
					@iLocationId = @iLocationId, @iMonthFilter = @CurrentMonth, @iIncludeDepletions = 1
			END

			-- determine the distinct set of digblocks	
			INSERT INTO @DistinctDigblocks
			SELECT DISTINCT merged.DigblockId
			FROM (
					SELECT lr.DigblockId 
					FROM @LiveResults lr
					UNION
					SELECT ar.DigblockId 
					FROM @ApprovedResults ar
				) AS merged
			
			INSERT INTO @ModelBlockPercentByProductSize(ModelBlockId, BlockModelId, SequenceNo, ProductSize, GeometType, [Percent])
			SELECT 
				mb.Model_Block_Id, 
				mb.Block_Model_Id, 
				mbp.Sequence_No,
				ps.ProductSize,
				CASE 
					WHEN ps.ProductSize = 'TOTAL' THEN 'NA'
					ELSE ISNULL(blp.GeometType, gt.GeometType)
				END as GeometType,
				CASE 
					WHEN ps.ProductSize = 'TOTAL' THEN 1 
					WHEN ps.ProductSize = 'LUMP' THEN COALESCE(blp.LumpPercent, lfr.[Percent])
					WHEN ps.ProductSize = 'FINES' THEN COALESCE(1 - blp.LumpPercent, lfr.[Percent])
				END
			FROM @DistinctDigblocks db
				CROSS JOIN (SELECT 'TOTAL' As ProductSize UNION SELECT 'LUMP' UNION SELECT 'FINES') ps
				INNER JOIN Digblock d ON (d.Digblock_Id = db.DigblockId)
				INNER JOIN DigblockLocation dl ON (dl.Digblock_Id = d.Digblock_Id)
				INNER JOIN Location blockLocation ON blockLocation.Location_Id = dl.Location_Id
				INNER JOIN Location blastLocation  ON blastLocation.Location_Id = blockLocation.Parent_Location_Id
				INNER JOIN Location benchLocation  ON benchLocation.Location_Id = blastLocation.Parent_Location_Id
				INNER JOIN Location pitLocation  ON pitLocation.Location_Id = benchLocation.Parent_Location_Id
				LEFT JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, @CurrentMonth, 1) lfr 
					ON lfr.LocationId = pitLocation.Location_Id 
						AND lfr.ProductSize= ps.ProductSize
				INNER JOIN DigblockModelBlock dbmb 
					ON dbmb.Digblock_Id = db.DigblockId
				INNER JOIN BhpbioModelBlock mb 
					ON mb.Model_Block_Id = dbmb.Model_Block_Id
				inner join ModelBlockPartial mbp
					on mbp.Model_Block_Id = mb.Model_Block_Id
				LEFT JOIN @GeometTypes gt
					on gt.ProductSize = ps.ProductSize
				LEFT JOIN BhpbioBlastBlockLumpPercent blp 
					ON blp.ModelBlockId = mb.Model_Block_Id
						and blp.SequenceNo = mbp.Sequence_No
						and blp.GeometType = gt.GeometType
			WHERE (ps.ProductSize = 'TOTAL' OR @iIncludeLumpFines = 1)
			
			INSERT INTO @Result
			SELECT
				db.DigblockId as BlastBlock,
				bm.Description as ModelName,
				pps.ProductSize,
				@CurrentMonth as ReportMonth,
				CASE WHEN a.DigblockId IS NOT NULL THEN 'True' Else 'False' End as Approved,
				mt.Abbreviation as OreType,
				COALESCE(se.GeometType, lp.GeometType, 'NA'),
				
				-- note under current design, there is only 1 mined percentage per block... if the Block is approved (and has summary data) .. then lr.MonthlyMinedPercent will be the same as the value approved
				COALESCE(se.Tonnes, (COALESCE(lr.MonthlyMinedPercent, MM.MinedPercentage) * mbp.Tonnes * pps.[Percent])) as DepletionTonnes,
				-- only output volume for TOTAL rows
				CASE WHEN pps.ProductSize = 'TOTAL' THEN COALESCE(se.Volume,(COALESCE(lr.MonthlyMinedPercent, MM.MinedPercentage) * mbpv.Field_Value * pps.[Percent])) ELSE NULL END as DepletionVolume,
				COALESCE(se.ModelFilename, mbpn.Notes) as ModelFilename,
			
				COALESCE(lr.MonthlyMinedPercent, MM.MinedPercentage) as MonthlyMinedPercent,
				COALESCE(lr.TotalMinedPercent, TM.TotalMinedPercentage) AS TotalMinedPercent,
			
				CASE WHEN pps.ProductSize = 'TOTAL' AND bm.Description = 'Grade Control Model' THEN COALESCE(ar.BestTonnes, lr.BestTonnes) * pps.[Percent] ELSE NULL END AS BestHauledTonnes,
				CASE WHEN pps.ProductSize = 'TOTAL' AND bm.Description = 'Grade Control Model' THEN COALESCE(ar.SurveyedTonnes, lr.SurveyedTonnes) * pps.[Percent] ELSE NULL END AS SurveyedTonnes,
				CASE WHEN pps.ProductSize = 'TOTAL' AND bm.Description = 'Grade Control Model' THEN COALESCE(ar.RemainingTonnes, lr.RemainingTonnes) * pps.[Percent] ELSE NULL END AS RemainingTonnes,
			
				CASE WHEN se.Tonnes IS NULL OR COALESCE(lr.MonthlyMinedPercent, MM.MinedPercentage,0) = 0 -- no approved data or no mined percentage
					THEN mbp.Tonnes * pps.[Percent] -- take from live
					ELSE se.Tonnes / COALESCE(lr.MonthlyMinedPercent, MM.MinedPercentage)  -- back-calculate from approved
					END as ModelTonnes,

				CASE WHEN pps.ProductSize = 'TOTAL' THEN
					CASE WHEN se.Volume IS NULL OR COALESCE(lr.MonthlyMinedPercent, MM.MinedPercentage,0) = 0 -- no approved data or no mined percentage
						THEN mbpv.Field_Value * pps.[Percent] -- calculate from live
						ELSE se.Volume / COALESCE(lr.MonthlyMinedPercent, MM.MinedPercentage)  -- back-calculate from approved
						END
				ELSE NULL END as ModelVolume,
				
				1 / COALESCE(S_Density.GradeValue,CASE WHEN pps.ProductSize = 'FINES' THEN lf_Density.FinesValue WHEN pps.ProductSize = 'LUMP' THEN lf_Density.LumpValue ELSE NULL END, Density.Grade_Value) as ModelDensity,
				COALESCE(S_Fe.GradeValue, CASE WHEN pps.ProductSize = 'FINES' THEN lf_Fe.FinesValue WHEN pps.ProductSize = 'LUMP' THEN lf_Fe.LumpValue ELSE NULL END, Fe.Grade_Value) as ModelFe,
				COALESCE(S_P.GradeValue, CASE WHEN pps.ProductSize = 'FINES' THEN lf_P.FinesValue WHEN pps.ProductSize = 'LUMP' THEN lf_P.LumpValue ELSE NULL END, P.Grade_Value) as ModelP,
				COALESCE(S_SiO2.GradeValue, CASE WHEN pps.ProductSize = 'FINES' THEN lf_SiO2.FinesValue WHEN pps.ProductSize = 'LUMP' THEN lf_SiO2.LumpValue ELSE NULL END, SiO2.Grade_Value) as ModelSiO2,
				COALESCE(S_Al2O3.GradeValue, CASE WHEN pps.ProductSize = 'FINES' THEN lf_Al2O3.FinesValue WHEN pps.ProductSize = 'LUMP' THEN lf_Al2O3.LumpValue ELSE NULL END, Al2O3.Grade_Value) as ModelAl2O3,
				COALESCE(S_LOI.GradeValue, CASE WHEN pps.ProductSize = 'FINES' THEN lf_LOI.FinesValue WHEN pps.ProductSize = 'LUMP' THEN lf_LOI.LumpValue ELSE NULL END, LOI.Grade_Value) as ModelLOI,
				COALESCE(S_H2O.GradeValue, CASE WHEN pps.ProductSize = 'FINES' THEN lf_H2O.FinesValue WHEN pps.ProductSize = 'LUMP' THEN lf_H2O.LumpValue ELSE NULL END,H2O.Grade_Value) AS ModelH2O,
				COALESCE(CASE WHEN S_ModelUltraFines.GradeValue > 0 THEN S_ModelUltraFines.GradeValue ELSE 0.0 END, CASE WHEN pps.ProductSize = 'FINES' THEN lf_UltraFines.FinesValue ELSE 0.0 END, NULL ) as ModelUltraFinesInFines,

				CASE 
					WHEN u.UserId IS NOT NULL THEN u.FirstName + ' ' + u.LastName
					WHEN u.UserId IS NULL AND a.UserId IS NOT NULL THEN 'Unknown User'
					ELSE ''
				END AS SignoffUser,
				a.SignOffDate,
				
				Case When bm.Description not like '%Short Term%' Then COALESCE(RCS_1.Value, RC_1.Field_Value) Else Null End AS Measured,
				Case When bm.Description not like '%Short Term%' Then COALESCE(RCS_2.Value, RC_2.Field_Value) Else Null End AS Indicated,
				Case When bm.Description not like '%Short Term%' Then COALESCE(RCS_3.Value, RC_3.Field_Value) Else Null End AS Inferred,
				Case When bm.Description not like '%Short Term%' Then COALESCE(RCS_4.Value, RC_4.Field_Value) Else Null End AS Potential,
				
				Case When bm.Description like '%Short Term%' Then COALESCE(RCS_1.Value, RC_1.Field_Value) Else Null End AS High,
				Case When bm.Description like '%Short Term%' Then COALESCE(RCS_2.Value, RC_2.Field_Value) Else Null End AS Medium,
				Case When bm.Description like '%Short Term%' Then COALESCE(RCS_3.Value, RC_3.Field_Value) Else Null End AS Low,
				Case When bm.Description like '%Short Term%' Then COALESCE(RCS_4.Value, RC_4.Field_Value) Else Null End AS [Very Low],
				
				COALESCE(RCS_5.Value, RC_5.Field_Value) AS [Default/Unclass],
				
				COALESCE(100 - COALESCE(RCS_1.Value, RC_1.Field_Value) 
					- COALESCE(RCS_2.Value, RC_2.Field_Value) 
					- COALESCE(RCS_3.Value, RC_3.Field_Value) 
					- COALESCE(RCS_4.Value, RC_4.Field_Value)
					- COALESCE(RCS_5.Value, RC_5.Field_Value)
				, 100) AS [No Information]
			
			FROM @DistinctDigblocks db INNER JOIN Digblock d ON (d.Digblock_Id = db.DigblockId)
				INNER JOIN DigblockLocation dl ON (dl.Digblock_Id = d.Digblock_Id)
				LEFT JOIN @LiveResults lr ON lr.DigblockId = db.DigblockId
				LEFT JOIN @ApprovedResults ar ON ar.DigblockId = db.DigblockId
				LEFT JOIN dbo.BhpbioApprovalDigblock a ON a.DigblockID = db.DigblockId AND a.ApprovedMonth = @CurrentMonth
				LEFT JOIN dbo.SecurityUser u ON u.UserId = a.UserId 
				LEFT JOIN dbo.BhpbioImportReconciliationMovement AS MM ON (MM.DateFrom = @CurrentMonth AND DL.Location_Id = MM.BlockLocationId)
				LEFT JOIN (
					SELECT BlockLocationId, SUM(MinedPercentage) AS TotalMinedPercentage
					FROM dbo.BhpbioImportReconciliationMovement
					WHERE DateTo < DateAdd(m, 1, @CurrentMonth)
					GROUP BY BlockLocationId
				) AS TM ON DL.Location_Id = TM.BlockLocationId
				INNER JOIN DigblockModelBlock dbmb ON dbmb.Digblock_Id = db.DigblockId
				INNER JOIN BhpbioModelBlock mb ON mb.Model_Block_Id = dbmb.Model_Block_Id
				INNER JOIN BlockModel bm ON bm.Block_Model_Id = mb.Block_Model_Id
				INNER JOIN ModelBlockPartial mbp ON mbp.Model_Block_Id = mb.Model_Block_Id
				INNER JOIN @ModelBlockPercentByProductSize pps 
					ON pps.ModelBlockId = mb.Model_Block_Id		
						AND pps.BlockModelId = mb.Block_Model_Id 
						AND pps.SequenceNo = mbp.Sequence_No
				LEFT JOIN BhpbioBlastBlockLumpPercent lp 
					ON lp.ModelBlockId = mb.Model_Block_Id 
						AND lp.SequenceNo = mbp.Sequence_No 
						And lp.GeometType = pps.GeometType
				INNER JOIN MaterialType mt ON mt.Material_Type_Id = mbp.Material_Type_Id
				LEFT JOIN ModelBlockPartialNotes mbpn ON mbpn.Model_Block_Id = mbp.Model_Block_Id AND mbpn.Sequence_No = mbp.Sequence_No AND mbpn.Model_Block_Partial_Field_Id = 'ModelFilename'
				LEFT JOIN ModelBlockPartialValue mbpv ON mbpv.Model_Block_Id = mbp.Model_Block_Id AND mbpv.Sequence_No = mbp.Sequence_No AND mbpv.Model_Block_Partial_Field_Id = 'ModelVolume'
			
				-- live head grades
				INNER JOIN ModelBlockPartialGrade Fe ON fe.Grade_Id = 1 AND fe.Model_Block_Id = mbp.Model_Block_Id AND fe.Sequence_No = mbp.Sequence_No
				INNER JOIN ModelBlockPartialGrade P ON P.Grade_Id = 2 AND P.Model_Block_Id = mbp.Model_Block_Id AND P.Sequence_No = mbp.Sequence_No
				INNER JOIN ModelBlockPartialGrade SiO2 ON SiO2.Grade_Id = 3 AND SiO2.Model_Block_Id = mbp.Model_Block_Id AND SiO2.Sequence_No = mbp.Sequence_No
				INNER JOIN ModelBlockPartialGrade Al2O3 ON Al2O3.Grade_Id = 4 AND Al2O3.Model_Block_Id = mbp.Model_Block_Id AND Al2O3.Sequence_No = mbp.Sequence_No
				INNER JOIN ModelBlockPartialGrade LOI ON LOI.Grade_Id = 5 AND LOI.Model_Block_Id = mbp.Model_Block_Id AND LOI.Sequence_No = mbp.Sequence_No
				LEFT JOIN ModelBlockPartialGrade Density ON Density.Grade_Id = 6 AND Density.Model_Block_Id = mbp.Model_Block_Id AND Density.Sequence_No = mbp.Sequence_No
				LEFT JOIN ModelBlockPartialGrade H2O ON H2O.Grade_Id = 7 AND H2O.Model_Block_Id = mbp.Model_Block_Id AND H2O.Sequence_No = mbp.Sequence_No

				
				-- live RC values
				LEFT JOIN dbo.ModelBlockPartialValue RC_1 ON RC_1.Model_Block_Id = mbp.Model_Block_Id AND RC_1.Sequence_No = mbp.Sequence_No AND RC_1.Model_Block_Partial_Field_Id = 'ResourceClassification1'
				LEFT JOIN dbo.ModelBlockPartialValue RC_2 ON RC_2.Model_Block_Id = mbp.Model_Block_Id AND RC_2.Sequence_No = mbp.Sequence_No AND RC_2.Model_Block_Partial_Field_Id = 'ResourceClassification2'
				LEFT JOIN dbo.ModelBlockPartialValue RC_3 ON RC_3.Model_Block_Id = mbp.Model_Block_Id AND RC_3.Sequence_No = mbp.Sequence_No AND RC_3.Model_Block_Partial_Field_Id = 'ResourceClassification3'
				LEFT JOIN dbo.ModelBlockPartialValue RC_4 ON RC_4.Model_Block_Id = mbp.Model_Block_Id AND RC_4.Sequence_No = mbp.Sequence_No AND RC_4.Model_Block_Partial_Field_Id = 'ResourceClassification4'
				LEFT JOIN dbo.ModelBlockPartialValue RC_5 ON RC_5.Model_Block_Id = mbp.Model_Block_Id AND RC_5.Sequence_No = mbp.Sequence_No AND RC_5.Model_Block_Partial_Field_Id = 'ResourceClassification5'
				
				-- live lump and fines grades
				LEFT JOIN BhpbioBlastBlockLumpFinesGrade lf_Fe ON lf_Fe.GradeId = 1 AND lf_Fe.ModelBlockId = mbp.Model_Block_Id AND lf_Fe.SequenceNo = mbp.Sequence_No AND lf_Fe.GeometType = lp.GeometType
				LEFT JOIN BhpbioBlastBlockLumpFinesGrade lf_P ON lf_P.GradeId = 2 AND lf_P.ModelBlockId = mbp.Model_Block_Id AND lf_P.SequenceNo = mbp.Sequence_No AND lf_P.GeometType = lp.GeometType
				LEFT JOIN BhpbioBlastBlockLumpFinesGrade lf_SiO2 ON lf_SiO2.GradeId = 3 AND lf_SiO2.ModelBlockId = mbp.Model_Block_Id AND lf_SiO2.SequenceNo = mbp.Sequence_No AND lf_SiO2.GeometType = lp.GeometType
				LEFT JOIN BhpbioBlastBlockLumpFinesGrade lf_Al2O3 ON lf_Al2O3.GradeId = 4 AND lf_Al2O3.ModelBlockId = mbp.Model_Block_Id AND lf_Al2O3.SequenceNo = mbp.Sequence_No AND lf_Al2O3.GeometType = lp.GeometType
				LEFT JOIN BhpbioBlastBlockLumpFinesGrade lf_LOI ON lf_LOI.GradeId = 5 AND lf_LOI.ModelBlockId = mbp.Model_Block_Id AND lf_LOI.SequenceNo = mbp.Sequence_No AND lf_LOI.GeometType = lp.GeometType
				LEFT JOIN BhpbioBlastBlockLumpFinesGrade lf_Density ON lf_Density.GradeId = 6 AND lf_Density.ModelBlockId = mbp.Model_Block_Id AND lf_Density.SequenceNo = mbp.Sequence_No AND lf_Density.GeometType = lp.GeometType
				LEFT JOIN BhpbioBlastBlockLumpFinesGrade lf_H2O ON lf_H2O.GradeId = 7 AND lf_H2O.ModelBlockId = mbp.Model_Block_Id AND lf_H2O.SequenceNo = mbp.Sequence_No AND lf_H2O.GeometType = lp.GeometType
				LEFT JOIN BhpbioBlastBlockLumpFinesGrade lf_UltraFines ON lf_UltraFines.GradeId = 10 AND lf_UltraFines.ModelBlockId = mbp.Model_Block_Id AND lf_UltraFines.SequenceNo = mbp.Sequence_No AND lf_UltraFines.GeometType = lp.GeometType
						
				-- approval main record
				LEFT JOIN dbo.BhpbioSummary s ON s.SummaryMonth = @CurrentMonth AND @iIncludeApprovedData = 1
				LEFT JOIN dbo.BhpbioSummaryEntryType st ON st.AssociatedBlockModelId = bm.Block_Model_Id AND st.Name like '%Movement' AND @iIncludeApprovedData = 1
				LEFT JOIN dbo.BhpbioSummaryEntry se 
					ON se.SummaryEntryTypeId = st.SummaryEntryTypeId 
						AND se.SummaryId = s.SummaryId 
						AND se.LocationId = dl.Location_Id 
						AND se.MaterialTypeId = mt.Material_Type_Id 
						AND se.ProductSize = pps.ProductSize
						And se.GeometType = pps.GeometType
				
				-- approved grades
				LEFT JOIN BhpbioSummaryEntryGrade S_Fe ON	S_Fe.SummaryEntryId = se.SummaryEntryId AND	S_Fe.GradeId = 1 
				LEFT JOIN BhpbioSummaryEntryGrade S_P ON	S_P.SummaryEntryId = se.SummaryEntryId AND	S_P.GradeId = 2 
				LEFT JOIN BhpbioSummaryEntryGrade S_SiO2 ON	S_SiO2.SummaryEntryId = se.SummaryEntryId AND	S_SiO2.GradeId = 3 
				LEFT JOIN BhpbioSummaryEntryGrade S_Al2O3 ON	S_Al2O3.SummaryEntryId = se.SummaryEntryId AND	S_Al2O3.GradeId = 4 
				LEFT JOIN BhpbioSummaryEntryGrade S_LOI ON	S_LOI.SummaryEntryId = se.SummaryEntryId AND	S_LOI.GradeId = 5 
				LEFT JOIN BhpbioSummaryEntryGrade S_Density ON	S_Density.SummaryEntryId = se.SummaryEntryId AND	S_Density.GradeId = 6 
				LEFT JOIN BhpbioSummaryEntryGrade S_H2O ON	S_H2O.SummaryEntryId = se.SummaryEntryId AND	S_H2O.GradeId = 7 
				LEFT JOIN BhpbioSummaryEntryGrade S_ModelUltraFines ON	S_ModelUltraFines.SummaryEntryId = se.SummaryEntryId AND S_ModelUltraFines.GradeId = 10
														
				-- approved RC values
				LEFT JOIN dbo.BhpbioSummaryEntryField RCSF_1 ON RCSF_1.Name = 'ResourceClassification1'
				LEFT JOIN dbo.BhpbioSummaryEntryField RCSF_2 ON RCSF_2.Name = 'ResourceClassification2'
				LEFT JOIN dbo.BhpbioSummaryEntryField RCSF_3 ON RCSF_3.Name = 'ResourceClassification3'
				LEFT JOIN dbo.BhpbioSummaryEntryField RCSF_4 ON RCSF_4.Name = 'ResourceClassification4'
				LEFT JOIN dbo.BhpbioSummaryEntryField RCSF_5 ON RCSF_5.Name = 'ResourceClassification5'
									
				LEFT JOIN dbo.BhpbioSummaryEntryFieldValue RCS_1 ON RCS_1.SummaryEntryFieldId = RCSF_1.SummaryEntryFieldId AND RCS_1.SummaryEntryId = se.SummaryEntryId
				LEFT JOIN dbo.BhpbioSummaryEntryFieldValue RCS_2 ON RCS_2.SummaryEntryFieldId = RCSF_2.SummaryEntryFieldId AND RCS_2.SummaryEntryId = se.SummaryEntryId
				LEFT JOIN dbo.BhpbioSummaryEntryFieldValue RCS_3 ON RCS_3.SummaryEntryFieldId = RCSF_3.SummaryEntryFieldId AND RCS_3.SummaryEntryId = se.SummaryEntryId						
				LEFT JOIN dbo.BhpbioSummaryEntryFieldValue RCS_4 ON RCS_4.SummaryEntryFieldId = RCSF_4.SummaryEntryFieldId AND RCS_4.SummaryEntryId = se.SummaryEntryId
				LEFT JOIN dbo.BhpbioSummaryEntryFieldValue RCS_5 ON RCS_5.SummaryEntryFieldId = RCSF_5.SummaryEntryFieldId AND RCS_5.SummaryEntryId = se.SummaryEntryId
			
			WHERE (@iIncludeLiveData = 1 Or (NOT se.SummaryEntryId 	IS NULL))
			
			SET @CurrentMonth = DATEADD(MONTH, 1, @CurrentMonth) --for the next while loop iteration
		END
		

		Select	*
		From @Result
		ORDER BY ModelName, 
			BlastBlock, 
			(CASE 
				WHEN ProductSize = 'TOTAL' THEN 1 
				WHEN ProductSize = 'LUMP' THEN 2 
				WHEN ProductSize = 'FINES' THEN 3
				ELSE 4
			END),
			OreType

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

GRANT EXECUTE ON dbo.GetBhpbioBlastblockbyOreTypeDataExportReport TO BhpbioGenericManager
GO
