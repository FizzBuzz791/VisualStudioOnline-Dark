IF OBJECT_ID('dbo.GetBhpbioApprovalDigblockListLiveData') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioApprovalDigblockListLiveData
GO 
  
CREATE PROCEDURE dbo.GetBhpbioApprovalDigblockListLiveData
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
	
	DECLARE @Results TABLE
	(
		DigblockId VARCHAR(31) COLLATE DATABASE_DEFAULT NULL,
		MaterialTypeId INTEGER,
		ApprovalMonth DATETIME NULL,
		MiningTonnes FLOAT NULL,
		GeologyTonnes FLOAT NULL,
		GradeControlTonnes FLOAT NULL,
		HauledTonnes FLOAT NULL,
		SurveyedTonnes FLOAT NULL,
		BestTonnes FLOAT NULL,
		CorrectedTonnes FLOAT NULL,
		RemainingTonnes FLOAT NULL,
		MinedPercent FLOAT NULL,
		BlockLocationId INT NULL
	)
	
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		ParentLocationID INT,
		IncludeStart DATETIME,
		IncludeEnd DATETIME,
		PRIMARY KEY (LocationId)
	)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioApprovalDigblockListLiveData',
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
		DECLARE @MaterialCategory VARCHAR(31)
		SET @MaterialCategory = 'Designation'
		
		SET @HauledFieldId = 'HauledTonnes'
		SET @SurveyedFieldId = 'GroundSurveyTonnes'
		SET @MonthDate = dbo.GetDateMonth(@iMonthFilter)
		SET @EndMonthDate = DateAdd(Day, -1, DateAdd(Month, 1, @MonthDate))

		INSERT INTO @Location
		SELECT LocationId, ParentLocationID, IncludeStart,IncludeEnd
		--FROM dbo.GetBhpbioReportLocation(@iLocationId)
		FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId,0,NULL,@MonthDate,@EndMonthDate)
		
		SET @LocationId = @iLocationId
		IF @LocationId IS NOT NULL AND @LocationId < 0
		BEGIN
			SET @LocationId = NULL
		END
		
		-- Insert the inital data of a digblock id, and any approvals including the sign off person.
		INSERT INTO @Results
			(
				DigblockId, ApprovalMonth, MinedPercent, BlockLocationId, 
				CorrectedTonnes, BestTonnes, HauledTonnes, SurveyedTonnes, RemainingTonnes, 
				MaterialTypeId
			)
		SELECT d.Digblock_Id, 
			@iMonthFilter,
			RM.MinedPercentage, 
			DL.Location_Id,
			processed.Corrected,
			field.Best,
			field.Hauled,
			field.Survey,
			-cumlative.Best,
			D.Material_Type_Id
		FROM dbo.Digblock AS D
			INNER JOIN dbo.DigblockLocation AS DL
				ON (D.Digblock_Id = DL.Digblock_Id)
			INNER JOIN @Location AS L
				ON (L.LocationId = DL.Location_Id)
				AND (@MonthDate BETWEEN L.IncludeStart AND L.IncludeEnd)
			LEFT JOIN dbo.BhpbioImportReconciliationMovement AS RM
				ON (RM.DateFrom >= @MonthDate
					AND RM.DateTo <= @EndMonthDate
					AND DL.Location_Id = RM.BlockLocationId)
			LEFT JOIN
				(
					SELECT DPT.Source_Digblock_Id As DigblockId,
						Coalesce(Sum(DPT.Tonnes), 0) As Corrected
					FROM dbo.DataProcessTransaction AS DPT
					WHERE DPT.Data_Process_Transaction_Date BETWEEN @MonthDate AND @EndMonthDate
					GROUP BY DPT.Source_Digblock_Id
				) AS processed
					ON D.Digblock_Id = processed.DigblockId
			LEFT JOIN
				(
					SELECT h.Source_Digblock_Id As DigblockId,
						Coalesce(Sum(h.Tonnes), 0) As Best,
						Coalesce(Sum(hauled.Field_Value), 0) As Hauled,
						Coalesce(Sum(survey.Field_Value), 0) As Survey
					FROM dbo.Haulage AS h
						LEFT JOIN dbo.HaulageValue AS hauled
							ON h.Haulage_Id = hauled.Haulage_Id
								AND hauled.Haulage_Field_Id = @HauledFieldId
						LEFT JOIN dbo.HaulageValue AS survey
							ON h.Haulage_Id = survey.Haulage_Id
								AND survey.Haulage_Field_Id = @SurveyedFieldId
					WHERE h.Haulage_Date BETWEEN @MonthDate AND @EndMonthDate
						AND h.Haulage_State_Id IN ('N', 'A')
						AND h.Child_Haulage_Id IS NULL
					GROUP BY h.Source_Digblock_Id	
				) AS field
					ON D.Digblock_Id = field.DigblockId
			LEFT JOIN
				(
					SELECT h.Source_Digblock_Id As DigblockId,
						Coalesce(Sum(h.Tonnes), 0) As Best
					FROM dbo.Haulage AS h
					WHERE h.Haulage_Date <= @EndMonthDate
						AND h.Haulage_State_Id IN ('N', 'A')
						AND h.Child_Haulage_Id IS NULL
					GROUP BY h.Source_Digblock_Id	
				) AS cumlative
					ON D.Digblock_Id = cumlative.DigblockId
		WHERE RM.MinedPercentage IS NOT NULL 
			OR field.Survey IS NOT NULL 
			OR field.Hauled IS NOT NULL 
			OR field.Best IS NOT NULL
			OR processed.Corrected IS NOT NULL

		-- Get the haulage and moved block tonnes
		UPDATE r
		SET MiningTonnes = model.Mining * r.MinedPercent,
			GradeControlTonnes = model.GradeControl * r.MinedPercent,
			GeologyTonnes = model.Geology * r.MinedPercent,
			RemainingTonnes = model.GradeControl + RemainingTonnes
		FROM @Results AS r
			LEFT JOIN 
				(
					SELECT r.DigblockId,
						Sum(CASE WHEN BM.Name = 'Mining' THEN MBP.Tonnes ELSE NULL END) AS Mining,
						Sum(CASE WHEN BM.Name = 'Grade Control' THEN MBP.Tonnes ELSE NULL END) As GradeControl,
						Sum(CASE WHEN BM.Name = 'Geology' THEN MBP.Tonnes ELSE NULL END) As Geology
					FROM @Results AS R
						INNER JOIN dbo.ModelBlockLocation AS MBL
							ON (R.BlockLocationId = MBL.Location_Id)
						INNER JOIN dbo.ModelBlock AS MB
							ON (MBL.Model_Block_Id = MB.Model_Block_Id)
						INNER JOIN dbo.BlockModel AS BM
							ON (BM.Block_Model_Id = MB.Block_Model_Id)
						INNER JOIN dbo.ModelBlockPartial AS MBP
							ON (MB.Model_Block_Id = MBP.Model_Block_Id)
						INNER JOIN dbo.GetMaterialsByCategory(@MaterialCategory) AS MC
							ON (MC.MaterialTypeId = MBP.Material_Type_Id)
						INNER JOIN dbo.MaterialType AS MT
							ON (MC.RootMaterialTypeId = MT.Material_Type_Id)
						--INNER JOIN dbo.GetBhpbioReportHighGrade() AS BRHG
						--	ON (BRHG.MaterialTypeId = MT.Material_Type_Id)
					GROUP BY R.DigblockId
				) AS model
					ON r.DigblockId = model.DigblockId

		IF @iRecordLimit IS NOT NULL
		BEGIN
			SET ROWCOUNT @iRecordLimit
		END
		
		-- Return the results					
		SELECT DigblockId, MaterialTypeId, MiningTonnes, GeologyTonnes, GradeControlTonnes, HauledTonnes,
				SurveyedTonnes, BestTonnes, RemainingTonnes
		FROM @Results
		ORDER BY DigblockId

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

GRANT EXECUTE ON dbo.GetBhpbioApprovalDigblockListLiveData TO BhpbioGenericManager
GO

--EXEC dbo.GetBhpbioApprovalDigblockListLiveData  4, '1-SEP-2008', NULL

--EXEC dbo.GetBhpbioApprovalDigblockListLiveData  4, '1-SEP-2008', NULL

/*
<TAG Name="Data Dictionary" FunctionName="dbo.GetBhpbioApprovalDigblockListLiveData">
 <Function>
	Retrieves a set of digblock approval listing data based on Live data only.
	Note: This is combined with Approved Summary results by the dbo.GetBhpbioApprovalDigblockList procedure
			
	Pass: 
			@iLocationId : Identifies the Location within which to select digblocks
			@iMonthFilter: The month to return data for
			@iRecordLimit: An optional Record Limit
	
	Returns: Set of digblock approval data
 </Function>
</TAG>
*/	