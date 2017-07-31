Update Staging.TmpAsDroppedImport 
set AD_LUMP_PCT = 100 - AD_LUMP_PCT
where MODEL = 'Grade control'

update Staging.BhpbioStageBlockModel
set LumpPercentAsDropped = 100 - LumpPercentAsDropped
where ModelName = 'Grade Control'
	and LumpPercentAsDropped is not null

update lp
set lp.LumpPercent = 1 - lp.LumpPercent
from dbo.BhpbioBlastBlockLumpPercent lp
	inner join ModelBlockPartial mbp
		on mbp.Model_Block_Id = lp.ModelBlockId
			and mbp.Sequence_No = lp.SequenceNo
	inner join ModelBlock mb
		on mb.Model_Block_Id = mbp.Model_Block_Id
	inner join BlockModel bm
		on bm.Block_Model_Id = mb.Block_Model_Id
where bm.name = 'Grade Control'
	and lp.GeometType = 'As-Dropped'

-- then run normal summary refresh proc (but only for GC)

Select * from Staging.TmpAsDroppedImport 
where MODEL = 'Grade control'

select * from Staging.BhpbioStageBlockModel
where ModelName = 'Grade Control'
	and LumpPercentAsDropped is not null

select *  
from dbo.BhpbioBlastBlockLumpPercent lp
	inner join ModelBlockPartial mbp
		on mbp.Model_Block_Id = lp.ModelBlockId
			and mbp.Sequence_No = lp.SequenceNo
	inner join ModelBlock mb
		on mb.Model_Block_Id = mbp.Model_Block_Id
	inner join BlockModel bm
		on bm.Block_Model_Id = mb.Block_Model_Id
where bm.name = 'Grade Control'
	and lp.GeometType = 'As-Dropped'