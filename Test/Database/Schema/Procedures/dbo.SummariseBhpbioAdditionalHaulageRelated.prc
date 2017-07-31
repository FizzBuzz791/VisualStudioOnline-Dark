IF OBJECT_ID('dbo.SummariseBhpbioAdditionalHaulageRelated') IS NOT NULL
     DROP PROCEDURE dbo.SummariseBhpbioAdditionalHaulageRelated
GO 

CREATE PROCEDURE dbo.SummariseBhpbioAdditionalHaulageRelated
(
	@iSummaryMonth DATETIME,
	@iSummaryLocationId INTEGER,
	@iIsHighGrade BIT,
	@iSpecificMaterialTypeId INTEGER
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	DECLARE @summaryEntryTypeId INTEGER
	DECLARE @blockModelId INTEGER
	DECLARE @HauledFieldId VARCHAR(31)
	DECLARE @SurveyedFieldId VARCHAR(31)
	DECLARE @MaterialCategory VARCHAR(31)
	SET @MaterialCategory = 'Designation'
		
	SET NOCOUNT ON 

	SELECT @TransactionName = 'SummariseBhpbioAdditionalHaulageRelated',
		@TransactionCount = @@TranCount 

	DECLARE @monthlyHauledSummaryEntryTypeId INTEGER
	DECLARE @monthlyBestSummaryEntryTypeId INTEGER
	DECLARE @surveySummaryEntryTypeId INTEGER
	DECLARE @cumulativeHauledEntryTypeId INTEGER
	DECLARE @totalGradeControlEntryTypeId INTEGER
	DECLARE @gradeControlBlockModelId INTEGER
	
	SELECT @monthlyHauledSummaryEntryTypeId = bset.SummaryEntryTypeId
	FROM dbo.BhpbioSummaryEntryType bset
	WHERE bset.Name like 'BlastBlockMonthlyHauled'
	
	SELECT @monthlyBestSummaryEntryTypeId = bset.SummaryEntryTypeId
	FROM dbo.BhpbioSummaryEntryType bset
	WHERE bset.Name like 'BlastBlockMonthlyBest'
	
	SELECT @surveySummaryEntryTypeId = bset.SummaryEntryTypeId
	FROM dbo.BhpbioSummaryEntryType bset
	WHERE bset.Name like 'BlastBlockSurvey'
	
	SELECT @cumulativeHauledEntryTypeId = bset.SummaryEntryTypeId
	FROM dbo.BhpbioSummaryEntryType bset
	WHERE bset.Name like 'BlastBlockCumulativeHauled'
	
	SELECT @totalGradeControlEntryTypeId = bset.SummaryEntryTypeId,
		@gradeControlBlockModelId = bset.AssociatedBlockModelId
	FROM dbo.BhpbioSummaryEntryType bset
	WHERE bset.Name like 'BlastBlockTotalGradeControl'
	
	SET @HauledFieldId = 'HauledTonnes'
	SET @SurveyedFieldId = 'GroundSurveyTonnes'
	
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
		DECLARE @summaryId INT
		DECLARE @startOfMonth DATETIME
		DECLARE @startOfNextMonth DATETIME

		-- the first step is to remove data already summarised for this set of criteria
		exec dbo.DeleteBhpbioSummaryAdditionalHaulageRelated	@iSummaryMonth = @iSummaryMonth,
																@iSummaryLocationId = @iSummaryLocationId,
																@iIsHighGrade = @iIsHighGrade,
																@iSpecificMaterialTypeId = @iSpecificMaterialTypeId

		-- determine the start of the summary month and the start of the following month
		-- this gives us a window of time to operate within
		SELECT @startOfMonth = dbo.GetDateMonth(@iSummaryMonth)
		SELECT @startOfNextMonth = DATEADD(month,1,@iSummaryMonth)

		-- determine the appropriate Summary Id the data calculated here is to be appended with
		EXEC dbo.GetBhpbioSummaryIdForMonth @iSummaryMonth = @startOfMonth,
											@oSummaryId = @summaryId OUTPUT

		-- create and populate a table variable to store Identifiers for relevant locations
		DECLARE @Location TABLE
		(
			LocationId INT NOT NULL,
			ParentLocationId INT NULL,
			PRIMARY KEY (LocationId)
		)
		
		INSERT INTO @Location(
			LocationId,
			ParentLocationId)
		SELECT LocationId, ParentLocationId
		FROM dbo.GetBhpbioReportLocationBreakdown(@iSummaryLocationId, 1, NULL)
				
		DECLARE @Staging TABLE
		(
			LocationId INT NOT NULL,
			MaterialTypeId INT NULL,
			BestTonnes REAL,
			HauledTonnes REAL,
			SurveyTonnes REAL,
			CumulativeHauledTonnes REAL,
			TotalGradeControl REAL
			PRIMARY KEY (LocationId)
		)
		
		DECLARE @ActiveDigblock TABLE
		(
			DigblockId VARCHAR(31)
		)
	
		-- find the digblocks active through either BhpbioImportReconciliationMovement or Haulage
		INSERT INTO @ActiveDigblock
		SELECT DISTINCT d.Digblock_Id
		FROM (
			SELECT DISTINCT dl.Digblock_Id
			FROM dbo.BhpbioImportReconciliationMovement rm
				INNER JOIN dbo.DigblockLocation dl ON dl.Location_Id = rm.BlockLocationId
			WHERE rm.DateTo >= @startOfMonth AND rm.DateTo < @startOfNextMonth
			UNION
			SELECT DISTINCT h.Source_Digblock_Id
			FROM dbo.Haulage h
			WHERE h.Haulage_Date >= @startOfMonth 
				AND h.Haulage_Date < @startOfNextMonth
		) as d
		
		-- calculate the best, hauled and survey tonnes
		INSERT INTO @Staging
		(
			LocationId,
			MaterialTypeId,
			BestTonnes,
			HauledTonnes,
			SurveyTonnes
		)
		SELECT	l.LocationId, 
				d.Material_Type_Id,
				COALESCE(SUM(h.Tonnes), 0) As BestTonnes,
				COALESCE(SUM(hauled.Field_Value), 0) As HauledTonnes,
				COALESCE(SUM(survey.Field_Value), 0) As SurveyTonnes
		FROM @ActiveDigblock ad
			INNER JOIN dbo.Digblock d
				ON d.Digblock_Id = ad.DigblockId
			INNER JOIN dbo.DigblockLocation dl
				ON dl.Digblock_Id = d.Digblock_Id
			INNER JOIN dbo.GetBhpbioFilteredMaterialTypes(@iIsHighGrade,@iSpecificMaterialTypeId) fmt
				ON fmt.MaterialTypeId = d.Material_Type_Id
			INNER JOIN @Location l
				ON l.LocationId = dl.Location_Id
			LEFT JOIN dbo.Haulage h
				ON h.Source_Digblock_Id = ad.DigblockId
				AND h.Haulage_Date >= @startOfMonth 
				AND h.Haulage_Date < @startOfNextMonth
				AND h.Haulage_State_Id IN ('N', 'A')
				AND h.Child_Haulage_Id IS NULL
			LEFT JOIN dbo.HaulageValue AS hauled
				ON h.Haulage_Id = hauled.Haulage_Id
					AND hauled.Haulage_Field_Id = @HauledFieldId
			LEFT JOIN dbo.HaulageValue AS survey
				ON h.Haulage_Id = survey.Haulage_Id
					AND survey.Haulage_Field_Id = @SurveyedFieldId
		GROUP BY l.LocationId, d.Material_Type_Id	
				
		-- update the cumulative tonnes				
		UPDATE s
		SET CumulativeHauledTonnes = cumulative.Best
		FROM @Staging AS s
			INNER JOIN (
				SELECT dl.Location_Id,
						Coalesce(Sum(ch.Tonnes), 0) As Best
					FROM dbo.Haulage AS ch
						INNER JOIN dbo.Digblock d
							ON d.Digblock_Id = ch.Source_Digblock_Id
						INNER JOIN dbo.DigblockLocation dl
							ON dl.Digblock_Id = d.Digblock_Id
					WHERE ch.Haulage_Date < @startOfNextMonth
						AND ch.Haulage_State_Id IN ('N', 'A')
						AND ch.Child_Haulage_Id IS NULL
					GROUP BY dl.Location_Id	
				) AS cumulative
					ON s.LocationId = cumulative.Location_Id

		-- update the grade control tonnes				
		UPDATE s
		SET TotalGradeControl = model.GradeControl
		FROM @Staging AS s
			LEFT JOIN 
				(
					SELECT R.LocationId,
						Sum(CASE WHEN BM.Name = 'Grade Control' THEN MBP.Tonnes ELSE NULL END) As GradeControl
					FROM @Staging AS R
						INNER JOIN dbo.ModelBlockLocation AS MBL
							ON (R.LocationId = MBL.Location_Id)
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
						WHERE BM.Block_Model_Id = @gradeControlBlockModelId
					GROUP BY R.LocationId
				) AS model
					ON s.LocationId = model.LocationId
		
		---- Insert the haulage tonnes
		INSERT INTO dbo.BhpbioSummaryEntry
		(
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			Tonnes
		)
		SELECT	@summaryId,
				@monthlyHauledSummaryEntryTypeId,
				s.LocationId,
				s.MaterialTypeId,
				COALESCE(s.HauledTonnes,0)
		FROM 	@Staging s
		
		---- Insert the Best tonnes
		INSERT INTO dbo.BhpbioSummaryEntry
		(
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			Tonnes
		)
		SELECT	@summaryId,
				@monthlyBestSummaryEntryTypeId,
				s.LocationId,
				s.MaterialTypeId,
				COALESCE(s.BestTonnes,0)
		FROM 	@Staging s
		
		---- Insert the Survey tonnes
		INSERT INTO dbo.BhpbioSummaryEntry
		(
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			Tonnes
		)
		SELECT	@summaryId,
				@surveySummaryEntryTypeId,
				s.LocationId,
				s.MaterialTypeId,
				COALESCE(s.SurveyTonnes,0)
		FROM 	@Staging s
		
		---- Insert the Cumulative Hauled tonnes
		INSERT INTO dbo.BhpbioSummaryEntry
		(
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			Tonnes
		)
		SELECT	@summaryId,
				@cumulativeHauledEntryTypeId,
				s.LocationId,
				s.MaterialTypeId,
				s.CumulativeHauledTonnes
		FROM 	@Staging s
		WHERE s.CumulativeHauledTonnes IS NOT NULL
		
		---- Insert the Total Grade Control
		INSERT INTO dbo.BhpbioSummaryEntry
		(
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			Tonnes
		)
		SELECT	@summaryId,
				@totalGradeControlEntryTypeId,
				s.LocationId,
				s.MaterialTypeId,
				s.TotalGradeControl
		FROM 	@Staging s
		WHERE s.TotalGradeControl IS NOT NULL
		
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

GRANT EXECUTE ON dbo.SummariseBhpbioAdditionalHaulageRelated TO BhpbioGenericManager
GO

/*
-- A call like this is used for additional haulage summarisation for a model
exec dbo.SummariseBhpbioAdditionalHaulageRelated
	@iSummaryMonth = '2009-11-01',
	@@iSummaryLocationId = 3,
	@iIsHighGrade = 1,
	@iSpecificMaterialTypeId = null
	
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.SummariseBhpbioAdditionalHaulageRelated">
 <Procedure>
	Generates a set of summary additional haulage data based on supplied criteria.
	The core set of data for this operation is that stored in:
		- the BhpbioImportReconciliationMovement table
		- the BlockModel and Model* tables
	
	Note that the BhpbioImportReconciliationMovement table contains MinedPercentage values.  These are combined with Model data
	to create a set of summarised Model Movements
	
	In the descriptions below the term Related Material Type means a MeterialType that is either
			- the Root for the specified type
			- a material type that has the specified type as its root
	In the descriptions below the phrase High Grade Related type means a type that is:
			- returned by the dbo.GetBhpbioReportHighGrade() function
			
	Pass: 
			@iSummaryMonth: the month for which summary data is to be generated,
			@iSummaryLocationId: the location (typically a Pit) used to filter the movements to have summary data generated,
			@iIsHighGrade : 
							when 0 - Data for High grade related types is excluded
							when 1 - Only data for high grade related types is included
							when null - this criteria has no impact on filtering
			@iSpecificMaterialTypeId:
							when specified - only Data for the exact matching MaterialTypeId or for MaterialTypes related to the exact match is included
							when null - this criteria has no impact on filtering
 </Procedure>
</TAG>
*/