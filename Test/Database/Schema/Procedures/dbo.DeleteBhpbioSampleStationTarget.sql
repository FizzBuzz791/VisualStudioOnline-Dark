IF OBJECT_ID('dbo.DeleteBhpbioSampleStationTarget') IS NOT NULL 
     DROP PROCEDURE dbo.DeleteBhpbioSampleStationTarget
GO 

CREATE PROCEDURE dbo.DeleteBhpbioSampleStationTarget
(
	@Id INT
)
AS
BEGIN
	DELETE FROM dbo.BhpbioSampleStationTarget WHERE Id = @Id
END
GO

GRANT EXECUTE ON dbo.DeleteBhpbioSampleStationTarget TO BhpbioGenericManager
GO