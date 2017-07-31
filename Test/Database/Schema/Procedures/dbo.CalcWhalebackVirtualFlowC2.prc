IF OBJECT_ID('dbo.CalcWhalebackVirtualFlowC2') IS NOT NULL
	DROP PROCEDURE dbo.CalcWhalebackVirtualFlowC2
GO 

CREATE PROCEDURE [dbo].[CalcWhalebackVirtualFlowC2]
(
	@iCalcDate DATETIME,
	@iProductSize VARCHAR(15) = NULL
)
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 
	
	-- If the raw outflow weightometer has productsize information, and no productsize was passed in, then we want to 
	-- re-run the proc twice, once for each productsize, then exit.
	--
	-- If C2OutFlow doesn't have any productsize data, then just continue as normal
	--
	-- We need to check this outside of the transaction I think, otherwise we might have problems calling this method again
	If @iProductSize Is Null And Exists (
		Select 1 
		From WeightometerSampleNotes ps
			Inner Join WeightometerSample ws
				On ws.Weightometer_Sample_Id = ps.Weightometer_Sample_Id
		Where ws.Weightometer_Sample_Date = @iCalcDate
			And ws.Weightometer_Id = 'WB-C2OutFlow'
			And ps.Weightometer_Sample_Field_Id = 'ProductSize'
	)
	Begin
		-- OK, now we check to see if there are any records WITHOUT lump fines for that date
		-- we cannot handle the situation where some C2 records have L/F and some don't so in this
		-- case we need to raise an exception.
		--
		-- This shouldn't actually happen in practise at the moment, but we would like to know if
		-- it does
		If Exists (
			Select 1 
			From WeightometerSample ws
				Left Join WeightometerSampleNotes ps
					On ps.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
						And ps.Weightometer_Sample_Field_Id = 'ProductSize'
			Where ws.Weightometer_Sample_Date = @iCalcDate
				And ws.Weightometer_Id = 'WB-C2OutFlow'
				And ps.Weightometer_Sample_Field_Id Is Null
		)
		Begin
			Raiserror('Cannot run CVF: WB-C2OutFlow contains both samples with L/F and without for a single day', 16, 1)
			Return
		End
		
		
		Print 'Lump/Fines Data found for WB-C2OutFlow - Rerunning with Product Sizes'
		exec [dbo].[CalcWhalebackVirtualFlowC2] @iCalcDate, 'LUMP'
		exec [dbo].[CalcWhalebackVirtualFlowC2] @iCalcDate, 'FINES'
		Return
	End

	SELECT @TransactionName = 'CalcWhalebackVirtualFlowC2',
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
		
		DECLARE @LocationId_Newman INT
		DECLARE @InputTonnesExist BIT
		DECLARE @OutputTonnesExist BIT
		DECLARE @minimumSignificantTonnes INTEGER
		
		SET @InputTonnesExist = 0
		SET @OutputTonnesExist = 0
		
		Declare @ProductSize Varchar(15)
		Declare @HasProductSize Bit
		
		Set @ProductSize = @iProductSize
		
		If @ProductSize Is Not Null 
			Set @HasProductSize = 1
		Else 
			Set @HasProductSize = 0
		
		
		If @ProductSize Is Null Print 'Running CVF-C2 without product size filter'
		Else If @ProductSize = 'LUMP' Print 'Running CVF-C2 for LUMP'
		Else If @ProductSize = 'FINES' Print 'Running CVF-C2 for FINES'
		
		-- determine the minimum movement tonnages to be considered significant (used to trigger 'No Tonnes Moved' messages)
		SELECT @minimumSignificantTonnes = convert(INTEGER, value)
		FROM Setting
		WHERE Setting_Id = 'WEIGHTOMETER_MINIMUM_TONNES_SIGNIFICANT'
		
		IF @minimumSignificantTonnes IS NULL
		BEGIN
			SET @minimumSignificantTonnes = 1
		END
		
		-- used to weight the impact of a discrepancy in OHP4 in/out tonnes on the calculated Sample Tonnes
		DECLARE @OHP4TonnesDiscrepancyFactor INT
		SET @OHP4TonnesDiscrepancyFactor = 10
		
		DECLARE @WeightometerInputList TABLE ( Weightometer VARCHAR(31), SampleSource VARCHAR(255), IncludeInSampledProportion BIT, UseSampleTonnesForGradeWeighting BIT, SampledProportionWeighting REAL)
		DECLARE @WeightometerOutputList TABLE ( Weightometer VARCHAR(31), SampleSource VARCHAR(255), SampledProportionWeighting REAL)
		
		SELECT @LocationId_Newman = l.Location_Id
		FROM dbo.Location l
		INNER JOIN dbo.LocationType lt
			ON l.Location_Type_Id = lt.Location_Type_Id
		WHERE l.[Name] = 'Newman'
			AND lt.[Description] = 'Site'
			
		IF @LocationId_Newman IS NULL
		BEGIN
			RAISERROR('Location Newman could not be found', 16, 1)				
		END
		
		-- Add weightometers to the input list as determined by custom weightometer groups
		INSERT INTO @WeightometerInputList (Weightometer, SampleSource, IncludeInSampledProportion, UseSampleTonnesForGradeWeighting, SampledProportionWeighting)
		
		-- Weightometers with Port Actual samples
		SELECT Weightometer_Id, 'PORT ACTUALS', 1, 0, 1
		FROM dbo.BhpbioWeightometerGroupWeightometer		
		WHERE Weightometer_Group_Id = 'WBC2BackCalcWithPortActuals'		
			AND ([Start_Date] <= @iCalcDate)
			AND ([End_Date] IS NULL OR [End_Date] >= @iCalcDate)
		UNION
		
		-- Weightometers with Crusher Actual samples
		SELECT Weightometer_Id, 'CRUSHER ACTUALS', 1, 0, 1
		FROM dbo.BhpbioWeightometerGroupWeightometer		
		WHERE Weightometer_Group_Id = 'WBC2BackCalcWithCrusherActuals'
			AND ([Start_Date] <= @iCalcDate)
			AND ([End_Date] IS NULL OR [End_Date] >= @iCalcDate)
		UNION
		
		-- Weightometers with no specific sample actual requirements
		SELECT Weightometer_Id, NULL, 0, 0, 1
		FROM dbo.BhpbioWeightometerGroupWeightometer		
		WHERE Weightometer_Group_Id = 'WBC2BackCalcWOutSampleActuals'	
			AND ([Start_Date] <= @iCalcDate)
			AND ([End_Date] IS NULL OR [End_Date] >= @iCalcDate)							
		
		SET @InputTonnesExist = (CASE WHEN EXISTS (
			SELECT TOP 1 1
			FROM @WeightometerInputList wi
			INNER JOIN GetBhpbioWeightometerSampleWithProductSize(@iCalcDate, @HasProductSize) ws
				ON ws.Weightometer_Id = wi.Weightometer
					AND ws.Weightometer_Sample_Date = @iCalcDate
					AND ws.Tonnes > 0
					AND (@HasProductSize = 0 OR ws.Product_Size = @ProductSize)
		) THEN 1 ELSE 0 END)
	
		-- Add pre-determined weightometers to the output list
		IF @iCalcDate > (SELECT End_Date FROM dbo.WeightometerFlowPeriod WHERE Weightometer_Id = 'NJV-OHPOutflow')
		BEGIN 

			INSERT INTO @WeightometerOutputList (Weightometer, SampleSource, SampledProportionWeighting)
			SELECT 'NJV-OHP4OutflowCorrected', 'COMBINED', 2
		END
		ELSE
		BEGIN
			INSERT INTO @WeightometerOutputList (Weightometer, SampleSource, SampledProportionWeighting)
			SELECT 'NJV-OHPOutflow', 'CRUSHER ACTUALS', 2
		END

		SET @OutputTonnesExist = (CASE WHEN EXISTS (
			SELECT TOP 1 1
			FROM @WeightometerOutputList wo
			INNER JOIN GetBhpbioWeightometerSampleWithProductSize(@iCalcDate, @HasProductSize) ws
				ON ws.Weightometer_Id = wo.Weightometer
					AND ws.Weightometer_Sample_Date = @iCalcDate
					AND ws.Tonnes > 0
					AND (@HasProductSize = 0 OR ws.Product_Size = @ProductSize)
		) THEN 1 ELSE 0 END)
				
		DECLARE @Cur CURSOR
		DECLARE @InnerCur CURSOR

		DECLARE @WeightometerId VARCHAR(31)
		DECLARE @WeightometerSampleShift CHAR(1)
		DECLARE @WeightometerSampleOrderNo INT
		DECLARE @WeightometerSampleTonnes FLOAT
		DECLARE @WeightometerSampleCorrectedTonnes FLOAT
		DECLARE @WeightometerSampleSourceStockpile INT
		DECLARE @WeightometerSampleDestinationStockpile INT
		DECLARE @WeightometerSampleProductSize VARCHAR(5)

		DECLARE @WeightometerSampleOriginalId INT
		DECLARE @WeightometerSampleId INT
		
		DECLARE @CrusherActualsExist BIT
		SET @CrusherActualsExist = 0
		
		-- Get the minimum date for applying back calculations
		DECLARE @SettingValue VARCHAR(255)
		DECLARE @BCStartDate DATETIME

		EXEC dbo.GetSystemSetting 
				@iSetting_Id = 'WB_C2_BACK_CALCULATION_START_DATE',
				@iValue = @SettingValue OUTPUT
		
		SET @BCStartDate = CAST(COALESCE(@SettingValue, '1-Jan-2014') AS DATETIME)		
		
		-- DELETE ANY EXISTING SAMPLE FOR THIS DATE
		IF EXISTS
		(
			SELECT TOP 1 1
			FROM GetBhpbioWeightometerSampleWithProductSize(@iCalcDate, @HasProductSize) ws
			WHERE Weightometer_Sample_Date = @iCalcDate
				AND Weightometer_Id IN
					(
						'WB-C2OutFlow-Corrected',
						'WB-C2OutFlow-CorrectedBCOnly'
					)
				AND (@HasProductSize = 0 OR ws.Product_Size = @ProductSize)
		)
		BEGIN
		
		SET @Cur = CURSOR FAST_FORWARD READ_ONLY FOR
		
			SELECT Weightometer_Sample_Id
			FROM GetBhpbioWeightometerSampleWithProductSize(@iCalcDate, @HasProductSize) ws
			WHERE Weightometer_Sample_Date = @iCalcDate
				AND Weightometer_Id IN
					(
						'WB-C2OutFlow-Corrected',
						'WB-C2OutFlow-CorrectedBCOnly'
					)
				AND (@HasProductSize = 0 OR ws.Product_Size = @ProductSize)
					
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
		
		-- Check if there were any Crusher Actuals recorded for the date for WB-C2OutFlow
		IF EXISTS
		(
			SELECT TOP 1 1
			FROM dbo.WeightometerSampleNotes wsn
			INNER JOIN GetBhpbioWeightometerSampleWithProductSize(@iCalcDate, 0) ws -- no default split for C2
				ON wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
					AND (@HasProductSize = 0 OR ws.Product_Size = @ProductSize)
			WHERE ws.Weightometer_Sample_Date = @iCalcDate 
				AND wsn.[Notes] = 'CRUSHER ACTUALS'
				AND ws.Weightometer_Id IN
					(
						'WB-C2OutFlow'
					)
		)
		BEGIN				
			SET @CrusherActualsExist = 1
		END
					
		-- Copy Weightometer sample data associated with WB-C2OutFlow to WB-C2OutFlow-Corrected						
		SET @Cur = CURSOR FAST_FORWARD READ_ONLY FOR
		
			SELECT Weightometer_Sample_Id, Weightometer_Sample_Shift, Order_No, Source_Stockpile_Id, Destination_Stockpile_Id, Tonnes, Corrected_Tonnes
			FROM GetBhpbioWeightometerSampleWithProductSize(@iCalcDate, 0) ws -- note that no default split for C2
			WHERE Weightometer_Sample_Date = @iCalcDate
				AND Weightometer_Id IN
					(
						'WB-C2OutFlow'
					)
				AND (@HasProductSize = 0 OR ws.Product_Size = @ProductSize)
					
		OPEN @Cur
				
		FETCH NEXT FROM @Cur INTO @WeightometerSampleOriginalId, @WeightometerSampleShift, @WeightometerSampleOrderNo, @WeightometerSampleSourceStockpile,
								  @WeightometerSampleDestinationStockpile, @WeightometerSampleTonnes, @WeightometerSampleCorrectedTonnes
				
		WHILE @@FETCH_STATUS = 0
		BEGIN		
			
			-- Copy the Weightometer sample to WB-C2OutFlow-Corrected
			EXEC AddWeightometerSample
					@iWeightometer_Id = 'WB-C2OutFlow-Corrected',							
					@iWeightometer_Sample_Date = @iCalcDate,
					@iWeightometer_Sample_Shift = @WeightometerSampleShift,
					@iOrder_No = @WeightometerSampleOrderNo,					
					@iTonnes = @WeightometerSampleTonnes,
					@iCorrected_Tonnes = @WeightometerSampleCorrectedTonnes,
					@iSource_Stockpile_Id = @WeightometerSampleSourceStockpile,
					@iDestination_Stockpile_Id = @WeightometerSampleDestinationStockpile,
					@oWeightometer_Sample_Id = @WeightometerSampleId OUTPUT
					
			-- Copy sample values to WB-C2OutFlow-Corrected
			-- If CRUSHER ACTUALS exist for WB-C2OutFlow, copy all values. If not, copy only when the field id is not 'SampleTonnes'				
			INSERT INTO dbo.WeightometerSampleValue (Weightometer_Sample_Id, Weightometer_Sample_Field_Id, Field_Value)
			SELECT @WeightometerSampleId, Weightometer_Sample_Field_Id, Field_Value
			FROM dbo.WeightometerSampleValue
			WHERE Weightometer_Sample_Id = @WeightometerSampleOriginalId
				AND (@CrusherActualsExist = 1 OR @iCalcDate < @BCStartDate OR 
						NOT Weightometer_Sample_Field_Id = 'SampleTonnes'
					)	
					
			-- Copy sample values to WB-C2OutFlow-Corrected
			-- If CRUSHER ACTUALS exist for WB-C2OutFlow, copy all notes. If not, copy only when the field id is not 'SampleSource'										
			INSERT INTO dbo.WeightometerSampleNotes (Weightometer_Sample_Id, Weightometer_Sample_Field_Id, [Notes])
			SELECT @WeightometerSampleId, Weightometer_Sample_Field_Id, [Notes]
			FROM dbo.WeightometerSampleNotes
			WHERE Weightometer_Sample_Id = @WeightometerSampleOriginalId
				AND (@CrusherActualsExist = 1 OR @iCalcDate < @BCStartDate OR 
						NOT Weightometer_Sample_Field_Id = 'SampleSource'
					)	
					
			-- If CRUSHER ACTUALS exist, copy sample grades to WB-C2OutFlow-Corrected						
			IF (@CrusherActualsExist = 1 OR @iCalcDate < @BCStartDate)
			BEGIN
			
				INSERT INTO dbo.WeightometerSampleGrade (Weightometer_Sample_Id, Grade_Id, Grade_Value)
				SELECT @WeightometerSampleId, Grade_Id, Grade_Value
				FROM dbo.WeightometerSampleGrade
				WHERE Weightometer_Sample_Id = @WeightometerSampleOriginalId
				
			END
	
			-- Copy the Weightometer sample to WB-C2OutFlow-CorrectedBCOnly
			EXEC AddWeightometerSample
					@iWeightometer_Id = 'WB-C2OutFlow-CorrectedBCOnly',							
					@iWeightometer_Sample_Date = @iCalcDate,
					@iWeightometer_Sample_Shift = @WeightometerSampleShift,
					@iOrder_No = @WeightometerSampleOrderNo,					
					@iTonnes = @WeightometerSampleTonnes,
					@iCorrected_Tonnes = @WeightometerSampleCorrectedTonnes,
					@iSource_Stockpile_Id = @WeightometerSampleSourceStockpile,
					@iDestination_Stockpile_Id = @WeightometerSampleDestinationStockpile,
					@oWeightometer_Sample_Id = @WeightometerSampleId OUTPUT
					
			-- Copy sample values to WB-C2OutFlow-CorrectedBCOnly where the field id is not 'SampleTonnes'		
			INSERT INTO dbo.WeightometerSampleValue (Weightometer_Sample_Id, Weightometer_Sample_Field_Id, Field_Value)
			SELECT @WeightometerSampleId, Weightometer_Sample_Field_Id, Field_Value
			FROM dbo.WeightometerSampleValue
			WHERE Weightometer_Sample_Id = @WeightometerSampleOriginalId
				AND NOT Weightometer_Sample_Field_Id = 'SampleTonnes'							
					
			-- Copy sample values to WB-C2OutFlow-CorrectedBCOnly where the field id is not 'SampleSource'								
			INSERT INTO dbo.WeightometerSampleNotes (Weightometer_Sample_Id, Weightometer_Sample_Field_Id, [Notes])
			SELECT @WeightometerSampleId, Weightometer_Sample_Field_Id, [Notes]
			FROM dbo.WeightometerSampleNotes
			WHERE Weightometer_Sample_Id = @WeightometerSampleOriginalId
				AND NOT Weightometer_Sample_Field_Id = 'SampleSource'
			
																				
			FETCH NEXT FROM @Cur INTO @WeightometerSampleOriginalId, @WeightometerSampleShift, @WeightometerSampleOrderNo, @WeightometerSampleSourceStockpile,
									  @WeightometerSampleDestinationStockpile, @WeightometerSampleTonnes, @WeightometerSampleCorrectedTonnes
			
		END
		
		CLOSE @Cur	
		DEALLOCATE @Cur					
		
		-- Grab the insufficient samples exception type
		DECLARE @DataExceptionTypeId_InsufficientSamples INT
		
		SELECT @DataExceptionTypeId_InsufficientSamples = Data_Exception_Type_Id
		FROM dbo.DataExceptionType
		WHERE [Name] = 'Insufficient sample information to back-calculate grades'			
				
		IF @DataExceptionTypeId_InsufficientSamples IS NULL
		BEGIN
			RAISERROR('Data Exception Type for insufficient sample information available to perform back-calculation could not be found', 16, 1)			
		END
		
		DECLARE @InsufficientForBCWeightometers TABLE
		(
			Weightometer VARCHAR(31)
		)
		
		DECLARE @distinctOutlflowSourceCount INTEGER

		SELECT @distinctOutlflowSourceCount = COUNT(*)
		FROM 
		(
			-- select a record for each sample source type matched
			SELECT DISTINCT wsn.[Notes]
			FROM @WeightometerOutputList wo
			INNER JOIN GetBhpbioWeightometerSampleWithProductSize(@iCalcDate, @HasProductSize) ws
				ON ws.Weightometer_Id = wo.Weightometer 
				AND ws.Weightometer_Sample_Date = @iCalcDate
			LEFT OUTER JOIN dbo.WeightometerSampleNotes wsn
				ON ws.Weightometer_Sample_Id = wsn.Weightometer_Sample_Id	
					AND wsn.Weightometer_Sample_Field_Id = 'SampleSource'
			INNER JOIN dbo.WeightometerSampleGrade wsg
				ON wsg.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
			WHERE ws.Tonnes > 0
				AND (wo.SampleSource IS NULL OR wo.SampleSource = wsn.[Notes] OR (wo.SampleSource = 'COMBINED' and wsn.Notes IN ('BACK-CALCULATED GRADES','CRUSHER ACTUALS')))
				AND (@HasProductSize = 0 OR ws.Product_Size = @ProductSize)
		) As IncludedSources


		DECLARE @SufficientSamplesForBC BIT
		SET @SufficientSamplesForBC = 0							
						
		-- Checks for samples required for back calculation
		-- there are insufficient samples if any of the weightometers on the input or output list
		-- have samples, but none from the sample source required for the specific weightometer for the date (with grades)
		-- and where realtonnes > @minimumSignificantTonnes (i.e. the weightometer was active)							
		INSERT INTO @InsufficientForBCWeightometers	
		SELECT wi.Weightometer
		FROM @WeightometerInputList wi				
		WHERE (
			SELECT Sum(Tonnes)
			FROM GetBhpbioWeightometerSampleWithProductSize(@iCalcDate, @HasProductSize) ws
			WHERE Weightometer_Id = wi.Weightometer 
				AND Weightometer_Sample_Date = @iCalcDate
				AND (@HasProductSize = 0 OR ws.Product_Size = @ProductSize)
			) >= @minimumSignificantTonnes				
		AND NOT EXISTS (
			SELECT TOP 1 1
			FROM GetBhpbioWeightometerSampleWithProductSize(@iCalcDate, @HasProductSize) ws
				LEFT OUTER JOIN dbo.WeightometerSampleNotes wsn
					ON ws.Weightometer_Sample_Id = wsn.Weightometer_Sample_Id	
						AND wsn.Weightometer_Sample_Field_Id = 'SampleSource'
				INNER JOIN dbo.WeightometerSampleGrade wsg
					ON wsg.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
			WHERE ws.Weightometer_Id = wi.Weightometer 
				AND ws.Weightometer_Sample_Date = @iCalcDate
				AND ws.Tonnes > 0
				AND (wi.SampleSource IS NULL OR wi.SampleSource = wsn.[Notes])
				AND (@HasProductSize = 0 OR ws.Product_Size = @ProductSize)
		)	
			
		UNION
		
		SELECT wo.Weightometer
		FROM @WeightometerOutputList wo
			LEFT JOIN 
			(
					-- count how many types of samplesources are valid for inclusion for each output weightometer
					SELECT IncludedSources.Weightometer, COUNT(*) as SampleTypeCount
					FROM
					(
					-- select a record for each sample source type matched
					SELECT DISTINCT wo2.Weightometer, wsn2.[Notes]
					FROM @WeightometerOutputList wo2
					INNER JOIN GetBhpbioWeightometerSampleWithProductSize(@iCalcDate, @HasProductSize) ws2
						ON ws2.Weightometer_Id = wo2.Weightometer 
						AND ws2.Weightometer_Sample_Date = @iCalcDate
					LEFT OUTER JOIN dbo.WeightometerSampleNotes wsn2
						ON ws2.Weightometer_Sample_Id = wsn2.Weightometer_Sample_Id	
							AND wsn2.Weightometer_Sample_Field_Id = 'SampleSource'
					INNER JOIN dbo.WeightometerSampleGrade wsg2
						ON wsg2.Weightometer_Sample_Id = ws2.Weightometer_Sample_Id
					WHERE ws2.Tonnes > 0
						AND (wo2.SampleSource IS NULL OR wo2.SampleSource = wsn2.[Notes] OR (wo2.SampleSource = 'COMBINED' and wsn2.Notes IN ('BACK-CALCULATED GRADES','CRUSHER ACTUALS')))
						AND (@HasProductSize = 0 OR ws2.Product_Size = @ProductSize)
					) As IncludedSources
					GROUP BY IncludedSources.Weightometer
			)  as sourceTypeCountByWeightometer ON sourceTypeCountByWeightometer.Weightometer = wo.Weightometer
		WHERE 
			-- where tonnes are moved
			EXISTS (
			SELECT TOP 1 1 
			FROM GetBhpbioWeightometerSampleWithProductSize(@iCalcDate, @HasProductSize) ws
			WHERE Weightometer_Id = wo.Weightometer 
				AND Weightometer_Sample_Date = @iCalcDate
				AND Tonnes > 0
				AND (@HasProductSize = 0 OR ws.Product_Size = @ProductSize)
			)	
			-- and not enough sample sources
			AND IsNull(sourceTypeCountByWeightometer.SampleTypeCount, 0) < CASE WHEN wo.SampleSource = 'COMBINED' AND @HasProductSize = 0 THEN 2 ELSE 1 END   
			-- if COMBINED and processing for all product sizes, then must be at least 2 sample source types, otherwise at least 1
		
			
		SET @SufficientSamplesForBC = 
			(CASE WHEN ((SELECT COUNT(*) FROM @InsufficientForBCWeightometers) = 0 AND @InputTonnesExist != 0 AND @OutputTonnesExist != 0) THEN 1 ELSE 0 END)

		PRINT 'CALC DATE = ' + CAST(@iCalcDate AS VARCHAR)

		DECLARE @WBC2TT FLOAT -- Total tonnes from WB-C2OutFlow
		DECLARE @TTO FLOAT -- Total tonnes from outputs
				
		-- Get the total tonnes from WB-C2OutFlow
		SELECT @WBC2TT = ISNULL(SUM(Tonnes), 0)
		FROM GetBhpbioWeightometerSampleWithProductSize(@iCalcDate, @HasProductSize) ws
		WHERE Weightometer_Sample_Date = @iCalcDate
			AND Weightometer_Id IN
			(
				'WB-C2OutFlow'
			)
			AND (@HasProductSize = 0 OR ws.Product_Size = @ProductSize)
				
		PRINT 'WBC2TT = ' + CAST(@WBC2TT AS VARCHAR)
		
		SELECT @TTO = SUM(Tonnes)
			FROM GetBhpbioWeightometerSampleWithProductSize(@iCalcDate, @HasProductSize) ws
			WHERE Weightometer_Sample_Date = @iCalcDate
				AND Weightometer_Id IN (SELECT Weightometer FROM @WeightometerOutputList)		
				AND (@HasProductSize = 0 OR ws.Product_Size = @ProductSize)	
			
			PRINT 'TTO = ' + CAST(@TTO AS VARCHAR)

				

		-- If sufficient samples are found for the inputs and outputs AND the tonnages are sufficient
		IF @SufficientSamplesForBC = 1 AND @WBC2TT >= @minimumSignificantTonnes AND @TTO >= @minimumSignificantTonnes
		BEGIN
			-- Clear existing data exceptions for this date
			DELETE FROM dbo.DataException
			WHERE Data_Exception_Type_Id = @DataExceptionTypeId_InsufficientSamples
				AND Data_Exception_Date = @iCalcDate		
				AND Details_XML.value('(/DocumentElement/Insufficient_Sample_Information/TargetWeightometer_Id)[1]', 'nvarchar(31)') = 'WB-C2OutFlow-Corrected'
			
			DECLARE @TTIex FLOAT -- Total tonnes from inputs (18-PostCrusherToTrainRake, 25-PostC2ToTrainRake, WB-M232-Corrected)						
			DECLARE @TTIinc FLOAT -- Total tonnes from inputs and WB-C2OutFlow (18-PostCrusherToTrainRake, 25-PostC2ToTrainRake, WB-M232-Corrected, WB-C2OutFlow)	
			DECLARE @SF FLOAT -- Scaling Factor
			DECLARE @WBC2ST FLOAT -- Scaled tonnes for WB-C2OutFlow
			
			DECLARE @SP FLOAT -- Sample Proportion
			
			SELECT @TTIex = SUM(Tonnes)
			FROM GetBhpbioWeightometerSampleWithProductSize(@iCalcDate, @HasProductSize) ws
			WHERE Weightometer_Sample_Date = @iCalcDate
				AND Weightometer_Id IN (SELECT Weightometer FROM @WeightometerInputList)
				AND (@HasProductSize = 0 OR ws.Product_Size = @ProductSize)
				
			PRINT 'TTIex = ' + CAST(@TTIex AS VARCHAR)
			
			SET @TTIinc = (@TTIex + @WBC2TT)
			
			PRINT 'TTIinc = ' + CAST(@TTIinc AS VARCHAR)
			
			SET @SF = (CASE WHEN @TTIinc = 0 THEN 0 ELSE @TTO / @TTIinc END)
			
			PRINT 'SF = ' + CAST(@SF AS VARCHAR)
			
			SET @WBC2ST = @WBC2TT * @SF
			
			PRINT 'WBC2ST = ' + CAST(@WBC2ST AS VARCHAR)
			
			-- Apply multiplicative weighting based on sample coverage for each contributing weightometer, so that poor 
			-- sampling across multiple weightometers will diminish the effective sample tonnes rapidly for the given 24 hour period
			-- Note that EXP(SUM(LOG())) applies multiplicative aggregation, and the POWER function is used on the sampled tonnes/tonnes 
			-- ratio to further emphasize the effect of poor sample coverage
			-- The DiscrepancyModifier is based on the OHP4 in/out tonnes discrepancy, and this will further reduce the sample weighting if
			-- a large tonnes discrepancy is present
			SELECT @SP = EXP(SUM(LOG(POWER(CASE WHEN SampleTonnes > Tonnes THEN 1 ELSE SampleTonnes / Tonnes END, SampledProportionWeighting)))) * AVG(DiscrepancyModifier)
			FROM (
				SELECT Weightometer, SampledProportionWeighting, NULLIF(SUM(ISNULL(
							CASE WHEN wio.UseSampleTonnesForGradeWeighting = 1 
									THEN wsv.Field_Value -- use the sample tonnes
								 WHEN IsNull(wio.UseSampleTonnesForGradeWeighting,0) = 0 AND wsn.Notes Is Not Null --  ie.  use the full tonnes, but only for movements that were sampled
									THEN ws.Tonnes
								 ELSE 0
							END
								 , 0)), 0) as SampleTonnes, NULLIF(SUM(TONNES), 0) As Tonnes
				FROM 
				(
					SELECT Weightometer, SampleSource, SampledProportionWeighting, UseSampleTonnesForGradeWeighting
					FROM @WeightometerInputList
					WHERE IncludeInSampledProportion = 1
					UNION
					SELECT Weightometer, SampleSource, SampledProportionWeighting, 0 as UseSampleTonnesForGradeWeighting
					FROM @WeightometerOutputList
				) wio 
				LEFT JOIN GetBhpbioWeightometerSampleWithProductSize(@iCalcDate, @HasProductSize) ws
					ON wio.Weightometer = ws.Weightometer_Id
					AND ws.Weightometer_Sample_Date = @iCalcDate
					AND (@HasProductSize = 0 OR ws.Product_Size = @ProductSize)
				LEFT JOIN dbo.WeightometerSampleNotes wsn
					ON ws.Weightometer_Sample_Id = wsn.Weightometer_Sample_Id
					AND wsn.Weightometer_Sample_Field_Id = 'SampleSource'
					AND (wio.SampleSource IS NULL OR (wio.SampleSource IS NOT NULL AND wio.SampleSource = wsn.[Notes]) or (wio.SampleSource = 'COMBINED' AND wsn.Notes IN ('BACK-CALCULATED GRADES', 'CRUSHER ACTUALS')))
				LEFT JOIN dbo.WeightometerSampleValue wsv
					ON wsv.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
					AND wsv.Weightometer_Sample_Field_Id = 'SampleTonnes'
					AND wsn.Weightometer_Sample_Id IS NOT NULL
				GROUP BY Weightometer, SampledProportionWeighting
			) SampleCoverage
			-- account for OHP4 in/out tonnes discrepancy
			CROSS JOIN 
			(
				SELECT POWER(1 - (ABS(SUM(InOutModifier * Tonnes)) / SUM(Tonnes)), @OHP4TonnesDiscrepancyFactor) As DiscrepancyModifier
				FROM 
				(
					SELECT Weightometer, 1 As InOutModifier
					FROM @WeightometerInputList
					WHERE IncludeInSampledProportion = 1
					UNION 
					SELECT 'WB-C2OutFlow-Corrected', 1 As InOutModifier
					UNION
					SELECT Weightometer, -1 As InOutModifier
					FROM @WeightometerOutputList
				) wio 
				LEFT JOIN GetBhpbioWeightometerSampleWithProductSize(@iCalcDate, @HasProductSize) ws
					ON wio.Weightometer = ws.Weightometer_Id
					AND ws.Weightometer_Sample_Date = @iCalcDate
					AND (@HasProductSize = 0 OR ws.Product_Size = @ProductSize)
			) InOutTonnesDiscrepancy
			
			-- Don't allow Sample Proportion to exceed a cap of 1.  This could only occur with abnormal SampleTonnes data
			IF @SP > 1
			BEGIN
				SET @SP = 1
			END
			
			PRINT 'SP = ' + CAST(@SP AS VARCHAR)
			
			DECLARE @InputWeightometer VARCHAR(31)
						
			DECLARE @GradeId INT
			
			DECLARE @OWAGa FLOAT -- Weighted Average Output Grade
			DECLARE @OGUa FLOAT -- Output Grade Units
						
			DECLARE @IWAGa FLOAT -- Weighted Average Input Grade
			DECLARE @IGUa FLOAT -- Input Grade Units
			
			DECLARE @TIGUa FLOAT -- Total Input Grade Units
			DECLARE @SIGUa FLOAT -- Scaled Input Grade Units
			
			DECLARE @MGa FLOAT -- Missing Grade Units
			DECLARE @BCa FLOAT -- Back-Calculated Grade Value
			DECLARE @inputTonnesWithoutGrade FLOAT
			DECLARE @inputTonnesWithGrade FLOAT
			
			-- For each Grade type
			SET @Cur = CURSOR FAST_FORWARD READ_ONLY FOR
			
				SELECT Grade_Id
				FROM dbo.Grade
						
			OPEN @Cur
					
			FETCH NEXT FROM @Cur INTO @GradeId
					
			WHILE @@FETCH_STATUS = 0
			BEGIN	
			
				SET @TIGUa = 0
				SET @inputTonnesWithoutGrade = 0 -- track the input tonnes that have no grade value
				SET @inputTonnesWithGrade = 0
				
				PRINT CAST(@GradeId AS VARCHAR)
				
				-- Calculate the weighted average output grade
				SELECT @OWAGa = (CASE WHEN SUM(ws.Tonnes) = 0 
									  THEN 0 
									  ELSE SUM(ws.Tonnes * wsg.Grade_Value) / SUM(ws.Tonnes) 
								 END)
				FROM dbo.WeightometerSampleValue wsv
				INNER JOIN GetBhpbioWeightometerSampleWithProductSize(@iCalcDate, @HasProductSize) ws
					ON wsv.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
				INNER JOIN dbo.WeightometerSampleNotes wsn
					ON ws.Weightometer_Sample_Id = wsn.Weightometer_Sample_Id
						AND wsn.Weightometer_Sample_Field_Id = 'SampleSource'
				INNER JOIN dbo.WeightometerSampleGrade wsg
					ON ws.Weightometer_Sample_Id = wsg.Weightometer_Sample_Id
				INNER JOIN @WeightometerOutputList wo
					ON ws.Weightometer_Id = wo.Weightometer
						AND (wo.SampleSource IS NULL OR wsn.[Notes] = wo.SampleSource OR (wo.SampleSource = 'COMBINED' AND wsn.[Notes] IN ('BACK-CALCULATED GRADES','CRUSHER ACTUALS')))
				WHERE wsv.Weightometer_Sample_Field_Id = 'SampleTonnes'
					AND ws.Weightometer_Sample_Date = @iCalcDate
					AND wsg.Grade_Id = @GradeId
					AND (@HasProductSize = 0 OR ws.Product_Size = @ProductSize)			
					
				PRINT 'OWAGa = ' + CAST(@OWAGa AS VARCHAR)
						
				-- Calculate the total output grade units
				SELECT @OGUa = SUM(Tonnes) * @OWAGa
				FROM GetBhpbioWeightometerSampleWithProductSize(@iCalcDate, @HasProductSize) ws
				WHERE Weightometer_Id IN (SELECT Weightometer FROM @WeightometerOutputList)
					AND Weightometer_Sample_Date = @iCalcDate
					AND (@HasProductSize = 0 OR ws.Product_Size = @ProductSize)
					
				PRINT 'OGUa = ' + CAST(@OGUa AS VARCHAR)
							
				-- For each Weightometer in @WeightometerInputList
				SET @InnerCur = CURSOR FAST_FORWARD FOR
				
					SELECT Weightometer
					FROM @WeightometerInputList
							
				OPEN @InnerCur
						
				FETCH NEXT FROM @InnerCur INTO @InputWeightometer
						
				WHILE @@FETCH_STATUS = 0
				BEGIN	
								
					PRINT @InputWeightometer
					
					-- Calculate the weighted average input grade
					SELECT @IWAGa = (CASE WHEN SUM(CASE WHEN wi.UseSampleTonnesForGradeWeighting = 1 THEN wsv.Field_Value ELSE ws.Tonnes END) = 0
										  THEN 0
										  ELSE SUM((CASE WHEN wi.UseSampleTonnesForGradeWeighting = 1 THEN wsv.Field_Value ELSE ws.Tonnes END) * wsg.Grade_Value) /
											   SUM(CASE WHEN wi.UseSampleTonnesForGradeWeighting = 1 THEN wsv.Field_Value ELSE ws.Tonnes END)
									 END)						
					FROM GetBhpbioWeightometerSampleWithProductSize(@iCalcDate, @HasProductSize) ws								
					INNER JOIN dbo.WeightometerSampleGrade wsg
						ON ws.Weightometer_Sample_Id = wsg.Weightometer_Sample_Id
					INNER JOIN @WeightometerInputList wi
						ON ws.Weightometer_Id = wi.Weightometer
					LEFT OUTER JOIN dbo.WeightometerSampleValue wsv
						ON wsv.Weightometer_Sample_Id = ws.Weightometer_Sample_Id		
							AND wsv.Weightometer_Sample_Field_Id = 'SampleTonnes'	
					LEFT OUTER JOIN dbo.WeightometerSampleNotes wsn
						ON ws.Weightometer_Sample_Id = wsn.Weightometer_Sample_Id
							AND wsn.Weightometer_Sample_Field_Id = 'SampleSource'									
					WHERE ws.Weightometer_Id = @InputWeightometer
						AND ws.Weightometer_Sample_Date = @iCalcDate
						AND wsg.Grade_Id = @GradeId
						AND (wi.SampleSource IS NULL OR (wsn.[Notes] IS NOT NULL AND wi.SampleSource = wsn.[Notes]))
						AND CASE WHEN wi.UseSampleTonnesForGradeWeighting = 1 THEN wsv.Field_Value ELSE ws.Tonnes END > 0
						AND (@HasProductSize = 0 OR ws.Product_Size = @ProductSize)
					
					PRINT 'IWAGa = ' + CAST(@IWAGa AS VARCHAR)
					
					-- calculate the total tonnes for this weightometer
					DECLARE @weightometerTotalTonnes FLOAT
					
					SELECT @weightometerTotalTonnes = SUM(Tonnes)
					FROM GetBhpbioWeightometerSampleWithProductSize(@iCalcDate, @HasProductSize) ws
					WHERE Weightometer_Id = @InputWeightometer
						AND Weightometer_Sample_Date = @iCalcDate
						AND (@HasProductSize = 0 OR ws.Product_Size = @ProductSize)
						
					-- Calculate the input grade units	(if possible)
					SELECT @IGUa = @weightometerTotalTonnes * @IWAGa
					
											
					PRINT 'IGUa = ' + CAST(@IGUa AS VARCHAR)
					
					IF @IWAGa IS NULL
					BEGIN
						-- can't associate grade with these tonnes
						-- sum them up so that they can be used later
						SET @inputTonnesWithoutGrade = (@inputTonnesWithoutGrade + ISNULL(@weightometerTotalTonnes, 0))
					END
					ELSE
					BEGIN
						-- Calculate the total input grade units
						SET @TIGUa = (@TIGUa + ISNULL(@IGUa, 0))
						PRINT 'TIGUa = ' + CAST(@TIGUa AS VARCHAR)
						
						SET @inputTonnesWithGrade = (@inputTonnesWithGrade + ISNULL(@weightometerTotalTonnes, 0))
					END
					
					FETCH NEXT FROM @InnerCur INTO @InputWeightometer
				END
					
				CLOSE @InnerCur		
				DEALLOCATE @InnerCur	
				
				DECLARE @interimWeightedAverageGrade FLOAT
				
				SET @interimWeightedAverageGrade = 0
				
				IF @inputTonnesWithGrade > 0
				BEGIN
					SET @interimWeightedAverageGrade = @TIGua / @inputTonnesWithGrade
				
					-- some tonnes may not have been assigned a grade... update the total as if these had the same grade as the weighted average of the other inputs
					IF @inputTonnesWithoutGrade > 0
					BEGIN
						SET @TIGua = @TIGua + (@interimWeightedAverageGrade * @inputTonnesWithoutGrade)
					END
				END
				
				-- Calculate the scaled input grade units
				SET @SIGUa = (@TIGua * @SF)
				
				PRINT 'SIGUa = ' + CAST(@SIGUa AS VARCHAR)
							
				-- Calculate the missing grade units
				SET @MGa = (@OGUa - @SIGUa)
				
				PRINT 'MGa = ' + CAST(@MGa AS VARCHAR)
				
				-- Calculate the Back-Calculated grade value
				SET @BCa = (CASE WHEN @WBC2ST = 0 THEN 0 ELSE @MGa / @WBC2ST END)
				
				PRINT 'BCa = ' + CAST(@BCa AS VARCHAR)
				
				-- Given that a back-calculated grade value could be determined
				IF @BCa IS NOT NULL
				BEGIN
					-- Insert the back-calculated grade value against WB-C2OutFlow-CorrectBCOnly 
					-- and WB-C2OutFlow-Corrected if there are no Crusher Actuals
					INSERT INTO dbo.WeightometerSampleGrade (Weightometer_Sample_Id, Grade_Id, Grade_Value)
					SELECT Weightometer_Sample_Id, @GradeId, @BCa
					FROM GetBhpbioWeightometerSampleWithProductSize(@iCalcDate, @HasProductSize) ws
					WHERE Weightometer_Sample_Date = @iCalcDate
						AND (Weightometer_Id = 'WB-C2OutFlow-CorrectedBCOnly' 
								OR (@CrusherActualsExist = 0 AND @iCalcDate >= @BCStartDate AND Weightometer_Id = 'WB-C2OutFlow-Corrected'))
						AND (@HasProductSize = 0 OR ws.Product_Size = @ProductSize)

				END
				
				FETCH NEXT FROM @Cur INTO @GradeId
				
			END
			
			CLOSE @Cur		
			DEALLOCATE @Cur		
			
			-- Create a BACK-CALCULATED GRADE sample note for WB-C2OutFlow-CorrectBCOnly 
			-- and WB-C2OutFlow-Corrected if there are no Crusher Actuals
			INSERT INTO dbo.WeightometerSampleNotes (Weightometer_Sample_Id, Weightometer_Sample_Field_Id, [Notes])
			SELECT Weightometer_Sample_Id, 'SampleSource', 'BACK-CALCULATED GRADES'
			FROM GetBhpbioWeightometerSampleWithProductSize(@iCalcDate, @HasProductSize) ws
			WHERE Weightometer_Sample_Date = @iCalcDate
				AND (Weightometer_Id = 'WB-C2OutFlow-CorrectedBCOnly' 
						OR (@CrusherActualsExist = 0 AND @iCalcDate >= @BCStartDate AND Weightometer_Id = 'WB-C2OutFlow-Corrected'))
				AND (@HasProductSize = 0 OR ws.Product_Size = @ProductSize)
				
			-- Given that a sample proportion was able to be determined
			IF @SP IS NOT NULL
			BEGIN
			
				-- For each sample on WB-C2OutFlow-CorrectedBCOnly (and WB-C2OutFlow-Corrected if no crusher actuals)
				-- add a sample tonnes value as a proportion of the total tonnes for the weightometer sample
				INSERT INTO dbo.WeightometerSampleValue (Weightometer_Sample_Id, Weightometer_Sample_Field_Id, Field_Value)
				SELECT Weightometer_Sample_Id, 'SampleTonnes', (@SP * Tonnes)
				FROM GetBhpbioWeightometerSampleWithProductSize(@iCalcDate, @HasProductSize) ws
				WHERE Weightometer_Sample_Date = @iCalcDate
					AND (Weightometer_Id = 'WB-C2OutFlow-CorrectedBCOnly' 
							OR (@CrusherActualsExist = 0 AND @iCalcDate >= @BCStartDate AND Weightometer_Id = 'WB-C2OutFlow-Corrected'))										
					AND (@HasProductSize = 0 OR ws.Product_Size = @ProductSize)
						
			END
		END
		ELSE
		BEGIN
			-- If there were insufficient samples found for the inputs and outputs
			-- and back-calculation should have occurred for WB-C2OutFlow-Corrected
			-- and WB-C2OutFlow had tonnes for the day (i.e. it was not shut down)
			IF @CrusherActualsExist = 0 
				AND @iCalcDate >= @BCStartDate 
				AND @WBC2TT >= @minimumSignificantTonnes 
				AND NOT (@InputTonnesExist = 0)
			BEGIN
			
				-- Get the number of days prior to the current date to in which data exceptions should not be raised
				SET @SettingValue = NULL
				DECLARE @DaysFromCurrentToExclude INT
				
				EXEC dbo.GetSystemSetting 
						@iSetting_Id = 'WEIGHTOMETER_MISSING_SAMPLE_IGNORE_MOST_RECENT_DAYS',
						@iValue = @SettingValue OUTPUT
				
				SET @DaysFromCurrentToExclude = CAST(COALESCE(@SettingValue, '0') AS INT)
		
				-- if the calculation date is before the exclusion period
				IF (@iCalcDate < DATEADD(DAY, @DaysFromCurrentToExclude * (-1), GETDATE()))
				BEGIN
					-- check if there is already a data exception for this date
					-- and retrieve the description and xml for comparison
					DECLARE @previouslyRaisedDetailsXML VARCHAR(Max)
					DECLARE @previouslyRaisedLongDescription VARCHAR(Max)
					
					SELECT TOP 1 @previouslyRaisedDetailsXML = convert(varchar(max), Details_XML), @previouslyRaisedLongDescription = Long_Description
						FROM dbo.DataException
						WHERE Data_Exception_Type_Id = @DataExceptionTypeId_InsufficientSamples
							AND Data_Exception_Date = @iCalcDate	
							AND Details_XML.value('(/DocumentElement/Insufficient_Sample_Information/TargetWeightometer_Id)[1]', 'nvarchar(31)') = 'WB-C2OutFlow-Corrected'
					
					-- build the new message
					DECLARE @currentDetailsXML VARCHAR(Max)
					DECLARE @currentLongDescription VARCHAR(Max)
					DECLARE @currentShortDescription VARCHAR(Max)
					
					DECLARE @DataExeceptionWeightometerList VARCHAR(MAX)
					
					IF (SELECT COUNT(*) FROM @InsufficientForBCWeightometers) > 0 
					BEGIN
						SELECT @DataExeceptionWeightometerList = COALESCE(@DataExeceptionWeightometerList + ', ', '') + Weightometer
						FROM @InsufficientForBCWeightometers
					END
					ELSE
					BEGIN
						IF @InputTonnesExist = 1 OR @TTO < @minimumSignificantTonnes
						BEGIN
							SELECT @DataExeceptionWeightometerList = COALESCE(@DataExeceptionWeightometerList + ', ', '') + Weightometer
							FROM @WeightometerOutputList
						END
						ELSE
						BEGIN
							SELECT @DataExeceptionWeightometerList = COALESCE(@DataExeceptionWeightometerList + ', ', '') + Weightometer
							FROM @WeightometerInputList	
						END											
					END
					
					SET @currentShortDescription = 'Insufficient sample information to back-calculate grades for WB-C2OutFlow-Corrected on ' + 
									CAST(DATENAME(DAY, @iCalcDate) AS VARCHAR) + '-' + CAST(DATENAME(MONTH, @iCalcDate) AS VARCHAR) + '-' + CAST(DATENAME(YEAR, @iCalcDate) AS VARCHAR)
					
					SET @currentLongDescription = 'Insufficient sample information exists for date ' +
									CAST(DATENAME(DAY, @iCalcDate) AS VARCHAR) + '-' + CAST(DATENAME(MONTH, @iCalcDate) AS VARCHAR) + '-' + CAST(DATENAME(YEAR, @iCalcDate) AS VARCHAR) +
										' to allow for the back-calculation of grades for WB-C2OutFlow-Corrected.' +
										(CASE WHEN (SELECT COUNT(*) FROM @InsufficientForBCWeightometers) > 0 
												THEN ' Sufficient sample information is missing for weightometers: ' + @DataExeceptionWeightometerList 
											  WHEN @TTO < @minimumSignificantTonnes
												THEN ' Output tonnes are less than the threshold required for output samples to be used.'
											  ELSE (CASE WHEN @InputTonnesExist = 1 THEN ' No data available for output weightometers.' ELSE ' No data available for input weightometers.' END)
										 END)
					
					SET @currentDetailsXML = '<DocumentElement><Insufficient_Sample_Information><SourceWeightometer_Ids>' + @DataExeceptionWeightometerList +
								 '</SourceWeightometer_Ids><TargetWeightometer_Id>WB-C2OutFlow-Corrected</TargetWeightometer_Id></Insufficient_Sample_Information></DocumentElement>'
					
					-- Only raise the message if there isn't an existing one that is exactly the same (this allows any dismissal to stay in place unless the message changes)
					IF (@previouslyRaisedLongDescription IS NULL)
						OR (@currentLongDescription <> @previouslyRaisedLongDescription OR @currentDetailsXML <> @previouslyRaisedDetailsXML)
					BEGIN
						-- clear the previous exception (if any); and
						-- raise the new exception
						DELETE FROM dbo.DataException
						WHERE Data_Exception_Type_Id = @DataExceptionTypeId_InsufficientSamples
							AND Data_Exception_Date = @iCalcDate		
							AND Details_XML.value('(/DocumentElement/Insufficient_Sample_Information/TargetWeightometer_Id)[1]', 'nvarchar(31)') = 'WB-C2OutFlow-Corrected'
						
						INSERT INTO dbo.DataException (Data_Exception_Type_Id, Data_Exception_Date, Data_Exception_Shift, 
							   Data_Exception_Status_Id, Short_Description, Long_Description, Details_XML)
						SELECT @DataExceptionTypeId_InsufficientSamples, @iCalcDate, 'D', 'A', @currentShortDescription, @currentLongDescription, @currentDetailsXML
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

GRANT EXECUTE ON dbo.CalcWhalebackVirtualFlowC2 TO BhpbioGenericManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.CalcWhalebackVirtualFlowC2">
 <Procedure>
	Updates the Whaleback Production Data for the crushers.
 </Procedure>
</TAG>
*/
