IF OBJECT_ID('dbo.GetBhpbioApprovalDigblockList') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioApprovalDigblockList  
GO 
  
CREATE PROCEDURE dbo.GetBhpbioApprovalDigblockList
(
	@iLocationId INT,
	@iMonthFilter DATETIME,
	@iRecordLimit INT
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @LocationId INT
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	DECLARE @MonthDate DATETIME
	DECLARE @EndMonthDate DATETIME
	DECLARE @HauledFieldId VARCHAR(31)
	DECLARE @SurveyedFieldId VARCHAR(31)
	
	-- Create a table used to store Live Results
	DECLARE @LiveResults TABLE
	(
		DigblockId VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialTypeId INTEGER,
		GeologyTonnes FLOAT NULL,
		MiningTonnes FLOAT NULL,
		ShortTermGeologyTonnes FLOAT NULL,
		GradeControlTonnes FLOAT NULL,
		GeologyVolume FLOAT NULL,
		MiningVolume FLOAT NULL,
		ShortTermGeologyVolume FLOAT NULL,
		GradeControlVolume FLOAT NULL,
		GeologyModelFilename VARCHAR(200) NULL,
		MiningModelFilename VARCHAR(200) NULL,
		ShortTermGeologyModelFilename VARCHAR(200) NULL,
		GradeControlModelFilename VARCHAR(200) NULL,
		MonthlyMinedPercent FLOAT NULL,
		TotalMinedPercent FLOAT NULL,
		HauledTonnes FLOAT NULL,
		SurveyedTonnes FLOAT NULL,
		BestTonnes FLOAT NULL,
		RemainingTonnes FLOAT NULL,
		
		PRIMARY KEY (DigblockId)
	)
	
	-- Create a table used to store Approved Results
	DECLARE @ApprovedResults TABLE
	(
		DigblockId VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		MaterialTypeId INTEGER,
		GeologyTonnes FLOAT NULL,
		MiningTonnes FLOAT NULL,
		ShortTermGeologyTonnes FLOAT NULL,
		GradeControlTonnes FLOAT NULL,
		GeologyVolume FLOAT NULL,
		MiningVolume FLOAT NULL,
		ShortTermGeologyVolume FLOAT NULL,
		GradeControlVolume FLOAT NULL,
		GeologyModelFilename VARCHAR(200) NULL,
		MiningModelFilename VARCHAR(200) NULL,
		ShortTermGeologyModelFilename VARCHAR(200) NULL,
		GradeControlModelFilename VARCHAR(200) NULL,
		MonthlyMinedPercent FLOAT NULL,
		TotalMinedPercent FLOAT NULL,
		HauledTonnes FLOAT NULL,
		SurveyedTonnes FLOAT NULL,
		BestTonnes FLOAT NULL,
		RemainingTonnes FLOAT NULL,
		
		PRIMARY KEY (DigblockId)
	)
	
	-- Create a table used to store Distinct Digblock Ids
	DECLARE @DistinctDigblocks TABLE
	(
		DigblockId VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		
		PRIMARY KEY (DigblockId)
	)
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioApprovalDigblockList',
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
		-- Get Live Data Results
		INSERT INTO @LiveResults
		(
			DigblockId, MaterialTypeId, GeologyTonnes, MiningTonnes, ShortTermGeologyTonnes, GradeControlTonnes,
			GeologyVolume, MiningVolume, ShortTermGeologyVolume, GradeControlVolume,
			HauledTonnes, SurveyedTonnes, BestTonnes, RemainingTonnes, GeologyModelFilename, MiningModelFilename,
			ShortTermGeologyModelFilename, GradeControlModelFilename, MonthlyMinedPercent, TotalMinedPercent
		)
		EXEC dbo.GetBhpbioApprovalDigblockListLiveData @iLocationId = @iLocationId,
														@iMonthFilter = @iMonthFilter,
														@iRecordLimit = @iRecordLimit
															
		-- Get Approved Data Results
		INSERT INTO @ApprovedResults
		(
			DigblockId, MaterialTypeId, GeologyTonnes, MiningTonnes, ShortTermGeologyTonnes, GradeControlTonnes, 
			GeologyVolume, MiningVolume, ShortTermGeologyVolume, GradeControlVolume,
			HauledTonnes, SurveyedTonnes, BestTonnes, RemainingTonnes, GeologyModelFilename, MiningModelFilename,
			ShortTermGeologyModelFilename, GradeControlModelFilename
		)
		EXEC dbo.GetBhpbioApprovalDigblockListApprovedData @iLocationId = @iLocationId,
															@iMonthFilter = @iMonthFilter

		-- determine the distinct set of digblocks	
		INSERT INTO @DistinctDigblocks
		SELECT DISTINCT merged.DigblockId
		FROM (
				SELECT lr.DigblockId 
				FROM @LiveResults lr
				UNION
				SELECT ar.DigblockId 
				FROM @ApprovedResults ar
			) AS merged
			
	
		-- Return the Results
		IF @iRecordLimit IS NOT NULL
		BEGIN
			SET ROWCOUNT @iRecordLimit
		END
		
		SELECT dd.DigblockId,
			CASE WHEN a.DigblockId IS NOT NULL THEN 1 ELSE 0 END AS Approved,
			CASE 
				WHEN u.UserId IS NOT NULL THEN u.FirstName + ' ' + u.LastName
				WHEN u.UserId IS NULL AND a.UserId IS NOT NULL THEN 'Unknown User'
				ELSE ''
			END AS SignoffUser,
			a.SignOffDate,
			mt.Description AS MaterialTypeDescription,
			d.Start_Tonnes AS GradeControlInventoryTonnes,
			-- depletion tonnes
			COALESCE(ar.GeologyTonnes, lr.GeologyTonnes) AS GeologyTonnes,
			COALESCE(ar.MiningTonnes, lr.MiningTonnes) AS MiningTonnes,
			COALESCE(ar.ShortTermGeologyTonnes, lr.ShortTermGeologyTonnes) AS ShortTermGeologyTonnes,
			COALESCE(ar.GradeControlTonnes, lr.GradeControlTonnes) AS GradeControlTonnes,
			-- ensure that depletion tonnes and model filenames are aligned (i.e. if approved tonnes is used, then approved filename should be displayed and vice versa)
			CASE WHEN ar.GeologyTonnes IS NOT NULL
				THEN ar.GeologyModelFilename
				ELSE lr.GeologyModelFilename
			END AS GeologyModelFilename,
			CASE WHEN ar.MiningTonnes IS NOT NULL
				THEN ar.MiningModelFilename
				ELSE lr.MiningModelFilename
			END AS MiningModelFilename,
			CASE WHEN ar.ShortTermGeologyTonnes IS NOT NULL
				THEN ar.ShortTermGeologyModelFilename
				ELSE lr.ShortTermGeologyModelFilename
			END AS ShortTermGeologyModelFilename,
			CASE WHEN ar.GradeControlTonnes IS NOT NULL
				THEN ar.GradeControlModelFilename
				ELSE lr.GradeControlModelFilename
			END AS GradeControlModelFilename,
			-- depletions
			lr.MonthlyMinedPercent AS MonthlyMinedPercent,
			lr.TotalMinedPercent AS TotalMinedPercent,
			-- actual tonnages
			COALESCE(ar.HauledTonnes, lr.HauledTonnes) AS HauledTonnes,
			COALESCE(ar.SurveyedTonnes, lr.SurveyedTonnes) AS SurveyedTonnes,
			COALESCE(ar.BestTonnes, lr.BestTonnes) AS BestTonnes,
			COALESCE(ar.RemainingTonnes, lr.RemainingTonnes) AS RemainingTonnes
		FROM @DistinctDigblocks dd
			INNER JOIN Digblock d
				ON d.Digblock_Id = dd.DigblockId
			INNER JOIN dbo.MaterialType mt
				ON mt.Material_Type_Id = d.Material_Type_Id
			LEFT JOIN @LiveResults lr 
				ON lr.DigblockId = dd.DigblockId
			LEFT JOIN @ApprovedResults ar
				ON ar.DigblockId = dd.DigblockId
			left JOIN dbo.BhpbioApprovalDigblock a
				ON a.DigblockID = dd.DigblockId
				AND a.ApprovedMonth = @iMonthFilter
			LEFT JOIN dbo.SecurityUser u
				ON u.UserId = a.UserId
		ORDER BY 1, 2
		
		IF @iRecordLimit IS NOT NULL
		BEGIN
			SET ROWCOUNT 0
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

GRANT EXECUTE ON dbo.GetBhpbioApprovalDigblockList TO BhpbioGenericManager
GO

--EXEC dbo.GetBhpbioApprovalDigblockList  1, '1-jul-2014', NULL

/*
<TAG Name="Data Dictionary" FunctionName="dbo.GetBhpbioApprovalDigblockList">
 <Function>
	Retrieves a set of digblock listing data based on Live AND Approved Summary data.
	Note: This is done by calling the dbo.GetBhpbioApprovalDigblockListLive and dbo.GetBhpbioApprovalDigblockListApproved procedures respectively
			
	Pass: 
			@iLocationId : Identifies the Location within which to select digblocks
			@iMonthFilter: The month to return data for
			@iRecordLimit: An optional Record Limit
	
	Returns: Set of digblock approval data
 </Function>
</TAG>
*/	


