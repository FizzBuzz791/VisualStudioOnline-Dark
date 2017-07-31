
Declare @ListingId Int

--
-- Update the F1F2F3 approval page
--
Select 
	@ListingId = User_Interface_Listing_Id 
From UserInterfaceListing 
Where Internal_Name = 'Approval_Data'

If Not Exists (Select 1 From UserInterfaceListingField Where Field_Name = 'SignOffDate' And User_Interface_Listing_Id = @ListingId) 
Begin

	-- Add a new UI column in second last position that will contain the signoff date
	Insert Into UserInterfaceListingField (User_Interface_Listing_Id, Field_Name, Display_Name, Pixel_Width, Is_Visible, Sum_Field, Order_No)
		Select @ListingId, 'SignOffDate', 'SignOff Date', 75, 1, 0, 12
		
	-- adjust the order of the other columns
	Update UserInterfaceListingField 
	Set Order_No = 20 
	Where Field_Name = 'Investigation' 
		And User_Interface_Listing_Id = @ListingId

End

--
-- Update the digblock approval page
--
Select 
	@ListingId = User_Interface_Listing_Id 
From UserInterfaceListing 
Where Internal_Name = 'Approval_Digblock'

If Not Exists (Select 1 From UserInterfaceListingField Where Field_Name = 'SignOffDate' And User_Interface_Listing_Id = @ListingId) 
Begin

	-- Add a new UI column in second last position that will contain the signoff date
	Insert Into UserInterfaceListingField (User_Interface_Listing_Id, Field_Name, Display_Name, Pixel_Width, Is_Visible, Sum_Field, Order_No)
		Select @ListingId, 'SignOffDate', 'Sign Off Date', 0, 1, 0, 20

End


--
-- Update the other movements approval page
--
Select 
	@ListingId = User_Interface_Listing_Id 
From UserInterfaceListing 
Where Internal_Name = 'Approval_Other'

If Not Exists (Select 1 From UserInterfaceListingField Where Field_Name = 'SignOffDate' And User_Interface_Listing_Id = @ListingId) 
Begin

	-- Add a new UI column in second last position that will contain the signoff date
	Insert Into UserInterfaceListingField (User_Interface_Listing_Id, Field_Name, Display_Name, Pixel_Width, Is_Visible, Sum_Field, Order_No)
		Select @ListingId, 'SignOffDate', 'Sign Off Date', 0, 1, 0, 110

End
