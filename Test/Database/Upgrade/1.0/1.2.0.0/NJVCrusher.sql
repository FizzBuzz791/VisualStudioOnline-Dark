INSERT INTO dbo.Crusher
(
	Crusher_Id, Description
)
SELECT 'NH-OHP4', 'NJV OHP Crusher'
GO

INSERT INTO dbo.CrusherLocation
(
	Crusher_Id, Location_Type_Id, Location_Id
)
SELECT c.Crusher_Id, lt.Location_Type_Id, l.Location_Id
FROM dbo.LocationType AS lt
	INNER JOIN dbo.Location AS l
		ON (lt.Location_Type_Id = l.Location_Type_Id)
	CROSS JOIN
	(
		SELECT 'NH-OHP4' AS Crusher_Id
	) AS c
WHERE lt.Description = 'Hub'
	AND l.Name = 'NJV'
GO