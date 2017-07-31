
Declare @CutoverDate datetime
Set @CutoverDate = '2014-05-30'

If Not Exists (Select Weightometer_Id From Weightometer Where Weightometer_Id = 'NJV-OHP4OutflowRaw')
Begin

	Insert Into Weightometer ([Weightometer_Id], [Description], [Is_Visible], [Weightometer_Type_Id], [Weightometer_Group_Id])
		Select 'NJV-OHP4OutflowRaw', 'NJV Hub OHP4 Raw OutFlow', 1, 'CVF+L1', null Union All
		Select 'NJV-OHP4OutflowCorrected', 'NJV-NJV Hub OHP4 Corrected OutFlow', 1, 'L1', null

	Insert Into  WeightometerFlowPeriod (
		Weightometer_Id, End_Date, Source_Stockpile_Id, Source_Crusher_Id, 
		Source_Mill_Id, Destination_Stockpile_Id, Destination_Crusher_Id, Destination_Mill_Id, 
		Is_Calculated, Processing_Order_No
	)
		Select 'NJV-OHP4OutflowRaw', Null, Null, 'NH-OHP4', Null, Null, Null, Null, 0, 4 Union All
		Select 'NJV-OHP4OutflowCorrected', Null, Null, 'NH-OHP4', Null, Null, Null, Null, 0, 4
		

	Update WeightometerFlowPeriod Set End_Date = @CutoverDate Where Weightometer_Id = 'NJV-OHPOutflow'
End

