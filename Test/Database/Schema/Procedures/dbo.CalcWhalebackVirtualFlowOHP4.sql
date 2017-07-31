IF OBJECT_ID('dbo.CalcWhalebackVirtualFlowOHP4') IS NOT NULL
	DROP PROCEDURE dbo.CalcWhalebackVirtualFlowOHP4
GO 

CREATE PROCEDURE [dbo].[CalcWhalebackVirtualFlowOHP4]
(
	@iCalcDate DATETIME
)
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 
	
	
	-- We shouldn't process anything in this proc unless it is past the end_date for the old outflow
	-- weightometer. Since there is no start_date field on the WeightometerFlowPeriod table, we use this
	-- date as a signal that we should start processing the new weightometers
	If @iCalcDate <= (Select End_Date From WeightometerFlowPeriod Where Weightometer_Id = 'NJV-OHPOutflow')
	Begin
		Return
	End
	
	SELECT @TransactionName = 'CalcWhalebackVirtualFlowOHP4',
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

		Declare @OHP4Raw_Weightometer_Id Varchar(64)
		Declare @OHP4Corrected_Weightometer_Id Varchar(64)
		Declare @OHP5_Weightometer_Id Varchar(64)

		Set @OHP4Raw_Weightometer_Id = 'NJV-OHP4OutflowRaw'
		Set @OHP4Corrected_Weightometer_Id = 'NJV-OHP4OutflowCorrected'
		Set @OHP5_Weightometer_Id = 'NJV-OHP5Outflow'

		-- some variables to allow looping through a list of sample_ids. As long as there are not
		-- too many records, this method is generally easier and less error prone than using a cursor.
		Declare @CurrentRow Int
		Declare @CurrentSampleId Int
		Declare @WeightometerSamples Table (
			Row_Id Int Null,
			Weightometer_Sample_Id Int
		)

		---- Delete all the existing corrected samples for the current date, so that we don't end up with duplicates		
		Insert Into @WeightometerSamples (Weightometer_Sample_Id)
			Select Weightometer_Sample_Id From WeightometerSample 
			Where Weightometer_Id = @OHP4Corrected_Weightometer_Id
				And Weightometer_Sample_Date = @iCalcDate
				
		Delete From dbo.WeightometerSampleGrade Where Weightometer_Sample_Id In (Select Weightometer_Sample_Id From @WeightometerSamples)
		Delete From dbo.WeightometerSampleNotes Where Weightometer_Sample_Id In (Select Weightometer_Sample_Id From @WeightometerSamples)
		Delete From dbo.WeightometerSampleValue Where Weightometer_Sample_Id In (Select Weightometer_Sample_Id From @WeightometerSamples)
		Delete From dbo.WeightometerSample Where Weightometer_Sample_Id In (Select Weightometer_Sample_Id From @WeightometerSamples)

		--
		-- copy lump from OutflowRaw to OutflowCorrected
		--
		-- first get a list of sample ids to copy to the new weightometer
		Delete From @WeightometerSamples
		Insert Into @WeightometerSamples (Weightometer_Sample_Id)
			Select
				ws.Weightometer_Sample_Id
			From WeightometerSample ws
				inner join WeightometerSampleNotes wsn 
					On wsn.Notes = 'LUMP' 
					And wsn.Weightometer_Sample_Field_Id = 'ProductSize'
					And wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
			Where Weightometer_Id = @OHP4Raw_Weightometer_Id
				And Weightometer_Sample_Date = @iCalcDate

		-- we also want to copy the FINES ESTIMATE samples over, as these do not get included
		-- in the back calculation. These are not strictly required, but might as well bring them 
		-- over as well, for completeness
		Insert Into @WeightometerSamples (Weightometer_Sample_Id)
			Select
				ws.Weightometer_Sample_Id
			From WeightometerSample ws
				Inner join WeightometerSampleNotes wsn 
					On wsn.Notes = 'FINES' 
					And wsn.Weightometer_Sample_Field_Id = 'ProductSize'
					And wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
				Inner Join WeightometerSampleNotes ss
					On ss.Notes = 'ESTIMATE' 
					And ss.Weightometer_Sample_Field_Id = 'SampleSource'
					And ss.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
			Where Weightometer_Id = @OHP4Raw_Weightometer_Id
				And Weightometer_Sample_Date = @iCalcDate
		

		-- now we copy the samples one by one. It would be nice to do this in a bulk way, but the
		-- structure of the tables doesn't really allow it.
		DECLARE loop_cursor CURSOR FOR SELECT Weightometer_Sample_Id FROM @WeightometerSamples; 
		OPEN loop_cursor
		FETCH NEXT FROM loop_cursor INTO @CurrentSampleId
		While @@FETCH_STATUS = 0
		Begin

			exec [dbo].[BhpbioCopyWeightometerSample] 
				@iDest_Weightometer_Id = @OHP4Corrected_Weightometer_Id, 
				@iSource_Weightometer_Sample_Id = @CurrentSampleId

			FETCH NEXT FROM loop_cursor INTO @CurrentSampleId
		End
		
		CLOSE loop_cursor
		DEALLOCATE loop_cursor

		-- calculate the corrected fines values from the ohp4 raw and ohp5 values
		-- the tonnes are already correct, so we just need to copy these over, and
		-- adjust the grades
		--
		-- Note that the grades only get adjusted for crusher actual samples
		
		Declare @TotalOutflowTonnes float

		Declare @OHP5WeightometerSamples Table (
			Weightometer_Sample_Id Int
		)
	
		Declare @OHP4CorrectedGrades Table (
			Grade_Id Int,
			Grade_Value real
		)
		
		-- first we get the list of samples for that shift for both the OHP4-Raw and
		-- OHP5. Note that we are only worried about FINES and CRUSHER ACUTAL samples.
		--
		-- The other sample types are dealt with elsewhere
		Delete From @WeightometerSamples
		Insert Into @WeightometerSamples (Row_Id, Weightometer_Sample_Id)
			Select
				Row_Number() Over (Order by ws.Weightometer_Sample_Id),
				ws.Weightometer_Sample_Id
			From WeightometerSample ws
				Inner join WeightometerSampleNotes wsn 
					On wsn.Notes = 'FINES' 
					And wsn.Weightometer_Sample_Field_Id = 'ProductSize'
					And wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
				Inner Join WeightometerSampleNotes ss
					On ss.Notes = 'CRUSHER ACTUALS' 
					And ss.Weightometer_Sample_Field_Id = 'SampleSource'
					And ss.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
			Where Weightometer_Id = @OHP4Raw_Weightometer_Id
				And Weightometer_Sample_Date = @iCalcDate

		Insert Into @OHP5WeightometerSamples (Weightometer_Sample_Id)
			Select 
				ws.Weightometer_Sample_Id
			From WeightometerSample ws
				Inner join WeightometerSampleNotes wsn 
					On wsn.Notes = 'FINES' 
					And wsn.Weightometer_Sample_Field_Id = 'ProductSize'
					And wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
				Inner Join WeightometerSampleNotes ss
					On ss.Notes = 'CRUSHER ACTUALS' 
					And ss.Weightometer_Sample_Field_Id = 'SampleSource'
					And ss.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
			Where ws.Weightometer_Id = @OHP5_Weightometer_Id
				And ws.Weightometer_Sample_Date = @iCalcDate
		
		-- We need to calculate the total outflow tonnes separately, because it doesn't correspond with the grades
		-- given in the OHP4-Raw weightometer
		Select @TotalOutflowTonnes = Sum(Tonnes) 
		From WeightometerSample
		Where Weightometer_Sample_Id in (Select Weightometer_Sample_Id From @WeightometerSamples)
			Or Weightometer_Sample_Id in (Select Weightometer_Sample_Id From @OHP5WeightometerSamples)

		-- Now we have all the OHP4 & OHP5 samples, as well as the total outflow tonnes, we can back-calculate the
		-- grades for the shift. We will insert these grades later against every corrected sample.
		Insert Into @OHP4CorrectedGrades
			Select 			
				Grade_Id,
				Sum(COALESCE(Grade_Value, 0) * Tonnes) / Sum(Tonnes) as Grade_Value
			From (
				-- OHP4-Raw Samples
				Select 
					@TotalOutflowTonnes as Tonnes,
					wsg.Grade_Id,
					Sum(wsg.Grade_Value * ws.Tonnes) / Sum(ws.Tonnes) as Grade_Value
				From WeightometerSample ws
					Inner Join dbo.WeightometerSampleGrade wsg 
						On wsg.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
					Inner Join dbo.WeightometerSampleValue st 
						On st.Weightometer_Sample_Id = ws.Weightometer_Sample_Id 
							and st.Weightometer_Sample_Field_Id = 'SampleTonnes'  -- only include movements with sample tonnes (even though real tonnes are used for weighting) 
				Where ws.Weightometer_Sample_Id in (Select Weightometer_Sample_Id  From @WeightometerSamples)
				Group By Grade_Id
				
				Union All
				
				-- OHP5 Samples
				Select 
					Sum(ws.Tonnes) * -1 as Tonnes,
					wsg.Grade_Id,
					Sum(wsg.Grade_Value * ws.Tonnes) / Sum(ws.Tonnes) as Grade_Value
				From WeightometerSample ws
					Inner Join dbo.WeightometerSampleGrade wsg 
						On wsg.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
					Inner Join dbo.WeightometerSampleValue st 
						On st.Weightometer_Sample_Id = ws.Weightometer_Sample_Id 
							and st.Weightometer_Sample_Field_Id = 'SampleTonnes' -- only include movements with sample tonnes (even though real tonnes are used for weighting) 
				Where ws.Weightometer_Sample_Id in (Select Weightometer_Sample_Id  From @OHP5WeightometerSamples)
				Group By wsg.Grade_Id
			) sg
			Group By Grade_Id
		
		-- loop through each of the source fines samples. We can copy the tonnes over like before, but we need
		-- to do some strange calculations in order to get the grades correctly calculated
		Set @CurrentRow = 1
		While @CurrentSampleId Is Not Null Or @CurrentRow = 1
		Begin
			
			Set @CurrentSampleId = Null
			Select 
				@CurrentSampleId = Weightometer_Sample_Id
			From @WeightometerSamples
			Where Row_Id = @CurrentRow
			
			If @CurrentSampleId Is Null Break

			Declare @OHP4RawSampleId Int
			Declare @OHP4CorrectedSampleId Int
			
			Set @OHP4CorrectedSampleId = Null
			Set @OHP4RawSampleId = @CurrentSampleId

			-- only the fines tonnes can be copied over - the grades have to be 
			-- calculated manually later
			exec [dbo].[BhpbioCopyWeightometerSample] 
				@iDest_Weightometer_Id = @OHP4Corrected_Weightometer_Id, 
				@iSource_Weightometer_Sample_Id = @OHP4RawSampleId,
				@iNo_Grades = 1,
				@oDest_Weightometer_Sample_Id = @OHP4CorrectedSampleId Output
			
			-- update the sample source, since it is a back calculated grade now
			-- *not* a crusher actual
			Update WeightometerSampleNotes 
			Set Notes = 'BACK-CALCULATED GRADES'
			Where Weightometer_Sample_Field_Id = 'SampleSource'
				And Weightometer_Sample_Id = @OHP4CorrectedSampleId
			
			-- Insert the previously calculated grades for the current sample
			Insert Into WeightometerSampleGrade(Weightometer_Sample_Id, Grade_Id, Grade_Value)
				Select @OHP4CorrectedSampleId, Grade_Id, Grade_Value From @OHP4CorrectedGrades
		
			Set @CurrentRow = @CurrentRow + 1
		End

											
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

GRANT EXECUTE ON dbo.CalcWhalebackVirtualFlowOHP4 TO BhpbioGenericManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.CalcWhalebackVirtualFlowC2">
 <Procedure>
	Updates the Whaleback Production Data for the crushers.
 </Procedure>
</TAG>
*/
