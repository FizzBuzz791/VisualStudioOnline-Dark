IF OBJECT_ID('dbo.AddOrUpdateBhpbioSampleStation') IS NOT NULL 
     DROP PROCEDURE dbo.AddOrUpdateBhpbioSampleStation
GO 

CREATE PROCEDURE dbo.AddOrUpdateBhpbioSampleStation
(
	@Location_Id INT,
	@Weightometer_Id VARCHAR(31),
	@Name NVARCHAR(MAX),
	@Description NVARCHAR(MAX),
	@ProductSize VARCHAR(5),
	@Id INT = NULL
)
AS
BEGIN
	IF @Id IS NULL
		INSERT INTO dbo.BhpbioSampleStation (Location_Id, Weightometer_Id, Name, Description, ProductSize)
		VALUES (@Location_Id, @Weightometer_Id, @Name, @Description, @ProductSize)
	ELSE
		UPDATE dbo.BhpbioSampleStation SET
			Location_Id = @Location_Id,
			Weightometer_Id = @Weightometer_Id,
			Name = @Name,
			Description = @Description,
			ProductSize = @ProductSize
		WHERE Id = @Id
END
GO

GRANT EXECUTE ON dbo.AddOrUpdateBhpbioSampleStation TO BhpbioGenericManager
GO