IF OBJECT_ID('dbo.GetBhpbioReportThresholdTypeList') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportThresholdTypeList
GO 

CREATE PROCEDURE dbo.GetBhpbioReportThresholdTypeList
AS 
BEGIN 
	SET NOCOUNT ON 

	BEGIN TRY
	
		SELECT ThresholdTypeId, Description
		FROM dbo.BhpbioReportThresholdType
	
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO
	
GRANT EXECUTE ON dbo.GetBhpbioReportThresholdTypeList TO BhpbioGenericManager
