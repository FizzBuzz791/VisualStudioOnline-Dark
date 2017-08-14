IF OBJECT_ID('dbo.GetBhpbioSampleStationTarget') IS NOT NULL
	DROP PROCEDURE dbo.GetBhpbioSampleStationTarget
GO

CREATE PROCEDURE dbo.GetBhpbioSampleStationTarget
(
	@TargetId INT
)
AS
BEGIN
	SELECT * FROM dbo.BhpbioSampleStationTarget WHERE Id = @TargetId
END
GO

GRANT EXECUTE ON dbo.GetBhpbioSampleStationTarget TO BhpbioGenericManager
GO