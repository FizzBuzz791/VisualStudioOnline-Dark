IF OBJECT_ID('dbo.IsBhpbioUserInLocation') IS NOT NULL
     DROP PROCEDURE dbo.IsBhpbioUserInLocation  
GO 
  
CREATE PROCEDURE dbo.IsBhpbioUserInLocation 
(
	@iUserId INT,
	@iLocationId INT,
	@oIsInLocation BIT OUTPUT
)
WITH ENCRYPTION
AS 
BEGIN 
	SET NOCOUNT ON 
  
	BEGIN TRY
		IF EXISTS
			(
        SELECT TOP 1 1
          FROM dbo.SecurityUserRole AS ur
	          INNER JOIN dbo.BhpbioSecurityRoleLocation AS rl
		          ON (rl.RoleId = ur.RoleId)
	          LEFT JOIN dbo.GetLocationParentLocationList(@iLocationId) AS pll
		          ON (pll.Location_Id = rl.LocationId)
          WHERE ur.UserId = @iUserId
          AND (rl.LocationId = @iLocationId OR pll.Location_Id = rl.LocationId)
			)
		BEGIN
			SET @oIsInLocation = 1
		END
		ELSE
		BEGIN
			SET @oIsInLocation = 0
		END
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON dbo.IsBhpbioUserInLocation TO BhpbioGenericManager
GO

/*
DECLARE @lol int
exec dbo.IsBhpbioUserInLocation 1, 4, @lol OUTPUT
SELECT @lol
*/

