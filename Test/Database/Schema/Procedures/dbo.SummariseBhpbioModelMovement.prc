IF OBJECT_ID('dbo.SummariseBhpbioModelMovement') IS NOT NULL
     DROP PROCEDURE dbo.SummariseBhpbioModelMovement
GO 

CREATE PROCEDURE dbo.SummariseBhpbioModelMovement
(
	@iSummaryMonth DATETIME,
	@iSummaryLocationId INTEGER,
	@iIsHighGrade BIT,
	@iSpecificMaterialTypeId INTEGER,
	@iModelName VARCHAR(255)
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	DECLARE @summaryEntryTypeId INTEGER
	DECLARE @blockModelId INTEGER
	DECLARE @effectiveBlockModelId INTEGER
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'SummariseBhpbioModelMovement',
		@TransactionCount = @@TranCount 

	SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
	FROM dbo.BhpbioSummaryEntryType bset
	WHERE bset.Name like REPLACE(@iModelName,' ','') + 'ModelMovement'
	
	SELECT @blockModelId = bm.Block_Model_Id
	FROM dbo.BlockModel bm
	WHERE bm.Name like @iModelName
	
	
	-- for the STGM grade control model, we want to use the data from the normal grade control
	-- model, but adjust it to use locations only where STGM data is present. This is only possible
	-- if we use two different block model ids.
	--
	-- first we get the ids based off the model names
	DECLARE @GradeControlModelId INT
	DECLARE @GradeControlSTGMModelId INT
	SELECT @GradeControlModelId = Block_Model_Id from BlockModel where Name = 'Grade Control'
	SELECT @GradeControlSTGMModelId = Block_Model_Id from BlockModel where Name = 'Grade Control STGM'

	-- once we have both ids, create an efficeive block _model_id that can be used where required
	SET @effectiveBlockModelId = (CASE WHEN @blockModelId = @GradeControlSTGMModelId THEN @GradeControlModelId ELSE @blockModelId END)
	
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
		exec dbo.DeleteBhpbioSummaryModelMovement	@iSummaryMonth = @iSummaryMonth,
													@iSummaryLocationId = @iSummaryLocationId,
													@iIsHighGrade = @iIsHighGrade,
													@iSpecificMaterialTypeId = @iSpecificMaterialTypeId,
													@iModelName = @iModelName

		-- determine the start of the summary month and the start of the following month
		-- this gives us a window of time to operate within
		SELECT @startOfMonth = dbo.GetDateMonth(@iSummaryMonth)
		SELECT @startOfNextMonth = DATEADD(month,1,@iSummaryMonth)

		-- determine the appropriate Summary Id the data calculated here is to be appended with
		EXEC dbo.GetBhpbioSummaryIdForMonth @iSummaryMonth = @startOfMonth,
											@oSummaryId = @summaryId OUTPUT

		DECLARE @MinedBlastBlock TABLE
		(
			BlockLocationId INT NOT NULL PRIMARY KEY,
			PitLocationId INT NOT NULL,
			MinedPercentage FLOAT NOT NULL
		)
		
		INSERT INTO @MinedBlastBlock
		(
			BlockLocationId,
			PitLocationId,
			MinedPercentage
		)
		SELECT BlockLocationId, PitLocationId, MinedPercentage
		FROM dbo.GetBhpbioReportReconBlockLocations(@iSummaryLocationId, @startOfMonth, @startOfNextMonth, 1)
		
		-- -----------------------------------------------------------------------------------------------------------------------------------
		-- The queries used in this procedure are based on / taken from the original reporting implementation (on non-summarised data)
		-- -----------------------------------------------------------------------------------------------------------------------------------
		
		Declare @GeometTypes TABLE (
			ProductSize varchar(32),
			GeometType varchar(32)
		)
		
		insert into @GeometTypes
			select 'LUMP', 'As-Shipped' union
			select 'LUMP', 'As-Dropped' union
			select 'FINES', 'As-Shipped' union
			select 'FINES', 'As-Dropped'
					
		---- Insert the actual tonnes for lump and fines
		INSERT INTO dbo.BhpbioSummaryEntry
		(
			SummaryId,
			SummaryEntryTypeId,
			LocationId,
			MaterialTypeId,
			ProductSize,
			Tonnes,
			Volume,
			ModelFilename,
			GeometType,
			StratNum,
			Weathering
		)
		SELECT	@summaryId,
				@summaryEntryTypeId,
				mbb.BlockLocationId,
				mbp.Material_Type_Id,
				defaultlf.ProductSize,
				Sum(mbp.Tonnes * mbb.MinedPercentage * ISNULL(
					CASE 
						WHEN defaultlf.ProductSize = 'LUMP' THEN blocklf.[LumpPercent] 
						WHEN defaultlf.ProductSize = 'FINES' THEN 1 - blocklf.[LumpPercent] 
					ELSE NULL END, defaultlf.[Percent])),
				-- note that we dont try to split the volume L/F - the value only exists for TOTAL.
				CASE 
					WHEN defaultlf.ProductSize = 'TOTAL' THEN SUM(mbpv.Field_Value * mbb.MinedPercentage) 
					ELSE NULL 
				END as Volume,
				CASE WHEN MIN(mbpn.Notes) IS NOT NULL
					THEN RIGHT(MIN(mbpn.Notes), 200) --summarise model filename: take the last 200 characters to retain name of file, but path is not important
					ELSE NULL
				END,
				CASE
					WHEN defaultlf.ProductSize = 'TOTAL' Then 'NA'
					ELSE ISNull(blocklf.GeometType, gt.GeometType)
				END as GeometType,
				dbnStratNum.Notes as StratNum,
				cast(dbnWeathering.Notes as integer) as Weathering
		FROM @MinedBlastBlock AS mbb
			INNER JOIN [dbo].[GetBhpbioReportModelBlockLocations](@BlockModelId) mbl
				ON mbl.Location_Id = mbb.BlockLocationId
			INNER JOIN ModelBlock mb
				ON mb.Model_Block_Id = mbl.Model_Block_Id
			INNER JOIN ModelBlockPartial mbp 
				ON mbp.Model_Block_Id = mb.Model_Block_Id
			LEFT JOIN dbo.ModelBlockPartialNotes mbpn
				ON (mbp.Model_Block_Id = mbpn.Model_Block_Id
					AND mbpn.Model_Block_Partial_Field_Id = 'ModelFilename'
					AND mbpn.Sequence_No = mbp.Sequence_No)
			LEFT JOIN dbo.ModelBlockPartialValue mbpv
				ON (mbp.Model_Block_Id = mbpv.Model_Block_Id
					AND mbpv.Model_Block_Partial_Field_Id = 'ModelVolume'
					AND mbpv.Sequence_No = mbp.Sequence_No)
			INNER JOIN dbo.GetBhpbioFilteredMaterialTypes(@iIsHighGrade,@iSpecificMaterialTypeId) mt
				ON mt.MaterialTypeId = mbp.Material_Type_Id
			INNER JOIN dbo.GetBhpbioDefaultLumpFinesRatios(null, null, 1) defaultlf
				ON mbb.PitLocationId = defaultlf.LocationId
				AND @iSummaryMonth BETWEEN defaultlf.StartDate AND defaultlf.EndDate
			LEFT JOIN @GeometTypes gt
				on gt.ProductSize = defaultlf.ProductSize
			LEFT JOIN BhpbioBlastBlockLumpPercent blocklf
				ON mbp.Model_Block_Id = blocklf.ModelBlockId
				AND mbp.Sequence_No = blocklf.SequenceNo
				AND gt.GeometType = blocklf.GeometType
				AND gt.ProductSize <> 'TOTAL'
			LEFT JOIN dbo.DigblockNotes dbnStratNum
				ON (mb.Code = dbnStratNum.Digblock_Id
					AND dbnStratNum.Digblock_Field_Id = 'StratNum')
			LEFT JOIN dbo.DigblockNotes dbnWeathering
				ON (mb.Code = dbnWeathering.Digblock_Id
					AND dbnWeathering.Digblock_Field_Id = 'Weathering')
		WHERE	mbp.Tonnes > 0 
				AND mbb.MinedPercentage > 0
				AND mb.Block_Model_Id = @effectiveBlockModelId
		GROUP BY mbb.BlockLocationId, mbp.Material_Type_Id, defaultlf.ProductSize, blocklf.GeometType, gt.GeometType, dbnStratNum.Notes, cast(dbnWeathering.Notes as integer)
		
		-- Calculate the grades
		-- this uses the same data as that for the tonnage above but joins the grade values from the block model
		-- Note: As material within a block is taken proportionately evenly the weighted averaging that is done
		-- can use the total tonnes of block partials (easire) rather than just the moved tonnes 
		--   e.g The block may have contained 2 partials, 1 of 100 and one of 50 tonnes
		--       only 10 tonnes of the first partial and 5 tonnes of the second partial were moved
		--       the weighted average operation will produce the same result whether total tonnes or moved tonnes are used
--		--			(100 and 50 or 10 and 5)
		INSERT INTO dbo.BhpbioSummaryEntryGrade
		(
			SummaryEntryId,
			GradeId,
			GradeValue
		)
		SELECT bse.SummaryEntryId,
			   mbpg.Grade_Id,
			   SUM(
					ISNULL(
						CASE
							WHEN bse.ProductSize = 'LUMP' THEN LFG.LumpValue
							WHEN bse.ProductSize = 'FINES' THEN LFG.FinesValue
							ELSE NULL
						END,
						MBPG.Grade_Value
					)
					* mbp.Tonnes
				)
				/ Sum(mbp.Tonnes)
		FROM dbo.BhpbioSummaryEntry bse
			INNER JOIN @MinedblastBlock mbb 
					ON mbb.BlockLocationId = bse.LocationId
			INNER JOIN dbo.GetBhpbioFilteredMaterialTypes(@iIsHighGrade,@iSpecificMaterialTypeId) mt
					ON mt.MaterialTypeId = bse.MaterialTypeId
			INNER JOIN [dbo].[GetBhpbioReportModelBlockLocations](@BlockModelId) mbl
					ON mbl.Location_Id = bse.LocationId
			INNER JOIN ModelBlock mb
					ON mb.Model_Block_Id = mbl.Model_Block_Id
			INNER JOIN ModelBlockPartial mbp 
					ON mbp.Model_Block_Id = mb.Model_Block_Id
					AND mbp.Material_Type_Id = bse.MaterialTypeId
			INNER JOIN ModelBlockPartialGrade mbpg
					ON mbpg.Model_Block_Id = mbp.Model_Block_Id
					AND mbpg.Sequence_No = mbp.Sequence_No
			LEFT JOIN BhpbioBlastBlockLumpFinesGrade lfg
				ON (LFG.ModelBlockId = mbl.Model_Block_Id
					AND mbpg.Grade_Id = lfg.GradeId
					AND mbpg.Sequence_No = lfg.SequenceNo
					AND bse.GeometType = lfg.GeometType)
		WHERE	mbp.Tonnes > 0 
				AND bse.SummaryId = @summaryId
				AND bse.SummaryEntryTypeId = @summaryEntryTypeId
				AND bse.Tonnes > 0
				AND mb.Block_Model_Id = @effectiveBlockModelId
		GROUP BY bse.SummaryEntryId, mbpg.Grade_Id

		-- Insert the resource classification percentage data
		INSERT INTO dbo.BhpbioSummaryEntryFieldValue(SummaryEntryId,SummaryEntryFieldId,Value)
		SELECT bse.SummaryEntryId, f.SummaryEntryFieldId, Max(mbpv.Field_Value)
		FROM dbo.BhpbioSummaryEntry bse
			INNER JOIN @MinedblastBlock mbb 
					ON mbb.BlockLocationId = bse.LocationId
			INNER JOIN dbo.GetBhpbioFilteredMaterialTypes(@iIsHighGrade,@iSpecificMaterialTypeId) mt
					ON mt.MaterialTypeId = bse.MaterialTypeId
			INNER JOIN [dbo].[GetBhpbioReportModelBlockLocations](@BlockModelId) mbl
					ON mbl.Location_Id = bse.LocationId
			INNER JOIN ModelBlock mb
					ON mb.Model_Block_Id = mbl.Model_Block_Id
			INNER JOIN ModelBlockPartial mbp 
					ON mbp.Model_Block_Id = mb.Model_Block_Id
					AND mbp.Material_Type_Id = bse.MaterialTypeId
			INNER JOIN BhpbioSummaryEntryField f ON f.[ContextKey] = 'ResourceClassification'
			INNER JOIN ModelBlockPartialValue mbpv ON mbpv.Model_Block_Id = mbp.Model_Block_Id
					AND mbpv.Sequence_No = mbp.Sequence_No
					AND mbpv.Model_Block_Partial_Field_Id = f.[Name]
		WHERE	mbp.Tonnes > 0 
				AND bse.SummaryId = @summaryId
				AND bse.SummaryEntryTypeId = @summaryEntryTypeId
				AND bse.Tonnes > 0
				AND mb.Block_Model_Id = @effectiveBlockModelId
		GROUP BY bse.SummaryEntryId, f.SummaryEntryFieldId
							
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

GRANT EXECUTE ON dbo.SummariseBhpbioModelMovement TO BhpbioGenericManager
GO

/*
-- A call like this is used for F1 related summarisation for a model
exec dbo.SummariseBhpbioModelMovement
	@iSummaryMonth = '2009-11-01',
	@@iSummaryLocationId = 3,
	@iIsHighGrade = 1,
	@iSpecificMaterialTypeId = null,
	@iModelName = 'Geology Model'
	
	
-- A call like this is used for Other Movements related summarisation for a particular material type
exec dbo.SummariseBhpbioModelMovement
	@iSummaryMonth = '2009-11-01',
	@iLocationId = 3,
	@iIsHighGrade = null,
	@iSpecificMaterialTypeId = 6,
	@iModelName = 'Grade Control Model'
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.SummariseBhpbioModelMovement">
 <Procedure>
	Generates a set of summary Model Movement data based on supplied criteria.
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
			@iModelName: Name of the block model used to obtain data
 </Procedure>
</TAG>
*/	