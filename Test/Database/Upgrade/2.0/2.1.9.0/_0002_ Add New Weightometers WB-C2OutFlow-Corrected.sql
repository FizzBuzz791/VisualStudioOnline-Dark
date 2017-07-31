
INSERT INTO [Weightometer] ([Weightometer_Id], [Description], [Is_Visible], [Weightometer_Type_Id])
VALUES ('WB-C2OutFlow-Corrected', 'WB-C2 outflow with back-calculated grades where neeeded', 1, 'L1')

INSERT INTO [WeightometerFlowPeriod] ([Weightometer_Id], [Source_Crusher_Id], [Is_Calculated], [Processing_Order_No])
SELECT 'WB-C2OutFlow-Corrected', 'WB-C2', 1, MAX([Processing_Order_No]) + 1
FROM [WeightometerFlowPeriod]

INSERT INTO [WeightometerLocation] ([Weightometer_Id], [Location_Type_Id], [Location_Id])
SELECT 'WB-C2OutFlow-Corrected', [Location_Type_Id], [Location_Id]
FROM [WeightometerLocation] 
WHERE [Weightometer_Id] = 'WB-C2OutFlow'

INSERT INTO [Weightometer] ([Weightometer_Id], [Description], [Is_Visible], [Weightometer_Type_Id])
VALUES ('WB-C2OutFlow-CorrectedBCOnly', 'WB-C2 outflow with back-calculated grades for comparison', 1, 'NULL')

INSERT INTO [WeightometerLocation] ([Weightometer_Id], [Location_Type_Id], [Location_Id])
SELECT 'WB-C2OutFlow-CorrectedBCOnly', [Location_Type_Id], [Location_Id]
FROM [WeightometerLocation] 
WHERE [Weightometer_Id] = 'WB-C2OutFlow'
