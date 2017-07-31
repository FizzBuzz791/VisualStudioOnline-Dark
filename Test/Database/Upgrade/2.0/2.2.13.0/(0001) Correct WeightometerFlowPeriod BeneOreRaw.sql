-- Correct the WB-BeneOreRaw WeightometerFlowPeriod record by specifying the destination Stockpile
-- this is neccessary to allow the WB-BeneFinesToSYard-Raw weightometer to be selected for other movements from WB-C3-EX
-- NOTE: It is safe to re-run this script as it only changes the WB-BeneOreRaw record where the destination stockpile is not yet set...

UPDATE WeightometerFlowPeriod
	SET Destination_Stockpile_Id = (SELECT Stockpile_Id FROM Stockpile WHERE Stockpile_Name = 'NH-COS')
WHERE Weightometer_Id = 'WB-BeneOreRaw'
	AND Destination_Stockpile_Id IS NULL
