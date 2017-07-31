--
-- This fixes the AD tonnes. It should only be necesary to run this in TEST, as the import
-- script has been corrected for the other environments
--
declare @GeometType varchar(64) = 'As-Dropped'
declare @FromMonth datetime = '2014-09-01'
declare @ToMonth datetime = '2017-07-01'
declare @SummaryMonth datetime = @FromMonth


While @SummaryMonth <= @ToMonth
begin
	print @SummaryMonth

	update se
		set se.Tonnes =	(Case 
			WHEN se.ProductSize = 'LUMP' Then lp.LumpPercent
			WHEN se.ProductSize = 'FINES'  Then (1 - lp.LumpPercent)
			ELSE 0.0
		END * se_total.Tonnes)
	from BhpbioSummaryEntry se
		inner join BhpbioSummaryEntry se_total
			on se_total.LocationId = se.LocationId
				and se_total.MaterialTypeId = se.MaterialTypeId
				and se_total.SummaryId = se.SummaryId
				and se_total.SummaryEntryTypeId = se.SummaryEntryTypeId
				and se_total.ProductSize = 'TOTAL'
				and se_total.GeometType = 'NA'
		inner join BhpbioSummary s
			on s.summaryId = se.SummaryId
		inner join BhpbioSummaryEntryType st
			on st.SummaryEntryTypeId = se.SummaryEntryTypeId
				and st.Name like '%ModelMovement'
		inner join BlockModel bm
			on bm.Block_Model_Id = (Case when st.AssociatedBlockModelId = 5 then 1 else st.AssociatedBlockModelId end)
		inner join ModelBlockLocation mbl
			on mbl.Location_Id = se.LocationId
		inner join ModelBlock mb
			on mb.Model_Block_Id = mbl.Model_Block_Id
				and mb.Block_Model_Id = bm.Block_Model_Id
		inner join ModelBlockPartial mbp
			on mbp.Model_Block_Id = mb.Model_Block_Id
				and mbp.Material_Type_Id = se.MaterialTypeId
		inner join BhpbioBlastBlockLumpPercent lp
			on lp.GeometType = se.GeometType
				and lp.ModelBlockId = mbp.Model_Block_Id
				and lp.SequenceNo = mbp.Sequence_No
	where se.GeometType = @GeometType
		and s.SummaryMonth = @SummaryMonth

	set @SummaryMonth = dateadd(m, 1, @SummaryMonth)

end

--select
--	mbp.Model_Block_Id,
--	mbp.Sequence_No,
--	bm.Name as Model_Name,
--	se.GeometType,
--	se.ProductSize,
--	se_total.Tonnes as TOTAL_TONNES,
--	lp.LumpPercent,
--	se.Tonnes,
--	(Case 
--		WHEN se.ProductSize = 'LUMP' Then lp.LumpPercent
--		WHEN se.ProductSize = 'FINES'  Then (1 - lp.LumpPercent)
--		ELSE 0.0
--	END * se_total.Tonnes) as RECALC_TONNES
--from BhpbioSummaryEntry se
--	inner join BhpbioSummaryEntry se_total
--		on se_total.LocationId = se.LocationId
--			and se_total.MaterialTypeId = se.MaterialTypeId
--			and se_total.SummaryId = se.SummaryId
--			and se_total.SummaryEntryTypeId = se.SummaryEntryTypeId
--			and se_total.ProductSize = 'TOTAL'
--			and se_total.GeometType = 'NA'
--	inner join BhpbioSummary s
--		on s.summaryId = se.SummaryId
--	inner join BhpbioSummaryEntryType st
--		on st.SummaryEntryTypeId = se.SummaryEntryTypeId
--			and st.Name like '%ModelMovement'
--	inner join BlockModel bm
--		on bm.Block_Model_Id = (Case when st.AssociatedBlockModelId = 5 then 1 else st.AssociatedBlockModelId end)
--	inner join ModelBlockLocation mbl
--		on mbl.Location_Id = se.LocationId
--	inner join ModelBlock mb
--		on mb.Model_Block_Id = mbl.Model_Block_Id
--			and mb.Block_Model_Id = bm.Block_Model_Id
--	inner join ModelBlockPartial mbp
--		on mbp.Model_Block_Id = mb.Model_Block_Id
--			and mbp.Material_Type_Id = se.MaterialTypeId
--	inner join BhpbioBlastBlockLumpPercent lp
--		on lp.GeometType = se.GeometType
--			and lp.ModelBlockId = mbp.Model_Block_Id
--			and lp.SequenceNo = mbp.Sequence_No
--where se.GeometType = @GeometType
--	and s.SummaryMonth = @SummaryMonth
