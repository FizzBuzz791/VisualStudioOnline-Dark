--
-- populates the grade id for the give site with some random data
--
declare @DateFrom datetime
declare @DateTo datetime
declare @BlockModelName varchar(64)
declare @LocationName varchar(64)
declare @GradeId int

Set @DateFrom = '2013-11-01'
Set @DateTo = '2013-11-30'
Set @BlockModelName = 'Grade Control'
Set @LocationName = 'Newman'
Set @GradeId = 7

-------------------------------------------
declare @LocationId Int
declare @LocationTypeId int
Set @LocationTypeId = 3 -- 3 = Site
Select @LocationId = Location_Id from Location where Name = @LocationName and Location_Type_Id = @LocationTypeId

insert into dbo.ModelBlockPartialGrade
	select
		mb.Model_Block_Id,
		mbp.Sequence_No,
		@GradeId as Grade_Id,
		((convert(float, abs(checksum(newid()) % 1000)) / 1000) * 4 + 2) as Grade_Value
	from dbo.ModelBlock mb
		inner join BlockModel bm on bm.Block_Model_Id = mb.Block_Model_Id
		inner join ModelBlockLocation mbl on mbl.Model_Block_Id = mb.Model_Block_Id
		inner join ModelBlockPartial mbp on mbp.Model_Block_Id = mb.Model_Block_Id
	where
		bm.Name = @BlockModelName and
		dbo.GetLocationTypeLocationId(mbl.Location_Id, @LocationTypeId) = @LocationId

insert into dbo.HaulageGrade
	select 
		h.Haulage_Id,
		@GradeId as Grade_Id,
		((convert(float, abs(checksum(newid()) % 1000)) / 1000) * 4 + 2) as Grade_Value
	from Haulage h
	where h.Haulage_Date between @DateFrom and @DateTo

insert into dbo.WeightometerSampleGrade
	select 
		w.Weightometer_Sample_Id,
		@GradeId as Grade_Id,
		((convert(float, abs(checksum(newid()) % 1000)) / 1000) * 4 + 2) as Grade_Value
	from WeightometerSample w
	where w.Weightometer_Sample_Date between @DateFrom and @DateTo
	
	