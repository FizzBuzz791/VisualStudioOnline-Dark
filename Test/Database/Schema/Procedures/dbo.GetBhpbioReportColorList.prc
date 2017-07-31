IF OBJECT_ID('dbo.GetBhpbioReportColorList') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportColorList  
GO 

CREATE PROCEDURE dbo.GetBhpbioReportColorList
(
	@iTagId VARCHAR(63) = NULL,
	@iShowVisible BIT = 0
)
WITH ENCRYPTION
AS 
BEGIN 
	SET NOCOUNT ON 

	BEGIN TRY
	
		SELECT TagId, Description, IsVisible, Color, LineStyle, MarkerShape
		FROM dbo.BhpbioReportColor
		WHERE (TagId = @iTagId OR @iTagId IS NULL)
			AND (@iShowVisible = 1 AND IsVisible = 1 OR @iShowVisible = 0)
			
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO
	
GRANT EXECUTE ON dbo.GetBhpbioReportColorList TO BhpbioGenericManager
