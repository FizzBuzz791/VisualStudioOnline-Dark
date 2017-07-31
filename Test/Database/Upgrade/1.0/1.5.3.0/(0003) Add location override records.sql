/*
		Add override records for crusher JB-C2
*/

INSERT	INTO dbo.BhpbioCrusherLocationOverride (Crusher_Id, Location_Type_Id, Location_Id, FromMonth, ToMonth)
SELECT	'JB-C2', 3, 10, '2012-10-01', '2050-12-31'
WHERE NOT EXISTS (SELECT 1 FROM dbo.BhpbioCrusherLocationOverride WHERE Crusher_Id = 'JB-C2')

INSERT	INTO dbo.BhpbioWeightometerLocationOverride (Weightometer_Id, Location_Type_Id, Location_Id, FromMonth, ToMonth)
SELECT	'JB-C2OutFlow', 3, 10, '2012-10-01', '2050-12-31'
WHERE NOT EXISTS (SELECT 1 FROM dbo.BhpbioWeightometerLocationOverride WHERE Weightometer_Id = 'JB-C2Outflow')

/* 
    Ensure existing default locations are correct
*/    

UPDATE crusherlocation
SET location_id = 12
WHERE crusher_id = 'JB-C2'

UPDATE weightometerlocation
SET location_id = 12
WHERE weightometer_id = 'JB-C2OutFlow'





