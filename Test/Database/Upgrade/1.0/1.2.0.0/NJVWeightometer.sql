
INSERT INTO dbo.Weightometer
(
	Weightometer_Id, Description, Is_Visible, Weightometer_Type_Id, Weightometer_Group_Id
)
SELECT 'NJV-OHPOutflow', 'NJV Hub OHP OutFlow.', 1, 'CVF+L1', NULL
UNION ALL SELECT 'NJV-ShuttleTrainRakeToCOS', 'Shuttle Rake to NJV COS Stockpile', 1, 'CVF+L1', NULL
UNION ALL SELECT 'NJV-COSToOHP', 'NJV Hub COS Stockpile to OHP Crusher', 1, 'CVF+L1', NULL
UNION ALL SELECT 'NJV-PostCrusherToPostCrusher', 'NJV Hub Stockyard Movements', 1, 'CVF+L1', NULL
UNION ALL SELECT 'NJV-PostCrusherToTrainRake', 'NJV Hub Stockyard to Train Rake', 1, 'CVF+L1', NULL

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
			SELECT 'NJV-OHPOutflow' AS Weightometer_Id
			UNION ALL
			SELECT 'NJV-ShuttleTrainRakeToCOS'
			UNION ALL
			SELECT 'NJV-COSToOHP'
			UNION ALL
			SELECT 'NJV-PostCrusherToPostCrusher'
			UNION ALL
			SELECT 'NJV-PostCrusherToTrainRake'
		) AS w
WHERE lt.Description = 'Hub'
	AND l.Name = 'NJV'
	
INSERT INTO dbo.WeightometerFlowPeriod
(
	Weightometer_Id, End_Date, Source_Stockpile_Id, Source_Crusher_Id, Source_Mill_Id,
	Destination_Stockpile_Id, Destination_Crusher_Id, Destination_Mill_Id, Is_Calculated, Processing_Order_No
)
SELECT 'NJV-OHPOutflow', NULL, NULL, 'NH-OHP4', NULL, NULL, NULL, NULL, 0, 3
UNION ALL SELECT 'NJV-COSToOHP', NULL, NULL, NULL, NULL, NULL, 'NH-OHP4', NULL, 0, 2
UNION ALL SELECT 'NJV-ShuttleTrainRakeToCOS', NULL, (SELECT TOP 1 Stockpile_Id FROM Stockpile WHERE Stockpile_Name = 'NJV Hub Feed Train Rake'), NULL, NULL, NULL, NULL, NULL, 0, 1


update bhpbioreportdatahistorical
set tagid = 'SitePostCrusherStockpileDelta'
where tagid = 'PostCrusherStockpileDelta'