
IF OBJECT_ID('dbo.GetBhpbioReportPatternValidationData') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportPatternValidationData
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReportPatternValidationData
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iLocationId INT
)
WITH ENCRYPTION
AS 
BEGIN 

	-- should get a list of patterns blocked-out in the date range. The point is 
	-- to show the models and filenames to validate that the pattern information is
	-- complete
	select 
		pl.Location_Id as LocationId,
		bm.Name as ModelName,
		mbpn.Notes as ModelFilename,
		COUNT(distinct dbmb.Digblock_Id) as BlockCount,
		(Case When Count(mbpv.Model_Block_Id) = 0 then 0 else 1 end) as HasResourceClassification,
		(Case When Count(lf.ModelBlockId) = 0 then 0 else 1 end) as HasGeomet,
		(Case When Count(lfg.ModelBlockId) = 0 then 0 else 1 end) as HasGeometGrades
	from dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 0, 'BLOCK', @iDateFrom, @iDateFrom) ls
		inner join Location l
			on l.Location_Id = ls.LocationId
		inner join LocationType lt
			on lt.Location_Type_Id = l.Location_Type_Id
		inner join ModelBlockLocation mbl
			on mbl.Location_Id = l.Location_Id
		inner join Location pl
			on pl.Location_Id = l.Parent_Location_Id
		inner join DigblockModelBlock dbmb
			on dbmb.Model_Block_Id = mbl.Model_Block_Id
		inner join DigblockNotes dbn
			on dbn.Digblock_Id = dbmb.Digblock_Id
				and dbn.Digblock_Field_Id = 'BlockedDate'
		inner join ModelBlock mb
			on mb.Model_Block_Id = mbl.Model_Block_Id
		inner join BlockModel bm
			on bm.Block_Model_Id = mb.Block_Model_Id
		inner join ModelBlockPartial mbp
			on mbp.Model_Block_Id = mb.Model_Block_Id
				and mbp.Sequence_No = 1
		left join ModelBlockPartialNotes mbpn
			on mbpn.Model_Block_Id = mbp.Model_Block_Id
				and mbpn.Sequence_No = mbp.Sequence_No
				and mbpn.Model_Block_Partial_Field_Id = 'ModelFilename'
		left join ModelBlockPartialValue mbpv
			on mbpv.Model_Block_Id = mbp.Model_Block_Id
				and mbpv.Sequence_No = mbp.Sequence_No
				and mbpv.Model_Block_Partial_Field_Id like 'ResourceClassification%'
		left join dbo.BhpbioBlastBlockLumpPercent lf
			on lf.ModelBlockId = mb.Model_Block_Id
				and lf.SequenceNo = mbp.Sequence_No
				and lf.GeometType = 'As-Shipped'
		left join dbo.BhpbioBlastBlockLumpFinesGrade lfg
			on lfg.ModelBlockId = mbp.Model_Block_Id
				and lfg.SequenceNo = mbp.Sequence_No
				and lfg.GradeId = 1
				AND lfg.GeometType = 'As-Shipped'
	where lt.[Description] = 'BLOCK'
		and Convert(datetime, Replace(dbn.Notes, '.0000000', '.000'), 126) between @iDateFrom and @iDateTo
	group by pl.Location_Id, bm.Block_Model_Id, bm.Name, mbpn.Notes
	order by pl.Location_Id

END 
GO

GRANT EXECUTE ON dbo.GetBhpbioReportPatternValidationData TO BhpbioGenericManager
GO