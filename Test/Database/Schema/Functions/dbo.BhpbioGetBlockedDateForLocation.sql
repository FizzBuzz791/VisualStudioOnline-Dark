IF OBJECT_ID('dbo.BhpbioGetBlockedDateForLocation') IS NOT NULL 
     DROP FUNCTION dbo.BhpbioGetBlockedDateForLocation
Go 

CREATE FUNCTION dbo.BhpbioGetBlockedDateForLocation
(
	@iLocationId Int,
	@iLocationDate DateTime
)

RETURNS DateTime
AS 
BEGIN
	Declare @Result DateTime
	
	-- this will get the latest blocked data, for all the child blocks
	-- of the given location - this is useful for getting the blocked date
	-- of a pattern, for instance
	select 
		-- there are too many decimals for the milliseconds - this causes the conversion
		-- to datetime to fail, so we replace them with a shorter version. This ONLY works
		-- for the blocked date, because the ms are always zero
		@Result = Replace(Max(dbn.Notes), '.0000000', '.000') 
	from dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 0, 'BLOCK', @iLocationDate, @iLocationDate) ls
		inner join Location l
			on l.Location_Id = ls.LocationId
		inner join LocationType lt
			on lt.Location_Type_Id = l.Location_Type_Id
		inner join ModelBlockLocation mbl
			on mbl.Location_Id = l.Location_Id
		inner join DigblockModelBlock dbmb
			on dbmb.Model_Block_Id = mbl.Model_Block_Id
		inner join DigblockNotes dbn
			on dbn.Digblock_Id = dbmb.Digblock_Id
				and dbn.Digblock_Field_Id = 'BlockedDate'
	where lt.[Description] = 'BLOCK'
	
	Return @Result
END
GO

GRANT EXECUTE ON dbo.BhpbioGetBlockedDateForLocation TO BhpbioGenericManager
GO
