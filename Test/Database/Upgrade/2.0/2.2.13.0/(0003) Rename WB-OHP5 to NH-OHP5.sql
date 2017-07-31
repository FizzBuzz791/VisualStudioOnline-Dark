Declare @oldCrusherId varchar(64)
Declare @oldWeightometerId varchar(31)
Declare @CrusherId varchar(64)
Declare @WeightometerId varchar(31)

Set @oldCrusherId = 'WB-OHP5'
Set @oldWeightometerId = 'WB-OHP5Outflow'

DELETE FROM WeightometerLocation WHERE Weightometer_Id = @oldWeightometerId
DELETE FROM WeightometerFlowPeriod WHERE Weightometer_Id = @oldWeightometerId
DELETE FROM Weightometer WHERE Weightometer_Id = @oldWeightometerId

DELETE FROM CrusherLocation WHERE Crusher_Id = @oldCrusherId
DELETE FROM Crusher WHERE Crusher_Id = @oldCrusherId

Set @CrusherId = 'NH-OHP5'
Set @WeightometerId = 'NJV-OHP5Outflow'

-- add new crusher and crusher location records. Unlike OHP4 which is assigned to the NJV Hub, OHP5
-- is assigned to the site at newman
If Not Exists (Select 1 From Crusher Where Crusher_Id=@CrusherId)
Begin

	Insert Into Crusher (Crusher_Id, Description, Is_Visible)
		Select @CrusherId, 'NJV OHP 5', 1
		
	Insert Into CrusherLocation (Crusher_Id, Location_Type_Id, Location_Id)
		Select top(1) @CrusherId, Location_Type_Id, Location_Id From Location Where Name='Newman'

End

If Not Exists (Select Weightometer_Id From Weightometer Where Weightometer_Id = @WeightometerId)
Begin
	
	Insert Into Weightometer ([Weightometer_Id], [Description], [Is_Visible], [Weightometer_Type_Id], [Weightometer_Group_Id])
		Select @WeightometerId, 'NJV OHP5 Outflow', 1, 'CVF+L1', null
		
	Insert Into WeightometerLocation (Weightometer_Id, Location_Type_Id, Location_Id)
		Select top(1) @WeightometerId, Location_Type_Id, Location_Id From Location Where Name='Newman'
		
	Insert Into  WeightometerFlowPeriod (
		Weightometer_Id, End_Date, Source_Stockpile_Id, Source_Crusher_Id, 
		Source_Mill_Id, Destination_Stockpile_Id, Destination_Crusher_Id, Destination_Mill_Id, 
		Is_Calculated, Processing_Order_No
	)
		Select @WeightometerId, Null, Null, @CrusherId, Null, Null, Null, Null, 0, 35

End

