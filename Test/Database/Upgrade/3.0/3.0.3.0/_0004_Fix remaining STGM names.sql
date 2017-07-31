-- we need to start using the BLockModel Description instead of the Name in
-- several places, and this means we need to correct the description for the
-- Geology Model
Update BlockModel 
Set Description = 'Geology Model'
Where Name = 'Geology'

--
-- This will fix the column headings for the Digblock approval page
-- and the other movements approval page
--
Update UserInterfaceListingField 
Set Display_Name = 'Monthly Short<br>Term Model'
Where Field_Name = 'ShortTermGeologyTonnes'

Update UserInterfaceListingField 
Set Display_Name = 'Short Term <br>Model ktonnes'
Where Field_Name = 'Short Term Geology'
