--
-- Update the titles of the Sign off date column on the other movements page
-- and the F1F2F3 approval page
--
Update f
	Set Display_Name = 'Latest Sign<br/> Off Date'
From UserInterfaceListingField f
	Inner Join UserInterfaceListing l 
		On l.User_Interface_Listing_Id = f.User_Interface_Listing_Id
Where Field_Name = 'SignoffDate' 
	And l.Internal_Name In ('Approval_Other', 'Approval_Data')