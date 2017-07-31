IF OBJECT_ID('dbo.IsBhpbioApprovalLocation') IS NOT NULL
     DROP PROCEDURE dbo.IsBhpbioApprovalLocation  
GO 
  
CREATE PROCEDURE dbo.IsBhpbioApprovalLocation 
(
	@iLocationId INT,
	@iMonth DATETIME,
	@iTagId VARCHAR(63),
	@iTagGroupId VARCHAR(124),
	@oIsApproved BIT OUTPUT
)
WITH ENCRYPTION
AS 
BEGIN 
	
	DECLARE @MonthDate DATETIME
	DECLARE @ReturnValue BIT
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'IsBhpbioApprovalLocation',
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
		SET @MonthDate = dbo.GetDateMonth(@iMonth)

		IF EXISTS
			(
				SELECT TOP 1 1 
				FROM dbo.BhpbioApprovalData AS a
					INNER JOIN dbo.BhpbioReportDataTags AS brdt
						ON brdt.TagId = a.TagId
				WHERE a.ApprovedMonth = @MonthDate 
					AND (a.TagId = @iTagId OR @iTagId IS NULL)
					AND (
							brdt.TagGroupId = @iTagGroupId 
						OR 
							( @iTagGroupId IS NULL AND brdt.TagGroupId <> 'F1Factor')
						)
			)
		BEGIN
			-- we have a "possible" match
			-- continue to invoke a location check
			IF EXISTS
				(
					SELECT TOP 1 1 
					FROM dbo.BhpbioApprovalData AS a
						INNER JOIN dbo.BhpbioReportDataTags AS brdt
							ON brdt.TagId = a.TagId
						INNER JOIN GetLocationSubtree(@iLocationId) AS t
							ON a.LocationId = t.Location_Id
					WHERE a.ApprovedMonth = @MonthDate 
						AND (a.TagId = @iTagId OR @iTagId IS NULL)
						AND (
							brdt.TagGroupId = @iTagGroupId 
						OR 
							( @iTagGroupId IS NULL AND brdt.TagGroupId <> 'F1Factor')
						)
				)
			BEGIN
				SET @ReturnValue = 1
			END
			ELSE
			BEGIN
				SET @ReturnValue = 0
			END
		END
		ELSE
		BEGIN
			SET @ReturnValue = 0
		END

		SET @oIsApproved = @ReturnValue

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

GRANT EXECUTE ON dbo.IsBhpbioApprovalLocation TO BhpbioGenericManager
GO
