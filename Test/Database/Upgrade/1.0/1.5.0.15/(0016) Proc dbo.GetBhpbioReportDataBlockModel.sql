IF OBJECT_ID('dbo.GetBhpbioReportDataBlockModel') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportDataBlockModel
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReportDataBlockModel
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iDateBreakdown VARCHAR(31),
	@iLocationId INT,
	@iChildLocations BIT,
	@iBlockModelName VARCHAR(31),
	@iIncludeLiveData BIT,
	@iIncludeApprovedData BIT
)
WITH ENCRYPTION
AS 
BEGIN 
	DECLARE @TransactionCount INT
	DECLARE @TransactionName VARCHAR(32)

	DECLARE @modelApprovalTagId VARCHAR(31)
	DECLARE @BlockModelId INT
	DECLARE @MaterialCategory VARCHAR(31)
	SET @MaterialCategory = 'Designation'
	
	DECLARE @TonnesTable TABLE
	(
		BlockModelId INT NULL,
		BlockModelName VARCHAR(31) NULL,
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		MaterialTypeId INT NOT NULL,
		ParentLocationId INT NULL,
		Tonnes FLOAT NOT NULL
	)
	DECLARE @GradesTable TABLE
	(
		BlockModelId INT NULL,
		BlockModelName VARCHAR(31) NULL,
		CalendarDate DATETIME NOT NULL,
		DateFrom DATETIME NOT NULL,
		DateTo DATETIME NOT NULL,
		MaterialTypeId INT NOT NULL,
		ParentLocationId INT NULL,
		GradeId INT NOT NULL,
		GradeValue FLOAT NOT NULL,
		Tonnes FLOAT NOT NULL
	)

	SET NOCOUNT ON 

	SELECT @TransactionName = 'GetBhpbioReportDataBlockModel',
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

	DECLARE curBlockModelCursor CURSOR FOR	SELECT DISTINCT Block_Model_Id, Name 
											FROM dbo.BlockModel bm
											WHERE (Name = @iBlockModelName OR @iBlockModelName IS NULL)
												AND bm.Is_Default = 1

	DECLARE @currentBlockModelName VARCHAR(31)
  			
	BEGIN TRY
	
		OPEN curBlockModelCursor
		DECLARE @Location TABLE
		(
			LocationId INTEGER,
			ParentLocationId INTEGER,
			IncludeStart DATETIME,
			IncludeEnd DATETIME
		)
		
		DECLARE @ModelMovement TABLE
				(
					CalendarDate DATETIME NOT NULL,
					DateFrom DATETIME NOT NULL,
					DateTo DATETIME NOT NULL,
					MaterialTypeId INT NOT NULL,
					BlockModelId INT NOT NULL,
					ParentLocationId INT NULL,
					ModelBlockId INT NOT NULL,
					SequenceNo INT NOT NULL,
					MinedPercentage FLOAT NOT NULL,
					Tonnes FLOAT NOT NULL,
					PRIMARY KEY (CalendarDate, DateFrom, DateTo, MaterialTypeId, BlockModelId, ModelBlockId, SequenceNo)
				)
		
		INSERT INTO @Location
			(LocationId, ParentLocationId, IncludeStart,IncludeEnd)
		SELECT LocationId, ParentLocationId,IncludeStart,IncludeEnd
		FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, @iChildLocations, NULL, @iDateFrom, @iDateTo)
		
		FETCH NEXT FROM curBlockModelCursor INTO @BlockModelId, @currentBlockModelName
		
		WHILE @@FETCH_STATUS = 0
		BEGIN
		
			DELETE FROM @ModelMovement

			IF @iIncludeLiveData  = 1
			BEGIN
			
				SELECT @modelApprovalTagId = 
				'F1' + REPLACE(@currentBlockModelName,' ','') + 'Model'

				-- Insert the MBP
				INSERT INTO @ModelMovement
					(CalendarDate, DateFrom, DateTo, BlockModelId, MaterialTypeId, ParentLocationId, ModelBlockId, SequenceNo, MinedPercentage, Tonnes)
				SELECT B.CalendarDate, B.DateFrom, B.DateTo, MB.Block_Model_Id, MT.Material_Type_Id, case when @iChildLocations=0 then null else L.ParentLocationId end as ParentLocationId , 
					MBP.Model_Block_Id, MBP.Sequence_No, 
					SUM(RM.MinedPercentage), SUM(RM.MinedPercentage * MBP.Tonnes)
				FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
					INNER JOIN dbo.BhpbioImportReconciliationMovement AS RM
						ON (RM.DateFrom >= B.DateFrom
							AND RM.DateTo <= B.DateTo)
							
					INNER JOIN @Location AS L
						ON (L.LocationId = RM.BlockLocationId  
						AND ( RM.DateFrom >= L.IncludeStart AND RM.DateTo <= L.IncludeEnd
						))
						
					INNER JOIN dbo.ModelBlockLocation AS MBL
						ON (L.LocationId = MBL.Location_Id)
					INNER JOIN dbo.ModelBlock AS MB
						ON (MBL.Model_Block_Id = MB.Model_Block_Id)
					INNER JOIN dbo.ModelBlockPartial AS MBP
						ON (MB.Model_Block_Id = MBP.Model_Block_Id)
					INNER JOIN dbo.GetMaterialsByCategory(@MaterialCategory) AS MC
						ON (MC.MaterialTypeId = MBP.Material_Type_Id)
					INNER JOIN dbo.MaterialType AS MT
						ON (MC.RootMaterialTypeId = MT.Material_Type_Id)
					INNER JOIN dbo.GetBhpbioReportHighGrade() AS BRHG
						ON (BRHG.MaterialTypeId = MT.Material_Type_Id)

					INNER JOIN BhpbioLocationDate block 
						ON block.Location_Id = L.LocationId
						AND ( B.CalendarDate BETWEEN  block.Start_Date AND block.End_Date)
						
					INNER JOIN BhpbioLocationDate blast 
						ON blast.Location_Id = block.Parent_Location_Id
						AND ( B.CalendarDate BETWEEN blast.Start_Date AND blast.End_Date)
					INNER JOIN BhpbioLocationDate bench 
						ON bench.Location_Id = blast.Parent_Location_Id
						AND ( B.CalendarDate BETWEEN bench.Start_Date AND bench.End_Date)
					INNER JOIN BhpbioLocationDate pit 
						ON pit.Location_Id = bench.Parent_Location_Id
						AND ( B.CalendarDate BETWEEN pit.Start_Date AND pit.End_Date)

					LEFT JOIN dbo.BhpbioApprovalData a
						ON a.LocationId = pit.Location_Id
						AND a.TagId = @modelApprovalTagId
						AND a.ApprovedMonth = dbo.GetDateMonth(RM.DateFrom)
				WHERE	(	
							MB.Block_Model_Id = @BlockModelId 
						)
						AND
						(
							@iIncludeApprovedData = 0
							OR 
							a.LocationId IS NULL
						)
				GROUP BY B.CalendarDate, B.DateFrom, B.DateTo, MB.Block_Model_Id, MT.Material_Type_Id
					, case when @iChildLocations=0 then null else L.ParentLocationId end	--L.ParentLocationId
					, MBP.Model_Block_Id, MBP.Sequence_No
				
				-- Retrieve Tonnes
				INSERT INTO @TonnesTable
				(
					BlockModelId,
					BlockModelName,
					CalendarDate,
					DateFrom,
					DateTo,
					MaterialTypeId,
					ParentLocationId,
					Tonnes
				)
				SELECT MM.BlockModelId, BM.Name AS ModelName, MM.CalendarDate, MM.DateFrom, MM.DateTo, MM.MaterialTypeId, MM.ParentLocationId, SUM(MM.Tonnes) AS Tonnes
				FROM @ModelMovement AS MM
					INNER JOIN dbo.BlockModel AS BM
						ON (BM.Block_Model_Id = MM.BlockModelId)
				GROUP BY MM.CalendarDate, MM.DateFrom, MM.DateTo, MM.MaterialTypeId, MM.ParentLocationId, MM.BlockModelId, BM.Name

				-- Retrieve Grades
				INSERT INTO @GradesTable
				(
					BlockModelId,
					BlockModelName,
					CalendarDate,
					DateFrom,
					DateTo,
					MaterialTypeId,
					ParentLocationId,
					GradeId,
					GradeValue,
					Tonnes
				)
				SELECT MM.BlockModelId, BM.Name AS ModelName, MM.CalendarDate, MM.DateFrom, MM.DateTo, MM.MaterialTypeId, MM.ParentLocationId, MBPG.Grade_Id,
					SUM(MBP.Tonnes * MM.MinedPercentage * MBPG.Grade_Value) / SUM(MBP.Tonnes * MM.MinedPercentage) As GradeValue,
					SUM(MBP.Tonnes * MM.MinedPercentage)
				FROM @ModelMovement AS MM
					INNER JOIN dbo.BlockModel AS BM
						ON (BM.Block_Model_Id = MM.BlockModelId)
					INNER JOIN dbo.ModelBlockPartial AS MBP
						ON (MBP.Model_Block_Id = MM.ModelBlockId
							AND MBP.Sequence_No = MM.SequenceNo)
					INNER JOIN dbo.ModelBlockPartialGrade AS MBPG
						ON (MBP.Model_Block_Id = MBPG.Model_Block_Id
							AND MBP.Sequence_No = MBPG.Sequence_No)
				GROUP BY MM.BlockModelId, BM.Name, MM.CalendarDate, MM.ParentLocationId, MM.DateFrom, MM.DateTo, MM.MaterialTypeId, MBPG.Grade_Id
			END
			
			IF @iIncludeApprovedData  = 1
			BEGIN
			
				DECLARE @summaryEntryTypeId INT
		
				SELECT @summaryEntryTypeId = bset.SummaryEntryTypeId
				FROM dbo.BhpbioSummaryEntryType bset
				WHERE bset.Name = REPLACE(@currentBlockModelName,' ','') + 'ModelMovement'
					AND bset.AssociatedBlockModelId = @BlockModelId
							
				-- Retrieve Tonnes
				INSERT INTO @TonnesTable
				(
					BlockModelId,
					BlockModelName,
					CalendarDate,
					DateFrom,
					DateTo,
					MaterialTypeId,
					ParentLocationId,
					Tonnes
				)
				SELECT @BlockModelId AS BlockModelId, @currentBlockModelName AS ModelName, B.CalendarDate AS CalendarDate, B.DateFrom, B.DateTo, MT.Material_Type_Id, case when @iChildLocations=0 then null else L.ParentLocationId end as ParentLocationId, SUM(bse.Tonnes) AS Tonnes
				FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
					INNER JOIN dbo.BhpbioSummary s
						ON s.SummaryMonth >= B.DateFrom AND s.SummaryMonth < B.DateTo
					INNER JOIN dbo.BhpbioSummaryEntry AS bse
						ON bse.SummaryId = s.SummaryId
						AND bse.SummaryEntryTypeId = @summaryEntryTypeId
					INNER JOIN @Location l
						ON l.LocationId = bse.LocationId
						AND s.SummaryMonth BETWEEN l.IncludeStart AND l.IncludeEnd
					INNER JOIN dbo.GetMaterialsByCategory(@MaterialCategory) AS MC
						ON (MC.MaterialTypeId = bse.MaterialTypeId)
					INNER JOIN dbo.MaterialType AS MT
						ON (MC.RootMaterialTypeId = MT.Material_Type_Id)
					INNER JOIN dbo.GetBhpbioReportHighGrade() AS BRHG
						ON (BRHG.MaterialTypeId = MT.Material_Type_Id)
				GROUP BY B.CalendarDate, B.DateFrom, B.DateTo, MT.Material_Type_Id, case when @iChildLocations=0 then null else L.ParentLocationId end

				-- Retrieve Grades
				INSERT INTO @GradesTable
				(
					BlockModelId,
					BlockModelName,
					CalendarDate,
					DateFrom,
					DateTo,
					ParentLocationId,
					MaterialTypeId,
					GradeId,
					GradeValue,
					Tonnes
				)
				SELECT @BlockModelId AS BlockModelId, @currentBlockModelName AS ModelName, B.CalendarDate AS CalendarDate, B.DateFrom, B.DateTo, case when @iChildLocations=0 then null else L.ParentLocationId end as ParentLocationId, MT.Material_Type_Id, bseg.GradeId,
					SUM(bse.Tonnes * bseg.GradeValue) / SUM(bse.Tonnes) As GradeValue,
					SUM(bse.Tonnes)
				FROM dbo.GetBhpbioReportBreakdown(@iDateBreakdown, @iDateFrom, @iDateTo, 1 /* do not include data before start date */) AS B
					INNER JOIN dbo.BhpbioSummary s
						ON s.SummaryMonth >= B.DateFrom AND s.SummaryMonth < B.DateTo
					INNER JOIN dbo.BhpbioSummaryEntry AS bse
						ON bse.SummaryId = s.SummaryId
						AND bse.SummaryEntryTypeId = @summaryEntryTypeId
					INNER JOIN @Location l
						ON l.LocationId = bse.LocationId
						AND s.SummaryMonth BETWEEN l.IncludeStart AND l.IncludeEnd
					INNER JOIN dbo.BhpbioSummaryEntryGrade AS bseg
						ON bseg.SummaryEntryId = bse.SummaryEntryId
					INNER JOIN dbo.GetMaterialsByCategory(@MaterialCategory) AS MC
						ON (MC.MaterialTypeId = bse.MaterialTypeId)
					INNER JOIN dbo.MaterialType AS MT
						ON (MC.RootMaterialTypeId = MT.Material_Type_Id)
					INNER JOIN dbo.GetBhpbioReportHighGrade() AS BRHG
						ON (BRHG.MaterialTypeId = MT.Material_Type_Id)
				GROUP BY B.CalendarDate, case when @iChildLocations=0 then null else L.ParentLocationId end, B.DateFrom, B.DateTo, MT.Material_Type_Id, bseg.GradeId
			END
			
			FETCH NEXT FROM curBlockModelCursor INTO @BlockModelId, @currentBlockModelName
			
		END
		-- output combined tonnes
		SELECT t.BlockModelId, t.BlockModelName AS ModelName, t.CalendarDate, 
			t.DateFrom, t.DateTo, t.MaterialTypeId, t.ParentLocationId, Sum(t.Tonnes) as Tonnes
		FROM @TonnesTable t
		GROUP BY t.CalendarDate, t.DateFrom, t.DateTo, t.MaterialTypeId, t.ParentLocationId, t.BlockModelId, t.BlockModelName
		
		-- output combined grades
		SELECT gt.BlockModelId, gt.BlockModelName AS ModelName, gt.CalendarDate, 
			gt.DateFrom, gt.DateTo, gt.ParentLocationId, gt.MaterialTypeId, g.Grade_Name As GradeName,
			SUM(gt.Tonnes * gt.GradeValue) / SUM(gt.Tonnes) As GradeValue
		FROM @GradesTable AS gt
			INNER JOIN dbo.Grade g
				ON (g.Grade_Id = gt.GradeId)
		GROUP BY gt.BlockModelId, gt.BlockModelName, gt.CalendarDate, gt.ParentLocationId, gt.DateFrom, gt.DateTo, gt.MaterialTypeId, g.Grade_Name
		
		CLOSE curBlockModelCursor
		DEALLOCATE curBlockModelCursor
		
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

GRANT EXECUTE ON dbo.GetBhpbioReportDataBlockModel TO BhpbioGenericManager
GO

/*
EXEC dbo.GetBhpbioReportDataBlockModel
	@iDateFrom = '1-apr-2008',
	@iDateTo = '1-jun-2009',
	@iDateBreakdown = 'MONTH',
	@iLocationId = 1,
	@iLocationBreakdown = 'ChildLocations',
	@iBlockModelName = NULL,
	@iIncludeLiveData = 1,
	@iIncludeApprovedData = 1
EXEC dbo.GetBhpbioReportDataBlockModel
	@iDateFrom = '2012-01-01',
	@iDateTo = '2012-01-31',
	@iDateBreakdown = NULL,
	@iLocationId = 8,
	@iChildLocations = 1,
	@iBlockModelName = 'Geology',
	@iIncludeLiveData = 0,
	@iIncludeApprovedData = 01
*/