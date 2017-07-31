IF OBJECT_ID('Staging.ImportStagingModelBlockAsDroppedToSummaryTables') IS NOT NULL
     DROP PROCEDURE Staging.ImportStagingModelBlockAsDroppedToSummaryTables 
GO 
  
-- this will copy the data from an existing standing model block to the summary tables
-- for As-Dropped ONLY. Although it takes the Staging Id, it actually takes the data from
-- the live tables, so you have to run ImportStagingModelBlockAsDroppedToLiveTables first
--
-- NOTE THAT WILL OVERWRITE ANY EXISTING DATA
CREATE PROCEDURE [Staging].[ImportStagingModelBlockAsDroppedToSummaryTables]
(
	@iStagingModelBlockId INTEGER,
	@iOverrideBlockModelId Integer = null,
	@iSkipDelete BIT  = 0
)
AS
BEGIN

	declare @AsDropped varchar(64) = 'As-Dropped'
	declare @ModelBlockId int
	declare @SequenceNo int
	declare @BlockModelId int
	declare @SummaryEntryTypeId int
	declare @LocationId int
	declare @MaterialTypeId int
	
	declare @SummaryEntries table (
		SummaryEntryId Int PRIMARY KEY,
		GeometType VARCHAR(31)
	)
	
	select
		@ModelBlockId = mbp.Model_Block_Id,
		@SequenceNo = mbp.Sequence_No,
		@BlockModelId = mb.Block_Model_Id,
		@LocationId = mbl.Location_Id,
		@MaterialTypeId = mbp.Material_Type_Id
	from Staging.StageBlockModel sbm
		inner join Staging.StageBlock sb
			on sb.BlockId = sbm.BlockId
		inner join DigblockModelBlock dbmb
			on sb.BlockFullName = dbmb.Digblock_Id
		inner join BlockModel bm
			on bm.[name] = sbm.BlockModelName
		inner join ModelBlock mb
			on mb.Block_Model_Id = bm.Block_Model_Id
				and mb.Model_Block_Id = dbmb.Model_Block_Id
		inner join ModelBlockLocation mbl ON mbl.Model_Block_Id = mb.Model_Block_Id
		inner join MaterialType mt
			on mt.Abbreviation = sbm.MaterialTypeName
				and mt.Material_Category_Id = 'OreType'
		inner join ModelBlockPartial mbp
			on mbp.Material_Type_Id = mt.Material_Type_Id
				and mbp.Model_Block_Id = mb.Model_Block_Id		
	where sbm.BlockModelId = @iStagingModelBlockId

	SELECT @SummaryEntryTypeId = st.SummaryEntryTypeId
	FROM BhpbioSummaryEntryType st
	WHERE st.AssociatedBlockModelId = IsNull(@iOverrideBlockModelId, @BlockModelId)
				and st.Name like '%ModelMovement'

	Insert Into @SummaryEntries
		Select 
			se.SummaryEntryId,
			se.GeometType
		from BhpbioSummaryEntry se
		inner join BhpbioSummary s
			on s.SummaryId = se.SummaryId
		where 
				se.LocationId = @LocationId
				and se.SummaryEntryTypeId = @SummaryEntryTypeId
				and se.MaterialTypeId = @MaterialTypeId
				and s.SummaryMonth >= '2014-09-01'
	
	delete seg
	from @SummaryEntries s
		inner join BhpbioSummaryEntry se
			on se.SummaryEntryId = s.SummaryEntryId
		inner join BhpbioSummaryEntryGrade seg
			on seg.SummaryEntryId = se.SummaryEntryId
		inner join Grade g
			on g.Grade_Id = seg.GradeId
	where (se.GeometType = @AsDropped Or g.Grade_Name in ('Ultrafines', 'H2O'))

	IF @iSkipDelete = 0
	BEGIN
		delete se
		from BhpbioSummaryEntry se
			inner join @SummaryEntries s ON s.SummaryEntryId = se.SummaryEntryId
		where s.GeometType = @AsDropped
	END

	declare @ProductSizes table (ProductSize varchar(32))

	Insert Into @ProductSizes
		select 'LUMP' union
		select 'FINES' union
		select 'TOTAL'

	Insert Into [dbo].[BhpbioSummaryEntry] (SummaryId, SummaryEntryTypeId, LocationId, MaterialTypeId, ProductSize, GeometType, ModelFilename, Tonnes, Volume)
		Select 
			se.SummaryId,
			se.SummaryEntryTypeId,
			se.LocationId,
			se.MaterialTypeId,
			p.ProductSize,
			@AsDropped,
			se.ModelFilename,
			(Case 
				WHEN p.ProductSize = 'LUMP' Then lp.LumpPercent
				WHEN p.ProductSize = 'FINES'  Then (1 - lp.LumpPercent)
				ELSE 0.0
			END * se.Tonnes),
			0 as Volume
		from @SummaryEntries s
			inner join @ProductSizes p
				on p.ProductSize <> 'TOTAL'
			inner join BhpbioSummaryEntry se
				on se.SummaryEntryId = s.SummaryEntryId
					and se.ProductSize = 'TOTAL'
					and se.GeometType = 'NA'
			inner join dbo.BhpbioBlastBlockLumpPercent lp
				on lp.ModelBlockId = @ModelBlockId
					and lp.SequenceNo = @SequenceNo
					and lp.GeometType = @AsDropped

	Delete From @SummaryEntries

	Insert Into @SummaryEntries
		Select 
			se.SummaryEntryId,
			se.GeometType
		from BhpbioSummaryEntry se
			inner join BhpbioSummary s
				on s.SummaryId = se.SummaryId
		where 
				s.SummaryMonth >= '2014-09-01'
				and se.LocationId = @LocationId
				and se.SummaryEntryTypeId = @SummaryEntryTypeId
				and se.MaterialTypeId = @MaterialTypeId
		

	Insert into dbo.BhpbioSummaryEntryGrade (SummaryEntryId, GradeId, GradeValue)
		Select 
			se.SummaryEntryId,
			lfg.GradeId,
			Case 
				when se.ProductSize = 'LUMP' then lfg.LumpValue
				when se.ProductSize = 'FINES' then lfg.FinesValue
				else null
			end
		from @SummaryEntries s
			inner join BhpbioSummaryEntry se
				on se.SummaryEntryId = s.SummaryEntryId
					and se.ProductSize <> 'TOTAL'
					and se.GeometType = 'As-Dropped'
			inner join dbo.BhpbioBlastBlockLumpFinesGrade lfg
				on lfg.ModelBlockId = @ModelBlockId
					and lfg.SequenceNo = @SequenceNo
					and lfg.GeometType = se.GeometType

	
	Insert into dbo.BhpbioSummaryEntryGrade (SummaryEntryId, GradeId, GradeValue)
		Select 
			se.SummaryEntryId,
			g.Grade_Id,
			Case 
				when se.ProductSize = 'LUMP' then lfg.LumpValue
				when se.ProductSize = 'FINES' then lfg.FinesValue
				when se.ProductSize = 'TOTAL' then mbg.Grade_Value
				else null
			end
		from @SummaryEntries s
			inner join BhpbioSummaryEntry se
				on se.SummaryEntryId = s.SummaryEntryId
			inner join Grade g
				on g.Grade_Name in ('Ultrafines', 'H2O')
			left join dbo.BhpbioBlastBlockLumpFinesGrade lfg
				on lfg.ModelBlockId = @ModelBlockId
					and lfg.SequenceNo = @SequenceNo
					and lfg.GeometType = se.GeometType
					and lfg.GradeId = g.Grade_Id
			left join dbo.ModelBlockPartialGrade mbg
				on mbg.Grade_Id = g.Grade_Id
					and mbg.Model_Block_Id = @ModelBlockId
					and mbg.Sequence_No = @SequenceNo
		where se.GeometType <> 'As-Dropped'
			And (Case 
				when se.ProductSize = 'LUMP' then lfg.LumpValue
				when se.ProductSize = 'FINES' then lfg.FinesValue
				when se.ProductSize = 'TOTAL' then mbg.Grade_Value
				else null
			end) is not null


END
GO

