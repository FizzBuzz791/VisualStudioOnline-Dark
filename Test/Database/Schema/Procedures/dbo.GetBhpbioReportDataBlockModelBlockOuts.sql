
IF OBJECT_ID('dbo.GetBhpbioReportDataBlockModelBlockOuts') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioReportDataBlockModelBlockOuts
GO 
  
CREATE PROCEDURE dbo.GetBhpbioReportDataBlockModelBlockOuts
(
	@iDateFrom DATETIME,
	@iDateTo DATETIME,
	@iLocationId INT,
	@iChildLocations BIT = 0,
	@iOverrideChildLocationType VARCHAR(31) = 'SITE'
)
WITH ENCRYPTION
AS 
BEGIN 

	declare @Blocks table (
		Digblock_Id varchar(64),
		Group_Location_Id int,
		Model_Block_Id int,
		Block_Model_Id int,
		Blocked_Date datetime,
		Material_Type_Id int,
		Sequence_No int,
		Tonnes float,
		Volume float
	)

	Insert Into @Blocks
	select
		db.Digblock_Id,
		Case
			When @iChildLocations = 0 Then @iLocationId
			when @iOverrideChildLocationType = 'BLAST' Then blast.Location_Id
			when @iOverrideChildLocationType = 'BENCH' Then bench.Location_Id
			when @iOverrideChildLocationType = 'PIT' Then pit.Location_Id
			when @iOverrideChildLocationType = 'SITE' Then [site].Location_Id
			else [site].Location_Id 
		end as Group_Location_Id,
		mb.Model_Block_Id,
		mb.Block_Model_Id,
		Convert(datetime, Replace(blocked.Notes, '.0000000', '.000'), 126) as BlockedDate,
		mt.Material_Type_Id,
		mbp.Sequence_No,
		mbp.Tonnes as Tonnes,
		mbpv.Field_Value as Volume
	from dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 1, 'BLOCK', @iDateFrom, @iDateTo) l
		inner join ModelBlockLocation mbl
			on mbl.Location_Id = l.LocationId
		inner join Location [block]
			on [block].Location_Id = mbl.Location_Id
		inner join Location blast
			on blast.Location_Id = [block].Parent_Location_Id
		inner join Location bench
			on bench.Location_Id = blast.Parent_Location_Id
		inner join Location pit
			on pit.Location_Id = bench.Parent_Location_Id
		inner join Location [site]
			on [site].Location_Id = pit.Parent_Location_Id
			
		inner join dbo.BhpbioModelBlock mb
			on mb.Model_Block_Id = mbl.Model_Block_Id
		inner join BlockModel bm 
			on bm.Block_Model_Id = mb.Block_Model_Id
		inner join DigblockModelBlock dmb 
			on dmb.Model_Block_Id = mb.Model_Block_Id
		inner join Digblock db
			on db.Digblock_Id = dmb.Digblock_Id
		inner join DigblockNotes blocked
			on blocked.Digblock_Id = db.Digblock_Id
				and blocked.Digblock_Field_Id = 'BlockedDate'
		inner join ModelBlockPartial mbp
			on mbp.Model_Block_Id = mb.Model_Block_Id
		inner join dbo.GetMaterialsByCategory('Designation') AS MC
			on mc.MaterialTypeId = mbp.Material_Type_Id
		inner join MaterialType mt
			on mt.Material_Type_Id = mc.RootMaterialTypeId
		left join ModelBlockPartialValue mbpv
			on mbpv.Model_Block_Id = mbp.Model_Block_Id
				and mbpv.Sequence_No = mbp.Sequence_No
				and mbpv.Model_Block_Partial_Field_Id = 'ModelVolume'
	where Convert(datetime, Replace(blocked.Notes, '.0000000', '.000'), 126) between @iDateFrom and @iDateTo

	select 
		b.Block_Model_Id as BlockModelId,
		bm.Name as ModelName,
		@iDateFrom as CalendarDate,
		@iDateFrom as DateFrom,
		@iDateTo as DateTo,
		b.Group_Location_Id as ParentLocationId,
		b.Material_Type_Id as MaterialTypeId,
		(case when hg.MaterialTypeId is null then 0 else 1 end) as IsHighGrade,
		'TOTAL' as ProductSize,
		null as ResourceClassification,
		Sum(Tonnes) as Tonnes,
		Sum(Volume) as Volume 
	from @Blocks b
		inner join BlockModel bm
			on bm.Block_Model_Id = b.Block_Model_Id
		left join dbo.GetBhpbioReportHighGrade() AS hg 
			on hg.MaterialTypeId = b.Material_Type_Id
	group by bm.Name, 
		b.Block_Model_Id, 
		b.Material_Type_Id, 
		hg.MaterialTypeId, 
		b.Group_Location_Id

	select 
		b.Block_Model_Id as BlockModelId,
		bm.Name as ModelName,
		@iDateFrom as CalendarDate,
		@iDateFrom as DateFrom,
		@iDateTo as DateTo,
		b.Group_Location_Id as ParentLocationId,
		b.Material_Type_Id as MaterialTypeId,
		(case when hg.MaterialTypeId is null then 0 else 1 end) as IsHighGrade,
		null as ResourceClassification,
		g.Grade_Name as GradeName,
		(Case 
			When SUM(b.Tonnes) = 0 Then 0
			Else SUM(b.Tonnes * mbpg.Grade_Value) / SUM(b.Tonnes) 
		End) As GradeValue,
		'TOTAL' as ProductSize
	from @Blocks b
		inner join BlockModel bm
			on bm.Block_Model_Id = b.Block_Model_Id
		left join dbo.GetBhpbioReportHighGrade() AS hg 
			on hg.MaterialTypeId = b.Material_Type_Id
		inner join ModelBlockPartialGrade mbpg
			on mbpg.Model_Block_Id = b.Model_Block_Id
				and mbpg.Sequence_No = b.Sequence_No
		inner join Grade g
			on g.Grade_Id = mbpg.Grade_Id
	group by bm.Name, 
		b.Block_Model_Id, 
		b.Material_Type_Id, 
		hg.MaterialTypeId, 
		b.Group_Location_Id,
		g.Grade_Name,
		g.Grade_Id
	order by b.Block_Model_Id, 
		b.Group_Location_Id, 
		b.Material_Type_Id, 
		g.Grade_Id


END 
GO

GRANT EXECUTE ON dbo.GetBhpbioReportDataBlockModelBlockOuts TO BhpbioGenericManager
GO