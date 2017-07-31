-- Crusher enhancements (May 2012)
Insert Into dbo.Crusher (Crusher_Id, Description)
Select 'YR-CND', 'Yarrie Cundaline Crusher' Union All
Select 'YR-CG', 'Yarrie Cattle Gorge Crusher'

Insert Into dbo.Weightometer (Weightometer_Id, Description, Is_Visible, Weightometer_Type_Id, Weightometer_Group_Id)
Select 'YR-CNDOutFlow', 'YR-CND Outflow to Stockpile', 1, 'CVF+L1', NULL Union All
Select 'YR-CGOutFlow', 'YR-CG Outflow to Stockpile', 1, 'CVF+L1', NULL

Insert Into dbo.WeightometerLocation (Weightometer_Id, Location_Type_Id, Location_Id)
Select 'YR-CNDOutFlow', 3, 5 Union All
Select 'YR-CGOutFlow', 3, 5

Insert Into dbo.WeightometerFlowPeriod (Weightometer_Id, End_Date, Source_Stockpile_Id, Source_Crusher_Id, Source_Mill_Id, Destination_Stockpile_Id, Destination_Crusher_Id, Destination_Mill_Id, Is_Calculated, Processing_Order_No)
Select 'YR-CNDOutFlow', NULL, NULL, 'YR-CND', NULL, NULL, NULL, NULL, 0, 28 Union All
Select 'YR-CGOutFlow', NULL, NULL, 'YR-CG', NULL, NULL, NULL, NULL, 0, 29

INSERT INTO CrusherLocation (Crusher_Id, Location_Type_Id, Location_Id)
 SELECT 'YR-CND', 3, 5

INSERT INTO CrusherLocation (Crusher_Id, Location_Type_Id, Location_Id)
 SELECT 'YR-CG', 3, 5