IF OBJECT_ID('dbo.GetBhpbioReportDataTags') IS NOT NULL
	DROP PROCEDURE dbo.GetBhpbioReportDataTags
GO 

CREATE PROCEDURE dbo.GetBhpbioReportDataTags
(
	@iTagGroupId VARCHAR(124) = NULL,
	@iLocationTypeId INT = NULL
)
WITH ENCRYPTION
AS 
BEGIN 
	SET NOCOUNT ON 

	BEGIN TRY

		SELECT TagGroupId, TagGroupLocationTypeId
		FROM dbo.BhpbioReportDataTags
		WHERE (TagGroupId = @iTagGroupId OR @iTagGroupId IS NULL)
			AND (@iLocationTypeId = TagGroupLocationTypeId OR @iLocationTypeId IS NULL)
		GROUP BY TagGroupId, TagGroupLocationTypeId
		
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON dbo.GetBhpbioReportDataTags TO CoreNotificationManager
GO