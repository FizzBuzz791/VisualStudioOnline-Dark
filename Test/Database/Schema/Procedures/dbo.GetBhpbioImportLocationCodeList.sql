IF OBJECT_ID('dbo.GetBhpbioImportLocationCodeList') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioImportLocationCodeList
GO 
  
CREATE PROCEDURE dbo.GetBhpbioImportLocationCodeList
(
	@iImportParameterId INT = NULL,
	@iLocationId INT = NULL
)
AS
BEGIN
	SELECT ilc.ImportParameterId, ilc.LocationId, ilc.LocationCode, l.Name, l.Description
	FROM dbo.BhpbioImportLocationCode AS ilc
		INNER JOIN dbo.Location AS l
			ON ilc.LocationId = l.Location_Id
	WHERE ilc.ImportParameterId = ISNULL(@iImportParameterId, ilc.ImportParameterId)
		AND ilc.LocationId = ISNULL(@iLocationId, ilc.LocationId)
	ORDER BY ilc.ImportParameterId, l.Description
END
GO
GRANT EXECUTE ON dbo.GetBhpbioImportLocationCodeList TO BhpbioGenericManager
GO