--
-- for some reason NJV got missed from the list of location codes (probably
-- because it is a Hub, not a Site). For the MQ2 imports it needs to be
-- in the select list, because some imports query the hub directly, not the
-- sites
--
Declare @NJVLocationId Integer

select @NJVLocationId = Location_Id 
From Location 
Where Name = 'NJV' and Location_Type_Id = 2

If Not Exists (Select 1 from BhpbioImportLocationCode Where LocationCode = 'NH')
Begin
	-- insert an NH (ie NJV) record for each import (but not for the blocks
	-- import - that really can only query sites)
	Insert Into BhpbioImportLocationCode
		Select 
			Distinct(c.ImportParameterId), 
			@NJVLocationId As LocationId, 
			'NH' as LocationCode
		From BhpbioImportLocationCode c
			Inner Join ImportParameter p on p.ImportParameterId = c.ImportParameterId
			Inner Join Import i on i.ImportId = p.ImportId
		Where ImportName <> 'Blocks'

End

