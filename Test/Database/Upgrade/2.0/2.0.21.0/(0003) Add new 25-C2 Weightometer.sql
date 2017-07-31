
-- Create a new weightometer to store the C2 to Train rake measurements
-- this will be used later to give a more accurate Actual-C calculation
Declare @NewWeightometerId varchar(31)
Set @NewWeightometerId = '25-PostC2ToTrainRake'

If Not Exists (Select Weightometer_Id From Weightometer Where Weightometer_Id = @NewWeightometerId)
Begin

	-- we need a new group for the C2 weightometer so that it gets treated specially when
	-- selecting the SampleSource type
	Insert Into WeightometerGroup ([Weightometer_Group_Id], [Description])
		Select 'AlwaysIncludeAsSampleSource', 'Always use this Weightometer when getting the Weightometer Sample Source'
		
	Insert Into Weightometer ([Weightometer_Id], [Description], [Is_Visible], [Weightometer_Type_Id], [Weightometer_Group_Id])
		Select @NewWeightometerId, 'Orebody 23/25 Post Crusher 2 to Train Rake.', 1, 'CVF+L1', 'AlwaysIncludeAsSampleSource'
		
	Insert Into WeightometerLocation (Weightometer_Id, Location_Type_Id, Location_Id)
		Select @NewWeightometerId, 3, 11
		
	Insert Into  WeightometerFlowPeriod (
		Weightometer_Id, End_Date, Source_Stockpile_Id, Source_Crusher_Id, 
		Source_Mill_Id, Destination_Stockpile_Id, Destination_Crusher_Id, Destination_Mill_Id, 
		Is_Calculated, Processing_Order_No
	)
		Select @NewWeightometerId, Null, 16821, Null, Null, Null, Null, Null, 0, 34

End

-- Update the historical records to move the data to the new weightometer. Basically we
-- want to split off all the movements from the C2 post crusher stockpile to the trainrake
-- into the new weightometer.
Update WeightometerSample
	Set Weightometer_Id = @NewWeightometerId
Where 
	Weightometer_Id = '25-PostCrusherToTrainRake' And
	Source_Stockpile_Id = 16821
	