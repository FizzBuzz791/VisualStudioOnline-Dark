IF OBJECT_ID('dbo.SaveBhpbioNotificationInstanceApproval') IS NOT NULL
     DROP PROCEDURE dbo.SaveBhpbioNotificationInstanceApproval
GO 

CREATE PROCEDURE dbo.SaveBhpbioNotificationInstanceApproval
(
	@iInstanceId INT,
	@iTagGroupId VARCHAR(124),
	@iLocationId INT
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'SaveBhpbioNotificationInstanceApproval',
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
		IF NOT EXISTS
			(
				SELECT 1
				FROM dbo.BhpbioNotificationInstanceApproval
				WHERE InstanceId = @iInstanceId
			)
		BEGIN
			INSERT INTO dbo.BhpbioNotificationInstanceApproval
				(InstanceId, TagGroupId, LocationId)
			VALUES
				(@iInstanceId, @iTagGroupId, @iLocationId)
		END
		ELSE
		BEGIN
			UPDATE dbo.BhpbioNotificationInstanceApproval
			SET TagGroupId = @iTagGroupId,
				LocationId = @iLocationId
			WHERE InstanceId = @iInstanceId
		END

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

GRANT EXECUTE ON dbo.SaveBhpbioNotificationInstanceApproval TO CoreNotificationManager
GO
