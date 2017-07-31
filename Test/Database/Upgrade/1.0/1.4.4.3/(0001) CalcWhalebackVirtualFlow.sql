/****** Object:  StoredProcedure [dbo].[CalcWhalebackVirtualFlow]    Script Date: 07/07/2010 10:39:37 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CalcWhalebackVirtualFlow]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[CalcWhalebackVirtualFlow]
GO

CREATE PROCEDURE [dbo].[CalcWhalebackVirtualFlow]
(
	@iCalcDate DATETIME
)
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 
	
	SELECT @TransactionName = 'CalcWhalebackVirtualFlow',
		@TransactionCount = @@TranCount

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
		-- The purpose of the calc virtual flow is to:
		-- collect the information from MQ2 surrounding the plant
		-- collect the information from MET Balancing surrounding the plant
		-- Generate the 'corrected' records surrounding the plant representing the balanced figures.
		
		-- The process will be:
		-- Check for Met Balancing Data - if exists use this.
		--		When using MET Balancing data, MQ2 data for Plant Product 
		--		must exist so we can assign destination stockpiles to the product data
		-- If Met Balancing does not exist use MQ2 data.
		
		-- PLANT NAME = 'WB-C3-EX'
		
		-- MET BALANCING DATA
		-- Plant Inflow			: M201			: Weightometer = 201
		-- Plant Product		: M232			: Weightometer = 232
		-- Fines to Stockpile	: M251			: StreamName = 'Bene Fines S/P' And PlantName = 'Total Ore to Stockpile'
		-- Plant Reject			: M233			: Weightometer = 233
		-- Slimes to Thickener	: ThickToTail	: Weightometer = 'Thick to tail'
		
		-- To Balance we will use: (All WetTonnes)
		--	ThickToTail = M201 - M232 - M251 - M233
		--	If ThickToTail < 0 Then
		--		ThickToTail = 0 And M233 = M201 - M232 - M251
		--		If M233 < 0
		--			Raise Error
		
		-- Once Balance Achieved, this needs to be Applied to all records as detected by MQ2.
		-- The following records must be received from MQ2:
		--		M232
		-- As the following flows will be fixed they do not have to already exist:
		--		M201, M233, ThickToTail, M251

		---------------------------------------------------------------------------------------------------------------
		
		DECLARE @M201 FLOAT
		DECLARE @M232 FLOAT
		DECLARE @M251 FLOAT
		DECLARE @M233 FLOAT
		DECLARE @ThickToTail FLOAT
		
		DECLARE @Cur CURSOR
		DECLARE @WeightometerSampleId INT
		
		DECLARE @Source_Stockpile_Id INT
		DECLARE @Destination_Stockpile_Id INT
		DECLARE @Tonnes FLOAT
		DECLARE @TonnesTotal FLOAT
		
		DECLARE @GradeId SMALLINT
		DECLARE @GradeValue REAL
		
		DECLARE @Balanced BIT
		DECLARE @BalanceTypeComment VARCHAR(255)
		
		DECLARE @FeedFe REAL
		DECLARE @FeedP REAL
		DECLARE @FeedSiO2 REAL
		DECLARE @FeedAL2O3 REAL
		
		DECLARE @LOIExists BIT
		
		DECLARE @Grade TABLE
		(
			Source VARCHAR(31) COLLATE DATABASE_DEFAULT,
			Weightometer_Id VARCHAR(31) COLLATE DATABASE_DEFAULT,
			Grade_Id SMALLINT,
			Grade_Value REAL,
			PRIMARY KEY (Source, Weightometer_Id, Grade_Id)
		)
		
		SET @Balanced = 0
		
		IF EXISTS
			(
				SELECT TOP 1 1
				FROM dbo.WeightometerSample
				WHERE Weightometer_Sample_Date = @iCalcDate
					AND Weightometer_Id IN
						(
							'WB-M201-Corrected', 'WB-M232-Corrected', 
							'WB-M233-Corrected', 'WB-M251-Corrected', 'WB-ThickToTail-Corrected'
						)
			)
		BEGIN
			SET @Cur = CURSOR FAST_FORWARD READ_ONLY FOR
				SELECT Weightometer_Sample_Id
				FROM dbo.WeightometerSample AS ws
				WHERE Weightometer_Sample_Date = @iCalcDate
					AND Weightometer_Id IN
						(
							'WB-M201-Corrected', 'WB-M232-Corrected', 
							'WB-M233-Corrected', 'WB-M251-Corrected', 'WB-ThickToTail-Corrected'
						)
			OPEN @Cur
			
			FETCH NEXT FROM @Cur INTO @WeightometerSampleId
			
			WHILE @@FETCH_STATUS = 0
			BEGIN
				EXEC DeleteWeightometerSample
					@iWeightometer_Sample_Id = @WeightometerSampleId
			
				FETCH NEXT FROM @Cur INTO @WeightometerSampleId
			END
			
			CLOSE @Cur
		END
		
		IF NOT EXISTS
			(
				SELECT TOP 1 1
				FROM dbo.WeightometerSample
				WHERE Weightometer_Sample_Date = @iCalcDate
					AND Weightometer_Id In ('WB-BeneOreRaw')
			)
			AND EXISTS
			(
				SELECT TOP 1 1
				FROM dbo.BhpbioMetBalancing BMT
				WHERE BMT.Weightometer = 'M232'
					AND BMT.CalendarDate = @iCalcDate
					AND WetTonnes > 0
			)
		BEGIN
			-- RAISE DATA EXCEPTION - MQ2 TRANSACTIONS FOR BENE PRODUCT DO NOT EXIST
			PRINT '-- RAISE DATA EXCEPTION - MQ2 TRANSACTIONS FOR BENE PRODUCT DO NOT EXIST'
			SET @Balanced = 0
		END
		ELSE IF EXISTS
			(
				SELECT TOP 1 1
				FROM WeightometerSample
				WHERE Weightometer_Sample_Date = @iCalcDate
					AND Weightometer_Id In ('WB-BeneOreRaw')
			)
		BEGIN
			SET @M201 = 0 
			SET @M232 = 0
			SET @M251 = 0
			SET @M233 = 0
		
			IF EXISTS
				(
					SELECT TOP 1 1
					FROM BhpbioMETBalancing
					WHERE CalendarDate = @iCalcDate
						AND Weightometer = '201'
						AND COALESCE(WetTonnes, 0.0) > 0.0
				)
			BEGIN
				SET @BalanceTypeComment = 'MET Balance Data'
				
				SET @M201 = COALESCE(
					(
						SELECT SUM(COALESCE(WetTonnes, 0.0))
						FROM dbo.BhpbioMETBalancing
						WHERE CalendarDate = @iCalcDate
							AND Weightometer = '201'
					), 0.0)
					
				SET @M232 = COALESCE(
					(
						SELECT SUM(COALESCE(WetTonnes, 0.0))
						FROM dbo.BhpbioMETBalancing
						WHERE CalendarDate = @iCalcDate
							AND Weightometer = '232'
							AND (PlantName = 'Total Ore to Loadout' OR PlantName = 'Total Ore to Hub')
					), 0.0)
				
				SET @M251 = COALESCE(
					(
						SELECT SUM(COALESCE(WetTonnes, 0.0))
						FROM dbo.BhpbioMETBalancing
						WHERE CalendarDate = @iCalcDate
							AND StreamName = 'Bene Fines S/P' 
							AND PlantName = 'Total Ore to Stockpile'
					), 0.0)
				
				SET @M233 = COALESCE(
					(
						SELECT SUM(COALESCE(WetTonnes, 0.0))
						FROM dbo.BhpbioMETBalancing
						WHERE CalendarDate = @iCalcDate
							AND Weightometer = '233'
					), 0.0)
				
				SET @ThickToTail = COALESCE(
					(
						SELECT SUM(COALESCE(WetTonnes, 0.0))
						FROM dbo.BhpbioMETBalancing
						WHERE CalendarDate = @iCalcDate
							AND Weightometer = 'Thick to tail'
					), 0.0)
					
				INSERT INTO @Grade
					(Source, Weightometer_ID, Grade_Id, Grade_Value)
				SELECT 'MET', 
					CASE
						WHEN BMB.Weightometer = '201' THEN 'WB-M201-Corrected'
						WHEN BMB.Weightometer = '232' AND (PlantName = 'Total Ore to Loadout' OR PlantName = 'Total Ore to Hub') THEN 'WB-M232-Corrected'
						WHEN BMB.StreamName = 'Bene Fines S/P' And BMB.PlantName = 'Total Ore to Stockpile' THEN 'WB-M251-Corrected'
						WHEN BMB.Weightometer = '233' THEN 'WB-M233-Corrected'
					END,
					BMBG.GradeId, BMBG.GradeValue
				FROM dbo.BhpbioMETBalancing AS bmb
					INNER JOIN dbo.BhpbioMETBalancingGrade AS bmbg
						ON (bmbg.BhpbioMetBalancingId = bmb.BhpbioMetBalancingId)
				WHERE bmb.CalendarDate = @iCalcDate
					AND
						(
							CASE
								WHEN Weightometer = '201' THEN 1.0
								WHEN Weightometer = '232' And (PlantName = 'Total Ore to Loadout' OR PlantName = 'Total Ore to Hub') THEN 1.0
								WHEN StreamName = 'Bene Fines S/P' And PlantName = 'Total Ore to Stockpile' THEN 1.0
								WHEN Weightometer = '233' THEN 1.0
								ELSE 0.0
							END
						) > 0.0
					END
			ELSE
			BEGIN
				Print 'MQ2'
				SET @BalanceTypeComment = 'MQ2 Transaction Data'
				
				SET @M201 = COALESCE((SELECT SUM(COALESCE(Corrected_Tonnes, Tonnes, 0))
										FROM WeightometerSample
										WHERE Weightometer_Sample_Date = @iCalcDate
											AND Weightometer_Id = 'WB-C3OutflowRaw'), 0)
					
				SET @M232 = COALESCE((SELECT SUM(COALESCE(Corrected_Tonnes, Tonnes, 0))
										FROM WeightometerSample
										WHERE Weightometer_Sample_Date = @iCalcDate
											AND Weightometer_Id = 'WB-BeneOreRaw'), 0)
				
				SET @M251 = COALESCE((SELECT SUM(COALESCE(Corrected_Tonnes, Tonnes, 0))
										FROM WeightometerSample
										WHERE Weightometer_Sample_Date = @iCalcDate
											AND Weightometer_Id = 'WB-BeneFinesRaw'), 0)
				
				SET @M233 = COALESCE((SELECT SUM(COALESCE(Corrected_Tonnes, Tonnes, 0))
										FROM WeightometerSample
										WHERE Weightometer_Sample_Date = @iCalcDate
											AND Weightometer_Id = 'WB-BeneRejectRaw'), 0)
					
				INSERT INTO @Grade
				(Source, Weightometer_ID, Grade_Id, Grade_Value)
				SELECT 'MQ2', 
					CASE WHEN WS.Weightometer_Id = 'WB-C3OutFlowRaw' THEN 'WB-M201-Corrected'
						WHEN WS.Weightometer_Id = 'WB-BeneOreRaw' THEN 'WB-M232-Corrected'
						WHEN WS.Weightometer_Id = 'WB-BeneFinesRaw' THEN 'WB-M251-Corrected'
						WHEN WS.Weightometer_Id = 'WB-BeneRejectRaw' THEN 'WB-M233-Corrected' END,
					Grade_ID, SUM(WS.Tonnes*WSG.Grade_Value)/SUM(WS.Tonnes)
				FROM WeightometerSample WS
					INNER JOIN WeightometerSampleGrade WSG
						ON WS.Weightometer_Sample_Id = WSG.Weightometer_Sample_Id
				WHERE Weightometer_Sample_Date = @iCalcDate
					AND CASE WHEN WS.Weightometer_Id = 'WB-C3OutFlowRaw' THEN 1
						WHEN WS.Weightometer_Id = 'WB-BeneOreRaw' THEN 1
						WHEN WS.Weightometer_Id = 'WB-BeneFinesRaw' THEN 1
						WHEN WS.Weightometer_Id = 'WB-BeneRejectRaw' THEN 1 
						ELSE 0 END = 1
				GROUP BY WS.Weightometer_Id, WSG.Grade_Id
				HAVING SUM(WS.Tonnes) > 0
			END

			SET @ThickToTail = @M201 - @M232 - @M251 - @M233
			
			IF @ThickToTail < 0.0
			BEGIN
				SET @ThickToTail = 0
				SET @M233 = @M201 - @M232 - @M251 
				
				IF @M233 < 0.0
				BEGIN
					-- RAISE DATA EXCEPTION - MET BALANCING PRODUCT AND FINES GREATER THAN INFLOW
					Print '-- RAISE DATA EXCEPTION - MET BALANCING PRODUCT AND FINES GREATER THAN INFLOW'
					SET @Balanced = 0
				END
				ELSE
				BEGIN
					SET @Balanced = 1
				END
			END
			ELSE
			BEGIN
				SET @Balanced = 1
			END
			
			IF @Balanced = 1
			BEGIN
				Print 'Balanced'
				EXEC AddWeightometerSample
					@iWeightometer_Id = 'WB-M201-Corrected',
					@iWeightometer_Sample_Date = @iCalcDate,
					@iWeightometer_Sample_Shift = 'D',
					@iOrder_No = 1,
					@iTonnes = @M201,
					@oWeightometer_Sample_Id = @WeightometerSampleId OUTPUT
				
				EXEC AddWeightometerSample
					@iWeightometer_Id = 'WB-ThickToTail-Corrected',
					@iWeightometer_Sample_Date = @iCalcDate,
					@iWeightometer_Sample_Shift = 'D',
					@iOrder_No = 1,
					@iTonnes = @ThickToTail,
					@oWeightometer_Sample_Id = @WeightometerSampleId OUTPUT

				EXEC AddWeightometerSample
					@iWeightometer_Id = 'WB-M251-Corrected',
					@iWeightometer_Sample_Date = @iCalcDate,
					@iWeightometer_Sample_Shift = 'D',
					@iOrder_No = 1,
					@iTonnes = @M251,
					@oWeightometer_Sample_Id = @WeightometerSampleId OUTPUT
				
				EXEC AddWeightometerSample
					@iWeightometer_Id = 'WB-M233-Corrected',
					@iWeightometer_Sample_Date = @iCalcDate,
					@iWeightometer_Sample_Shift = 'D',
					@iOrder_No = 1,
					@iTonnes = @M233,
					@oWeightometer_Sample_Id = @WeightometerSampleId OUTPUT
					
				SELECT @TonnesTotal = SUM(Tonnes)
				FROM WeightometerSample
				WHERE Weightometer_Id = 'WB-BeneOreRaw'
					AND Weightometer_Sample_Date = @iCalcDate
					
				SET @Cur = CURSOR FOR
					SELECT Source_Stockpile_Id, Destination_Stockpile_Id, Tonnes
					FROM WeightometerSample
					WHERE Weightometer_Id = 'WB-BeneOreRaw'
						AND Weightometer_Sample_Date = @iCalcDate
						
				OPEN @Cur
				
				FETCH NEXT FROM @Cur INTO @Source_Stockpile_Id, @Destination_Stockpile_ID, @Tonnes
			
				WHILE @@FETCH_STATUS = 0
				BEGIN
					
					SET @Tonnes = (@Tonnes / @TonnesTotal) * @M232
					
					EXEC AddWeightometerSample
						@iWeightometer_Id = 'WB-M232-Corrected',
						@iWeightometer_Sample_Date = @iCalcDate,
						@iWeightometer_Sample_Shift = 'D',
						@iOrder_No = 1,
						@iSource_Stockpile_Id = @Source_Stockpile_Id,
						@iDestination_Stockpile_Id = @Destination_Stockpile_ID,
						@iTonnes = @Tonnes,
						@oWeightometer_Sample_Id = @WeightometerSampleId OUTPUT
						
					FETCH NEXT FROM @Cur INTO @Source_Stockpile_Id, @Destination_Stockpile_ID, @Tonnes			
				END
			
				CLOSE @Cur
				DEALLOCATE @Cur
				
				SET @Cur = CURSOR FOR
					SELECT WS.Weightometer_Sample_Id, G.Grade_ID, G.Grade_Value
					FROM @Grade G
						INNER JOIN WeightometerSample WS
							ON WS.Weightometer_ID = G.Weightometer_Id
					WHERE WS.Weightometer_Sample_Date = @iCalcDate
						AND G.Source = CASE WHEN @BalanceTypeComment = 'MET Balance Data' THEN 'MET' ELSE 'MQ2' END
				
				OPEN @Cur
				
				FETCH NEXT FROM @Cur INTO @WeightometerSampleId, @GradeId, @GradeValue
				
				WHILE @@FETCH_STATUS = 0
				BEGIN

					EXEC dbo.AddOrUpdateWeightometerSampleGrade
						@iWeightometer_Sample_Id = @WeightometerSampleId,
						@iGrade_Id = @GradeId,
						@iGrade_Value = @GradeValue
						
					FETCH NEXT FROM @Cur INTO @WeightometerSampleId, @GradeId, @GradeValue
				END
				
				CLOSE @Cur
				DEALLOCATE @Cur
				
				SELECT @GradeId = Grade_Id
				FROM Grade
				WHERE Grade_Name = 'LOI'
				
				IF NOT EXISTS (SELECT TOP 1 1 
								FROM @Grade
								WHERE Weightometer_Id = 'WB-M232-Corrected'
									AND Grade_Id = @GradeId
								)
				BEGIN
					SELECT 
						@FeedFe = Sum(CASE WHEN Gr.Grade_Name = 'FE' THEN G.Grade_Value ELSE 0 END),
						@FeedP = Sum(CASE WHEN Gr.Grade_Name = 'P' THEN G.Grade_Value ELSE 0 END),
						@FeedSiO2 = Sum(CASE WHEN Gr.Grade_Name = 'SiO2' THEN G.Grade_Value ELSE 0 END),
						@FeedAL2O3 = Sum(CASE WHEN Gr.Grade_Name = 'AL2O3' THEN G.Grade_Value ELSE 0 END)	
					FROM @Grade G
						INNER JOIN Grade Gr
							ON Gr.Grade_Id = G.Grade_Id
					WHERE G.Source = CASE WHEN @BalanceTypeComment = 'MET Balance Data' THEN 'MET' ELSE 'MQ2' END
						AND G.Weightometer_Id = 'WB-M201-Corrected'

					SELECT @WeightometerSampleId = Weightometer_Sample_Id
					FROM WeightometerSample
					WHERE Weightometer_Id = 'WB-M232-Corrected'
						AND Weightometer_Sample_Date = @iCalcDate

					IF @FeedFe > 0 AND @FeedP > 0 AND @FeedSiO2 > 0 AND @FeedAL2O3 > 0
						AND @WeightometerSampleId IS NOT NULL
					BEGIN

						SET @GradeValue = 99.7-((1.429*@FeedFe)+(2.205*@FeedP)+@FeedSiO2+@FeedAL2O3)
						
						IF @GradeValue > 0.0
						BEGIN
							EXEC dbo.AddOrUpdateWeightometerSampleGrade
								@iWeightometer_Sample_Id = @WeightometerSampleId,
								@iGrade_Id = @GradeId,
								@iGrade_Value = @GradeValue
						END
					END
					ELSE IF EXISTS(SELECT TOP 1 1 
									FROM WeightometerSampleGrade 
									WHERE Weightometer_Sample_Id = @WeightometerSampleId
										AND Grade_Id = @GradeId)
						AND @WeightometerSampleId IS NOT NULL
					BEGIN
						DELETE FROM WeightometerSampleGrade
						WHERE Weightometer_Sample_Id = @WeightometerSampleId
							AND Grade_Id = @GradeId
					END
				END
				
				-- check for 201 LOI grades and if they dont exist add them
				IF NOT EXISTS (SELECT TOP 1 1 
								FROM @Grade
								WHERE Weightometer_Id = 'WB-M201-Corrected'
									AND Grade_Id = @GradeId
								)
				BEGIN
					
					DECLARE @StartDate DATETIME
					DECLARE @EndDate DATETIME

					SET @StartDate = '1-Jul-' + CAST(CASE WHEN MONTH(@iCalcDate) <= 6 THEN YEAR(@iCalcDate) - 2 ELSE YEAR(@iCalcDate) - 1 END AS VARCHAR)
					SET @EndDate = '30-Jun-' + CAST(CASE WHEN MONTH(@iCalcDate) <= 6 THEN YEAR(@iCalcDate) - 1 ELSE YEAR(@iCalcDate) END AS VARCHAR)

					DECLARE @MaterialCategory VARCHAR(32)
					SET @MaterialCategory = 'Designation'
					DECLARE @BeneFeed INT

					SELECT @BeneFeed = MT.Material_Type_Id
					FROM MaterialType MT
						INNER JOIN MaterialCategory MTG
							ON MTG.MaterialCategoryId = MT.Material_Category_Id
					WHERE MTG.MaterialCategoryId = 'Designation'
						AND MT.Description = 'Bene Feed'

					SELECT @GradeValue = SUM(MBS.Tonnes*birm.MinedPercentage*MBS.LOI) / SUM(MBS.Tonnes*birm.MinedPercentage)
					FROM BhpbioImportReconciliationMovement birm
					INNER JOIN (Select mbl.Location_Id, SUM(MBP.Tonnes) As Tonnes,
									CASE WHEN SUM(MBP.Tonnes) > 0 THEN 
											SUM(MBPG.Grade_Value * MBP.Tonnes) 
											/ SUM(MBP.Tonnes) 
										ELSE
											NULL
										END As LOI
								FROM ModelBlockLocation mbl
								INNER JOIN ModelBlock MB
									ON MB.Model_Block_Id = mbl.Model_Block_Id
								INNER JOIN BlockModel BM
									ON BM.Block_Model_Id = MB.Block_Model_Id
								INNER JOIN ModelBlockPartial MBP
									ON MBP.Model_Block_Id = MB.Model_Block_Id
								INNER JOIN ModelBlockPartialGrade MBPG
									ON MBPG.Model_Block_Id = MBP.Model_Block_Id
										AND MBPG.Sequence_No = MBP.Sequence_No
								INNER JOIN dbo.GetMaterialsByCategory(@MaterialCategory) GMBC
									ON GMBC.MaterialTypeId = MBP.Material_Type_Id
										AND GMBC.RootMaterialTypeId = @BeneFeed
								WHERE BM.Name = 'Mining'
									AND MBPG.Grade_Id = @GradeId
								GROUP BY mbl.Location_Id
						) MBS
						ON MBS.Location_Id = birm.BlockLocationId
					WHERE [Site] = 'NEWMAN'
						AND Orebody = 'WB'
						AND DateFrom BETWEEN @StartDate AND @EndDate

					SELECT @WeightometerSampleId = Weightometer_Sample_Id
					FROM WeightometerSample
					WHERE Weightometer_Id = 'WB-M201-Corrected'
						AND Weightometer_Sample_Date = @iCalcDate

					IF @GradeValue > 0 AND @WeightometerSampleId IS NOT NULL
					BEGIN
						EXEC dbo.AddOrUpdateWeightometerSampleGrade
							@iWeightometer_Sample_Id = @WeightometerSampleId,
							@iGrade_Id = @GradeId,
							@iGrade_Value = @GradeValue
					END
					ELSE IF EXISTS(SELECT TOP 1 1 
									FROM WeightometerSampleGrade 
									WHERE Weightometer_Sample_Id = @WeightometerSampleId
										AND Grade_Id = @GradeId)
						AND @WeightometerSampleId IS NOT NULL
					BEGIN
						DELETE FROM WeightometerSampleGrade
						WHERE Weightometer_Sample_Id = @WeightometerSampleId
							AND Grade_Id = @GradeId
					END
				END
				
			END
		END
		
		-- if we started a new transaction that is still valid then commit the changes
		IF (@TransactionCount = 0) AND (XAct_State() = 1)
		BEGIN
			COMMIT TRANSACTION
		END
					
		Exec RecalcL1Raise @iCalcDate
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