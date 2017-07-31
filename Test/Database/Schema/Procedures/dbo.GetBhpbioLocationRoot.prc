IF OBJECT_ID('dbo.GetBhpbioLocationRoot') IS NOT NULL
	DROP PROCEDURE dbo.GetBhpbioLocationRoot  
GO 
  
CREATE PROCEDURE dbo.GetBhpbioLocationRoot
(
	@oLocationId INT OUTPUT
)
WITH ENCRYPTION
AS 
BEGIN 
	SET NOCOUNT ON 

	BEGIN TRY
		SELECT @oLocationId = L.Location_Id
		FROM dbo.Location AS L
		WHERE Parent_Location_Id IS NULL
	
		SELECT L.Location_Id, L.Name, L.Description, LT.Location_Type_Id, L.Description
		FROM dbo.Location AS L
			INNER JOIN dbo.LocationType AS LT
				ON (L.Location_Type_Id = LT.Location_Type_Id)
		WHERE Parent_Location_Id IS NULL
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON dbo.GetBhpbioLocationRoot TO BhpbioGenericManager
GO


/*
DECLARE @Id INT
EXEC dbo.GetBhpbioLocationRoot @Id OUTPUT
SELECT @Id
*/