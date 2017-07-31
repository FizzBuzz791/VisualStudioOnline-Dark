IF OBJECT_ID('Staging.ImportStagingModelBlockAsDroppedToLiveTables') IS NOT NULL
     DROP PROCEDURE Staging.ImportStagingModelBlockAsDroppedToLiveTables 
GO 
  
-- this will copy the data from an existing standing model block to the live tables
-- for As-Dropped ONLY
--
-- NOTE THAT WILL OVERWRITE ANY EXISTING DATA
CREATE PROCEDURE Staging.ImportStagingModelBlockAsDroppedToLiveTables
(
	@iStagingModelBlockId INTEGER
)
AS
BEGIN

	declare @ModelBlockId int
	declare @SequenceNo int
	declare @AsDropped varchar(64) = 'As-Dropped'

	-- first we need to match the model block and and sequence number to the staging
	-- model block
	select
		@ModelBlockId = mbp.Model_Block_Id,
		@SequenceNo = mbp.Sequence_No
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
		inner join MaterialType mt
			on mt.Abbreviation = sbm.MaterialTypeName
				and mt.Material_Category_Id = 'OreType'
		inner join ModelBlockPartial mbp
			on mbp.Material_Type_Id = mt.Material_Type_Id
				and mbp.Model_Block_Id = mb.Model_Block_Id		
	where sbm.BlockModelId = @iStagingModelBlockId

	-- insert the as-dropped lump percent for this block
	delete from dbo.BhpbioBlastBlockLumpPercent
	where ModelBlockId = @ModelBlockId
		and SequenceNo = @SequenceNo
		and GeometType = @AsDropped

	Insert Into dbo.BhpbioBlastBlockLumpPercent(ModelBlockId, SequenceNo, GeometType, LumpPercent)
		Select @ModelBlockId, @SequenceNo, @AsDropped, LumpPercentAsDropped / 100
		from Staging.StageBlockModel sbm
		where sbm.BlockModelId = @iStagingModelBlockId
			and not sbm.LumpPercentAsDropped is null

	delete from dbo.BhpbioBlastBlockLumpFinesGrade
	where ModelBlockId = @ModelBlockId
		and SequenceNo = @SequenceNo
		and (GeometType = @AsDropped Or GradeId in (7, 10)) -- h2o or UF

	delete from dbo.ModelBlockPartialGrade
	where Model_Block_Id = @ModelBlockId
		and Sequence_No = @SequenceNo
		and Grade_Id = 10

	Insert Into BhpbioBlastBlockLumpFinesGrade (ModelBlockId, SequenceNo, GradeId, GeometType, LumpValue, FinesValue)
		Select 
			@ModelBlockId,
			@SequenceNo,
			g.Grade_Id,
			sbmg.GeometType,
			sbmg.LumpValue,
			sbmg.FinesValue
		from Staging.StageBlockModelGrade sbmg
			inner join Grade g
				on g.Grade_Name = sbmg.GradeName
		where sbmg.BlockModelId = @iStagingModelBlockId
			and (GeometType = @AsDropped Or (sbmg.GradeName in ('Ultrafines', 'H2O') And GeometType <> 'NA'))
			and sbmg.LumpValue is not null
			and sbmg.FinesValue is not null

	Insert Into dbo.ModelBlockPartialGrade (Model_Block_Id, Sequence_No, Grade_Id, Grade_Value)
		Select @ModelBlockId, @SequenceNo, g.Grade_Id, sbmg.GradeValue
		From Staging.StageBlockModelGrade sbmg
			inner join Grade g
				on g.Grade_Name = sbmg.GradeName
		Where sbmg.GradeName = 'Ultrafines'
			And sbmg.GeometType = 'NA'
			And sbmg.BlockModelId = @iStagingModelBlockId
			And sbmg.GradeValue is not null

END
GO

