--
-- This will show an blocks that have a mining model in Staging
-- but not in the live tables. This is an indication that the 
-- 'Blocks' import hasn't been trigger properly, and might
-- need to be run manually
--
select
	distinct sb.BlockFullName
from Staging.StageBlock sb
	inner join Staging.StageBlockModel sbm 
		on sbm.BlockId = sb.BlockId
			and sbm.BlockModelName = 'Mining'
	inner join dbo.BlockModel bm
		on bm.Name = sbm.BlockModelName
	inner join dbo.Digblock d
		on d.Digblock_Id = sb.BlockFullName
	left join dbo.ModelBlock mb
		on mb.Code = d.Digblock_Id
			and mb.Block_Model_Id = bm.Block_Model_Id
where mb.Model_Block_Id is null
order by sb.BlockFullName

	
