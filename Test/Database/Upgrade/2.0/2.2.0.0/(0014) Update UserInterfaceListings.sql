--update other movement page

Declare @UserInterfaceListingId Int

Select @UserInterfaceListingId = User_Interface_Listing_Id 
From UserInterfaceListing
Where Internal_Name = 'Approval_Other'


Update UserInterfaceListingField
Set Order_No = Order_No+4
where  User_Interface_Listing_Id = @UserInterfaceListingId
and Order_No >= 5

INSERT INTO UserInterfaceListingField
Select @UserInterfaceListingId, 'HauledToOreStockpile', 'ktonnes hauled<br>to Ore Stockpiles<br>(from Blocks)', 0,1,0,5 Union All
Select @UserInterfaceListingId, 'HauledToNonOreStockpile', 'ktonnes hauled to<br>Non-Ore Stockpiles<br>(from Blocks)', 0,1,0,6 Union All
Select @UserInterfaceListingId, 'HauledToCrusher', 'ktonnes hauled<br>to Crusher<br>(from Blocks)', 0,1,0,7 Union All
Select @UserInterfaceListingId, 'HaulageTotal', 'total ktonnes<br>hauled<br>(from Blocks)', 0,1,0,8 

-- create some new summary types for the new columns
INSERT INTO BhpbioSummaryEntryType
Select 26, 'HauledToNonOreStockpile', NULL Union All
Select 27, 'HauledToOreStockpile', NULL Union All
Select 28, 'HauledToCrusher', NULL

-- hide the current stockpile movements column - it is misleading now because it uses the SP type to splt the material
-- instead of the block like all the other columns
Update UserInterfaceListingField Set Is_Visible = 0 
Where User_Interface_Listing_Id = @UserInterfaceListingId And Field_Name = 'Actual'

-- When opening Approvals tab the default page should be the F1F2F3 Validation & Approval page (WREC-545)
Update dbo.UserInterfaceListingTab
Set Link = '../Approval/ApprovalData.aspx'
Where User_Interface_Listing_Tab_Id = 'Approval'

-- Re-arrange the two columns on Other Approvals page to ensure Export to CSV works correctly
Update UserInterfaceListingField
Set Order_No = 10
Where User_Interface_Listing_Id = 8 And Field_Name = 'ApprovedCheck'

Update UserInterfaceListingField
Set Order_No = 99
Where User_Interface_Listing_Id = 8 And Field_Name = 'Signoff'