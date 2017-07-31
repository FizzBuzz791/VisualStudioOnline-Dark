IF OBJECT_ID('dbo.GetBhpbioStockpileBalanceReport') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioStockpileBalanceReport 
GO 
  
CREATE PROCEDURE dbo.GetBhpbioStockpileBalanceReport 
( 
	@iLocationId INT,
    @iStockpileId INT,
	@iStartDate DATETIME,
	@iStartShift CHAR(1),
	@iEndDate DATETIME,
	@iEndShift CHAR(1),
	@iIsVisible BIT
) 
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @StartDate DATETIME
	DECLARE @StartShift CHAR(1)
	DECLARE @EndDate DATETIME
	DECLARE @EndShift CHAR(1)
	DECLARE @PrevStartDate DATETIME
	DECLARE @PrevStartShift CHAR(1)

	DECLARE @Result TABLE
	(
		StockpileId INT NOT NULL,
		StockpileName VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialTypeId INT NOT NULL,
		MaterialAbbreviation VARCHAR(15) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialDescription VARCHAR(63) COLLATE DATABASE_DEFAULT NOT NULL,
		OpeningBalanceTonnes FLOAT NOT NULL,
		TransactionToTonnes FLOAT NOT NULL,
		TransactionFromTonnes FLOAT NOT NULL,
		AdjustmentTonnes FLOAT NOT NULL,
		ClosingBalanceTonnes FLOAT NOT NULL,
		PRIMARY KEY (StockpileId)
	)

	DECLARE @StockpileLookup TABLE
	(
		StockpileId INT NOT NULL,
		IncludeStart DATETIME,
		IncludeEnd DATETIME,
		PRIMARY KEY (StockpileId, IncludeStart,IncludeEnd)
	)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioStockpileBalanceReport',
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
		-- determine the start/end dates
		IF @iStartDate IS NULL
		BEGIN
			SET @StartDate =
				(
					SELECT MIN(Start_Date)
					FROM dbo.StockpileBuild
				)
			SET @StartShift = dbo.GetFirstShiftType()
		END
		ELSE
		BEGIN
			SET @StartDate = @iStartDate
			IF @iStartShift IS NULL
			BEGIN
				SET @StartShift = dbo.GetFirstShiftType()
			END
			ELSE
			BEGIN
				SET @StartShift = @iStartShift
			END
		END

		IF @iEndDate IS NULL
		BEGIN
			SET @EndDate =
				(
					SELECT MAX(Start_Date)
					FROM dbo.StockpileBuild
				)
			SET @EndShift = dbo.GetLastShiftType()
		END
		ELSE
		BEGIN
			SET @EndDate = @iEndDate
			IF @iEndShift IS NULL
			BEGIN
				SET @EndShift = dbo.GetLastShiftType()
			END
			ELSE
			BEGIN
				SET @EndShift = @iEndShift
			END
		END

		-- get the previous date/shift
		EXEC dbo.GetPreviousDateShift
			@Date = @StartDate,
			@Shift = @StartShift,
			@Previous_Date = @PrevStartDate OUTPUT,
			@Previous_Shift = @PrevStartShift OUTPUT

		-- create a short-list of stockpiles
		INSERT INTO @StockpileLookup
			(StockpileId,IncludeStart,IncludeEnd)
		SELECT DISTINCT s.Stockpile_Id,sub.IncludeStart,sub.IncludeEnd
		FROM
			(
				SELECT Stockpile_Id,@StartDate [IncludeStart],@EndDate [IncludeEnd]
				FROM dbo.Stockpile AS s
				WHERE NOT EXISTS
					(
						SELECT 1
						FROM dbo.BhpbioStockpileLocationDate AS sl
						WHERE s.Stockpile_Id = sl.Stockpile_Id
						AND	(sl.[Start_Date] BETWEEN @StartDate AND @EndDate
							OR sl.End_Date BETWEEN @StartDate AND @EndDate
							OR (sl.[Start_Date] < @StartDate AND sl.End_Date >@EndDate))
					)

				UNION ALL

				SELECT DISTINCT Stockpile_Id,ls.IncludeStart,ls.IncludeEnd
				FROM dbo.BhpbioStockpileLocationDate AS sl
					--INNER JOIN dbo.GetLocationSubtree(@iLocationId) AS ls
					INNER JOIN dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId,0,NULL,@StartDate,@EndDate) AS ls
						ON (sl.Location_Id = ls.LocationId)
						AND	(sl.[Start_Date] BETWEEN ls.IncludeStart AND ls.IncludeEnd
							OR sl.End_Date BETWEEN ls.IncludeStart AND ls.IncludeEnd
							OR (sl.[Start_Date] < ls.IncludeStart AND sl.End_Date > ls.IncludeEnd))
			) AS sub
			INNER JOIN dbo.Stockpile AS s
				ON (s.Stockpile_Id = sub.Stockpile_Id)
		WHERE s.Stockpile_Id = ISNULL(@iStockpileId, s.Stockpile_Id)
			AND s.Is_Visible = ISNULL(@iIsVisible, s.Is_Visible)

		-- collect the results
		INSERT INTO @Result
		(
			StockpileId, StockpileName, MaterialTypeId, MaterialAbbreviation, MaterialDescription,
			OpeningBalanceTonnes, TransactionToTonnes,
			TransactionFromTonnes,
			AdjustmentTonnes,
			ClosingBalanceTonnes
		)
		SELECT s.Stockpile_Id, s.Stockpile_Name, mt.Material_Type_Id, mt.Abbreviation, mt.Description,
			ISNULL(openBalance.Tonnes, 0.0), ISNULL(transactionTo.TransactionTonnes, 0.0),
			ISNULL(transactionFrom.TransactionTonnes, 0.0),
			ISNULL(transactionTo.AdjustmentTonnes, 0.0) - ISNULL(transactionFrom.AdjustmentTonnes, 0.0),
			ISNULL(closingBalance.Tonnes, 0.0)
		FROM dbo.Stockpile AS s
			-- ensure the stockpiles match the required locations
			INNER JOIN @StockpileLookup AS sl
				ON (sl.StockpileId = s.Stockpile_Id)
			-- stockpiles must have builds in the required date range
			INNER JOIN
				(
					SELECT Stockpile_Id
					FROM dbo.StockpileBuild
					WHERE 
						(
							(End_Date >= @StartDate AND dbo.CompareDateShift(End_Date, End_Shift, '>=', @StartDate, @StartShift) = 1)
							OR End_Date IS NULL
						)
						AND
						(
							(Start_Date <= @EndDate AND dbo.CompareDateShift(Start_Date, Start_Shift, '<=', @EndDate, @EndShift) = 1)
							OR Start_Date IS NULL
						)
				) AS sb
				ON (s.Stockpile_Id = sb.Stockpile_Id)
			-- capture the material type info
			INNER JOIN dbo.MaterialType AS mt
				ON (mt.Material_Type_Id = s.Material_Type_Id)
			-- opening balance based on prev stockpile balance + start build
			LEFT OUTER JOIN
				(
					SELECT s.Stockpile_Id AS Stockpile_Id,
						ISNULL(method1.Tonnes, method2.Tonnes) AS Tonnes
					FROM dbo.Stockpile AS s
						LEFT OUTER JOIN
						(
							SELECT Stockpile_Id, SUM(Tonnes) AS Tonnes
							FROM dbo.DataProcessStockpileBalance
							WHERE Data_Process_Stockpile_Balance_Date = @PrevStartDate
								AND Data_Process_Stockpile_Balance_Shift = @PrevStartShift
							GROUP BY Stockpile_Id
						) AS method1
						ON (method1.Stockpile_Id = s.Stockpile_Id)
						LEFT OUTER JOIN
						(
							SELECT sb.Stockpile_Id, SUM(sbc.Start_Tonnes) AS Tonnes
							FROM dbo.StockpileBuildComponent AS sbc
								INNER JOIN dbo.StockpileBuild AS sb
									ON (sbc.Stockpile_Id = sb.Stockpile_Id
										AND sbc.Build_Id = sb.Build_Id)
							WHERE sb.Start_Date = @StartDate
								AND sb.Start_Shift = @StartShift
							GROUP BY sb.Stockpile_ID
						) AS method2
						ON (method2.Stockpile_Id = s.Stockpile_Id)
				) AS openBalance
				ON (s.Stockpile_Id = openBalance.Stockpile_Id)
			-- tonnes added
			LEFT OUTER JOIN
				(
					SELECT Destination_Stockpile_Id AS Stockpile_Id,
						SUM(CASE WHEN Stockpile_Adjustment_Id IS NULL THEN Tonnes ELSE 0.0 END) AS TransactionTonnes,
						SUM(CASE WHEN Stockpile_Adjustment_Id IS NOT NULL THEN Tonnes ELSE 0.0 END) AS AdjustmentTonnes
					FROM dbo.DataProcessTransaction





					WHERE Data_Process_Transaction_Date BETWEEN @StartDate AND @EndDate
						AND dbo.CompareDateShift(Data_Process_Transaction_Date, Data_Process_Transaction_Shift, '>=', @StartDate, @StartShift) = 1
						AND dbo.CompareDateShift(Data_Process_Transaction_Date, Data_Process_Transaction_Shift, '<=', @EndDate, @EndShift) = 1

					GROUP BY Destination_Stockpile_Id
				) AS transactionTo
				ON (s.Stockpile_Id = transactionTo.Stockpile_Id)
			-- tonnes removed
			LEFT OUTER JOIN
				(
					SELECT Source_Stockpile_Id AS Stockpile_Id,
						SUM(CASE WHEN Stockpile_Adjustment_Id IS NULL THEN Tonnes ELSE 0.0 END) AS TransactionTonnes,
						SUM(CASE WHEN Stockpile_Adjustment_Id IS NOT NULL THEN Tonnes ELSE 0.0 END) AS AdjustmentTonnes
					FROM dbo.DataProcessTransaction





					WHERE Data_Process_Transaction_Date BETWEEN @StartDate AND @EndDate
						AND dbo.CompareDateShift(Data_Process_Transaction_Date, Data_Process_Transaction_Shift, '>=', @StartDate, @StartShift) = 1
						AND dbo.CompareDateShift(Data_Process_Transaction_Date, Data_Process_Transaction_Shift, '<=', @EndDate, @EndShift) = 1

					GROUP BY Source_Stockpile_Id
				) AS transactionFrom
				ON (s.Stockpile_Id = transactionFrom.Stockpile_Id)
			-- closing balance
			LEFT OUTER JOIN
				(
					SELECT Stockpile_Id, SUM(Tonnes) AS Tonnes
					FROM
						(
							-- locate any builds that close before the date we're querying for the closing balance
							-- the *latest* balance record is located and the closing tonnes are used
							SELECT sb.Stockpile_Id, SUM(Tonnes) AS Tonnes
							FROM dbo.StockpileBuild AS sb
								INNER JOIN dbo.DataProcessStockpileBalance AS dpsb
									ON (sb.Stockpile_Id = dpsb.Stockpile_Id
										AND sb.Build_Id = dpsb.Build_Id
										AND sb.Last_Recalc_Date = dpsb.Data_Process_Stockpile_Balance_Date
										AND sb.Last_Recalc_Shift = dpsb.Data_Process_Stockpile_Balance_Shift)
							WHERE sb.End_Date <= @EndDate
								AND dbo.CompareDateShift(sb.End_Date, sb.End_Shift, '<', @EndDate, @EndShift) = 1
							GROUP BY sb.Stockpile_Id

							UNION ALL

							SELECT Stockpile_Id, SUM(Tonnes) AS Tonnes
							FROM dbo.DataProcessStockpileBalance
							WHERE Data_Process_Stockpile_Balance_Date = @EndDate
								AND Data_Process_Stockpile_Balance_Shift = @EndShift
							GROUP BY Stockpile_Id
						) AS sub
					GROUP BY Stockpile_Id
				) AS closingBalance
				ON (s.Stockpile_Id = closingBalance.Stockpile_Id)

		-- return the results joined on the groups
		-- we may get dupes but the consuming report will group these back out
		SELECT r.StockpileId, sgs.Stockpile_Group_Id AS StockpileGroupId,
			r.StockpileName, r.MaterialTypeId, r.MaterialAbbreviation, r.MaterialDescription,
			r.OpeningBalanceTonnes, r.TransactionToTonnes, r.TransactionFromTonnes, 
			r.AdjustmentTonnes, r.ClosingBalanceTonnes
		FROM @Result AS r
			LEFT OUTER JOIN dbo.StockpileGroupStockpile AS sgs
				ON (r.StockpileId = sgs.Stockpile_Id)

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

GRANT EXECUTE ON dbo.GetBhpbioStockpileBalanceReport TO CoreReporting
GRANT EXECUTE ON dbo.GetBhpbioStockpileBalanceReport TO BhpbioGenericManager
GO


/* testing

EXEC dbo.GetBhpbioStockpileBalanceReport
	@iLocationId = 5,
    @iStockpileId = NULL,
	@iStartDate = '02-APR-2008',
	@iStartShift = NULL,
	@iEndDate = '05-APR-2008',
	@iEndShift = NULL,
	@iIsVisible = NULL
GO

*/

