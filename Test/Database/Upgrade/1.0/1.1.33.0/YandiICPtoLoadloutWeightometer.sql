IF NOT EXISTS (SELECT * FROM Weightometer WHERE Weightometer_Id = 'YD-ICP_To_Stockpile')
BEGIN

	INSERT INTO dbo.Weightometer
	(
		Weightometer_Id, Description, Is_Visible, Weightometer_Type_Id, Weightometer_Group_Id
	)
	SELECT 'YD-ICP_To_Stockpile', 'YD-ICP Outflow to Loadout Stockpiles.', 1, 'CVF+L1', NULL

	-- set the Yandi (site) locations
	INSERT INTO dbo.WeightometerLocation
	(
		Weightometer_Id, Location_Type_Id, Location_Id
	)
	SELECT w.Weightometer_Id, lt.Location_Type_Id, l.Location_Id
	FROM dbo.LocationType AS lt
		INNER JOIN dbo.Location AS l
			ON (lt.Location_Type_Id = l.Location_Type_Id)
		CROSS JOIN
			(
				SELECT 'YD-ICP_To_Stockpile' As Weightometer_Id
			) AS w
	WHERE lt.Description = 'Site'
		AND l.Name = 'Yandi'
		
		
	INSERT INTO dbo.WeightometerFlowPeriod
	(
		Weightometer_Id, End_Date, Source_Stockpile_Id, Source_Crusher_Id, Source_Mill_Id,
		Destination_Stockpile_Id, Destination_Crusher_Id, Destination_Mill_Id, Is_Calculated, Processing_Order_No
	)
	SELECT 'YD-ICP_To_Stockpile', NULL, NULL, 'YD-ICP', NULL, NULL, NULL, NULL, 0, 15

END
GO