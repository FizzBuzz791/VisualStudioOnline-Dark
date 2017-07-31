-- Crusher enhancements (Mar 2013)
Insert Into dbo.Crusher (Crusher_Id, Description)
Select 'YR-CT', 'Yarrie CT Crusher' Union All
Select 'AC-C3', 'AreaC Crusher 3'

Insert Into dbo.Weightometer (Weightometer_Id, Description, Is_Visible, Weightometer_Type_Id, Weightometer_Group_Id)
Select 'YR-CTOutFlow', 'YR-CT Outflow to Stockpile', 1, 'CVF+L1', NULL Union All
Select 'AC-C3OutFlow', 'AC-C3 Outflow to Stockpile', 1, 'CVF+L1', NULL

Insert Into dbo.WeightometerLocation (Weightometer_Id, Location_Type_Id, Location_Id)
Select 'YR-CTOutFlow', 3, 5 Union All
Select 'AC-C3OutFlow', 3, 7

Insert Into dbo.WeightometerFlowPeriod (Weightometer_Id, End_Date, Source_Stockpile_Id, Source_Crusher_Id, Source_Mill_Id, Destination_Stockpile_Id, Destination_Crusher_Id, Destination_Mill_Id, Is_Calculated, Processing_Order_No)
Select 'YR-CTOutFlow', NULL, NULL, 'YR-CT', NULL, NULL, NULL, NULL, 0, 31 Union All
Select 'AC-C3OutFlow', NULL, NULL, 'AC-C3', NULL, NULL, NULL, NULL, 0, 32

INSERT INTO CrusherLocation (Crusher_Id, Location_Type_Id, Location_Id)
 SELECT 'YR-CT', 3, 5

INSERT INTO CrusherLocation (Crusher_Id, Location_Type_Id, Location_Id)
 SELECT 'AC-C3', 3, 7