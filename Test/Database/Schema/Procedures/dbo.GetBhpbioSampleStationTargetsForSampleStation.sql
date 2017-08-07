IF OBJECT_ID('dbo.GetBhpbioSampleStationTargetsForSampleStation') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioSampleStationTargetsForSampleStation
GO 

CREATE PROCEDURE dbo.GetBhpbioSampleStationTargetsForSampleStation
(
	@SampleStationId INT
)
AS
BEGIN
	SELECT * FROM dbo.BhpbioSampleStationTarget WHERE SampleStation_Id = @SampleStationId
END
GO
	
GRANT EXECUTE ON dbo.GetBhpbioSampleStationTargetsForSampleStation TO BhpbioGenericManager
GO