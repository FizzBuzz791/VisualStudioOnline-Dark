/*
* This script is intended to clear erroneous WeightometerSampleNote ProductSize data 
*/
DELETE 
FROM WeightometerSampleNotes 
WHERE Weightometer_Sample_Field_Id = 'ProductSize' 
AND (Notes = 'ROM' or Notes = 'TOTAL')