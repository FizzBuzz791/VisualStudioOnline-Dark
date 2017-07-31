IF OBJECT_ID('dbo.GetBhpbioNotificationInstanceApproval') IS NOT NULL
	DROP PROCEDURE dbo.GetBhpbioNotificationInstanceApproval
GO 

CREATE PROCEDURE dbo.GetBhpbioNotificationInstanceApproval
(
	@iInstanceId INT
)
WITH ENCRYPTION
AS 
BEGIN 
	SET NOCOUNT ON 

	BEGIN TRY
		IF @iInstanceId IS NULL
		BEGIN
			RAISERROR('The Instance Id must not be null.', 16, 1)
		END

		SELECT TagGroupId, LocationId
		FROM dbo.BhpbioNotificationInstanceApproval
		WHERE InstanceId = @iInstanceId
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON dbo.GetBhpbioNotificationInstanceApproval TO CoreNotificationManager
GO
