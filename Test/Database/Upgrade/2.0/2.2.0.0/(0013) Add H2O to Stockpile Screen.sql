Declare @UserInterfaceListingId Int

Select @UserInterfaceListingId = User_Interface_Listing_Id 
From UserInterfaceListing 
Where Internal_Name = 'Stockpile_Listing'

-- add H2O to the stockpile list screen
Insert Into UserInterfaceListingField (User_Interface_Listing_Id, Field_Name, Display_Name, Pixel_Width, Is_Visible, Sum_Field, Order_No)
	Select @UserInterfaceListingId, 'H2O', 'H2O', 0, 1, 0, null

-- fix the field order of the stockpile list field so that the grades are in the proper order
Update UserInterfaceListingField Set Order_No = 10 Where Field_Name = 'Fe' And User_Interface_Listing_Id = @UserInterfaceListingId
Update UserInterfaceListingField Set Order_No = 20 Where Field_Name = 'P' And User_Interface_Listing_Id = @UserInterfaceListingId
Update UserInterfaceListingField Set Order_No = 30 Where Field_Name = 'SiO2' And User_Interface_Listing_Id = @UserInterfaceListingId
Update UserInterfaceListingField Set Order_No = 40 Where Field_Name = 'Al2O3' And User_Interface_Listing_Id = @UserInterfaceListingId
Update UserInterfaceListingField Set Order_No = 50 Where Field_Name = 'LOI' And User_Interface_Listing_Id = @UserInterfaceListingId
Update UserInterfaceListingField Set Order_No = 60 Where Field_Name = 'H2O' And User_Interface_Listing_Id = @UserInterfaceListingId
