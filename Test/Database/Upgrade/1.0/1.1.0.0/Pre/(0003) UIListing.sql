
UPDATE dbo.UserInterfaceListingField
	Set Sum_Field = 1
WHERE User_Interface_Listing_Id = 3
	AND Field_Name = 'Tonnes'