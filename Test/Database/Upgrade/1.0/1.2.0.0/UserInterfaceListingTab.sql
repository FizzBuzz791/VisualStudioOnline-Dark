UPDATE dbo.UserInterfaceListingTab
SET Image_Unselected = 'Blastblock.gif'
WHERE User_Interface_Listing_Tab_Id = 'Digblocks'

UPDATE dbo.UserInterfaceListingTab
SET Image_Selected = 'BlastblockOn.gif'
WHERE User_Interface_Listing_Tab_Id = 'Digblocks'
