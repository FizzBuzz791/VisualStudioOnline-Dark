IF OBJECT_ID('dbo.UpdateBhpbioReconciliationMovement') IS NOT NULL
     DROP PROCEDURE dbo.UpdateBhpbioReconciliationMovement  
GO 
  
CREATE PROCEDURE dbo.UpdateBhpbioReconciliationMovement
(
	@iPitLocationId INT = NULL
)
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'UpdateBhpbioReconciliationMovement',
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

		DECLARE @blockLocationIdImpactDetectionLookbackMonths INTEGER
		SET @blockLocationIdImpactDetectionLookbackMonths = 12

		-- work out the set of recent recon movements without a BlockLocationId
		-- prior to the script executing
		DECLARE @birmUnallocatedLocationId TABLE([Site] varchar(9), Orebody varchar(2), Pit varchar(10), Bench varchar(4), PatternNumber VARCHAR(4), DateFrom DateTime, BlockName VARCHAR(5))
		
		DECLARE @cutoff DATETIME
		SET @cutoff= DATEADD(month, -1 * @blockLocationIdImpactDetectionLookbackMonths, dbo.GetDateMonth(GetDate()))
		
		INSERT INTO @birmUnallocatedLocationId([Site],Orebody,Pit,Bench,PatternNumber,DateFrom,BlockName)
		SELECT DISTINCT m.[Site], m.Orebody, m.Pit, m.Bench, m.PatternNumber, m.DateFrom, m.BlockName
		FROM dbo.BhpbioImportReconciliationMovement AS m
		WHERE m.DateFrom >= @cutoff
		AND m.BlockLocationId IS NULL
		
		CREATE TABLE #LocationHierarchy 
		(
			LocationId INT,
			Name VARCHAR(31) COLLATE DATABASE_DEFAULT,
			Type VARCHAR(255) COLLATE DATABASE_DEFAULT,
			ParentLocationId INT,
			
			PRIMARY KEY (LocationId)
		)
		
		CREATE NONCLUSTERED INDEX IX_ParentLocationId ON #LocationHierarchy (ParentLocationId, Name, Type)
		
		INSERT INTO #LocationHierarchy
		SELECT l.Location_Id, l.Name, lt.Description, ISNULL(l.Parent_Location_Id, 0)
		FROM dbo.Location AS l
			INNER JOIN dbo.LocationType AS lt
				ON (l.Location_Type_Id = lt.Location_Type_Id)
		
		-- work out the impacted months for later outlier processing
		DECLARE @ImpactedMonths TABLE (DateFrom DATETIME)
		
		-- determine the set of distinct months with updates
		INSERT INTO @ImpactedMonths(DateFrom)
		SELECT DISTINCT dbo.getDateMonth(mov.DateFrom)
		FROM dbo.BhpbioImportReconciliationMovementStage AS s
			INNER JOIN dbo.BhpbioImportReconciliationMovement AS mov
				ON (mov.BlockNumber = s.BlockNumber
					AND mov.BlockName = s.BlockName
					AND mov.Site = s.Site
					AND mov.Orebody = s.Orebody
					AND mov.Pit = s.Pit
					AND mov.Bench = s.Bench
					AND mov.PatternNumber = s.PatternNumber
					AND mov.DateFrom = s.DateFrom)
			LEFT OUTER JOIN dbo.DigblockLocation AS dl
				ON dl.Location_Id = mov.BlockLocationId
			LEFT OUTER JOIN dbo.BhpbioApprovalDigblock AS bad
				ON bad.DigblockId = dl.Digblock_Id
				AND bad.ApprovedMonth = dbo.getDateMonth(mov.DateFrom)
		WHERE bad.DigblockId IS NULL
			AND ( -- and the data is different
				mov.LastModifiedDate <> s.LastModifiedDate OR
				mov.LastModifiedUser <> s.LastModifiedUser OR
				mov.MinedPercentage <> s.MinedPercentage)
		
		-- update existing, only where the blastblock is not approved.
		UPDATE mov
		SET	DateTo = s.DateTo,
			LastModifiedDate = s.LastModifiedDate,
			LastModifiedUser = s.LastModifiedUser,
			MinedPercentage = s.MinedPercentage
		FROM dbo.BhpbioImportReconciliationMovementStage AS s
			INNER JOIN dbo.BhpbioImportReconciliationMovement AS mov
				ON (mov.BlockNumber = s.BlockNumber
					AND mov.BlockName = s.BlockName
					AND mov.Site = s.Site
					AND mov.Orebody = s.Orebody
					AND mov.Pit = s.Pit
					AND mov.Bench = s.Bench
					AND mov.PatternNumber = s.PatternNumber
					AND mov.DateFrom = s.DateFrom)
			LEFT OUTER JOIN dbo.DigblockLocation AS dl
				ON dl.Location_Id = mov.BlockLocationId
			LEFT OUTER JOIN dbo.BhpbioApprovalDigblock AS bad
				ON bad.DigblockId = dl.Digblock_Id
				AND bad.ApprovedMonth = dbo.getDateMonth(mov.DateFrom)
		WHERE bad.DigblockId IS NULL

		-- work out the months impacted by new records (for later outlier processing)
		INSERT INTO @ImpactedMonths(DateFrom)
		SELECT DISTINCT dbo.getDateMonth(s.DateFrom)
		FROM dbo.BhpbioImportReconciliationMovementStage AS s
			LEFT JOIN dbo.BhpbioImportReconciliationMovement AS mov
				ON (mov.BlockNumber = s.BlockNumber
					AND mov.BlockName = s.BlockName
					AND mov.Site = s.Site
					AND mov.Orebody = s.Orebody
					AND mov.Pit = s.Pit
					AND mov.Bench = s.Bench
					AND mov.PatternNumber = s.PatternNumber
					AND mov.DateFrom = s.DateFrom)
		WHERE mov.BlockNumber IS NULL
			AND NOT EXISTS (SELECT * FROM @ImpactedMonths im2 WHERE im2.DateFrom = dbo.getDateMonth(s.DateFrom))
		
		-- insert new
		INSERT INTO dbo.BhpbioImportReconciliationMovement
		(
			BlockNumber, BlockName, Site, Orebody, Pit, Bench, PatternNumber,
			DateFrom, DateTo, LastModifiedDate, LastModifiedUser, MinedPercentage
		)
		SELECT s.BlockNumber, s.BlockName, s.Site, s.Orebody, s.Pit, s.Bench, s.PatternNumber,
			s.DateFrom, s.DateTo, s.LastModifiedDate, s.LastModifiedUser, s.MinedPercentage
		FROM dbo.BhpbioImportReconciliationMovementStage AS s
			LEFT JOIN dbo.BhpbioImportReconciliationMovement AS mov
				ON (mov.BlockNumber = s.BlockNumber
					AND mov.BlockName = s.BlockName
					AND mov.Site = s.Site
					AND mov.Orebody = s.Orebody
					AND mov.Pit = s.Pit
					AND mov.Bench = s.Bench
					AND mov.PatternNumber = s.PatternNumber
					AND mov.DateFrom = s.DateFrom)
		WHERE mov.BlockNumber IS NULL
		
		-- calculate the block's location id (based on Pit Code)
		UPDATE m
		SET BlockLocationId = blocklh.LocationId
		FROM dbo.BhpbioImportReconciliationMovement AS m
			-- note that we join here to the Block Holding system
			INNER JOIN Staging.StageBlock AS b
				ON (b.Site = m.Site
					AND b.Orebody = m.Orebody
					AND b.Pit = m.Pit
					AND b.Bench = m.Bench
					AND b.PatternNumber = m.PatternNumber
					AND b.BlockName = m.BlockName)
			LEFT JOIN Staging.StageDataMap mp ON mp.ContextKey = 'Site' AND mp.[From] = b.[Site]
			INNER JOIN #LocationHierarchy AS sitelh
				ON (sitelh.Name = IsNull(mp.[To], m.Site) -- join on site names, but take any name mapping into account
					AND sitelh.Type = 'Site')
			INNER JOIN #LocationHierarchy AS pitlh
				ON (pitlh.Name = COALESCE(b.AlternativePitCode, m.Pit)
					AND pitlh.Type = 'Pit'
					AND pitlh.ParentLocationId = sitelh.LocationId)
			INNER JOIN #LocationHierarchy AS benchlh
				ON (benchlh.Name = m.Bench
					AND benchlh.Type = 'Bench'
					AND benchlh.ParentLocationId = pitlh.LocationId)
			INNER JOIN #LocationHierarchy AS blastlh
				ON (blastlh.Name = m.PatternNumber
					AND blastlh.Type = 'Blast'
					AND blastlh.ParentLocationId = benchlh.LocationId)
			INNER JOIN #LocationHierarchy blocklh
				ON (blocklh.Name = m.BlockName
					AND blocklh.Type = 'Block'
					AND blocklh.ParentLocationId = blastlh.LocationId)
			LEFT JOIN dbo.BhpbioApprovalData AS BADA
				ON (BADA.LocationId = pitlh.LocationId
					AND BADA.ApprovedMonth = dbo.getDateMonth(m.DateFrom))
			LEFT JOIN dbo.BhpbioApprovalData AS BADA2
				ON (BADA2.LocationId = sitelh.LocationId
					AND BADA2.ApprovedMonth = dbo.getDateMonth(m.DateFrom))
		WHERE (BlockLocationId IS NULL OR BlockLocationId <> blocklh.LocationId)
			AND blocklh.LocationId IS NOT NULL
			AND BADA.LocationId IS NULL
			AND BADA2.LocationId IS NULL
			AND (pitlh.LocationId = @iPitLocationId OR @iPitLocationId IS NULL)

		-- check if any movements previously unallocated in terms of location Id
		-- are now allocated... treat these as impacts requiring outlier detection also
		INSERT INTO @ImpactedMonths(DateFrom)
		SELECT DISTINCT dbo.GetDateMonth(m.DateFrom)
		FROM @birmUnallocatedLocationId un
		INNER JOIN dbo.BhpbioImportReconciliationMovement AS m
			ON m.[Site] = un.[Site] AND m.Orebody = un.Orebody and m.Pit = un.Pit and m.Bench = un.Bench and m.PatternNumber = un.PatternNumber AND m.DateFrom = un.DateFrom AND m.BlockName = un.BlockName
		WHERE m.BlockLocationId IS NOT NULL
			AND NOT EXISTS (SELECT * FROM @ImpactedMonths im WHERE im.DateFrom = dbo.GetDateMonth(m.DateFrom))

		--
		-- There can be circumstances where there are multiple records with the same BlockLocationId for the
		-- same month, this causes all sorts of key constraint errors later on, so we need to remove records like
		-- like. 
		--
		-- The solution is to set the BlockLocationId to null if it doesn't have the new LastModifiedDate
		--
		-- If the block is already approved, then the BlockLocationId should never get updated in the previous
		-- code and the duplicates never created, so this update doesn't have to explicitly handle this case
		--
		UPDATE rm
			SET BlockLocationId = null
		FROM dbo.BhpbioImportReconciliationMovement AS rm
			INNER JOIN (
				-- this will return all Depletions with a location in Rec with the latest modifed
				-- date for that block/date combination. Later we can check if this is not the newest
				-- one, and set all the locations to null
				Select 
					DateFrom,
					DateTo,
					BlockLocationId,
					Max(LastModifiedDate) AS LastModifiedDate
				FROM BhpbioImportReconciliationMovement rm2
				GROUP BY BlockLocationId, DateFrom, DateTo
			) nd ON nd.BlockLocationId = rm.BlockLocationId 
				AND nd.DateFrom = rm.DateFrom 
				AND nd.DateTo = rm.DateTo
		WHERE rm.LastModifiedDate != nd.LastModifiedDate

		DROP TABLE #LocationHierarchy
				
		-- raise the outlier detection queue entries for the impacted months
		DECLARE curImpactedMonth CURSOR FOR SELECT DateFrom FROM @ImpactedMonths ORDER BY DateFrom
		
		OPEN curImpactedMonth
		DECLARE @month DATETIME
		
		FETCH NEXT FROM curImpactedMonth INTO @month
		WHILE @@FETCH_STATUS = 0
		BEGIN
			-- raise an outlie detection entry for this month
			exec dbo.AddBhpbioDataRetrievalQueueEntry @month
			FETCH NEXT FROM curImpactedMonth INTO @month
		END
		
		CLOSE curImpactedMonth
		DEALLOCATE curImpactedMonth

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

GRANT EXECUTE ON dbo.UpdateBhpbioReconciliationMovement TO BhpbioGenericManager
GO
