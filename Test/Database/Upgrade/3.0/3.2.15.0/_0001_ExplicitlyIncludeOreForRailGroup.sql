IF NOT EXISTS (SELECT * FROM WeightometerGroup WHERE Weightometer_Group_Id = 'ExplicitlyIncludeInOreForRail')
BEGIN
	INSERT INTO WeightometerGroup(Weightometer_Group_Id, [Description])
	VALUES ('ExplicitlyIncludeInOreForRail','Explicitly include')

	INSERT INTO BhpbioWeightometerGroupWeightometer(Weightometer_Group_Id, Weightometer_Id, [Start_Date], End_Date)
	VALUES('ExplicitlyIncludeInOreForRail', '25-PostCrusherToTrainRake', '2009-04-01', null)
END