--
-- This poc is part of Core, which is also updated, but adding the change here as well,
-- so that this change can go in as a config change just my running the upgrade script
-- and not having to replace every proc
--
IF OBJECT_ID('dbo.GetImportAutoQueueProfileList') IS NOT NULL
	DROP PROCEDURE dbo.GetImportAutoQueueProfileList
GO

CREATE PROCEDURE dbo.GetImportAutoQueueProfileList
(
	@iIsActive BIT = NULL
)

WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT iaqp.ImportAutoQueueProfileId, iaqp.ImportId, iaqp.FrequencyHours, iaqp.TimeOfDay, iaqp.IsActive
	FROM dbo.ImportAutoQueueProfile iaqp
	WHERE iaqp.IsActive = @iIsActive 
		OR @iIsActive IS NULL
	ORDER BY iaqp.Priority ASC, iaqp.TimeOfDay ASC
		
END
GO

GRANT EXECUTE ON dbo.GetImportAutoQueueProfileList TO CommonImportManager
GO
