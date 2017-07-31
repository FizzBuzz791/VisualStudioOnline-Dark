IF OBJECT_ID('dbo.GetBhpbioReportDataTagsDetailed') IS NOT NULL
	DROP PROCEDURE dbo.GetBhpbioReportDataTagsDetailed
GO 

CREATE PROCEDURE dbo.GetBhpbioReportDataTagsDetailed
WITH ENCRYPTION
AS 
BEGIN 
	SET NOCOUNT ON 

	BEGIN TRY
		SELECT TagId, TagGroupId, ApprovalOrder
		FROM dbo.BhpbioReportDataTags
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
	
END 
GO

GRANT EXECUTE ON dbo.GetBhpbioReportDataTagsDetailed TO BhpbioGenericManager
GO