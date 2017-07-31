IF OBJECT_ID('dbo.CalcWhalebackVirtualFlowBene') IS NOT NULL
	DROP PROCEDURE dbo.CalcWhalebackVirtualFlowBene
GO 

CREATE PROCEDURE [dbo].[CalcWhalebackVirtualFlowBene]
(
	@iCalcDate DATETIME
)
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 
	
	SELECT @TransactionName = 'CalcWhalebackVirtualFlowBene',
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
		-- Fines to Stockpile	: M251			: StreamName in ('Bene Fines S/P', 'Bene Fines to BPF0')  And PlantName = 'Total Ore to Stockpile'
		-- Fines to Stockyard	: 252			: StreamName = 'M251 - Bene Fines to Stockyard'
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
		
		DECLARE @Cur CURSOR

		DECLARE @WeightometerId VARCHAR(31)
		DECLARE @WeightometerSampleTonnes FLOAT
		DECLARE @WeightometerSampleProductSize VARCHAR(5)
		DECLARE @DestinationStockpileId INT

		DECLARE @WeightometerSampleId INT
		
		DECLARE @Source_Stockpile_Id INT
		DECLARE @Destination_Stockpile_Id INT
		
		DECLARE @RawTonnes FLOAT
		DECLARE @232Tonnes FLOAT
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
		
		DECLARE @BeneFineToBPF0StreamName VARCHAR(127)
		DECLARE @BeneFineToStockyardStreamName VARCHAR(127)
		SET @BeneFineToBPF0StreamName = 'Bene Fines to BPF0'
		SET @BeneFineToStockyardStreamName = 'M251 - Bene Fines to Stockyard'
		
		DECLARE @Tonnes TABLE
		(
			Weightometer_Id VARCHAR(31) COLLATE DATABASE_DEFAULT,
			Product_Size VARCHAR(5) COLLATE DATABASE_DEFAULT,
			Destination_Stockpile_Id INT NULL,
			Tonnes FLOAT,
			PRIMARY KEY (Weightometer_Id, Product_Size)
		)		
		
		DECLARE @Grade TABLE
		(
			Source VARCHAR(31) COLLATE DATABASE_DEFAULT,
			Weightometer_Id VARCHAR(31) COLLATE DATABASE_DEFAULT,
			Product_Size VARCHAR(5) COLLATE DATABASE_DEFAULT,
			Grade_Id SMALLINT,
			Grade_Value REAL,
			PRIMARY KEY (Source, Weightometer_Id, Product_Size, Grade_Id)
		)
		
		SET @Balanced = 0
		
		-- DELETE ANY EXISTING SAMPLE FOR THIS DATE
		IF EXISTS
			(
				SELECT TOP 1 1
				FROM dbo.WeightometerSample
				WHERE Weightometer_Sample_Date = @iCalcDate
					AND Weightometer_Id IN
						(
							'WB-M201-Corrected', 'WB-M232-Corrected', 
							'WB-M233-Corrected', 'WB-BeneFinesToBPF0-Corrected', 'WB-ThickToTail-Corrected',
							'WB-BeneFinesToSYard-Corrected'
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
							'WB-M233-Corrected', 'WB-BeneFinesToBPF0-Corrected', 'WB-ThickToTail-Corrected',
							'WB-BeneFinesToSYard-Corrected'
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
		
		
		-- IS THERE ANY DATA PRESENT FOR THIS DATE?
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
		
		-- ONLY CONTINUE IF VALUE FOR WEIGHTOMETER 'WB-BeneOreRaw' EXISTS
		ELSE IF EXISTS
			(
				SELECT TOP 1 1
				FROM WeightometerSample
				WHERE Weightometer_Sample_Date = @iCalcDate
					AND Weightometer_Id In ('WB-BeneOreRaw')
			)
		BEGIN
		
			DECLARE @Has201MetData bit
			DECLARE @HasStockyardMetData bit
			
			-- if we met data for the 201 stream, then we are going to assume that
			-- there is data for the rest of the met streams as well...
			IF EXISTS (
				SELECT TOP 1 1
				FROM BhpbioMETBalancing
				WHERE CalendarDate = @iCalcDate
					AND Weightometer = '201'
					AND COALESCE(WetTonnes, 0.0) > 0.0
			)
				SET @Has201MetData = 1
			ELSE
				SET @Has201MetData = 0
			
			-- ...except for the SYard stream - we check this separately. It will use the Met data
			-- if present, otherwise it will use the MQ2 data (via the Raw weightometer), regardless of
			-- where the other data comes from
			IF EXISTS (
				SELECT TOP(1) 1
				FROM dbo.BhpbioMETBalancing
				WHERE CalendarDate = @iCalcDate
					AND StreamName = @BeneFineToStockyardStreamName
					AND COALESCE(WetTonnes, 0.0) > 0.0
			)
				SET @HasStockyardMetData = 1
			ELSE
				SET @HasStockyardMetData = 0
							
			IF @Has201MetData = 1 AND @HasStockyardMetData = 0
			BEGIN
				-- in this case we have the general met data, but we don't have anything for the SYard stream
				-- so we need to get this data from the RAW weightometer (ie from MQ2). 
				print 'No Stockyard Met Stream - coping from Raw Weightometer'
			
				INSERT INTO @Tonnes	(Weightometer_Id, Product_Size, Destination_Stockpile_Id, Tonnes)
					SELECT 
						'252', 
						ISNULL(Notes, 'ROM'),
						Min(WS.Destination_Stockpile_Id),
						ISNULL( SUM(COALESCE(Corrected_Tonnes, Tonnes, 0)), 0.0)
					FROM WeightometerSample WS
					LEFT JOIN WeightometerSampleNotes WSN
						ON WS.Weightometer_Sample_Id = WSN.Weightometer_Sample_Id
						AND WSN.Weightometer_Sample_Field_Id = 'ProductSize'
					WHERE Weightometer_Sample_Date = @iCalcDate
					AND Weightometer_Id = 'WB-BeneFinesToSYard-Raw'				
					GROUP BY Notes
			
				INSERT INTO @Grade (Source, Weightometer_ID, Product_Size, Grade_Id, Grade_Value)
					SELECT 'MQ2', 
						'WB-BeneFinesToSYard-Corrected',
						ISNULL(WSN.Notes, 'ROM'),
						Grade_ID, 
						SUM(WS.Tonnes*WSG.Grade_Value)/SUM(WS.Tonnes)
					FROM WeightometerSample WS
						INNER JOIN WeightometerSampleGrade WSG
							ON WS.Weightometer_Sample_Id = WSG.Weightometer_Sample_Id
						LEFT JOIN WeightometerSampleNotes WSN
							ON WS.Weightometer_Sample_Id = WSN.Weightometer_Sample_Id
							AND WSN.Weightometer_Sample_Field_Id = 'ProductSize'
					WHERE Weightometer_Sample_Date = @iCalcDate
						AND WS.Weightometer_Id = 'WB-BeneFinesToSYard-Raw'
					GROUP BY WS.Weightometer_Id, WSG.Grade_Id, Notes
					HAVING SUM(WS.Tonnes) > 0
					
			END
			
			-- IF MT FEED DATA EXISTS (201) THEN PROCEED USING MET BALANCE DATA
			IF @Has201MetData = 1
			BEGIN
				SET @BalanceTypeComment = 'MET Balance Data'
				
				INSERT INTO @Tonnes	(Weightometer_Id, Product_Size, Tonnes)
				SELECT '201', ISNULL(ProductSize, 'ROM'), ISNULL(SUM(COALESCE(WetTonnes, 0.0)), 0.0)
				FROM dbo.BhpbioMETBalancing
				WHERE CalendarDate = @iCalcDate
					AND Weightometer = '201'
				GROUP BY ProductSize				

				INSERT INTO @Tonnes	(Weightometer_Id, Product_Size, Tonnes)
				SELECT '232', ISNULL(ProductSize, 'ROM'), ISNULL(SUM(COALESCE(WetTonnes, 0.0)), 0.0)
				FROM dbo.BhpbioMETBalancing
				WHERE CalendarDate = @iCalcDate
					AND Weightometer = '232'	
					AND (PlantName = 'Total Ore to Loadout' OR PlantName = 'Total Ore to Hub')
				GROUP BY ProductSize				

				INSERT INTO @Tonnes	(Weightometer_Id, Product_Size, Tonnes)
				SELECT '251', ISNULL(ProductSize, 'ROM'), ISNULL(SUM(COALESCE(WetTonnes, 0.0)), 0.0)
				FROM dbo.BhpbioMETBalancing
				WHERE CalendarDate = @iCalcDate
					AND (StreamName = 'Bene Fines S/P' OR StreamName = @BeneFineToBPF0StreamName)
					AND PlantName = 'Total Ore to Stockpile'
				GROUP BY ProductSize
				
				INSERT INTO @Tonnes	(Weightometer_Id, Product_Size, Tonnes)
				SELECT '252', ISNULL(ProductSize, 'ROM'), ISNULL(SUM(COALESCE(WetTonnes, 0.0)), 0.0)
				FROM dbo.BhpbioMETBalancing
				WHERE CalendarDate = @iCalcDate
					AND StreamName = @BeneFineToStockyardStreamName
				GROUP BY ProductSize

				INSERT INTO @Tonnes	(Weightometer_Id, Product_Size, Tonnes)
				SELECT '233', ISNULL(ProductSize, 'ROM'), ISNULL(SUM(COALESCE(WetTonnes, 0.0)), 0.0)
				FROM dbo.BhpbioMETBalancing
				WHERE CalendarDate = @iCalcDate
					AND Weightometer = '233'				
				GROUP BY ProductSize				
					
				INSERT INTO @Grade (Source, Weightometer_ID, Product_Size, Grade_Id, Grade_Value)
				SELECT 'MET', 
					CASE
						WHEN BMB.Weightometer = '201' THEN 'WB-M201-Corrected'
						WHEN BMB.Weightometer = '232' AND (PlantName = 'Total Ore to Loadout' OR PlantName = 'Total Ore to Hub') THEN 'WB-M232-Corrected'
						WHEN (BMB.StreamName = 'Bene Fines S/P' OR BMB.StreamName = @BeneFineToBPF0StreamName) And BMB.PlantName = 'Total Ore to Stockpile' THEN 'WB-BeneFinesToBPF0-Corrected'
						WHEN BMB.StreamName = @BeneFineToStockyardStreamName THEN 'WB-BeneFinesToSYard-Corrected'
						WHEN BMB.Weightometer = '233' THEN 'WB-M233-Corrected'
					END,
					ISNULL(ProductSize, 'ROM'),
					BMBG.GradeId, 
					BMBG.GradeValue
				FROM dbo.BhpbioMETBalancing AS bmb
					INNER JOIN dbo.BhpbioMETBalancingGrade AS bmbg
						ON (bmbg.BhpbioMetBalancingId = bmb.BhpbioMetBalancingId)
				WHERE bmb.CalendarDate = @iCalcDate
					AND
						(
							CASE
								WHEN Weightometer = '201' THEN 1.0
								WHEN Weightometer = '232' And (PlantName = 'Total Ore to Loadout' OR PlantName = 'Total Ore to Hub') THEN 1.0
								WHEN (StreamName = 'Bene Fines S/P' OR StreamName = @BeneFineToBPF0StreamName) And PlantName = 'Total Ore to Stockpile' THEN 1.0
								WHEN StreamName = @BeneFineToStockyardStreamName THEN 1.0
								WHEN Weightometer = '233' THEN 1.0
								ELSE 0.0
							END
						) > 0.0
					END
			ELSE
			BEGIN
				Print 'MQ2'
				SET @BalanceTypeComment = 'MQ2 Transaction Data'
				
				INSERT INTO @Tonnes	(Weightometer_Id, Product_Size, Tonnes)
				SELECT '201', ISNULL(Notes, 'ROM'), ISNULL( SUM(COALESCE(Corrected_Tonnes, Tonnes, 0)), 0.0)
				FROM WeightometerSample WS
				LEFT JOIN WeightometerSampleNotes WSN
					ON WS.Weightometer_Sample_Id = WSN.Weightometer_Sample_Id
					AND WSN.Weightometer_Sample_Field_Id = 'ProductSize'
				WHERE Weightometer_Sample_Date = @iCalcDate
				AND Weightometer_Id = 'WB-C3OutflowRaw'		
				GROUP BY Notes				
				
				INSERT INTO @Tonnes	(Weightometer_Id, Product_Size, Tonnes)
				SELECT '232', ISNULL(Notes, 'ROM'), ISNULL( SUM(COALESCE(Corrected_Tonnes, Tonnes, 0)), 0.0)
				FROM WeightometerSample WS
				LEFT JOIN WeightometerSampleNotes WSN
					ON WS.Weightometer_Sample_Id = WSN.Weightometer_Sample_Id
					AND WSN.Weightometer_Sample_Field_Id = 'ProductSize'
				WHERE Weightometer_Sample_Date = @iCalcDate
				AND Weightometer_Id = 'WB-BeneOreRaw'				
				GROUP BY Notes				

				INSERT INTO @Tonnes	(Weightometer_Id, Product_Size, Tonnes)
				SELECT '251', ISNULL(Notes, 'ROM'), ISNULL( SUM(COALESCE(Corrected_Tonnes, Tonnes, 0)), 0.0)
				FROM WeightometerSample WS
				LEFT JOIN WeightometerSampleNotes WSN
					ON WS.Weightometer_Sample_Id = WSN.Weightometer_Sample_Id
					AND WSN.Weightometer_Sample_Field_Id = 'ProductSize'
				WHERE Weightometer_Sample_Date = @iCalcDate
				AND Weightometer_Id = 'WB-BeneFinesToBPF0-Raw'				
				GROUP BY Notes
				
				INSERT INTO @Tonnes	(Weightometer_Id, Product_Size, Tonnes)
				SELECT '252', ISNULL(Notes, 'ROM'), ISNULL( SUM(COALESCE(Corrected_Tonnes, Tonnes, 0)), 0.0)
				FROM WeightometerSample WS
				LEFT JOIN WeightometerSampleNotes WSN
					ON WS.Weightometer_Sample_Id = WSN.Weightometer_Sample_Id
					AND WSN.Weightometer_Sample_Field_Id = 'ProductSize'
				WHERE Weightometer_Sample_Date = @iCalcDate
				AND Weightometer_Id = 'WB-BeneFinesToSYard-Raw'				
				GROUP BY Notes

				INSERT INTO @Tonnes	(Weightometer_Id, Product_Size, Tonnes)
				SELECT '233', ISNULL(Notes, 'ROM'), ISNULL( SUM(COALESCE(Corrected_Tonnes, Tonnes, 0)), 0.0)
				FROM WeightometerSample WS
				LEFT JOIN WeightometerSampleNotes WSN
					ON WS.Weightometer_Sample_Id = WSN.Weightometer_Sample_Id
					AND WSN.Weightometer_Sample_Field_Id = 'ProductSize'
				WHERE Weightometer_Sample_Date = @iCalcDate
				AND Weightometer_Id = 'WB-BeneRejectRaw'				
				GROUP BY Notes				
				
				INSERT INTO @Grade (Source, Weightometer_ID, Product_Size, Grade_Id, Grade_Value)
				SELECT 'MQ2', 
					CASE WHEN WS.Weightometer_Id = 'WB-C3OutFlowRaw' THEN 'WB-M201-Corrected'
						WHEN WS.Weightometer_Id = 'WB-BeneOreRaw' THEN 'WB-M232-Corrected'
						WHEN WS.Weightometer_Id = 'WB-BeneFinesToBPF0-Raw' THEN 'WB-BeneFinesToBPF0-Corrected'
						WHEN WS.Weightometer_Id = 'WB-BeneFinesToSYard-Raw' THEN 'WB-BeneFinesToSYard-Corrected'
						WHEN WS.Weightometer_Id = 'WB-BeneRejectRaw' THEN 'WB-M233-Corrected' END,
					ISNULL(WSN.Notes, 'ROM'),
					Grade_ID, 
					SUM(WS.Tonnes*WSG.Grade_Value)/SUM(WS.Tonnes)
				FROM WeightometerSample WS
					INNER JOIN WeightometerSampleGrade WSG
						ON WS.Weightometer_Sample_Id = WSG.Weightometer_Sample_Id
					LEFT JOIN WeightometerSampleNotes WSN
						ON WS.Weightometer_Sample_Id = WSN.Weightometer_Sample_Id
						AND WSN.Weightometer_Sample_Field_Id = 'ProductSize'
				WHERE Weightometer_Sample_Date = @iCalcDate
					AND CASE WHEN WS.Weightometer_Id = 'WB-C3OutFlowRaw' THEN 1
						WHEN WS.Weightometer_Id = 'WB-BeneOreRaw' THEN 1
						WHEN WS.Weightometer_Id = 'WB-BeneFinesToBPF0-Raw' THEN 1
						WHEN WS.Weightometer_Id = 'WB-BeneFinesToSYard-Raw' THEN 1
						WHEN WS.Weightometer_Id = 'WB-BeneRejectRaw' THEN 1 
						ELSE 0 END = 1
				GROUP BY WS.Weightometer_Id, WSG.Grade_Id, Notes
				HAVING SUM(WS.Tonnes) > 0
			END

			INSERT INTO @Tonnes	(Weightometer_Id, Product_Size, Tonnes)
			SELECT 'Thick to tail', 'ROM',
				(SELECT SUM(Tonnes) FROM @Tonnes WHERE Weightometer_Id = '201') - (SELECT SUM(Tonnes) FROM @Tonnes WHERE Weightometer_Id <> '201')
				
			IF (SELECT ISNULL(SUM(Tonnes), 0.0) FROM @Tonnes WHERE Weightometer_Id = 'Thick to tail') < 0.0
			BEGIN
				UPDATE @Tonnes
				SET Tonnes = 0
				WHERE Weightometer_Id = 'Thick to tail'
				
				DELETE 
				FROM @Tonnes 
				WHERE Weightometer_Id = '233'
				
				INSERT INTO @Tonnes	(Weightometer_Id, Product_Size, Tonnes)
				SELECT '233', 'ROM', 
					(SELECT SUM(Tonnes) FROM @Tonnes WHERE Weightometer_Id = '201') - (SELECT SUM(Tonnes) FROM @Tonnes WHERE Weightometer_Id IN ('232', '251'))

				IF (SELECT ISNULL(SUM(Tonnes), 0.0) FROM @Tonnes WHERE Weightometer_Id = '233') < 0.0
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
				
				SET @Cur = CURSOR FOR
					SELECT 
						CASE 
							WHEN Weightometer_Id = '201' THEN 'WB-M201-Corrected'
							WHEN Weightometer_Id = 'Thick to tail' THEN 'WB-ThickToTail-Corrected'
							WHEN Weightometer_Id = '251' THEN 'WB-BeneFinesToBPF0-Corrected'
							WHEN Weightometer_Id = '252' THEN 'WB-BeneFinesToSYard-Corrected'
							WHEN Weightometer_Id = '233' THEN 'WB-M233-Corrected'
						END,
						Product_Size, Tonnes, Destination_Stockpile_Id
					FROM @Tonnes
					WHERE Weightometer_Id IN ('201', 'Thick to tail', '251', '233', '252')
						
				OPEN @Cur
				
				FETCH NEXT FROM @Cur INTO @WeightometerId, @WeightometerSampleProductSize, @WeightometerSampleTonnes, @DestinationStockpileId
				
				WHILE @@FETCH_STATUS = 0
				BEGIN
					EXEC AddWeightometerSample
						@iWeightometer_Id = @WeightometerId,							
						@iWeightometer_Sample_Date = @iCalcDate,
						@iWeightometer_Sample_Shift = 'D',
						@iOrder_No = 1,
						@iTonnes = @WeightometerSampleTonnes,
						@oWeightometer_Sample_Id = @WeightometerSampleId OUTPUT
						
					IF (@WeightometerSampleProductSize <> 'ROM')
					BEGIN
						INSERT INTO WeightometerSampleNotes (Weightometer_Sample_Id, Weightometer_Sample_Field_Id, Notes)
						SELECT @WeightometerSampleId, 'ProductSize', @WeightometerSampleProductSize
					END										

					--
					-- This weightometer can't handle having a WFP as the destination, because it always seems to be a diff stockpile, 
					-- so we use the Destination from the original MQ2 data, if we have it
					--
					IF @WeightometerId = 'WB-BeneFinesToSYard-Corrected' AND @DestinationStockpileId IS NOT NULL
					BEGIN
						UPDATE WeightometerSample SET Destination_Stockpile_Id = @DestinationStockpileId
						WHERE Weightometer_Sample_Id = @WeightometerSampleId
					END

					FETCH NEXT FROM @Cur INTO @WeightometerId, @WeightometerSampleProductSize, @WeightometerSampleTonnes, @DestinationStockpileId
				END
			
				CLOSE @Cur
				DEALLOCATE @Cur
					
				SELECT @TonnesTotal = SUM(Tonnes)
				FROM WeightometerSample
				WHERE Weightometer_Id = 'WB-BeneOreRaw'
					AND Weightometer_Sample_Date = @iCalcDate
				
				SET @Cur = CURSOR FOR
					SELECT ws.Source_Stockpile_Id, ws.Destination_Stockpile_Id, ws.Tonnes, pt.Product_Size
					FROM WeightometerSample ws
					-- get the distinct set of ProductSizes relevant in this shift for 232
					-- this is required so that a seperate sample record can be generated for each product size
					CROSS JOIN (SELECT Distinct IsNull(t.Product_Size, 'ROM') as Product_Size FROM @Tonnes t WHERE t.Weightometer_Id = '232') As pt
					WHERE ws.Weightometer_Id = 'WB-BeneOreRaw'
						AND ws.Weightometer_Sample_Date = @iCalcDate
						
				OPEN @Cur
				
				FETCH NEXT FROM @Cur INTO @Source_Stockpile_Id, @Destination_Stockpile_ID, @RawTonnes, @WeightometerSampleProductSize
			
				WHILE @@FETCH_STATUS = 0
				BEGIN
					
					-- the tonnes for this product size are proportioned based on the proportion of RawTonnes to the TonnesTotal of the BeneOreRaw sample
					SELECT @232Tonnes = (@RawTonnes / @TonnesTotal) 
										* (SELECT ISNULL(SUM(t.Tonnes), 0.0) 
											FROM @Tonnes  t
											WHERE t.Weightometer_Id = '232'
											AND IsNull(t.Product_Size, 'ROM') = @WeightometerSampleProductSize)
					
					EXEC AddWeightometerSample
						@iWeightometer_Id = 'WB-M232-Corrected',
						@iWeightometer_Sample_Date = @iCalcDate,
						@iWeightometer_Sample_Shift = 'D',
						@iOrder_No = 1,
						@iSource_Stockpile_Id = @Source_Stockpile_Id,
						@iDestination_Stockpile_Id = @Destination_Stockpile_ID,
						@iTonnes = @232Tonnes,
						@oWeightometer_Sample_Id = @WeightometerSampleId OUTPUT
					
					-- Add the Product Size Note
					IF (@WeightometerSampleProductSize <> 'ROM')
					BEGIN
						INSERT INTO WeightometerSampleNotes (Weightometer_Sample_Id, Weightometer_Sample_Field_Id, Notes)
						SELECT @WeightometerSampleId, 'ProductSize', @WeightometerSampleProductSize
					END	
					
					FETCH NEXT FROM @Cur INTO @Source_Stockpile_Id, @Destination_Stockpile_ID, @RawTonnes, @WeightometerSampleProductSize		
				END
			
				CLOSE @Cur
				DEALLOCATE @Cur
				
				-- ADD WEIGHTOMETER SAMPLE GRADES 
				SET @Cur = CURSOR FOR
					SELECT WS.Weightometer_Sample_Id, G.Grade_ID, G.Grade_Value
					FROM @Grade G
						INNER JOIN WeightometerSample WS
							ON WS.Weightometer_ID = G.Weightometer_Id
						LEFT JOIN WeightometerSampleNotes WSN
							ON WS.Weightometer_Sample_Id = WSN.Weightometer_Sample_Id
							AND WSN.Weightometer_Sample_Field_Id = 'ProductSize'
					WHERE WS.Weightometer_Sample_Date = @iCalcDate
						-- I'm not sure that the @BalanceTypeComment filtering does anything, maybe it can be removed, but in anycase, it needs
						-- to be ignored for the SYard weightometer, because this can come from MQ2 even when everything else comes from the MET
						AND (G.Source = (CASE WHEN @BalanceTypeComment = 'MET Balance Data' THEN 'MET' ELSE 'MQ2' END) OR G.Weightometer_Id = 'WB-BeneFinesToSYard-Corrected')
						AND G.Product_Size = ISNULL(WSN.Notes, 'ROM')
				
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

GRANT EXECUTE ON dbo.CalcWhalebackVirtualFlowBene TO BhpbioGenericManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.CalcWhalebackVirtualFlowBene">
 <Procedure>
	Updates the Whaleback Production Data for the crushers.
 </Procedure>
</TAG>
*/

