-- Insert data for the STGM based off the current Geology model
--
-- WARNING: this will delete all existing records for the STGM
-- 
-- Nathan Reed, 2014-03-25

Set NOCOUNT ON
GO

declare @GeologyModelId int
declare @STGMModelId int
declare @AdjustmentFactor float
declare @LocationName varchar(64)

Set @LocationName = 'EE'

-- Ids of for the relevant block models
set @GeologyModelId = 2
set @STGMModelId = 4

-- a number between 0 and 1. The geology model will be changed by some random
-- amount in this range to create the STGM. An adjustment factor of 0.10 means
-- that the geology model will changed by a random amount between -5% and +5%
-- for each model block / measure
set @AdjustmentFactor = 0.15

-- get locations ids from the name provided
declare @LocationId Int
declare @LocationTypeId int

Select 
	@LocationId = Location_Id,
	@LocationTypeId = Location_Type_Id  
from Location 
where 
	Name = @LocationName and 
	Location_Type_Id <= 4


-- first clear all the existing records for this model. This needs to be done in
-- reverse order from how they are created, in order to avoid breaking any FK constraints
--delete from dbo.DigblockModelBlock where Model_Block_Id in (select Model_Block_Id from ModelBlock where Block_Model_Id = @STGMModelId)
--delete from dbo.ModelBlockLocation where Model_Block_Id in (select Model_Block_Id from ModelBlock where Block_Model_Id = @STGMModelId)
--delete from dbo.ModelBlockPartialGrade where Model_Block_Id in (select Model_Block_Id from ModelBlock where Block_Model_Id = @STGMModelId)
--delete from dbo.ModelBlockPartial where Model_Block_Id in (select Model_Block_Id from ModelBlock where Block_Model_Id = @STGMModelId)
--delete from dbo.ModelBlock where Block_Model_Id = @STGMModelId

print 'all tables cleared of STGM data'

-- Duplicate the geo model into block table. This doesn't seem to change
insert into dbo.ModelBlock
	select @STGMModelId, X, Y, Z, Code, X_Inc, Y_Inc, Z_Inc 
	from ModelBlock mb
		inner join ModelBlockLocation mbl on mbl.Model_Block_Id =  mb.Model_Block_Id
	where Block_Model_Id = @GeologyModelId and dbo.GetLocationTypeLocationId(mbl.Location_Id, @LocationTypeId) = @LocationId

print 'ModelBlocks created'

-- Duplicate the digblock list

insert into dbo.DigblockModelBlock (Digblock_Id, Model_Block_Id, Percentage_In_Model_Block, Percentage_In_Digblock)
	select 
		dmb.DigBlock_Id,
		mb_st.Model_Block_Id,
		dmb.Percentage_In_Model_Block,
		dmb.Percentage_In_Digblock
	from DigblockModelBlock dmb
		inner join ModelBlock mb on mb.Model_Block_Id = dmb.Model_Block_Id
		inner join ModelBlock mb_st on mb.Code = mb_st.Code and mb_st.Block_Model_Id = @STGMModelId
		inner join ModelBlockLocation mbl on mbl.Model_Block_Id =  mb.Model_Block_Id
	where 
		mb.Block_Model_Id = @GeologyModelId and 
		dbo.GetLocationTypeLocationId(mbl.Location_Id, @LocationTypeId) = @LocationId
	
print 'DigblockModelBlocks created'


-- now create the new tonnes measures means
insert into dbo.ModelBlockPartial
	select	
		mb_st.Model_Block_Id,
		mbp.Sequence_No,
		mbp.Material_Type_Id,
		-- we adjust the tonnes by some random amount from the adjustment factor
		mbp.Tonnes + mbp.Tonnes * (((ABS(CHECKSUM(NewId())) % 1000000) / 1e6) * @AdjustmentFactor - (@AdjustmentFactor / 2)) as Tonnes
	from ModelBlockPartial mbp
		inner join ModelBlock mb_geo on mb_geo.Model_Block_Id = mbp.Model_Block_Id
		inner join ModelBlock mb_st on mb_geo.Code = mb_st.Code and mb_st.Block_Model_Id = @STGMModelId
		inner join ModelBlockLocation mbl on mbl.Model_Block_Id =  mb_geo.Model_Block_Id
	where 
		mb_geo.Block_Model_Id = @GeologyModelId and
		dbo.GetLocationTypeLocationId(mbl.Location_Id, @LocationTypeId) = @LocationId

print 'ModelBlockPartials created'

-- now create the grades using the same method as for tonnes
insert into dbo.ModelBlockPartialGrade
	select	
		mb_st.Model_Block_Id,
		mbp.Sequence_No,
		mbp.Grade_Id,
		-- we adjust the grade by some random amount from the adjustment factor
		mbp.Grade_Value + mbp.Grade_Value * (((ABS(CHECKSUM(NewId())) % 1000000) / 1e6) * @AdjustmentFactor - (@AdjustmentFactor / 2)) as Grade_Value
	from ModelBlockPartialGrade mbp
		inner join ModelBlock mb_geo on mb_geo.Model_Block_Id = mbp.Model_Block_Id
		inner join ModelBlock mb_st on mb_geo.Code = mb_st.Code and mb_st.Block_Model_Id = @STGMModelId
		inner join ModelBlockLocation mbl on mbl.Model_Block_Id =  mb_geo.Model_Block_Id
	where 
		mb_geo.Block_Model_id = @GeologyModelId and
		dbo.GetLocationTypeLocationId(mbl.Location_Id, @LocationTypeId) = @LocationId

print 'ModelBlockPartialGrade created'

insert into ModelBlockLocation
	SELECT 
		mb_st.Model_Block_Id,
		mbl.Location_Type_Id,
		mbl.Location_Id
	FROM ModelBlockLocation mbl
		inner join ModelBlock mb_geo on mb_geo.Model_Block_Id = mbl.Model_Block_Id
		inner join ModelBlock mb_st on mb_geo.Code = mb_st.Code and mb_st.Block_Model_Id = @STGMModelId
	where 
		mb_geo.Block_Model_id = @GeologyModelId and
		dbo.GetLocationTypeLocationId(mbl.Location_Id, @LocationTypeId) = @LocationId

print 'ModelBlockLocation created'

print 'done'
