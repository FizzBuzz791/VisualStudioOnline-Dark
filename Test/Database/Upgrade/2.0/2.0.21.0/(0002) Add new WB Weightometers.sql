--
-- Add the new weightometers. Has to be WB-BeneFinesToSYard-Raw, not WB-BeneFinesToStockyard-Raw
-- because of limitations to the Weightometer_Id field
--

Insert Into Weightometer ([Weightometer_Id], [Description], [Is_Visible], [Weightometer_Type_Id], [Weightometer_Group_Id])
	Select 'WB-BeneFinesToSYard-Raw', '', 1, 'CVF', Null Union
	Select 'WB-BeneFinesToSYard-Corrected', '', 1, 'CVF', Null
	
Insert Into WeightometerLocation (Weightometer_Id, Location_Type_Id, Location_Id)
	Select 'WB-BeneFinesToSYard-Raw', 3, 9 Union
	Select 'WB-BeneFinesToSYard-Corrected', 3, 9
	
Insert Into  WeightometerFlowPeriod (
	Weightometer_Id, End_Date, Source_Stockpile_Id, Source_Crusher_Id, 
	Source_Mill_Id, Destination_Stockpile_Id, Destination_Crusher_Id, Destination_Mill_Id, 
	Is_Calculated, Processing_Order_No
)
	Select 'WB-BeneFinesToSYard-Raw', Null, Null, Null, 'WB-C3-EX', Null, Null, Null, 0, 8 Union
	Select 'WB-BeneFinesToSYard-Corrected', Null, Null, Null, 'WB-C3-EX', Null, Null, Null, 0, 8
