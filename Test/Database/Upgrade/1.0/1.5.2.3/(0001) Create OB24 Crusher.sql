/*
		Create Crusher C2 at OB24 (OB23/25 Eastern Ridge)
*/

INSERT	INTO dbo.Crusher (Crusher_Id, Description)
SELECT	'25-C2', 'Orebody 24 Crusher'
WHERE NOT EXISTS (SELECT 1 FROM dbo.Crusher WHERE Crusher_Id='25-C2')

INSERT	INTO dbo.Weightometer (Weightometer_Id, Description, Is_Visible, Weightometer_Type_Id, Weightometer_Group_Id)
SELECT	'25-C2OutFlow', '25-C2 Outflow to Stockpile', 1, 'CVF+L1', NULL
WHERE NOT EXISTS (SELECT 1 FROM dbo.Weightometer WHERE Weightometer_Id='25-C2OutFlow')

INSERT	INTO dbo.WeightometerLocation (Weightometer_Id, Location_Type_Id, Location_Id)
SELECT	'25-C2OutFlow', 3, 11
WHERE NOT EXISTS (SELECT 1 FROM dbo.WeightometerLocation WHERE Weightometer_Id='25-C2OutFlow')

INSERT	INTO dbo.WeightometerFlowPeriod (Weightometer_Id, End_Date, Source_Stockpile_Id, Source_Crusher_Id, Source_Mill_Id, Destination_Stockpile_Id, Destination_Crusher_Id, Destination_Mill_Id, Is_Calculated, Processing_Order_No)
SELECT	'25-C2OutFlow', NULL, NULL, '25-C2', NULL, NULL, NULL, NULL, 0, (SELECT MAX(Processing_Order_No)+1 FROM	dbo.WeightometerFlowPeriod)
WHERE NOT EXISTS (SELECT 1 FROM dbo.WeightometerFlowPeriod WHERE Weightometer_Id='25-C2OutFlow' AND Source_Crusher_Id='25-C2')

INSERT INTO CrusherLocation (Crusher_Id, Location_Type_Id, Location_Id)
SELECT '25-C2', 3, 11
WHERE NOT EXISTS (SELECT 1 FROM dbo.CrusherLocation WHERE Crusher_Id='25-C2')

