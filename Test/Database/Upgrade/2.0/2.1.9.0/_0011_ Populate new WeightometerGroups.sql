-- Add the new weightometer groups
INSERT INTO [WeightometerGroup] (Weightometer_Group_Id, [Description])
SELECT 'WBC2BackCalcWithPortActuals', 'Weightometers to include as inputs for WBC2 back calculations with expected Port Actuals' UNION
SELECT 'WBC2BackCalcWithCrusherActuals', 'Weightometers to include as inputs for WBC2 back calculations with expected Crusher Actuals' UNION
SELECT 'WBC2BackCalcWOutSampleActuals', 'Weightometers to include as inputs for WBC2 back calculations with no expected sample actuals'

GO

-- Associates weightometers to the new weightometer groups to define the input weightometers for WBC2 back calculations
INSERT INTO [BhpbioWeightometerGroupWeightometer] (Weightometer_Group_Id, Weightometer_Id, [Start_Date], [End_Date])
SELECT 'WBC2BackCalcWithPortActuals', '18-PostCrusherToTrainRake', '2009-04-01', NULL UNION
SELECT 'WBC2BackCalcWithPortActuals', '25-PostC2ToTrainRake', '2009-04-01', NULL UNION
SELECT 'WBC2BackCalcWOutSampleActuals', 'WB-M232-Corrected', '2009-04-01', NULL

GO

