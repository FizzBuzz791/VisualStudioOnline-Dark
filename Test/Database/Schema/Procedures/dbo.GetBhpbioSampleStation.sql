IF OBJECT_ID('dbo.GetBhpbioSampleStation') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioSampleStation
GO 

CREATE PROCEDURE dbo.GetBhpbioSampleStation
(
	@Id INT
)
AS
BEGIN
	SELECT * FROM dbo.BhpbioSampleStation WHERE Id = @Id
END
GO
	
GRANT EXECUTE ON dbo.GetBhpbioSampleStation TO BhpbioGenericManager
GO