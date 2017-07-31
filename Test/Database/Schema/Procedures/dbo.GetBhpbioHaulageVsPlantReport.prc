IF OBJECT_ID('dbo.GetBhpbioHaulageVsPlantReport') IS NOT NULL
	DROP PROCEDURE dbo.GetBhpbioHaulageVsPlantReport
GO
 
CREATE PROCEDURE dbo.GetBhpbioHaulageVsPlantReport
(
	@iLocationId INT,
	@iFromDate DATETIME,
	@iToDate DATETIME
)
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @FromDate DATETIME
	DECLARE @ToDate DATETIME
	
	-- in this report we actually don't want to exclude stockpiles, but this option
	-- allows it to be easier turned on later if it is needed
	DECLARE @ExcludeStockpilesGenericReports BIT
	SET @ExcludeStockpilesGenericReports = 0

	DECLARE @Crusher TABLE
	(
		CrusherId VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		IncludeStart DateTime NOT NULL,
		IncludeEnd DateTime NOT NULL
		
		PRIMARY KEY (CrusherId)
	)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioHaulageVsPlantReport',
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
		-- when dealing with haulage vs plant we need to realise the following:
		-- 1. only WEIGHTOMETERS can deliver to a plant
		-- 2. only CRUSHERS allow Haulage to be converted into Weightometer flows
		-- hence this is a haulage vs weightometer around crushers report

		-- The location concerned is the crusher's location
		
		-- Summary: No Date/Shift breakdown
		-- Full (No split-by-shift): Date breakdown
		-- Full (split-by-shift): Date/Shift breakdown

		-- determine the crushers
		INSERT INTO @Crusher
			(CrusherId, IncludeStart, IncludeEnd)
		SELECT DISTINCT Crusher_Id, IncludeStart, IncludeEnd
		FROM
			(
				SELECT cl.Crusher_Id, cl.IncludeStart, cl.IncludeEnd
				FROM dbo.GetBhpbioCrusherLocationWithOverride(@iFromDate, @iToDate) AS cl
					INNER JOIN dbo.GetLocationSubtree(@iLocationId) AS ls
						ON (cl.Location_Id = ls.Location_Id)

				UNION ALL

				SELECT Crusher_Id, @iFromDate, @iToDate
				FROM dbo.Crusher
				WHERE Crusher_Id NOT IN
					(
						SELECT Crusher_Id
						FROM dbo.GetBhpbioCrusherLocationWithOverride(@iFromDate, @iToDate)
					)
			) AS sub
			-- exclude Crusher to Crusher deliveries
			-- where it's a weightometer delivering to a crusher
			-- the recalc cannot actually handle this situation when weightometer and haulage delivers to the same crusher
			-- this is a haulage vs weightometer report
		WHERE NOT EXISTS
			(
				SELECT 1
				FROM dbo.WeightometerFlowPeriodView AS wfp2
				WHERE wfp2.Destination_Crusher_Id = sub.Crusher_Id
			)

		-- calculate the effective start/end dates
		IF @iFromDate IS NULL
		BEGIN
			SET @FromDate =
				(
					SELECT
						CASE
							WHEN (MIN(h.Haulage_Date) < MIN(ws.Weightometer_Sample_Date))
								OR (MIN(ws.Weightometer_Sample_Date) IS NULL) THEN MIN(h.Haulage_Date)
							ELSE MIN(ws.Weightometer_Sample_Date)
						END
					FROM @Crusher AS c
						LEFT OUTER JOIN dbo.Haulage AS h
							ON (h.Destination_Crusher_Id = c.CrusherId
								AND h.Haulage_State_Id IN ('N', 'A')
								AND h.Child_Haulage_Id IS NULL
								AND h.Haulage_Date BETWEEN c.IncludeStart and c.IncludeEnd)
						LEFT OUTER JOIN dbo.WeightometerSampleView AS ws
							ON (ws.Destination_Crusher_Id = c.CrusherId
								AND ws.Weightometer_Sample_Date BETWEEN c.IncludeStart and c.IncludeEnd)
				)
		END
		ELSE
		BEGIN
			SET @FromDate = @iFromDate
		END

		IF @iToDate IS NULL
		BEGIN
			SET @ToDate =
				(
					SELECT
						CASE
							WHEN (MAX(h.Haulage_Date) < MAX(ws.Weightometer_Sample_Date))
								OR (MAX(ws.Weightometer_Sample_Date) IS NULL) THEN MAX(h.Haulage_Date)
							ELSE MAX(ws.Weightometer_Sample_Date)
						END
					FROM @Crusher AS c
						LEFT OUTER JOIN dbo.Haulage AS h
							ON (h.Destination_Crusher_Id = c.CrusherId
								AND h.Haulage_State_Id IN ('N', 'A')
								AND h.Child_Haulage_Id IS NULL
								AND h.Haulage_Date BETWEEN c.IncludeStart and c.IncludeEnd)
						LEFT OUTER JOIN dbo.WeightometerSampleView AS ws
							ON (ws.Destination_Crusher_Id = c.CrusherId
								AND ws.Weightometer_Sample_Date BETWEEN c.IncludeStart and c.IncludeEnd)
				)
		END
		ELSE
		BEGIN
			SET @ToDate = @iToDate
		END

		-- collate the result at the lowest level
		SELECT c.CrusherId AS CrusherId,
			dl.This_Date AS TransactionDate, s.Shift AS TransactionShift,
			ISNULL(h.TotalTonnes, 0.0) AS TotalHaulageTonnes,
			ISNULL(h.DigblockTonnes, 0.0) AS DigblockHaulageTonnes,
			ISNULL(h.StockpileTonnes, 0.0) AS StockpileHaulageTonnes,
			ISNULL(ws.Effective_Tonnes, 0.0) AS ConveyorTonnes
		FROM @Crusher AS c
			CROSS JOIN dbo.GetDateList(@FromDate, @ToDate, 'Day', 1) AS dl
			CROSS JOIN dbo.ShiftType AS s
			-- collect the haulage flows
			LEFT JOIN
				(
					SELECT DISTINCT Haulage_Date, Haulage_Shift, Destination_Crusher_Id,
						SUM(Tonnes) AS TotalTonnes,
						SUM(CASE WHEN Source_Digblock_Id IS NOT NULL THEN Tonnes ELSE 0 END) AS DigblockTonnes,
						SUM(CASE WHEN Source_Stockpile_Id IS NOT NULL THEN Tonnes ELSE 0 END) AS StockpileTonnes
					FROM dbo.Haulage h
						LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('GenericReports') xsrc ON xsrc.StockpileId = h.Source_Stockpile_Id
						LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('GenericReports') xdest ON xdest.StockpileId = h.Destination_Stockpile_Id
						LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('HaulageVsPlantReport') xhvpSource ON xhvpSource.StockpileId = h.Source_Stockpile_Id
						LEFT OUTER JOIN dbo.GetBhpbioExcludeStockpileGroup('HaulageVsPlantReport') xhvpDest ON xhvpDest.StockpileId = h.Destination_Stockpile_Id
					WHERE Haulage_State_Id IN ('N', 'A')
						AND Child_Haulage_Id IS NULL
						AND Destination_Crusher_Id IS NOT NULL
						AND (xsrc.StockpileId IS NULL Or @ExcludeStockpilesGenericReports = 0) -- No movements from excluded groups.
						AND (xdest.StockpileId IS NULL Or @ExcludeStockpilesGenericReports = 0) -- No movements to excluded groups.
						AND (xhvpSource.StockpileId IS NULL) -- No movements from excluded groups specifically excluded for this report.
						AND (xhvpDest.StockpileId IS NULL) -- No movements to excluded groups specifically excluded for this report.
					GROUP BY Haulage_Date, Haulage_Shift, Destination_Crusher_Id
				) AS h
				ON (h.Haulage_Date = dl.This_Date
					AND h.Haulage_Shift = s.Shift
					AND h.Destination_Crusher_Id = c.CrusherId
					AND h.Haulage_Date BETWEEN c.IncludeStart AND c.IncludeEnd)
			-- collect the weightometer flows
			LEFT JOIN
				(
					SELECT ws.Weightometer_Sample_Date, ws.Weightometer_Sample_Shift, ws.Source_Crusher_Id,
						SUM(ws.Effective_Tonnes) AS Effective_Tonnes
					FROM dbo.WeightometerSampleView AS ws
						INNER JOIN dbo.Weightometer AS w
							ON (ws.Weightometer_Id = w.Weightometer_Id)
					WHERE w.Weightometer_Type_Id IN ('L1', 'CVF+L1')
					GROUP BY ws.Weightometer_Id, ws.Weightometer_Sample_Date, ws.Weightometer_Sample_Shift, ws.Source_Crusher_Id
				) AS ws
				ON (ws.Weightometer_Sample_Date = dl.This_Date
					AND ws.Weightometer_Sample_Shift = s.Shift
					AND ws.Source_Crusher_Id = c.CrusherId)

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

GRANT EXECUTE ON dbo.GetBhpbioHaulageVsPlantReport TO CoreReporting
GRANT EXECUTE ON dbo.GetBhpbioHaulageVsPlantReport TO BhpbioGenericManager
GO
