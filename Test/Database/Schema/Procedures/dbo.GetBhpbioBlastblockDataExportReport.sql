IF OBJECT_ID('dbo.GetBhpbioBlastblockDataExportReport') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioBlastblockDataExportReport  
GO 

CREATE PROCEDURE dbo.GetBhpbioBlastblockDataExportReport
(
	@iLocationId INT,
	@iStartMonth DATETIME,
	@iEndMonth DATETIME,
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
	DECLARE @Results TABLE
	(
		Blastblock VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		[Month] DATETIME,
		Approved VARCHAR(5),
		OreType VARCHAR(63),
		GeologyDepletionTonnes FLOAT NULL,
		MiningDepletionTonnes FLOAT NULL,
		ShortTermGeologyDepletionTonnes FLOAT NULL,
		GradeControlDepletionTonnes FLOAT NULL,
		GeologyDepletionVolume FLOAT NULL,
		MiningDepletionVolume FLOAT NULL,
		ShortTermGeologyDepletionVolume FLOAT NULL,
		GradeControlDepletionVolume FLOAT NULL,
		GeologyModelFilename VARCHAR(200) NULL,
		MiningModelFilename VARCHAR(200) NULL,
		ShortTermGeologyModelFilename VARCHAR(200) NULL,
		GradeControlModelFilename VARCHAR(200) NULL,
		MonthlyMinedPercent FLOAT NULL,
		TotalMinedPercent FLOAT NULL,
		BestHauledTonnes FLOAT NULL,--Best Tonnes
		SurveyedTonnes FLOAT NULL,
		RemainingTonnes FLOAT NULL,
		GeologyModelTonnes FLOAT NULL,
		MiningModelTonnes FLOAT NULL,
		ShortTermGeologyModelTonnes FLOAT NULL,
		GradeControlModelTonnes FLOAT NULL,
		GeologyModelVolume FLOAT NULL,
		MiningModelVolume FLOAT NULL,
		ShortTermGeologyModelVolume FLOAT NULL,
		GradeControlModelVolume FLOAT NULL,
		GeologyModelDensity FLOAT NULL,
		MiningModelDensity FLOAT NULL,
		ShortTermGeologyModelDensity FLOAT NULL,
		GradeControlModelDensity FLOAT NULL,
		GeologyModelFe FLOAT NULL,
		MiningModelFe FLOAT NULL,
		ShortTermGeologyModelFe FLOAT NULL,
		GradeControlModelFe FLOAT NULL,
		GeologyModelP FLOAT NULL,
		MiningModelP FLOAT NULL,
		ShortTermGeologyModelP FLOAT NULL,
		GradeControlModelP FLOAT NULL,
		GeologyModelSiO2 FLOAT NULL,
		MiningModelSiO2 FLOAT NULL,
		ShortTermGeologyModelSiO2 FLOAT NULL,
		GradeControlModelSiO2 FLOAT NULL,
		GeologyModelAl2O3 FLOAT NULL,
		MiningModelAl2O3 FLOAT NULL,
		ShortTermGeologyModelAl2O3 FLOAT NULL,
		GradeControlModelAl2O3 FLOAT NULL,
		GeologyModelLOI FLOAT NULL,
		MiningModelLOI FLOAT NULL,
		ShortTermGeologyModelLOI FLOAT NULL,
		GradeControlModelLOI FLOAT NULL,
		GeologyModelH2O FLOAT NULL,
		MiningModelH2O FLOAT NULL,
		ShortTermGeologyModelH2O FLOAT NULL,
		GradeControlModelH2O FLOAT NULL,
		MiningModelH2OAsDropped FLOAT NULL,
		ShortTermGeologyModelH2OAsDropped FLOAT NULL,
		MiningModelH2OAsShipped FLOAT NULL,
		ShortTermGeologyModelH2OAsShipped FLOAT NULL,
		SignoffUser VARCHAR(513)
	)
	
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
			
			
			INSERT INTO @Results
			(
				Blastblock, [Month], Approved, OreType, GeologyDepletionTonnes, MiningDepletionTonnes, ShortTermGeologyDepletionTonnes, GradeControlDepletionTonnes,
				GeologyDepletionVolume, MiningDepletionVolume, ShortTermGeologyDepletionVolume, GradeControlDepletionVolume,	
				GeologyModelFilename, MiningModelFilename, ShortTermGeologyModelFilename, GradeControlModelFilename, 
				MonthlyMinedPercent, TotalMinedPercent, BestHauledTonnes, SurveyedTonnes, RemainingTonnes,
				GeologyModelTonnes, MiningModelTonnes, ShortTermGeologyModelTonnes, GradeControlModelTonnes, 
				GeologyModelVolume, MiningModelVolume, ShortTermGeologyModelVolume, GradeControlModelVolume,	
				GeologyModelDensity, MiningModelDensity, ShortTermGeologyModelDensity, GradeControlModelDensity,
				GeologyModelFe, MiningModelFe, ShortTermGeologyModelFe, GradeControlModelFe,
				GeologyModelP, MiningModelP, ShortTermGeologyModelP, GradeControlModelP, 
				GeologyModelSiO2, MiningModelSiO2, ShortTermGeologyModelSiO2, GradeControlModelSiO2, 
				GeologyModelAl2O3, MiningModelAl2O3, ShortTermGeologyModelAl2O3, GradeControlModelAl2O3, 
				GeologyModelLOI, MiningModelLOI, ShortTermGeologyModelLOI, GradeControlModelLOI, 
				GeologyModelH2O, MiningModelH2O, ShortTermGeologyModelH2O, GradeControlModelH2O, 
				MiningModelH2OAsDropped, ShortTermGeologyModelH2OAsDropped, 
				MiningModelH2OAsShipped, ShortTermGeologyModelH2OAsShipped, 
				SignoffUser
			)
			SELECT dd.DigblockId,
				@CurrentMonth,
				CASE WHEN a.DigblockId IS NOT NULL THEN 'True' ELSE 'False' END,
				mt.Description,
				-- monthly depletion tonnes
				COALESCE(ar.GeologyTonnes, lr.GeologyTonnes),
				COALESCE(ar.MiningTonnes, lr.MiningTonnes),
				COALESCE(ar.ShortTermGeologyTonnes, lr.ShortTermGeologyTonnes),
				COALESCE(ar.GradeControlTonnes, lr.GradeControlTonnes),
				
				---- monthly depletion volume
				COALESCE(ar.GeologyVolume, lr.GeologyVolume),
				COALESCE(ar.MiningVolume, lr.MiningVolume),
				COALESCE(ar.ShortTermGeologyVolume, lr.ShortTermGeologyVolume),
				COALESCE(ar.GradeControlVolume, lr.GradeControlVolume),
				
				-- ensure that depletion tonnes and model filenames are aligned (i.e. if approved tonnes is used, then approved filename should be displayed, even if it's null)
				CASE WHEN ar.GeologyTonnes IS NOT NULL
					THEN ar.GeologyModelFilename
					ELSE lr.GeologyModelFilename
				END,
				CASE WHEN ar.MiningTonnes IS NOT NULL
					THEN ar.MiningModelFilename
					ELSE lr.MiningModelFilename
				END,
				CASE WHEN ar.ShortTermGeologyTonnes IS NOT NULL
					THEN ar.ShortTermGeologyModelFilename
					ELSE lr.ShortTermGeologyModelFilename
				END,
				CASE WHEN ar.GradeControlTonnes IS NOT NULL
					THEN ar.GradeControlModelFilename
					ELSE lr.GradeControlModelFilename
				END,
				-- depletions
				COALESCE(lr.MonthlyMinedPercent, RM.MinedPercentage) as MonthlyMinedPercent,
				COALESCE(lr.TotalMinedPercent, TM.TotalMinedPercentage) AS TotalMinedPercent,
				-- actual tonnages
				COALESCE(ar.BestTonnes, lr.BestTonnes) AS BestTonnes,
				COALESCE(ar.SurveyedTonnes, lr.SurveyedTonnes) AS SurveyedTonnes,
				COALESCE(ar.RemainingTonnes, lr.RemainingTonnes) AS RemainingTonnes,
				
				model.GeologyModelTonnes,
				model.MiningModelTonnes,
				model.ShortTermGeologyModelTonnes,
				model.GradeControlModelTonnes,
				
				model.GeologyModelVolume,
				model.MiningModelVolume,
				model.ShortTermGeologyModelVolume,
				model.GradeControlModelVolume,
				
				-- Density needs to be inverted for display - it is stored as m3/t, but needs to be
				-- displayed to users as t/m3
				1 / modelGrade.GeologyModelDensity,
				1 / modelGrade.MiningModelDensity,
				1 / modelGrade.ShortTermGeologyModelDensity,
				1 / modelGrade.GradeControlModelDensity,
				
				modelGrade.GeologyModelFe,
				modelGrade.MiningModelFe,
				modelGrade.ShortTermGeologyModelFe,
				modelGrade.GradeControlModelFe,
				
				modelGrade.GeologyModelP,
				modelGrade.MiningModelP,
				modelGrade.ShortTermGeologyModelP,
				modelGrade.GradeControlModelP,
				
				modelGrade.GeologyModelSiO2,
				modelGrade.MiningModelSiO2,
				modelGrade.ShortTermGeologyModelSiO2,
				modelGrade.GradeControlModelSiO2,
				
				modelGrade.GeologyModelAl2O3,
				modelGrade.MiningModelAl2O3,
				modelGrade.ShortTermGeologyModelAl2O3,
				modelGrade.GradeControlModelAl2O3,
				
				modelGrade.GeologyModelLOI,
				modelGrade.MiningModelLOI,
				modelGrade.ShortTermGeologyModelLOI,
				modelGrade.GradeControlModelLOI,
				
				modelGrade.GeologyModelH2O,
				modelGrade.MiningModelH2O,
				modelGrade.ShortTermGeologyModelH2O,
				modelGrade.GradeControlModelH2O,
				
				modelGrade.MiningModelH2OAsDropped,
				modelGrade.ShortTermGeologyModelH2OAsDropped,
				
				modelGrade.MiningModelH2OAsShipped,
				modelGrade.ShortTermGeologyModelH2OAsShipped,
				
				CASE 
					WHEN u.UserId IS NOT NULL THEN u.FirstName + ' ' + u.LastName
					WHEN u.UserId IS NULL AND a.UserId IS NOT NULL THEN 'Unknown User'
					ELSE ''
				END
			FROM @DistinctDigblocks dd
				INNER JOIN Digblock d
					ON (d.Digblock_Id = dd.DigblockId)
				INNER JOIN DigblockLocation dl
					ON (dl.Digblock_Id = d.Digblock_Id)
				INNER JOIN dbo.MaterialType mt
					ON (mt.Material_Type_Id = d.Material_Type_Id)
				LEFT JOIN @LiveResults lr 
					ON (lr.DigblockId = dd.DigblockId)
				LEFT JOIN @ApprovedResults ar
					ON (ar.DigblockId = dd.DigblockId)
				LEFT JOIN dbo.BhpbioApprovalDigblock a
					ON (a.DigblockID = dd.DigblockId
						AND a.ApprovedMonth = @CurrentMonth)
				LEFT JOIN dbo.BhpbioImportReconciliationMovement AS RM
					ON (RM.DateFrom = @CurrentMonth
						AND DL.Location_Id = RM.BlockLocationId)
				LEFT JOIN
				(
					SELECT BlockLocationId, SUM(MinedPercentage) AS TotalMinedPercentage
					FROM dbo.BhpbioImportReconciliationMovement
					WHERE DateTo < DateAdd(m, 1, @CurrentMonth)
					GROUP BY BlockLocationId
				)
				AS TM
					ON DL.Location_Id = TM.BlockLocationId
				LEFT JOIN dbo.SecurityUser u
					ON (u.UserId = a.UserId)
				LEFT JOIN
				(
					SELECT dd.DigblockId,
						SUM(CASE WHEN BM.Name = 'Geology' THEN MBP.Tonnes ELSE NULL END) As GeologyModelTonnes,
						SUM(CASE WHEN BM.Name = 'Mining' THEN MBP.Tonnes ELSE NULL END) AS MiningModelTonnes,
						SUM(CASE WHEN BM.Name = 'Short Term Geology' THEN MBP.Tonnes ELSE NULL END) AS ShortTermGeologyModelTonnes,
						SUM(CASE WHEN BM.Name = 'Grade Control' THEN MBP.Tonnes ELSE NULL END) AS GradeControlModelTonnes,
						
						SUM(CASE WHEN BM.Name = 'Geology' THEN MBPF.Field_Value ELSE NULL END) As GeologyModelVolume,
						SUM(CASE WHEN BM.Name = 'Mining' THEN MBPF.Field_Value ELSE NULL END) AS MiningModelVolume,
						SUM(CASE WHEN BM.Name = 'Short Term Geology' THEN MBPF.Field_Value ELSE NULL END) AS ShortTermGeologyModelVolume,
						SUM(CASE WHEN BM.Name = 'Grade Control' THEN MBPF.Field_Value ELSE NULL END) AS GradeControlModelVolume
						
					FROM @DistinctDigblocks dd
						INNER JOIN dbo.ModelBlock AS MB
							ON (dd.DigblockId = MB.Code)
						INNER JOIN dbo.BlockModel AS BM
							ON (BM.Block_Model_Id = MB.Block_Model_Id)
						INNER JOIN dbo.ModelBlockPartial AS MBP
							ON (MB.Model_Block_Id = MBP.Model_Block_Id)
						LEFT JOIN dbo.ModelBlockPartialValue AS MBPF
							ON (MBPF.Model_Block_Id = MBP.Model_Block_Id
								AND MBPF.Sequence_No = MBP.Sequence_No
								AND MBPF.Model_Block_Partial_Field_Id = @modelVolumeFieldId)
					GROUP BY dd.DigblockId
				) AS model
					ON dd.DigblockId = model.DigblockId
				LEFT JOIN
				(
					SELECT dd.DigblockId,
						SUM(CASE WHEN BM.Name = 'Geology' AND g.Grade_Name = 'Density' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Geology' AND g.Grade_Name = 'Density' THEN MBP.Tonnes ELSE NULL END)
							AS GeologyModelDensity,
						SUM(CASE WHEN BM.Name = 'Geology' AND g.Grade_Name = 'Fe' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Geology' AND g.Grade_Name = 'Fe' THEN MBP.Tonnes ELSE NULL END)
							AS GeologyModelFe,
						SUM(CASE WHEN BM.Name = 'Geology' AND g.Grade_Name = 'P' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Geology' AND g.Grade_Name = 'P' THEN MBP.Tonnes ELSE NULL END)
							AS GeologyModelP,
						SUM(CASE WHEN BM.Name = 'Geology' AND g.Grade_Name = 'SiO2' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Geology' AND g.Grade_Name = 'SiO2' THEN MBP.Tonnes ELSE NULL END)
							AS GeologyModelSiO2,
						SUM(CASE WHEN BM.Name = 'Geology' AND g.Grade_Name = 'Al2O3' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Geology' AND g.Grade_Name = 'Al2O3' THEN MBP.Tonnes ELSE NULL END)
							AS GeologyModelAl2O3,
						SUM(CASE WHEN BM.Name = 'Geology' AND g.Grade_Name = 'LOI' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Geology' AND g.Grade_Name = 'LOI' THEN MBP.Tonnes ELSE NULL END)
							AS GeologyModelLOI,
						SUM(CASE WHEN BM.Name = 'Geology' AND g.Grade_Name = 'H2O' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Geology' AND g.Grade_Name = 'H2O' THEN MBP.Tonnes ELSE NULL END)
							AS GeologyModelH2O,
							
						SUM(CASE WHEN BM.Name = 'Mining' AND g.Grade_Name = 'Density' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Mining' AND g.Grade_Name = 'Density' THEN MBP.Tonnes ELSE NULL END)
							AS MiningModelDensity,
						SUM(CASE WHEN BM.Name = 'Mining' AND g.Grade_Name = 'Fe' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Mining' AND g.Grade_Name = 'Fe' THEN MBP.Tonnes ELSE NULL END)
							AS MiningModelFe,
						SUM(CASE WHEN BM.Name = 'Mining' AND g.Grade_Name = 'P' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Mining' AND g.Grade_Name = 'P' THEN MBP.Tonnes ELSE NULL END)
							AS MiningModelP,
						SUM(CASE WHEN BM.Name = 'Mining' AND g.Grade_Name = 'SiO2' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Mining' AND g.Grade_Name = 'SiO2' THEN MBP.Tonnes ELSE NULL END)
							AS MiningModelSiO2,
						SUM(CASE WHEN BM.Name = 'Mining' AND g.Grade_Name = 'Al2O3' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Mining' AND g.Grade_Name = 'Al2O3' THEN MBP.Tonnes ELSE NULL END)
							AS MiningModelAl2O3,
						SUM(CASE WHEN BM.Name = 'Mining' AND g.Grade_Name = 'LOI' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Mining' AND g.Grade_Name = 'LOI' THEN MBP.Tonnes ELSE NULL END)
							AS MiningModelLOI,
						SUM(CASE WHEN BM.Name = 'Mining' AND g.Grade_Name = 'H2O' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Mining' AND g.Grade_Name = 'H2O' THEN MBP.Tonnes ELSE NULL END)
							AS MiningModelH2O,
						SUM(CASE WHEN BM.Name = 'Mining' AND g.Grade_Name = 'H2O-As-Dropped' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Mining' AND g.Grade_Name = 'H2O-As-Dropped' THEN MBP.Tonnes ELSE NULL END)
							AS MiningModelH2OAsDropped,
						SUM(CASE WHEN BM.Name = 'Mining' AND g.Grade_Name = 'H2O-As-Shipped' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Mining' AND g.Grade_Name = 'H2O-As-Shipped' THEN MBP.Tonnes ELSE NULL END)
							AS MiningModelH2OAsShipped,

						SUM(CASE WHEN BM.Name = 'Short Term Geology' AND g.Grade_Name = 'Density' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Short Term Geology' AND g.Grade_Name = 'Density' THEN MBP.Tonnes ELSE NULL END)
							AS ShortTermGeologyModelDensity,
						SUM(CASE WHEN BM.Name = 'Short Term Geology' AND g.Grade_Name = 'Fe' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Short Term Geology' AND g.Grade_Name = 'Fe' THEN MBP.Tonnes ELSE NULL END)
							AS ShortTermGeologyModelFe,
						SUM(CASE WHEN BM.Name = 'Short Term Geology' AND g.Grade_Name = 'P' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Short Term Geology' AND g.Grade_Name = 'P' THEN MBP.Tonnes ELSE NULL END)
							AS ShortTermGeologyModelP,
						SUM(CASE WHEN BM.Name = 'Short Term Geology' AND g.Grade_Name = 'SiO2' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Short Term Geology' AND g.Grade_Name = 'SiO2' THEN MBP.Tonnes ELSE NULL END)
							AS ShortTermGeologyModelSiO2,
						SUM(CASE WHEN BM.Name = 'Short Term Geology' AND g.Grade_Name = 'Al2O3' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Short Term Geology' AND g.Grade_Name = 'Al2O3' THEN MBP.Tonnes ELSE NULL END)
							AS ShortTermGeologyModelAl2O3,
						SUM(CASE WHEN BM.Name = 'Short Term Geology' AND g.Grade_Name = 'LOI' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Short Term Geology' AND g.Grade_Name = 'LOI' THEN MBP.Tonnes ELSE NULL END)
							AS ShortTermGeologyModelLOI,
						SUM(CASE WHEN BM.Name = 'Short Term Geology' AND g.Grade_Name = 'H2O' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Short Term Geology' AND g.Grade_Name = 'H2O' THEN MBP.Tonnes ELSE NULL END)
							AS ShortTermGeologyModelH2O,
						SUM(CASE WHEN BM.Name = 'Short Term Geology' AND g.Grade_Name = 'H2O-As-Dropped' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Short Term Geology' AND g.Grade_Name = 'H2O-As-Dropped' THEN MBP.Tonnes ELSE NULL END)
							AS ShortTermGeologyModelH2OAsDropped,
						SUM(CASE WHEN BM.Name = 'Short Term Geology' AND g.Grade_Name = 'H2O-As-Shipped' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Short Term Geology' AND g.Grade_Name = 'H2O-As-Shipped' THEN MBP.Tonnes ELSE NULL END)
							AS ShortTermGeologyModelH2OAsShipped,
							
						
						SUM(CASE WHEN BM.Name = 'Grade Control' AND g.Grade_Name = 'Density' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Grade Control' AND g.Grade_Name = 'Density' THEN MBP.Tonnes ELSE NULL END)
							AS GradeControlModelDensity,
						SUM(CASE WHEN BM.Name = 'Grade Control' AND g.Grade_Name = 'Fe' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Grade Control' AND g.Grade_Name = 'Fe' THEN MBP.Tonnes ELSE NULL END)
							AS GradeControlModelFe,
						SUM(CASE WHEN BM.Name = 'Grade Control' AND g.Grade_Name = 'P' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Grade Control' AND g.Grade_Name = 'P' THEN MBP.Tonnes ELSE NULL END)
							AS GradeControlModelP,
						SUM(CASE WHEN BM.Name = 'Grade Control' AND g.Grade_Name = 'SiO2' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Grade Control' AND g.Grade_Name = 'SiO2' THEN MBP.Tonnes ELSE NULL END)
							AS GradeControlModelSiO2,
						SUM(CASE WHEN BM.Name = 'Grade Control' AND g.Grade_Name = 'Al2O3' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Grade Control' AND g.Grade_Name = 'Al2O3' THEN MBP.Tonnes ELSE NULL END)
							AS GradeControlModelAl2O3,
						SUM(CASE WHEN BM.Name = 'Grade Control' AND g.Grade_Name = 'LOI' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Grade Control' AND g.Grade_Name = 'LOI' THEN MBP.Tonnes ELSE NULL END)
							AS GradeControlModelLOI,
						SUM(CASE WHEN BM.Name = 'Grade Control' AND g.Grade_Name = 'H2O' THEN MBP.Tonnes * MBPG.Grade_Value ELSE NULL END)
							/ SUM(CASE WHEN BM.Name = 'Grade Control' AND g.Grade_Name = 'H2O' THEN MBP.Tonnes ELSE NULL END)
							AS GradeControlModelH2O
							
					FROM @DistinctDigblocks dd
						INNER JOIN dbo.ModelBlock AS MB
							ON (dd.DigblockId = MB.Code)
						INNER JOIN dbo.BlockModel AS BM
							ON (BM.Block_Model_Id = MB.Block_Model_Id)
						INNER JOIN dbo.ModelBlockPartial AS MBP
							ON (MB.Model_Block_Id = MBP.Model_Block_Id)
						LEFT JOIN dbo.ModelBlockPartialGrade MBPG
							ON (MB.Model_Block_Id = MBPG.Model_Block_Id
								AND MBP.Sequence_No = MBPG.Sequence_No)
						LEFT JOIN dbo.Grade g
							ON (MBPG.Grade_Id = g.Grade_Id)
					GROUP BY dd.DigblockId
				) AS modelGrade
					ON dd.DigblockId = modelGrade.DigblockId
			WHERE (@iIncludeLiveData = 1 OR @iIncludeApprovedData = 1) --combined
				OR (a.DigblockId IS NULL AND @iIncludeLiveData = 1) -- live 
				OR (a.DigblockId IS NOT NULL AND @iIncludeApprovedData = 1) --approved only
				
			SET @CurrentMonth = DATEADD(MONTH, 1, @CurrentMonth) --for the next while loop iteration
		END
		
		-- return results
		SELECT Blastblock, [Month], Approved, OreType, GeologyDepletionTonnes, MiningDepletionTonnes, ShortTermGeologyDepletionTonnes As ShortTermDepletionTonnes, GradeControlDepletionTonnes,
			GeologyDepletionVolume, MiningDepletionVolume, ShortTermGeologyDepletionVolume As ShortTermDepletionVolume, GradeControlDepletionVolume,
			MonthlyMinedPercent, TotalMinedPercent, BestHauledTonnes, RemainingTonnes, 
			GeologyModelTonnes, MiningModelTonnes, ShortTermGeologyModelTonnes As ShortTermModelTonnes, GradeControlModelTonnes,
			GeologyModelVolume, MiningModelVolume, ShortTermGeologyModelVolume As ShortTermModelVolume, GradeControlModelVolume,
			GeologyModelDensity, MiningModelDensity, ShortTermGeologyModelDensity As ShortTermModelDensity, GradeControlModelDensity,
			GeologyModelFe, MiningModelFe, ShortTermGeologyModelFe As ShortTermModelFe, GradeControlModelFe,
			GeologyModelP, MiningModelP, ShortTermGeologyModelP As ShortTermModelP, GradeControlModelP, 
			GeologyModelSiO2, MiningModelSiO2, ShortTermGeologyModelSiO2 As ShortTermModelSiO2,
			GradeControlModelSiO2, GeologyModelAl2O3, MiningModelAl2O3, ShortTermGeologyModelAl2O3 As ShortTermModelAl2O3, GradeControlModelAl2O3, GeologyModelLOI,
			MiningModelLOI, ShortTermGeologyModelLOI As ShortTermModelLOI, GradeControlModelLOI, 
			GeologyModelH2O, MiningModelH2O, ShortTermGeologyModelH2O As ShortTermModelH2O, GradeControlModelH2O,
			MiningModelH2OAsDropped, ShortTermGeologyModelH2OAsDropped As ShortTermModelH2OAsDropped,
			MiningModelH2OAsShipped, ShortTermGeologyModelH2OAsShipped As ShortTermModelH2OAsShipped,
			GeologyModelFilename, MiningModelFilename, ShortTermGeologyModelFilename As ShortTermModelFilename, GradeControlModelFilename, SignoffUser
		FROM @Results
		ORDER BY Blastblock, [Month], Approved

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

GRANT EXECUTE ON dbo.GetBhpbioBlastblockDataExportReport TO BhpbioGenericManager
GO
