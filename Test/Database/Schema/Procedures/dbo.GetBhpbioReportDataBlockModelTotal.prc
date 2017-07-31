IF OBJECT_ID('dbo.GetBhpbioReportDataBlockModelTotal') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportDataBlockModelTotal  
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReportDataBlockModelTotal
(
	@iLocationId INT,
	@iAllBlocks BIT
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)
	
	DECLARE @Location TABLE
	(
		LocationId INT NOT NULL,
		PRIMARY KEY (LocationId)
	)
	
	DECLARE @Grade TABLE
	(
		Factor VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		Code VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		GradeName VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
		OrderNo INT NOT NULL,
		GCGradeValue REAL NOT NULL,
		MMGradeValue REAL NOT NULL,
		PRIMARY KEY (Factor, Code, GradeName)
	)
	
	DECLARE @MaterialCategory VARCHAR(31)
	SET @MaterialCategory = 'Designation'
	
	DECLARE @BlankFactor VARCHAR(10)
	SET @BlankFactor = '_blank_'
	
	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioReportDataBlockModelTotal',
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
		
		INSERT INTO @Location
			(LocationId)
		SELECT LocationId
		FROM dbo.GetBhpbioReportLocation(@iLocationId)
		
		CREATE TABLE #FACTOR
		(
			Factor VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
			Code VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
			Tonnes FLOAT NULL,
			Volume FLOAT NULL,
			PRIMARY KEY (Factor, Code)
		)

		CREATE TABLE #FACTORGRADE
		(
			Factor VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
			Code VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
			GradeName VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
			OrderNo INT NOT NULL,
			GradeValue FLOAT NULL,
			PRIMARY KEY (Factor, Code, GradeName)
		)
		
		DECLARE @ModelBlockPartial TABLE
		(
			BlockModelId INT NOT NULL,
			ModelBlockId INT NOT NULL,
			SequenceNo INT NOT NULL,
			Code VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
			Tonnes FLOAT NULL,
			PRIMARY KEY (BlockModelId, ModelBlockId, SequenceNo, Code)
		)
		
		-- Get the MBP Records
		INSERT INTO @ModelBlockPartial
			(BlockModelId, ModelBlockId, SequenceNo, Code, Tonnes)
		SELECT MB.Block_Model_Id, MBP.Model_Block_Id, MBP.Sequence_No, MB.Code, MBP.Tonnes
		FROM dbo.ModelBlockLocation AS MBL
			INNER JOIN @Location AS L
				ON (L.LocationId = MBL.Location_Id)
			INNER JOIN dbo.ModelBlock AS MB
				ON (MB.Model_Block_Id = MBL.Model_Block_Id)
			INNER JOIN dbo.ModelBlockPartial AS MBP
				ON (MBP.Model_Block_Id = MB.Model_Block_Id)
			INNER JOIN dbo.GetMaterialsByCategory(@MaterialCategory) AS MC
				ON (MC.MaterialTypeId = MBP.Material_Type_Id)
			INNER JOIN dbo.GetBhpbioReportHighGrade() AS BRHG
				ON (BRHG.MaterialTypeId = MC.RootMaterialTypeId)
			INNER JOIN dbo.BlockModel AS BM
				ON (BM.Block_Model_Id = MB.Block_Model_Id)
		WHERE BM.Name IN ('Grade Control', 'Mining', 'Short Term Geology')
		
		
		-- Tonnes (F1)
		INSERT INTO #FACTOR
			(Factor, Code, Tonnes)
		SELECT 'F1Factor' AS Factor, CASE WHEN @iAllBlocks = 1 THEN MMBP.Code ELSE 'All' END, 
			Coalesce(Sum(CASE WHEN BM.Name = 'Grade Control' THEN Tonnes ELSE 0 END) /
			Nullif(Sum(CASE WHEN BM.Name = 'Mining' THEN Tonnes ELSE 0 END), 0), 0) AS Tonnes
		FROM @ModelBlockPartial AS MMBP
			INNER JOIN dbo.BlockModel AS BM
				ON (BM.Block_Model_Id = MMBP.BlockModelId)
		GROUP BY CASE WHEN @iAllBlocks = 1 THEN MMBP.Code ELSE 'All' END

		-- Tonnes (F1.5)
		INSERT INTO #FACTOR
			(Factor, Code, Tonnes)
		SELECT 'F15Factor' AS Factor, CASE WHEN @iAllBlocks = 1 THEN MMBP.Code ELSE 'All' END, 
			Coalesce(Sum(CASE WHEN BM.Name = 'Grade Control' THEN Tonnes ELSE 0 END) /
			Nullif(Sum(CASE WHEN BM.Name = 'Short Term Geology' THEN Tonnes ELSE 0 END), 0), 0) AS Tonnes
		FROM @ModelBlockPartial AS MMBP
			INNER JOIN dbo.BlockModel AS BM
				ON (BM.Block_Model_Id = MMBP.BlockModelId)
		GROUP BY CASE WHEN @iAllBlocks = 1 THEN MMBP.Code ELSE 'All' END
		
		-- Volume (F1)
		UPDATE f
		SET Volume = RS1.Volume
		FROM (
			SELECT 'F1Factor' AS Factor, CASE WHEN @iAllBlocks = 1 THEN MMBP.Code ELSE 'All' END as Code, 
				Coalesce(Sum(CASE WHEN BM.Name = 'Grade Control' THEN MBPV.Field_Value ELSE 0 END) /
				Nullif(Sum(CASE WHEN BM.Name = 'Mining' THEN MBPV.Field_Value ELSE 0 END), 0), 0) AS Volume
			FROM @ModelBlockPartial AS MMBP
				INNER JOIN dbo.BlockModel AS BM
					ON (BM.Block_Model_Id = MMBP.BlockModelId)
				INNER JOIN ModelBlockPartialValue mbpv 
					ON mbpv.Model_Block_Id = MMBP.ModelBlockId 
						AND mbpv.Model_Block_Partial_Field_Id = 'ModelVolume'
						AND mbpv.Sequence_No = MMBP.SequenceNo
			GROUP BY CASE WHEN @iAllBlocks = 1 THEN MMBP.Code ELSE 'All' END
		) As RS1
		Inner Join #FACTOR As f
		ON RS1.Factor = f.Factor and RS1.Code = f.Code
		
		-- Volume (F1.5)
		UPDATE f
		SET Volume = RS1.Volume
		FROM (
			SELECT 'F15Factor' AS Factor, CASE WHEN @iAllBlocks = 1 THEN MMBP.Code ELSE 'All' END as Code, 
				Coalesce(Sum(CASE WHEN BM.Name = 'Grade Control' THEN MBPV.Field_Value ELSE 0 END) /
				Nullif(Sum(CASE WHEN BM.Name = 'Short Term Geology' THEN MBPV.Field_Value ELSE 0 END), 0), 0) AS Volume
			FROM @ModelBlockPartial AS MMBP
				INNER JOIN dbo.BlockModel AS BM
					ON (BM.Block_Model_Id = MMBP.BlockModelId)
				INNER JOIN ModelBlockPartialValue mbpv 
					ON mbpv.Model_Block_Id = MMBP.ModelBlockId 
						AND mbpv.Model_Block_Partial_Field_Id = 'ModelVolume'
						AND mbpv.Sequence_No = MMBP.SequenceNo					
			GROUP BY CASE WHEN @iAllBlocks = 1 THEN MMBP.Code ELSE 'All' END
		) As RS1
		Inner Join #FACTOR As f
		ON RS1.Factor = f.Factor and RS1.Code = f.Code

		--Set to zero if null
		UPDATE #FACTOR
		SET Volume = 0
		Where Volume is Null

		-- Grades (F1)
		INSERT INTO @Grade
			(Factor, Code, GradeName, OrderNo, GCGradeValue, MMGradeValue)
		SELECT 'F1Factor' AS Factor, GV.Code, G.Grade_Name, G.Order_No, 
			Coalesce(Sum(CASE WHEN GV.Name = 'Grade Control' THEN GV.GradeValue ELSE 0 END), 0),
			Coalesce(Sum(CASE WHEN GV.Name = 'Mining' THEN GV.GradeValue ELSE 0 END), 0)
		FROM (
				SELECT BM.Name AS Name, CASE WHEN @iAllBlocks = 1 THEN MMBP.Code ELSE 'All' END AS Code, MBPG.Grade_Id AS GradeId, 
					Sum(MBPG.Grade_Value * MMBP.Tonnes) / Nullif(Sum(MMBP.Tonnes), 0) As GradeValue
				FROM @ModelBlockPartial AS MMBP
					INNER JOIN dbo.BlockModel AS BM
						ON (BM.Block_Model_Id = MMBP.BlockModelId)
					INNER JOIN dbo.ModelBlockPartialGrade AS MBPG
						ON (MBPG.Model_Block_Id = MMBP.ModelBlockId
							AND MBPG.Sequence_No = MMBP.SequenceNo)
				GROUP BY BM.Name, CASE WHEN @iAllBlocks = 1 THEN MMBP.Code ELSE 'All' END, MBPG.Grade_Id
			) AS GV
			INNER JOIN dbo.Grade AS G
				ON (GV.GradeId = G.Grade_Id)
		GROUP BY GV.Code, G.Grade_Name, G.Order_No
		
		
		-- Grades (F1.5)
		INSERT INTO @Grade
			(Factor, Code, GradeName, OrderNo, GCGradeValue, MMGradeValue)
		SELECT 'F15Factor' AS Factor, GV.Code, G.Grade_Name, G.Order_No, 
			Coalesce(Sum(CASE WHEN GV.Name = 'Grade Control' THEN GV.GradeValue ELSE 0 END), 0),
			Coalesce(Sum(CASE WHEN GV.Name = 'Short Term Geology' THEN GV.GradeValue ELSE 0 END), 0)
		FROM (
				SELECT BM.Name AS Name, CASE WHEN @iAllBlocks = 1 THEN MMBP.Code ELSE 'All' END AS Code, MBPG.Grade_Id AS GradeId, 
					Sum(MBPG.Grade_Value * MMBP.Tonnes) / Nullif(Sum(MMBP.Tonnes), 0) As GradeValue
				FROM @ModelBlockPartial AS MMBP
					INNER JOIN dbo.BlockModel AS BM
						ON (BM.Block_Model_Id = MMBP.BlockModelId)
					INNER JOIN dbo.ModelBlockPartialGrade AS MBPG
						ON (MBPG.Model_Block_Id = MMBP.ModelBlockId
							AND MBPG.Sequence_No = MMBP.SequenceNo)
				GROUP BY BM.Name, CASE WHEN @iAllBlocks = 1 THEN MMBP.Code ELSE 'All' END, MBPG.Grade_Id
			) AS GV
			INNER JOIN dbo.Grade AS G
				ON (GV.GradeId = G.Grade_Id)
		GROUP BY GV.Code, G.Grade_Name, G.Order_No
		
		-- Insert all grades for pivoting
		INSERT INTO #FACTORGRADE (Factor, Code, GradeName, OrderNo, GradeValue)
		SELECT @BlankFactor, @BlankFactor, Grade_Name, Order_No, 0.0
		FROM dbo.Grade
		WHERE Is_Visible = 1
		UNION ALL
		SELECT @BlankFactor, @BlankFactor, Grade_Name + 'Absolute', Order_No + 70, 0.0
		FROM dbo.Grade
		WHERE Is_Visible = 1

		-- Grade Values
		INSERT INTO #FACTORGRADE
			(Factor, Code, GradeName, OrderNo, GradeValue)
		SELECT Factor, Code, GradeName, OrderNo,
			(GCGradeValue / NULLIF(MMGradeValue, 0))
		FROM @Grade

		-- Grade Absolute
		INSERT INTO #FACTORGRADE
			(Factor, Code, GradeName, OrderNo, GradeValue)
		SELECT Factor, Code, GradeName + 'Absolute', OrderNo + 70,
			COALESCE(ABS(GCGradeValue - MMGradeValue), 0)
		FROM @Grade
		
		-- Pivot the tables and return.
		EXEC dbo.PivotTable
			@iTargetTable = '#FACTOR',
			@iPivotTable = '#FACTORGRADE',
			@iJoinColumns = '#FACTOR.Factor = #FACTORGRADE.Factor AND #FACTOR.Code = #FACTORGRADE.Code',
			@iPivotColumn = 'GradeName',
			@iPivotValue = 'GradeValue',
			@iPivotType = 'REAL',
			@iPivotOrderColumn = 'OrderNo'

		DELETE FROM #FACTOR
		WHERE Factor = @BlankFactor
		
		-- Not sure if this is correct, but if all H2O values are null, then report displays broken image and #Error because
		-- the web service doesn't produce any <H2O> elements in the result set
		UPDATE #FACTOR
		SET H2O = 0.0, H2OAbsolute = 0.0
		WHERE H2O IS NULL
		
		-- Return results
		SELECT *
		FROM #FACTOR
		ORDER BY Factor Desc
				
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

GRANT EXECUTE ON dbo.GetBhpbioReportDataBlockModelTotal TO BhpbioGenericManager
GO

--EXEC dbo.GetBhpbioReportDataBlockModelTotal  50, 1