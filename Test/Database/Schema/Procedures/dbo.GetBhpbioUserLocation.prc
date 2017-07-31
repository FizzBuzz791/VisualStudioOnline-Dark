IF OBJECT_ID('dbo.GetBhpbioUserLocation') IS NOT NULL
	DROP PROCEDURE dbo.GetBhpbioUserLocation
GO 
  
CREATE PROCEDURE dbo.GetBhpbioUserLocation
(
	@iUserId INT,
	@oLocationId INT OUTPUT
)
AS 
BEGIN 
	SET NOCOUNT ON 
	DECLARE @Null INT

	BEGIN TRY

		--Get the location id of the user where the user is only associated
		--with a single role with a location against it.
		SELECT @oLocationId = Min(LocationId), @Null = UserId
		FROM dbo.SecurityUserRole AS ur
			INNER JOIN dbo.BhpbioSecurityRoleLocation AS rl
				ON (ur.RoleId = rl.RoleId)
		WHERE ur.UserId = @iUserId
		GROUP BY UserId
		HAVING COUNT(*) = 1

	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON dbo.GetBhpbioUserLocation TO BhpbioGenericManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.GetBhpbioUserLocation">
 <Procedure>
	Returns the User's default Location based on their role.
	If the user does not belong to a role which has a mapped location, NULL is returned.
 </Procedure>
</TAG>
*/

/* testing
DECLARE @LocationId INT
EXEC dbo.GetBhpbioUserLocation 13, @LocationId OUTPUT
SELECT @LocationId
*/