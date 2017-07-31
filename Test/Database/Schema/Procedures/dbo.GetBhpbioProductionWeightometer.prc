IF OBJECT_ID('dbo.GetBhpbioProductionWeightometer') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioProductionWeightometer
GO 
  
CREATE PROCEDURE dbo.GetBhpbioProductionWeightometer
(
	@iSourceStockpileId INT,
	@iSourceCrusherId VARCHAR(31),
	@iSourceMillId VARCHAR(31),
	@iDestinationStockpileId INT,
	@iDestinationCrusherId VARCHAR(31),
	@iDestinationMillId VARCHAR(31),
	@iTransactionDate DATETIME,
	@iSourceType VARCHAR(255),
	@iDestinationType VARCHAR(255),
	@iSiteLocationId INT,
	@oWeightometerId VARCHAR(31) OUTPUT,
	@oIsError BIT OUTPUT,
	@oErrorDescription VARCHAR(255) OUTPUT
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @WeightometerId VARCHAR(31)
	DECLARE @IsError BIT
	DECLARE @ErrorDescription VARCHAR(255)

	DECLARE @LocationTypeId SmallInt

	SET NOCOUNT ON 

	------------------------------------------------------------------------------------------------------------------------------
	-- This procedure is used by the Production Import code.   The Production Import processes data retrieved from MQ2
	--
	-- MQ2, unlike Reconcilor, does not model a dynamic location hierarchy where pits and sites can be reassigned...
	-- Care must be taken here... some entity and weightometer assignments are corrected based on dynamic hierarchy considerations
	-- in a post process step of the Production Import.
	------------------------------------------------------------------------------------------------------------------------------

	Declare @startDateRangeToCheck DateTime
	Declare @endDateRangeToCheck DateTime
	
	Set @startDateRangeToCheck = dbo.GetSystemStartDate()
	Set @endDateRangeToCheck = GetDate()
			
	SELECT @TransactionName = 'GetBhpbioProductionWeightometer',
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
		SET @oWeightometerId = NULL
		SET @oIsError = 0
		SET @oErrorDescription = NULL
		
		SET @WeightometerId = NULL
		SET @IsError = 0

		-- extra condition added by PP to stop Crusher to crusher movements, as this causes the L1-Recalc to fail somehow
		IF @iSourceType = 'crusher' AND @iSourceCrusherId = 'WB-C2' AND (@iDestinationType = 'post crusher' OR @iDestinationType = 'train rake' OR @iDestinationType = 'pre crusher')
		BEGIN
		    -- Force the WeightometerId for outflow from WB-C2 to be WB-C2OutFlow
			-- This is neccessary as WB-C2OutFlow cannot have an entry in WeightometerFlowPeriod as it must be excluded from
			-- calculations
			SET @WeightometerId = 'WB-C2OutFlow'
		END
		-- these flows below are fixed to specific cross-site weightometers
		-- this is because these flows are a-typical and users will be interested
		-- in investigating these flows
		ELSE IF @iSourceType = 'post crusher' AND @iDestinationType = 'pre crusher'
		BEGIN
			SELECT @WeightometerId = w.Weightometer_Id
			FROM dbo.Weightometer AS w
				INNER JOIN dbo.WeightometerLocation AS wl
					ON (w.Weightometer_Id = wl.Weightometer_Id)
			WHERE w.Weightometer_Id LIKE '%PostCrusherToPreCrusher'
				AND wl.Location_Id = @iSiteLocationId
		END
		ELSE IF @iSourceType = 'post crusher' AND @iDestinationType = 'post crusher'
		BEGIN
			SELECT @WeightometerId = w.Weightometer_Id
			FROM dbo.Weightometer AS w
				INNER JOIN dbo.WeightometerLocation AS wl
					ON (w.Weightometer_Id = wl.Weightometer_Id)
			WHERE w.Weightometer_Id LIKE '%PostCrusherToPostCrusher'
				AND wl.Location_Id = @iSiteLocationId
		END
		ELSE IF @iSourceType = 'post crusher' AND @iDestinationType = 'crusher'
		BEGIN
			SELECT @WeightometerId = w.Weightometer_Id
			FROM dbo.Weightometer AS w
				INNER JOIN dbo.WeightometerLocation AS wl
					ON (w.Weightometer_Id = wl.Weightometer_Id)
			WHERE w.Weightometer_Id LIKE '%PostCrusherToCrusher'
				AND wl.Location_Id = @iSiteLocationId
		END
		ELSE IF @iSourceType = 'post crusher' AND @iDestinationType = 'train rake'
		BEGIN
			-- attempt match using weightometer flow period and
			-- load out stockpile if possible,
			-- this is used for Crusher 2 at Eastern Ridge/OB24
			SELECT @WeightometerId = Weightometer_Id
			FROM (
				SELECT TOP 1 wfp.Weightometer_Id
				FROM WeightometerFlowPeriod wfp
				INNER JOIN dbo.WeightometerLocation AS wl
					ON (wfp.Weightometer_Id = wl.Weightometer_Id)				
				WHERE (@iTransactionDate <= WFP.End_Date OR WFP.End_Date IS NULL) 
				AND WFP.Source_Stockpile_Id = @iSourceStockpileId
				AND wl.Location_Id = @iSiteLocationId
				ORDER BY WFP.End_Date ASC	
			) W
		
			-- else resolve the weightometer based on the site
			IF (@WeightometerId IS NULL)
			BEGIN
				SELECT @WeightometerId = w.Weightometer_Id
				FROM dbo.Weightometer AS w
					INNER JOIN dbo.WeightometerLocation AS wl
						ON (w.Weightometer_Id = wl.Weightometer_Id)
				WHERE w.Weightometer_Id LIKE '%PostCrusherToTrainRake'
					AND wl.Location_Id = @iSiteLocationId
			END
		END
		ELSE IF @iSourceType = 'crusher' AND @iDestinationType = 'crusher'
		BEGIN
			SELECT @WeightometerId = w.Weightometer_Id
			FROM dbo.Weightometer As w
				INNER JOIN dbo.WeightometerLocation As wl
					ON (w.Weightometer_Id = wl.Weightometer_Id)
				INNER JOIN dbo.WeightometerFlowPeriod As wfp
					ON (wfp.Weightometer_Id = w.Weightometer_Id)
			WHERE (w.Weightometer_Id Like '%Raw%' Or w.Weightometer_Id Not Like '%Corrected%')
				AND wl.Location_Id = @iSiteLocationId
				AND ( wfp.Source_Crusher_Id = @iSourceCrusherId
						OR wfp.Source_Mill_Id = @iSourceMillId	)
				AND ( wfp.Destination_Crusher_ID = @iDestinationCrusherId
						OR wfp.Destination_Mill_Id = @iDestinationMillId) 
		END		
		ELSE IF (@iSourceType = 'train rake')
		BEGIN
			
			SELECT @LocationTypeId = Location_Type_Id
			FROM LocationType LT
			WHERE Description = 'Hub'

			SELECT @WeightometerId = w.Weightometer_Id
			FROM dbo.Weightometer As w
				INNER JOIN dbo.WeightometerLocation As wl
					ON (w.Weightometer_Id = wl.Weightometer_Id)
				INNER JOIN dbo.WeightometerFlowPeriod As wfp
					ON (wfp.Weightometer_Id = w.Weightometer_Id)
			WHERE (w.Weightometer_Id Like '%Raw%' Or w.Weightometer_Id Not Like '%Corrected%')
				AND wl.Location_Id = dbo.getlocationtypelocationid(@iSiteLocationId, @LocationTypeId)
				AND wfp.Source_Stockpile_Id IS NOT NULL
				AND (wfp.Destination_Stockpile_Id = @iDestinationStockpileId)
		END	
		ELSE IF ((@iSourceType = 'pre crusher' OR @iSourceType = 'post crusher') AND @iDestinationType = 'crusher')
			OR (@iSourceType = 'crusher' AND (@iDestinationType = 'post crusher' OR @iDestinationType = 'train rake' OR @iDestinationType = 'pre crusher'))
			OR (@iDestinationType = 'crusher')
		BEGIN
			-- these flows are typical and hence are routed through the Weightometer Flow Period system
			-- try to determine if we can use a site's weightometer based on the weightometer flow period
			-- besides - how else do you hook it up to a crusher/mill!  (stoopid wfp system)
			;WITH BhpbioWeightometerFlowPeriod (Weightometer_Id, Start_Date, End_Date, Source_Stockpile_Id, Source_Crusher_Id,
				Source_Mill_Id, Destination_Stockpile_Id, Destination_Crusher_Id, Destination_Mill_Id, Is_Calculated, Processing_Order_No) AS
			(
				SELECT wfp.Weightometer_Id,
					(
						SELECT TOP 1 DATEADD(DAY, 1, wfp2.End_Date)
						FROM dbo.WeightometerFlowPeriod AS wfp2
						WHERE wfp.Weightometer_Id = wfp2.Weightometer_Id
							AND wfp2.End_Date < ISNULL(wfp.End_Date, DATEADD(DAY, 1, wfp2.End_Date))
						ORDER BY wfp2.End_Date DESC
					) AS Start_Date,
					End_Date, Source_Stockpile_Id, Source_Crusher_Id, Source_Mill_Id, Destination_Stockpile_Id,
					Destination_Crusher_Id, Destination_Mill_Id, Is_Calculated, Processing_Order_No
				FROM dbo.WeightometerFlowPeriod AS wfp


			)
			SELECT TOP 1 @WeightometerId = w.Weightometer_Id
			FROM dbo.Weightometer AS w
				INNER JOIN dbo.WeightometerLocation AS wl
					ON (w.Weightometer_Id = wl.Weightometer_Id)
				INNER JOIN Location l ON l.Location_Id = wl.Location_Id
				INNER JOIN (
						-- use the Weightometer Flow Period table to work out if any of the entries are applicable
						SELECT wfp1.Weightometer_Id, wfp1.Source_Crusher_Id, wfp1.Source_Mill_Id, wfp1.Source_Stockpile_Id, 
							wfp1.Destination_Crusher_Id, wfp1.Destination_Mill_Id, wfp1.Destination_Stockpile_Id
						FROM BhpbioWeightometerFlowPeriod AS wfp1
						WHERE 
							(
								-- match on source crusher / mill (if it is specified)
								(wfp1.Source_Crusher_Id = @iSourceCrusherId)
								OR (wfp1.Source_Mill_Id = @iSourceMillId)
								OR (wfp1.Source_Stockpile_Id = @iSourceStockpileId)
								OR
								(
									-- this enforces a Mill and Crusher to be specific
									-- if the stockpile hasn't been identified then that is ok
									-- as the source/destination can be "floating"
									wfp1.Source_Mill_Id IS NULL AND @iSourceMillId IS NULL
									AND wfp1.Source_Crusher_Id IS NULL AND @iSourceCrusherId IS NULL
									AND wfp1.Source_Stockpile_Id IS NULL
								)
							)
							AND
							(
								-- match on destination crusher / mill (if it is specified)
								(wfp1.Destination_Crusher_Id = @iDestinationCrusherId)
								OR (wfp1.Destination_Mill_Id = @iDestinationMillId)
								OR (wfp1.Destination_Stockpile_Id = @iDestinationStockpileId)
								OR
								(
									-- ditto for source (above)
									wfp1.Destination_Mill_Id IS NULL AND @iDestinationMillId IS NULL
									AND wfp1.Destination_Crusher_Id IS NULL AND @iDestinationCrusherId IS NULL
									AND wfp1.Destination_Stockpile_Id IS NULL
								)
							)
							AND (@iTransactionDate <= ISNULL(wfp1.End_Date, @iTransactionDate))
							AND (@iTransactionDate >= ISNULL(wfp1.Start_Date, @iTransactionDate))


					) wfp 
					ON w.Weightometer_Id = wfp.Weightometer_Id
			WHERE 	-- match if the weightometer is at the expected location OR at a child location of the expected location
					-- this is required in some cases (such as for OHP5) where the data is imported at the hub level but the weightometer is assigned to a site
					(wl.Location_Id = @iSiteLocationId OR (l.Parent_Location_Id = @iSiteLocationId))
					AND w.Weightometer_Id Not Like '%Corrected'
			ORDER BY (
					CASE WHEN COALESCE(wfp.Source_Crusher_Id, wfp.Source_Mill_Id, Cast(wfp.Source_Stockpile_Id As Varchar)) IS NOT NULL THEN 10 ELSE 0 END
					+ CASE WHEN COALESCE(wfp.Destination_Crusher_Id, wfp.Destination_Mill_Id, Cast(wfp.Destination_Stockpile_Id As Varchar)) IS NOT NULL THEN 10 ELSE 0 END
					+ CASE WHEN wl.Location_Id = @iSiteLocationId THEN 1 ELSE 0 END -- favour exact location matches
					) DESC
					
		END

		DECLARE @sourceLocationIdOverride INT
		DECLARE @destinationLocationIdOverride INT
		DECLARE @sourceLocationParentId INT
		
		-- if the source is a stockpile (post crusher)
		IF (@iSourceType = 'post crusher') 
		BEGIN
			-- get the location Id (considering overrides)
			SELECT @sourceLocationIdOverride = sld.Location_Id
			FROM Stockpile s
				INNER JOIN BhpbioStockpileLocationDate sld ON sld.Stockpile_Id = s.Stockpile_ID
					AND @iTransactionDate BETWEEN sld.Start_Date and sld.End_Date
			WHERE s.Stockpile_Id = @iSourceStockpileId
		END

		-- if the source is a crusher		
		IF (@iSourceType = 'crusher') 
		BEGIN
			-- get the location Id (considering overrides)
			SELECT @sourceLocationIdOverride = clo.Location_Id
			FROM dbo.GetBhpbioCrusherLocationWithOverride(@startDateRangeToCheck, @endDateRangeToCheck) clo
			WHERE clo.Crusher_Id = @iSourceCrusherId
				AND @iTransactionDate BETWEEN clo.IncludeStart and clo.IncludeEnd
		END
		
		-- if the destination is a stockpile (post crusher)
		IF (@iDestinationType = 'post crusher') 
		BEGIN
			-- get the location Id (considering overrides)
			SELECT @destinationLocationIdOverride = sld.Location_Id
			FROM Stockpile s
				INNER JOIN BhpbioStockpileLocationDate sld ON sld.Stockpile_Id = s.Stockpile_ID
					AND @iTransactionDate BETWEEN sld.Start_Date and sld.End_Date
			WHERE s.Stockpile_Id = @iDestinationStockpileId
		END
		
		-- determine the parent of the source location
		SELECT @sourceLocationParentId = Parent_Location_Id 
		FROM Location 
		WHERE Location_ID = @sourceLocationIdOverride
		
		-- ensure that the source and destination are at the same location, in consideration of overrides (dynamic location hierarchy)
		-- or that the source is a child of the destination
		IF (@sourceLocationIdOverride IS NOT NULL AND @destinationLocationIdOverride IS NOT NULL
				AND @sourceLocationIdOverride <> @destinationLocationIdOverride
				AND @sourceLocationParentId <> @destinationLocationIdOverride)
		BEGIN
			SET @IsError = 1
			SET @ErrorDescription = 'There is a site mismatch between source and destination locations.  Please review your location assignments.'
		END

		IF @WeightometerId IS NULL
		BEGIN
			SET @IsError = 1
			SET @ErrorDescription = 'Unable to determine an appropriate weightometer.'
		END

		-- return the results
		SET @oWeightometerId = @WeightometerId
		SET @oIsError = @IsError
		SET @oErrorDescription = @ErrorDescription

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

GRANT EXECUTE ON dbo.GetBhpbioProductionWeightometer TO BhpbioGenericManager
GO
