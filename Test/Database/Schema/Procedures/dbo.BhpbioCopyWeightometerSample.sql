IF OBJECT_ID('dbo.BhpbioCopyWeightometerSample') IS NOT NULL
	DROP PROCEDURE dbo.BhpbioCopyWeightometerSample
GO 

CREATE PROCEDURE [dbo].[BhpbioCopyWeightometerSample]
(
	@iDest_Weightometer_Id Varchar(64),
	@iSource_Weightometer_Sample_Id Int,
	@iNo_Grades Bit = 0, -- if true, no grade records get inserted
	@oDest_Weightometer_Sample_id int = Null Output
)
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 
	
	SELECT @TransactionName = 'BhpbioCopyWeightometerSample',
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

		Declare @Dest_Weightometer_Sample_Id Int

		-- Insert the new WeightometerSample record, then get the Id
		-- of the new sample
		Insert Into dbo.WeightometerSample (Weightometer_Id, Weightometer_Sample_Date, Weightometer_Sample_Shift, Order_No, Source_Stockpile_Id, Source_Build_Id, Source_Component_Id,
			Destination_Stockpile_Id, Destination_Build_Id, Destination_Component_Id, Tonnes, Corrected_Tonnes)
			Select
				@iDest_Weightometer_Id As Weightometer_Id,
				Weightometer_Sample_Date,
				Weightometer_Sample_Shift,
				Order_No,
				Source_Stockpile_Id,
				Source_Build_Id,
				Source_Component_Id,
				Destination_Stockpile_Id,
				Destination_Build_Id,
				Destination_Component_Id,
				Tonnes,
				Corrected_Tonnes
			From WeightometerSample ws
			Where Weightometer_Sample_Id = @iSource_Weightometer_Sample_Id

		Set @Dest_Weightometer_Sample_Id = SCOPE_IDENTITY()

		-- Copy WeightometerSampleNotes
		Insert Into dbo.WeightometerSampleNotes (Weightometer_Sample_Id, Weightometer_Sample_Field_Id, Notes)
			Select 
				 @Dest_Weightometer_Sample_Id As Weightometer_Sample_Id,
				 Weightometer_Sample_Field_Id,
				 Notes
			From dbo.WeightometerSampleNotes
			Where Weightometer_Sample_Id = @iSource_Weightometer_Sample_Id

		-- Copy WeightometerSampleValue
		Insert Into dbo.WeightometerSampleValue (Weightometer_Sample_Id, Weightometer_Sample_Field_Id, Field_Value)
			Select 
				 @Dest_Weightometer_Sample_Id As Weightometer_Sample_Id,
				 Weightometer_Sample_Field_Id,
				 Field_Value
			From dbo.WeightometerSampleValue
			Where Weightometer_Sample_Id = @iSource_Weightometer_Sample_Id

		-- WeightometerSampleGrade
		If @iNo_Grades = 0
		Begin
		
			Insert Into dbo.WeightometerSampleGrade (Weightometer_Sample_Id, Grade_Id, Grade_Value)
				Select 
					@Dest_Weightometer_Sample_Id As Weightometer_Sample_Id,
					Grade_Id,
					Grade_Value
				From dbo.WeightometerSampleGrade
				Where Weightometer_Sample_Id = @iSource_Weightometer_Sample_Id
				
		End

		-- return the new Sample Id to the caller in case they need it
		Set @oDest_Weightometer_Sample_Id = @Dest_Weightometer_Sample_Id
																
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

GRANT EXECUTE ON dbo.BhpbioCopyWeightometerSample TO BhpbioGenericManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.CalcWhalebackVirtualFlowC2">
 <Procedure>
	Updates the Whaleback Production Data for the crushers.
 </Procedure>
</TAG>
*/
