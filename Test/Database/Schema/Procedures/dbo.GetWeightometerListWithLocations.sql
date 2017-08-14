IF OBJECT_ID('dbo.GetWeightometerListWithLocations') IS NOT NULL
     DROP PROCEDURE dbo.GetWeightometerListWithLocations
GO 

CREATE PROCEDURE dbo.GetWeightometerListWithLocations
AS
BEGIN
	SELECT W.Weightometer_Id, W.Description, WL.Location_Id, L.Parent_Location_Id
	FROM Weightometer W
	INNER JOIN WeightometerLocation WL ON WL.Weightometer_Id = W.Weightometer_Id
	INNER JOIN Location L ON L.Location_Id = WL.Location_Id
	ORDER BY W.Weightometer_Id
END
GO
	
GRANT EXECUTE ON dbo.GetWeightometerListWithLocations TO BhpbioGenericManager
GO