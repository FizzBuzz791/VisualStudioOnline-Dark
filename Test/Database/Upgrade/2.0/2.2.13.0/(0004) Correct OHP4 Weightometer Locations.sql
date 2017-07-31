IF NOT EXISTS (SELECT * FROM WeightometerLocation WHERE Weightometer_ID like 'NJV-OHP4%')
BEGIN
	Insert Into WeightometerLocation ([Weightometer_Id], Location_Type_Id, [Location_Id])
			Select 'NJV-OHP4OutflowRaw', 2, 8 Union All
			Select 'NJV-OHP4OutflowCorrected', 2, 8
END