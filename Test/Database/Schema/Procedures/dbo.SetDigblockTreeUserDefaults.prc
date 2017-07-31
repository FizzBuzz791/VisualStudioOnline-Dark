 IF OBJECT_ID('dbo.SetDigblockTreeUserDefaults') IS NOT NULL
     DROP PROCEDURE dbo.SetDigblockTreeUserDefaults  
GO 
  
CREATE PROCEDURE dbo.SetDigblockTreeUserDefaults
(
	@iLocationId INT,
	@iUserId INT
)
WITH ENCRYPTION AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @LocationCursor CURSOR
	DECLARE @LocationId INT
	DECLARE @LocationTypeId SMALLINT
	DECLARE @LocationLevel INT
	DECLARE @SettingTypeName VARCHAR(255)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'SetDigblockTreeUserDefaults',
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
		-- add the bottom-level call
		EXEC dbo.AddOrUpdateSecurityUserSetting
			@iUserId = @iUserId,
			@iSettingTypeName = 'Node_DigblockTree_1_0_1_Expanded',
			@iSettingValue = 'True',
			@iAutoAddSettingType = 1	

		SET @LocationCursor = CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
			SELECT l.Location_Id, lt.Location_Type_Id, lth.Location_Level
			FROM
				(
					SELECT Location_Id
					FROM dbo.GetLocationParentLocationList(@iLocationId)
					WHERE Location_Id IS NOT NULL

					UNION ALL

					SELECT @iLocationId
				) AS pll
				INNER JOIN dbo.Location AS l
					ON (pll.Location_Id = l.Location_Id)
				INNER JOIN dbo.LocationType AS lt
					ON (l.Location_Type_Id = lt.Location_Type_Id)
				INNER JOIN dbo.GetLocationTypeHierarchy(0) AS lth
					ON (lt.Location_Type_Id = lth.Location_Type_Id)
			ORDER BY lth.Location_Level

		OPEN @LocationCursor
		FETCH NEXT FROM @LocationCursor INTO @LocationId, @LocationTypeId, @LocationLevel

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @SettingTypeName = 'Node_DigblockTree_' + CONVERT(VARCHAR(10), @LocationLevel + 2) + '_' +
				CONVERT(VARCHAR(10), @LocationId) + '_' + CONVERT(VARCHAR(10), @LocationTypeId) + '_Expanded'

			-- add the successive-level call
			EXEC dbo.AddOrUpdateSecurityUserSetting
				@iUserId = @iUserId,
				@iSettingTypeName = @SettingTypeName,
				@iSettingValue = 'True',
				@iAutoAddSettingType = 1

			FETCH NEXT FROM @LocationCursor INTO @LocationId, @LocationTypeId, @LocationLevel
		END

		CLOSE @LocationCursor

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

GRANT EXECUTE ON dbo.SetDigblockTreeUserDefaults TO BhpbioGenericManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.SetDigblockTreeUserDefaults">
 <Procedure>
	Applies settings to the Digblock Tree for the existing user.
	The settings applied will allow the tree to be expanded to the node that represents the location passed in.
 </Procedure>
</TAG>
*/	