If Object_Id('dbo.GetBhpbioWeightometerSampleWithProductSize') Is Not Null
	Drop Function dbo.GetBhpbioWeightometerSampleWithProductSize
Go
--
-- Returns a the list of weightometer samples appropriately broken down by lump/fines
-- If the sample doesn't have any product size information, then the default split will
-- be applied
--
Create Function dbo.GetBhpbioWeightometerSampleWithProductSize
(
	@SampleDate DateTime,
	@ApplyDefaultSplit Bit = 1
)
Returns @WeightometerSamples Table
(
	Weightometer_Sample_Id INT NOT NULL,
	Weightometer_Id VARCHAR(31) NOT NULL,
	Weightometer_Sample_Date DATETIME NOT NULL,
	Weightometer_Sample_Shift CHAR(1) NULL,
	Order_No INT NULL,
	Source_Stockpile_Id INT NULL,
	Source_Build_Id INT NULL,
	Source_Component_Id INT NULL,
	Destination_Stockpile_Id INT NULL,
	Destination_Build_Id INT NULL,
	Destination_Component_Id INT NULL,
	
	Default_LF BIT NULL,
	Product_Size VARCHAR(15) NULL,
	Product_Percent Float Null,
	
	Sample_Tonnes Float NULL,
	Tonnes Float NULL,
	Corrected_Tonnes Float NULL
)
As
Begin
	
	Insert Into @WeightometerSamples
		Select 
			ws.Weightometer_Sample_Id,
			ws.Weightometer_Id,
			Weightometer_Sample_Date,
			Weightometer_Sample_Shift,
			Order_No,
			Source_Stockpile_Id,
			Source_Build_Id,
			Source_Component_Id,
			Destination_Stockpile_Id,
			Destination_Build_Id,
			Destination_Component_Id,

			Case When dlf.ProductSize is Not Null Then 1 Else 0 End as Default_LF,
			Coalesce(ps.Notes, dlf.ProductSize) As Product_Size,
			dlf.[Percent] As Product_Percent,

			Coalesce(dlf.[Percent], 1) * st.Field_Value as SampleTonnes,
			Coalesce(dlf.[Percent], 1) * Tonnes,
			Coalesce(dlf.[Percent], 1) * Corrected_Tonnes
		From WeightometerSample ws
			Inner Join WeightometerLocation wl 
				On wl.Weightometer_Id = ws.Weightometer_Id
			Left Join dbo.WeightometerSampleValue st 
				on st.Weightometer_Sample_Id = ws.Weightometer_Sample_Id 
				and st.Weightometer_Sample_Field_Id = 'SampleTonnes'
			Left Join dbo.WeightometerSampleNotes ps 
				On ps.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
				And ps.Weightometer_Sample_Field_Id = 'ProductSize'
			Left Join  dbo.GetBhpbioDefaultLumpFinesRatios(Null, Null, Null) dlf
				On dlf.LocationId = wl.Location_Id
				And ws.Weightometer_Sample_Date Between dlf.StartDate And dlf.EndDate
				And ps.Notes Is Null
				And @ApplyDefaultSplit = 1
		Where Weightometer_Sample_Date = @SampleDate
	
	Return
End