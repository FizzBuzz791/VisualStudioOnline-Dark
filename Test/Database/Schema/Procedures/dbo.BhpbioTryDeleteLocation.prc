IF OBJECT_ID('dbo.BhpbioTryDeleteLocation') IS NOT NULL
     DROP PROCEDURE dbo.BhpbioTryDeleteLocation
GO 
  
CREATE PROCEDURE dbo.BhpbioTryDeleteLocation
( 
    @iLocationId INT,
	@iName VARCHAR(31),
	@iLocationTypeId TINYINT,
	@iParentLocationName VARCHAR(31),
	@oIsError BIT OUTPUT,
	@oErrorMessage VARCHAR(255) OUTPUT
)
AS
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @IsError BIT
	DECLARE @ErrorMessage VARCHAR(255)
	DECLARE @LocationId INT

	SET NOCOUNT ON 

	SELECT @TransactionName = 'TryDeleteLocation',
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
	
		-- if the location id is not given
		IF (@iLocationId IS NULL)
		BEGIN
			-- obtain it from the other details given
			IF (@iLocationTypeId IS NOT NULL)
			BEGIN
				SET @LocationId =	
					(
						SELECT Location_Id
						FROM dbo.Location
						WHERE Name = @iName
							AND Location_Type_Id = @iLocationTypeId
					)
			END
			ELSE
			BEGIN
				SET @LocationId =	
					(
						SELECT L.Location_Id
						FROM dbo.Location AS L
							INNER JOIN dbo.Location AS PL
								ON (L.Parent_Location_Id = PL.Location_Id)
						WHERE L.Name = @iName
							AND PL.Name = @iParentLocationName
					)
			END
		END	
		ELSE
		BEGIN
			SET @LocationId = @iLocationId
		END

		SET @IsError = 0
		SET @ErrorMessage = NULL
		
		IF EXISTS
			(
				SELECT TOP 1 1
				FROM dbo.BhpbioApprovalData
				WHERE LocationId = @LocationId
			)
		BEGIN
			SET @IsError = 1
			SET @ErrorMessage = 'This location is currently in use by a F1F2F3 Approval.'
		END
		
		IF EXISTS
			(
				SELECT TOP 1 1
				FROM dbo.BhpbioDataExceptionLocation
				WHERE LocationId = @LocationId
			)
		BEGIN
			SET @IsError = 1
			SET @ErrorMessage = 'This location is currently in use by a Data Exception.'
		END
				
		IF EXISTS
			(
				SELECT TOP 1 1
				FROM dbo.BhpbioLocationStockpileConfiguration
				WHERE LocationId = @LocationId
			)
		BEGIN
			SET @IsError = 1
			SET @ErrorMessage = 'This location is currently in use by a BHPBIO Custom Configuration - Stockpiles.'
		END
		
		IF EXISTS
			(
				SELECT TOP 1 1
				FROM dbo.BhpbioPortBalance
				WHERE HubLocationId = @LocationId
			)
		BEGIN
			SET @IsError = 1
			SET @ErrorMessage = 'This location is currently in use by a Port Balance Record.'
		END
		
		IF EXISTS
			(
				SELECT TOP 1 1
				FROM dbo.BhpbioPortBlending
				WHERE SourceHubLocationId = @LocationId
					OR DestinationHubLocationId = @LocationId
					OR LoadSiteLocationId = @LocationId
			)
		BEGIN
			SET @IsError = 1
			SET @ErrorMessage = 'This location is currently in use by a Port Blending Record.'
		END
		
		IF EXISTS
			(
				SELECT TOP 1 1
				FROM dbo.BhpbioReportThreshold
				WHERE LocationId = @LocationId
			)
		BEGIN
			SET @IsError = 1
			SET @ErrorMessage = 'This location is currently in use by a Reporting Threshold.'
		END
		
		IF EXISTS
			(
				SELECT TOP 1 1
				FROM dbo.BhpbioSecurityRoleLocation
				WHERE LocationId = @LocationId
			)
		BEGIN
			SET @IsError = 1
			SET @ErrorMessage = 'This location is currently in use by a Security Role.'
		END
		
		IF EXISTS
			(
				SELECT TOP 1 1
				FROM dbo.BhpbioShippingNominationItemParcel
				WHERE HubLocationId = @LocationId
			)
		BEGIN
			SET @IsError = 1
			SET @ErrorMessage = 'This location is currently in use by a Shipping Record.'
		END
		
			
		-- delete the location record
		IF @IsError = 0
		BEGIN
			EXEC dbo.TryDeleteLocation
				@iLocationId = @iLocationId,
				@iName = @iName,
				@iLocationTypeId = @iLocationTypeId,
				@iParentLocationName = @iParentLocationName,
				@oIsError = @oIsError OUTPUT,
				@oErrorMessage = @oErrorMessage OUTPUT
		END	

		-- return the check results
		SET @oIsError = @IsError
		SET @oErrorMessage = @ErrorMessage

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

GRANT EXECUTE ON dbo.BhpbioTryDeleteLocation TO CoreUtilityManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.BhpbioTryDeleteLocation">
 <Procedure>
	Attempts to deletes a record from the Location table.
	Can be called by on of the following methods:
	  1. Providing the location id
	  2. Providing the location name and parent location name, if the location is in a hierarchical group which has a parent group
	  3. Providing the location name and location type group, if the location is in an independant group
	Errors are raised if:
		The Location Exists in the Bhpbio approvals tables
		Any Core Checks.
 </Procedure>
</TAG>
*/
