
Set Identity_Insert dbo.Grade On

Insert Into Grade (Grade_Id, Grade_Name, Description, Order_No, Units, Display_Precision, Display_Format, Grade_Type_Id, Is_Visible)
	Select 7, 'H2O', 'H2O', 7, '%', 2, 'DP', 'Normal', 1 Union All
	Select 8, 'H2O-As-Dropped', 'H2O-As-Dropped', 8, '%', 2, 'DP', 'Normal', 0 Union All
	Select 9, 'H2O-As-Shipped', 'H2O-As-Shipped', 9, '%', 2, 'DP', 'Normal', 0
	
	
Set Identity_Insert dbo.Grade Off

-- Add a H2O column to the F1F2F3 Approval page
--
-- get the id of the page we are adding the new field to. Approval_Data is the F1F2F3 page
Declare @UserInterfaceListingId Int
Select @UserInterfaceListingId = User_Interface_Listing_Id From dbo.UserInterfaceListing Where Internal_Name = 'Approval_Data'

-- update the order numbers to there is space for us to insert the new records
Update UserInterfaceListingField 
Set Order_No = Order_No + 3 
Where User_Interface_Listing_Id = @UserInterfaceListingId 
	And Order_No > 6

Insert Into UserInterfaceListingField (User_Interface_Listing_Id, Field_Name, Display_Name, Pixel_Width, Is_Visible, Sum_Field, Order_No)
	Select @UserInterfaceListingId, 'H2O', 'H2O', 0, 1, 0, 7