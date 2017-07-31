IF OBJECT_ID('dbo.DeleteBhpbioReportThreshold') IS NOT NULL
     DROP PROCEDURE dbo.DeleteBhpbioReportThreshold
GO 

CREATE PROCEDURE dbo.DeleteBhpbioReportThreshold
(
	@iLocationId INT,
	@iThresholdTypeId VARCHAR(31),
	@iFieldId SMALLINT = NULL
)
WITH ENCRYPTION
AS 
BEGIN 
	SET NOCOUNT ON 

	BEGIN TRY
	
		-- Error if it does not exist.
		IF NOT EXISTS (
						SELECT 1 
						FROM dbo.BhpbioReportThreshold 
						WHERE LocationId = @iLocationId
							AND (ThresholdTypeId = @iThresholdTypeId OR @iThresholdTypeId IS NULL)
							AND (FieldId = @iFieldId OR @iFieldId IS NULL)
					   )
		BEGIN
			RAISERROR('This reporting threshold does not exist.', 16, 1)
		END
		
		-- Delete the threshold records associated with the location (and field).
		DELETE
		FROM dbo.BhpbioReportThreshold 
		WHERE LocationId = @iLocationId
			AND (ThresholdTypeId = @iThresholdTypeId OR @iThresholdTypeId IS NULL)
			AND (FieldId = @iFieldId OR @iFieldId IS NULL)
	
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO
	
GRANT EXECUTE ON dbo.DeleteBhpbioReportThreshold TO BhpbioGenericManager
