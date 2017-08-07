IF OBJECT_ID('dbo.DeleteBhpbioSampleStation') IS NOT NULL 
     DROP PROCEDURE dbo.DeleteBhpbioSampleStation
GO 

CREATE PROCEDURE dbo.DeleteBhpbioSampleStation
(
	@Id INT
)
AS
BEGIN
	DELETE FROM dbo.BhpbioSampleStationTarget WHERE SampleStation_Id = @Id
	DELETE FROM dbo.BhpbioSampleStation WHERE Id = @Id
END
GO

GRANT EXECUTE ON dbo.DeleteBhpbioSampleStation TO BhpbioGenericManager
GO