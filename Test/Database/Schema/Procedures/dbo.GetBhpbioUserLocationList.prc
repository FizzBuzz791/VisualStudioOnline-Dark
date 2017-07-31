IF OBJECT_ID('dbo.GetBhpbioUserLocationList') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioUserLocationList  
GO 
  
CREATE PROCEDURE dbo.GetBhpbioUserLocationList 
(
	@iUserId INT
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @ReturnValue BIT
	DECLARE @Roles TABLE
	(
		RoleId VARCHAR(31)
	)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioUserLocationList',
		@TransactionCount = @@TranCount 

	-- if there are no transactions available then start a new one
	-- if there is already a transaction then only mark a savepoint
	IF @TransactionCount = 0
	BEGIN
		SET TRANSACTION ISOLATION LEVEL REPEATABLE READ 
		BEGIN TRANSACTION
	END
	ELSE
	BEGIN
		SAVE TRANSACTION @TransactionName
	END
  
	BEGIN TRY

		-- retreieve all the users roles from the 3 different types.
		INSERT INTO @Roles
			(RoleId)
		SELECT RoleId
		From dbo.SecurityUserRole
		Where UserId = @iUserId

		-- get all locations of this user.
		SELECT @iUserId AS UserId, r.RoleId, srl.LocationId, l.Name, l.Description
		FROM @Roles AS r
			INNER JOIN dbo.BhpbioSecurityRoleLocation AS srl
				ON (r.RoleId = srl.RoleId)
			INNER JOIN dbo.Location As l
				ON (l.Location_Id = srl.LocationId)

		-- if we started a new transaction that is still valid then commit the changes
		IF (@TransactionCount = 0) AND (XAct_State() = 1)
		BEGIN
			COMMIT TRANSACTION
		END
	END TRY
	BEGIN CATCH
		-- if we started a transaction then roll it back
		IF (@TransactionCount = 0)
		BEGIN
			ROLLBACK TRANSACTION
		END
		-- if we are part of an existing transaction and 
		ELSE IF (XAct_State() = 1) AND (@TransactionCount > 0)
		BEGIN
			ROLLBACK TRANSACTION @TransactionName
		END

		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON dbo.GetBhpbioUserLocationList TO BhpbioGenericManager
GO

--exec dbo.GetBhpbioUserLocationList 1
