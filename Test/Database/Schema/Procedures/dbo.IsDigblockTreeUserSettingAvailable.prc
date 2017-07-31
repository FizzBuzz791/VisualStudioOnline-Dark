 IF OBJECT_ID('dbo.IsDigblockTreeUserSettingAvailable') IS NOT NULL
     DROP PROCEDURE dbo.IsDigblockTreeUserSettingAvailable 
GO 
  
CREATE PROCEDURE dbo.IsDigblockTreeUserSettingAvailable 
(
	@iUserId INT,
	@oSettingAvailable BIT OUTPUT
)
WITH ENCRYPTION AS
BEGIN 
	SET NOCOUNT ON 

	BEGIN TRY
		IF EXISTS
			(
				SELECT 1
				FROM dbo.SecurityUserSetting AS us
					INNER JOIN dbo.SecurityUserSettingType AS st
						ON (us.UserSettingTypeId = st.UserSettingTypeId)
				WHERE us.UserId = @iUserId
					AND st.Name LIKE 'Node_DigblockTree%'
			)
		BEGIN
			SET @oSettingAvailable = 1
		END
		ELSE
		BEGIN
			SET @oSettingAvailable = 0
		END
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON dbo.IsDigblockTreeUserSettingAvailable TO BhpbioGenericManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.IsDigblockTreeUserSettingAvailable">
 <Procedure>
	Determines if there are any digblock tree user settings for the specified user.
 </Procedure>
</TAG>
*/	

