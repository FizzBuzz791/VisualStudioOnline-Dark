INSERT INTO dbo.BhpbioReportThresholdType
(
	ThresholdTypeId, Description
)
SELECT 'GraphThreshold','Graph Threshold'

--Default thresholds.
DELETE FROM dbo.BhpbioReportThreshold
WHERE ThresholdTypeId = 'GraphThreshold'
INSERT INTO dbo.BhpbioReportThreshold
(
	LocationId, FieldId, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold
)
SELECT LocationId, Case When (Grade_Id Is Not Null) Then Grade_Id Else 0 End, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold
FROM
	(
		SELECT 1 As LocationId, 'Tonnes' As FieldIdName, 'GraphThreshold' As ThresholdTypeId, 
		0.9 As LowThreshold, 1.1 As HighThreshold, 0 As AbsoluteThreshold UNION	-- Tonnes
		SELECT 1, 'Fe', 'GraphThreshold', 0.99, 1.01, 0 UNION	-- Fe
		SELECT 1, 'P', 'GraphThreshold', 0.9, 1.1, 0 UNION	-- P
		SELECT 1, 'SiO2', 'GraphThreshold', 0.9, 1.1, 0 UNION	-- SiO2
		SELECT 1, 'Al2O3', 'GraphThreshold', 0.9, 1.1, 0 UNION	-- Al2O3
		SELECT 1, 'LOI', 'GraphThreshold', 0.9, 1.1, 0 UNION	-- LOI
		SELECT 1, 'Density', 'GraphThreshold', 0.9, 1.1, 0
	) AS T
	LEFT JOIN dbo.Grade As G
		ON G.Grade_Name = T.FieldIdName