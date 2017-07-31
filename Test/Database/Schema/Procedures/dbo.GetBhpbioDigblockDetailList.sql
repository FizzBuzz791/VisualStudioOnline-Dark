IF object_id('dbo.GetBhpbioDigblockDetailList') IS NOT NULL 
     DROP PROCEDURE dbo.GetBhpbioDigblockDetailList 
GO 

-- This is copied from the original GetDigblockDetailList in Core
-- and modified to use Lump Fines where appropriate
CREATE PROCEDURE dbo.GetBhpbioDigblockDetailList 
( 
    @iDigblock_Id VARCHAR(31),
	@iIncludeBlockModels BIT = 1,
	@iIncludeMinePlans BIT = 1,
	@iGrade_Visibility Bit = 1,
	@iIncludeLumpFines Bit = 1
) 
WITH ENCRYPTION 
AS
BEGIN 
SET NOCOUNT ON 
  
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ 
    BEGIN TRANSACTION 
	
	DECLARE @LumpFinesGrades TABLE (
		GradeId VARCHAR(64)
	)

	-- We don't want to break all the grades down by lump and fines, because the fields will
	-- appear in the pivot table regardless of if they have values or not. We will only break down
	-- the grades listed here
	--
	-- Not sure if it is best to use grade names or grade_ids here?
	INSERT INTO @LumpFinesGrades
		SELECT 8 UNION	-- H2O-As-Dropped
		SELECT 9		-- H2O-As-Shipped
			
	CREATE TABLE #Attribute
	(
		Attribute VARCHAR(255) COLLATE Database_Default NOT NULL,
		OrderNo INT NOT NULL,

		PRIMARY KEY (Attribute)
	)  

	CREATE TABLE #Value
	(
		Attribute VARCHAR(255) COLLATE Database_Default NOT NULL,
		Measure VARCHAR(255) COLLATE Database_Default NOT NULL,
		ProductSize VARCHAR(31) NULL,
		OrderNo INT NOT NULL,
		Value FLOAT NULL,

		--PRIMARY KEY (Attribute, Measure)
	)

	-- All Plans
	DECLARE @MinePlanDates TABLE
	(
		Mine_Plan_Id INT, 
		Mine_Plan_Type_Id INT,
		Start_Date DATETIME,
		End_Date DATETIME 
	)

	DECLARE @GradeControlTerm VARCHAR(255),
		@GCPercentTerm VARCHAR(255),
		@HauledTerm VARCHAR(255),
		@TonnesTerm VARCHAR(255),
		@ReconciledTerm VARCHAR(255),
		@TonnesIndex Integer,
		@GCPercentIndex Integer,
		@GCIndex Integer,
		@BlockModelIndex Integer,
		@MinePlanIndex Integer,
		@HaulageIndex Integer,
		@SurveyIndex Integer,
		@ReconciledIndex Integer

    BEGIN TRY
		--Get all the mine plans that we should use over the life of mine
		INSERT INTO @MinePlanDates
		EXEC GetMinePlansOverRange

		--Check Digblock exists
		IF NOT EXISTS 
			(
				SELECT 1
				FROM dbo.Digblock AS D
				WHERE Digblock_Id = @iDigblock_Id
			)
		BEGIN
			RaisError('Digblock Id does not exist.', 16, 1)
		END

		-- Return the list of terms and their local names for the system
		SELECT @GradeControlTerm = 'Grade Control',
			@HauledTerm = 'Hauled',
			@TonnesTerm = 'Tonnes',
			@ReconciledTerm = 'Reconciled'

		SELECT @GradeControlTerm = Site_Terminology
		FROM dbo.Terminology
		WHERE Terminology_Id = @GradeControlTerm

		SELECT @HauledTerm = Site_Terminology
		FROM dbo.Terminology
		WHERE Terminology_Id = @HauledTerm
		
		SELECT @ReconciledTerm = Site_Terminology
		FROM dbo.Terminology
		WHERE Terminology_Id = @ReconciledTerm

		SELECT @TonnesTerm = Site_Terminology
		FROM dbo.Terminology
		WHERE Terminology_Id = @TonnesTerm

		SELECT @GCPercentTerm = '% of ' + @GradeControlTerm,
			@TonnesIndex = -2,
			@GCPercentIndex = -1,
			@GCIndex = 1,
			@BlockModelIndex = 2,
			@MinePlanIndex = 3,
			@HaulageIndex = 4,
			@SurveyIndex = 5,
			@ReconciledIndex = 6

		--Populate Attributes
		INSERT INTO #Attribute
		(
			Attribute, OrderNo
		)
		SELECT @TonnesTerm, @TonnesIndex
		UNION All
		SELECT @GCPercentTerm, @GCPercentIndex
		UNION All
		SELECT G.Grade_Name, G.Order_No
		FROM dbo.Grade As G
		WHERE (G.Is_Visible = @iGrade_Visibility 
				OR @iGrade_Visibility IS NULL)

		--Insert all possible combinations
		INSERT INTO #Value
		(
			Attribute, Measure, OrderNo, Value
		)
		SELECT '', @GradeControlTerm, @GCIndex, NULL
		
		IF @iIncludeBlockModels = 1
		BEGIN
			INSERT INTO #Value
			(
				Attribute, Measure, OrderNo, Value
			)
			SELECT '', Name, @BlockModelIndex, NULL
			FROM dbo.BlockModel AS BM
			WHERE Is_Displayed = 1
		END

		IF @iIncludeMinePlans = 1
		BEGIN
			INSERT INTO #Value
			(
				Attribute, Measure, OrderNo, Value
			)
			SELECT '', Name, @MinePlanIndex, NULL
			FROM dbo.MinePlan AS MP
			WHERE Parent_Mine_Plan_Id IS NULL
				AND Is_Visible = 1 
		END

		INSERT INTO #Value
		(
			Attribute, Measure, OrderNo, Value
		)
		SELECT '', @HauledTerm, @HaulageIndex, NULL
		UNION All
		SELECT '', Name, @SurveyIndex, NULL
		FROM dbo.DigblockSurveyType AS DST
		WHERE Is_Visible = 1
		UNION All
		SELECT '', @ReconciledTerm, @ReconciledIndex, NULL

		--Populate Values
		INSERT INTO #Value
		(
			Attribute, Measure, OrderNo, Value
		)
		--Grade Control AKA Digblock table
		SELECT @TonnesTerm, @GradeControlTerm, @GCIndex, D.Start_Tonnes
		FROM dbo.Digblock AS D
		WHERE D.Digblock_Id = @iDigblock_Id
		UNION All
		SELECT G.Grade_Name, @GradeControlTerm, @GCIndex, 
			DG.Grade_Value
		FROM dbo.Digblock AS D
			INNER JOIN dbo.DigblockGrade AS DG
				ON (D.Digblock_Id = DG.Digblock_Id)
			INNER JOIN dbo.Grade AS G
				ON (G.Grade_Id = DG.Grade_Id)
		WHERE D.Digblock_Id = @iDigblock_Id
			AND (G.Is_Visible = @iGrade_Visibility 
				OR @iGrade_Visibility IS NULL)
		UNION All
		--Haulage
		SELECT @TonnesTerm, @HauledTerm, @HaulageIndex, Sum(H.Tonnes)
		FROM dbo.Haulage AS H
		WHERE H.Source_Digblock_Id = @iDigblock_Id
			AND H.Haulage_State_Id = 'N'
		UNION All
		SELECT G.Grade_Name, @HauledTerm, @HaulageIndex, 
			Sum(HG.Grade_Value * H.Tonnes) / NullIf(Sum(H.Tonnes), 0)
		FROM dbo.Haulage AS H
			INNER JOIN dbo.HaulageGrade AS HG
				ON (H.Haulage_Id = HG.Haulage_Id)
			INNER JOIN dbo.Grade AS G
				ON (G.Grade_Id = HG.Grade_Id)
		WHERE H.Source_Digblock_Id = @iDigblock_Id
			AND H.Haulage_State_Id = 'N'
			AND (G.Is_Visible = @iGrade_Visibility 
				OR @iGrade_Visibility IS NULL)
		GROUP BY G.Grade_Name
		UNION All
		--Survey 
		SELECT @TonnesTerm, DST.Name, @SurveyIndex, Sum(DSS.Depleted_Tonnes)
		FROM dbo.DigblockSurveyType AS DST
			INNER JOIN dbo.DigblockSurvey AS DS
				ON (DST.Digblock_Survey_Type_Id = DS.Digblock_Survey_Type_Id)
			INNER JOIN dbo.DigblockSurveySample AS DSS
				ON (DSS.Digblock_Survey_Id = DS.Digblock_Survey_Id)
		WHERE DST.Is_Visible = 1
			AND DSS.Digblock_Id = @iDigblock_Id
		GROUP BY DST.Name
		UNION All
		SELECT G.Grade_Name, DST.Name, @SurveyIndex,
			Sum(DSS.Depleted_Tonnes * DSSG.Grade_Value) / NullIf(Sum(DSS.Depleted_Tonnes), 0)
		FROM dbo.DigblockSurveyType AS DST
			INNER JOIN dbo.DigblockSurvey AS DS
				ON (DST.Digblock_Survey_Type_Id = DS.Digblock_Survey_Type_Id)
			INNER JOIN dbo.DigblockSurveySample AS DSS
				ON (DSS.Digblock_Survey_Id = DS.Digblock_Survey_Id)
			INNER JOIN dbo.DigblockSurveySampleGrade AS DSSG
				ON (DSS.Digblock_Survey_Sample_Id = DSSG.Digblock_Survey_Sample_Id)
			INNER JOIN dbo.Grade AS G
				ON (DSSG.Grade_Id = G.Grade_Id)
		WHERE DST.Is_Visible = 1
			AND DSS.Digblock_Id = @iDigblock_Id
			AND (G.Is_Visible = @iGrade_Visibility 
				OR @iGrade_Visibility IS NULL)
		GROUP BY DST.Name, G.Grade_Name
		UNION All
		--Reconciled
		SELECT @TonnesTerm, @ReconciledTerm, @ReconciledIndex, Sum(DPT.Tonnes)
		FROM dbo.DataProcessTransaction AS DPT
		WHERE DPT.Source_Digblock_Id = @iDigblock_Id
		UNION All
		SELECT G.Grade_Name, @ReconciledTerm, @ReconciledIndex, 
			Sum(DPT.Tonnes * DPTG.Grade_Value) / NullIf(Sum(DPT.Tonnes), 0)
		FROM dbo.DataProcessTransaction AS DPT
			INNER JOIN dbo.DataProcessTransactionGrade DPTG
				ON (DPT.Data_Process_Transaction_Id = DPTG.Data_Process_Transaction_Id)
			INNER JOIN dbo.Grade G
				ON (DPTG.Grade_Id = G.Grade_Id)
		WHERE DPT.Source_Digblock_Id = @iDigblock_Id
			AND (G.Is_Visible = @iGrade_Visibility 
				OR @iGrade_Visibility IS NULL)
		GROUP BY G.Grade_Name

		--Block Models
		IF @iIncludeBlockModels = 1
		BEGIN
			INSERT INTO #Value
			(
				Attribute, Measure, OrderNo, Value
			)
			SELECT @TonnesTerm, BM.Name, @BlockModelIndex, 
				Sum(MBP.Tonnes * Percentage_In_Digblock)
			FROM dbo.BlockModel AS BM
				INNER JOIN dbo.ModelBlock AS MB
					ON (BM.Block_Model_Id = MB.Block_Model_Id)
				INNER JOIN dbo.DigblockModelBlock DMB
					ON (DMB.Model_Block_Id = MB.Model_Block_Id)
				INNER JOIN dbo.ModelBlockPartial MBP
					ON (MBP.Model_Block_Id = MB.Model_Block_Id)
			WHERE BM.Is_Displayed = 1
				AND DMB.Digblock_Id = @iDigblock_Id
			GROUP BY BM.Name
			UNION All
			SELECT G.Grade_Name, BM.Name, @BlockModelIndex, 
				Sum(MBP.Tonnes * Percentage_In_Digblock * MBPG.Grade_Value) / NullIf(Sum(MBP.Tonnes * Percentage_In_Digblock), 0)
			FROM dbo.BlockModel AS BM
				INNER JOIN dbo.ModelBlock AS MB
					ON (BM.Block_Model_Id = MB.Block_Model_Id)
				INNER JOIN dbo.DigblockModelBlock DMB
					ON (DMB.Model_Block_Id = MB.Model_Block_Id)
				INNER JOIN dbo.ModelBlockPartial MBP
					ON (MBP.Model_Block_Id = MB.Model_Block_Id)
				INNER JOIN dbo.ModelBlockPartialGrade AS MBPG	
					ON (MBP.Model_Block_Id = MBPG.Model_Block_Id
						AND MBP.Sequence_No = MBPG.Sequence_No)
				INNER JOIN dbo.Grade AS G
					ON (MBPG.Grade_Id = G.Grade_Id)
			WHERE BM.Is_Displayed = 1
				AND DMB.Digblock_Id = @iDigblock_Id
				AND (G.Is_Visible = @iGrade_Visibility 
					OR @iGrade_Visibility IS NULL)
			GROUP BY BM.Name, G.Grade_Name
		END

		--Mine Plans
		IF @iIncludeMinePlans = 1
		BEGIN
			INSERT INTO #Value
			(
				Attribute, Measure, OrderNo, Value
			)
			SELECT @TonnesTerm, MP.Name, @MinePlanIndex, Sum(MPP.Tonnes)
			FROM dbo.MinePlan AS MP
				INNER JOIN @MinePlanDates AS MPD
					ON (MP.Mine_Plan_Id = MPD.Mine_Plan_Id)
				INNER JOIN dbo.MinePlanPeriod AS MPP
					ON (MPD.Mine_Plan_Id = MPP.Mine_Plan_Id
						AND MPP.End_Date >= MPD.Start_Date
						AND MPP.Start_Date <= MPD.End_Date)
				INNER JOIN 
					(
						--Only return 1 MPL Record based ON Digblocks (Stops double counting)
						SELECT MPL.Mine_Plan_Period_Id
						FROM dbo.DigblockLocation AS DL
							INNER JOIN dbo.LocationType AS LT
								ON (DL.Location_Type_Id = LT.Location_Type_Id)
							INNER JOIN dbo.MinePlanPeriodLocation AS MPL
								ON DL.Location_Id = MPL.Location_Id
							INNER JOIN dbo.MinePlanPeriod AS MPP
								ON (MPL.Mine_Plan_Period_Id = MPP.Mine_Plan_Period_Id)
							INNER JOIN @MinePlanDates AS MPD
								ON (MPD.Mine_Plan_Id = MPP.Mine_Plan_Id)
						WHERE DL.Digblock_Id = @iDigblock_Id
							AND LT.Defines_3d_Point = 1
						GROUP BY MPL.Mine_Plan_Period_Id
					) AS MPL
				ON (MPL.Mine_Plan_Period_Id = MPP.Mine_Plan_Period_Id)
			WHERE MP.Parent_Mine_Plan_Id IS NULL
				AND MP.Is_Visible = 1 
				AND MPP.Is_From_Pit = 1
			GROUP BY MP.Name
			UNION All
			SELECT G.Grade_Name, MP.Name, @MinePlanIndex, 
				Sum(MPP.Tonnes * MPPG.Grade_Value) / NullIf(Sum(MPP.Tonnes), 0)
			FROM dbo.MinePlan AS MP
				INNER JOIN @MinePlanDates AS MPD
					ON (MP.Mine_Plan_Id = MPD.Mine_Plan_Id)
				INNER JOIN dbo.MinePlanPeriod AS MPP
					ON (MPD.Mine_Plan_Id = MPP.Mine_Plan_Id
						AND MPP.End_Date >= MPD.Start_Date
						AND MPP.Start_Date <= MPD.End_Date)
				INNER JOIN 
					(
						--Only return 1 MPL Record based on Digblocks (Stops double counting)
						SELECT MPL.Mine_Plan_Period_Id
						FROM dbo.DigblockLocation AS DL
							INNER JOIN dbo.LocationType AS LT
								ON (DL.Location_Type_Id = LT.Location_Type_Id)
							INNER JOIN dbo.MinePlanPeriodLocation AS MPL
								ON DL.Location_Id = MPL.Location_Id
							INNER JOIN dbo.MinePlanPeriod AS MPP
								ON (MPL.Mine_Plan_Period_Id = MPP.Mine_Plan_Period_Id)
							INNER JOIN @MinePlanDates AS MPD
								ON (MPD.Mine_Plan_Id = MPP.Mine_Plan_Id)
						WHERE DL.Digblock_Id = @iDigblock_Id
							AND LT.Defines_3d_Point = 1
						GROUP BY MPL.Mine_Plan_Period_Id
					) AS MPL
					ON (MPL.Mine_Plan_Period_Id = MPP.Mine_Plan_Period_Id)
				INNER JOIN dbo.MinePlanPeriodGrade AS MPPG
					ON (MPPG.Mine_Plan_Period_Id = MPP.Mine_Plan_Period_Id)
				INNER JOIN dbo.Grade AS G
					ON (MPPG.Grade_Id = G.Grade_Id)
			WHERE MP.Parent_Mine_Plan_Id IS NULL
				AND MP.Is_Visible = 1 
				AND MPP.Is_From_Pit = 1
				AND (G.Is_Visible = @iGrade_Visibility 
					OR @iGrade_Visibility IS NULL)
			GROUP BY MP.Name, G.Grade_Name
		END

		--Use Grade Control for Haulage & Survey Grades when they are NULL
		INSERT INTO #Value
		(
			Attribute, Measure, OrderNo, Value
		)
		SELECT V.Attribute, @HauledTerm, @HaulageIndex,  V.Value
		FROM #Value AS V
			INNER JOIN #Value AS H2 --This check makes sure we got tonnes 
				ON (H2.Attribute = @TonnesTerm
					AND H2.Measure = @HauledTerm)
			LEFT OUTER JOIN #Value AS H
				ON (V.Attribute = H.Attribute
					AND H.Measure = @HauledTerm)
		WHERE V.Measure = @GradeControlTerm
			AND V.Attribute <> @TonnesTerm
		GROUP BY V.Attribute, V.Value
		HAVING Count(H.Attribute) = 0
		UNION ALL
		SELECT V.Attribute, S2.Measure, @SurveyIndex,  V.Value
		FROM #Value AS V
			INNER JOIN #Value AS S2  --This check makes sure we got tonnes 
				ON (S2.Attribute = @TonnesTerm
					AND S2.OrderNo = @SurveyIndex)
			LEFT OUTER JOIN #Value AS S
				ON (V.Attribute = S.Attribute
					AND S2.OrderNo = @SurveyIndex)
		WHERE V.Measure = @GradeControlTerm
			AND V.Attribute <> @TonnesTerm
		GROUP BY V.Attribute, V.Value, S2.Measure
		HAVING Count(S.Attribute) = 0

		--Work out Percentage of Grade Control
		INSERT INTO #Value
		(
			Attribute, Measure, OrderNo, Value
		)
		SELECT @GCPercentTerm, M.Measure, M.OrderNo, 
			(M.Value / NullIf(GC.Value, 0)) * 100
		FROM #Value AS GC
			INNER JOIN #Value AS M
				ON (GC.Attribute = M.Attribute)
		WHERE GC.Measure = @GradeControlTerm
			AND M.Measure <> @GradeControlTerm
			AND GC.Attribute = @TonnesTerm

		UPDATE #Value Set ProductSize = 'TOTAL'

		If @iIncludeLumpFines = 1
		Begin
		
			INSERT INTO #Value (Attribute, Measure, ProductSize, OrderNo, Value)
				SELECT 
					g.Grade_Name as Attribute,
					bm.Name as Measure,
					'LUMP' as ProductSize,
					2 as OrderNo, -- This has to be hardcoded to match the OrderNo for the other model records
					Sum(mbp.Tonnes * bg.LumpValue) / Sum(mbp.Tonnes) as Value
				FROM #Value v
					INNER JOIN Grade g ON g.Grade_Name = v.Attribute
					INNER JOIN BlockModel bm ON bm.Name = v.Measure
					INNER JOIN ModelBlock mb ON mb.Code = @iDigblock_Id AND mb.Block_Model_Id = bm.Block_Model_Id
					INNER JOIN ModelBlockPartial mbp ON mbp.Model_Block_Id = mb.Model_Block_Id
					INNER JOIN dbo.BhpbioBlastBlockLumpFinesGrade bg 
						ON bg.ModelBlockId = mbp.Model_Block_Id 
							AND bg.SequenceNo = mbp.Sequence_No
							AND bg.GradeId = g.Grade_Id
							AND bg.GeometType = 'As-Shipped'
				GROUP BY bm.Name, g.Grade_Id, g.Grade_Name
				UNION
				SELECT 
					g.Grade_Name as Attribute,
					bm.Name as Measure,
					'FINES' as ProductSize,
					2 as OrderNo, -- This has to be hardcoded to match the OrderNo for the other model records
					Sum(mbp.Tonnes * bg.FinesValue) / Sum(mbp.Tonnes) as Value
				FROM #Value v
					INNER JOIN Grade g ON g.Grade_Name = v.Attribute
					INNER JOIN BlockModel bm ON bm.Name = v.Measure
					INNER JOIN ModelBlock mb ON mb.Code = @iDigblock_Id AND mb.Block_Model_Id = bm.Block_Model_Id
					INNER JOIN ModelBlockPartial mbp ON mbp.Model_Block_Id = mb.Model_Block_Id
					INNER JOIN dbo.BhpbioBlastBlockLumpFinesGrade bg 
						ON bg.ModelBlockId = mbp.Model_Block_Id 
							AND bg.SequenceNo = mbp.Sequence_No
							AND bg.GradeId = g.Grade_Id
							AND bg.GeometType = 'As-Shipped'
				GROUP BY bm.Name, g.Grade_Id, g.Grade_Name
				
			UPDATE #Value Set Attribute = Attribute + ' (' COLLATE Database_Default + ProductSize + ')' COLLATE Database_Default Where ProductSize != ('TOTAL'	COLLATE Database_Default)
			
			UPDATE #Value Set Value = 1 / Value WHERE Attribute = 'Density' COLLATE Database_Default AND ISNULL(Value,0) > 0
			
			-- The attribute table needs to have a list of the all the attribute names - it doesn't
			-- populate them automatically when pivoting. We will generate the L/F attribute names automatically
			-- based off the list of allowed grades in @LumpFinesGrades
			INSERT INTO #Attribute (Attribute, OrderNo)
				SELECT 
					g.Grade_Name + ' (' + s.ProductSize + ')' as Attribute, -- make sure this matches the attribute names in the #Value query above
					CASE WHEN ProductSize = 'Lump' Then a.OrderNo + 1 Else a.OrderNo + 2 End as OrderNo
				FROM Grade g
					INNER JOIN #Attribute a ON a.Attribute = g.Grade_Name
					INNER JOIN @LumpFinesGrades lfg on lfg.GradeId = g.Grade_Id
					CROSS JOIN (
						Select 'Lump' as ProductSize 
						Union 
						Select 'Fines' as ProductSize 
					) as s

		End

		
		--Pivot values against attribute table
		EXEC PivotTable
			@iTargetTable = '#Attribute',
			@iPivotTable = '#Value',
			@iJoinColumns = '#Attribute.Attribute = #Value.Attribute',
			@iPivotColumn = 'Measure',
			@iPivotValue = 'Value',
			@iPivotType = 'FLOAT',
			@iPivotOrderColumn = 'OrderNo',
			@iPivotOrderDirection = 'Asc'

		--Select Final Results
		SELECT *
		FROM #Attribute
		Order BY OrderNo

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@Trancount > 0 
		BEGIN
			ROLLBACK TRANSACTION
		END

		--Rethrow the exception
		DECLARE @ErrorMessage NVARCHAR(4000),
			@ErrorSeverity INT,
			@ErrorState INT

		SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), 
			@ErrorState = ERROR_STATE()

		RaisError(@ErrorMessage, @ErrorSeverity, @ErrorState)
	END CATCH	

	DROP TABLE #Attribute
	DROP TABLE #Value

END 
GO 
GRANT EXECUTE ON dbo.GetBhpbioDigblockDetailList TO CoreDigblockManager

/*
<TAG Name="Data Dictionary" ProcedureName="GetDigblockDetailList">
 <Procedure>
	Returns the digblock details for the specified @iDigblock_Id.
	Errors raised:
		Digblock Id does not exist.
 </Procedure>
</TAG>
*/
