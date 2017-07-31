--
-- This will show the ModelBlock details, plus the weighted tonnes
-- for all the partials in this block, plus will list the metals tonnes and
-- grades for every model block partial in the block. This is useful for debugging
-- the UI to make sure that it is showing the correct information
--
-- test block: '18SP-0599-0820-A02'
--

declare @BlockName varchar(64) = 'E7-0534-0001-W1'
declare @BlockModelName varchar(31) = 'Grade Control'

--------------------------------------

declare @BlockModel int

select @BlockModel = Block_Model_Id 
from BlockModel 
where Name = @BlockModelName

select
	mb.Model_Block_Id,
	mb.Code,
	mbl.Location_Id,
	sum(mbp.Tonnes) as Tonnes,
	sum(mbpv.Field_Value) as Volume,
	case 
		when sum(mbpv.Field_Value) > 0 then sum(mbp.Tonnes) / sum(mbpv.Field_Value) 
		else null 
	end as Density
from ModelBlock mb
	inner join ModelBlockLocation mbl 
		on mbl.Model_Block_Id = mb.Model_Block_Id
	inner join ModelBlockPartial mbp 
		on mbp.Model_Block_Id = mb.Model_Block_Id
	left join ModelBLockPartialValue mbpv 
		on mbp.Model_Block_Id = mbpv.Model_Block_Id 
			and mbp.Sequence_No = mbpv.Sequence_No 
			and mbpv.Model_Block_Partial_Field_Id = 'ModelVolume'
where mb.Code = @BlockName
	and mb.Block_Model_Id = @BlockModel
group by mb.Model_Block_Id,	mb.Code, mbl.Location_Id


select 
	Model_Block_Id,
	Code,
	Grade_Name,
	(sum(Grade_Tonnes) / sum(Tonnes)) * 100 as WeightedGrade,
	sum(Tonnes) as Tonnes
from
(
	select
		mb.Model_Block_Id,
		mb.Code,
		mbpg.Sequence_No,
		g.Grade_Id,
		g.Grade_Name,
		mbpg.Grade_Value,
		mbp.Tonnes,
		(mbpg.Grade_Value / 100) * mbp.Tonnes as Grade_Tonnes,
		mbpn.Notes as ModelFilename
	from ModelBlock mb
		inner join ModelBLockPartial mbp 
			on mbp.Model_Block_Id = mb.Model_Block_Id
		inner join ModelBlockPartialGrade mbpg 
			on mbpg.Model_Block_Id = mb.Model_Block_Id 
				and mbpg.Sequence_No = mbp.Sequence_No 
		inner join Grade g 
			on g.Grade_Id = mbpg.Grade_Id
		left join dbo.ModelBlockPartialNotes mbpn 
			on mbpn.Sequence_No = mbp.Sequence_No 
				and mbpn.Model_Block_Id = mb.Model_Block_Id 
				and mbpn.Model_Block_Partial_Field_Id = 'ModelFilename'
	where 
		mb.Code = @BlockName and
		mb.Block_Model_Id = @BlockModel
) all_grades
group by Model_Block_Id, Code, Grade_Id, Grade_Name
order by Grade_Id


select
	mb.Model_Block_Id,
	mb.Code,
	mbpg.Sequence_No,
	mt.Description,
	g.Grade_Id,
	g.Grade_Name,
	mbpg.Grade_Value,
	mbp.Tonnes,
	(mbpg.Grade_Value / 100) * mbp.Tonnes as Grade_Tonnes,
	mbpn.Notes as ModelFilename
from ModelBlock mb
	inner join ModelBlockPartial mbp 
		on mbp.Model_Block_Id = mb.Model_Block_Id
	inner join MaterialType mt 
		on mt.Material_Type_Id = mbp.Material_Type_Id
	inner join ModelBlockPartialGrade mbpg 
		on mbpg.Model_Block_Id = mb.Model_Block_Id and mbpg.Sequence_No = mbp.Sequence_No 
	inner join Grade g 
		on g.Grade_Id = mbpg.Grade_Id
	left join dbo.ModelBlockPartialNotes mbpn 
		on mbpn.Sequence_No = mbp.Sequence_No
			and mbpn.Model_Block_Id = mb.Model_Block_Id 
			and mbpn.Model_Block_Partial_Field_Id = 'ModelFilename'
where 
	mb.Code = @BlockName and
	mb.Block_Model_Id = @BlockModel
order by [description], g.grade_id
