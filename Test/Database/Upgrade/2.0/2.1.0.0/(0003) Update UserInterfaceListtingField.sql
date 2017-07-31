--hide hauled tonnes as they are no longer needed in the UI (keep them in stored procs in case they are needed somewhere else)
Update f
Set Is_Visible = 0
From UserInterfaceListingField f
	Join UserInterfaceListing l
		On f.User_Interface_Listing_Id = l.User_Interface_Listing_Id
Where l.Internal_Name='Approval_Digblock' and f.Field_Name='HauledTonnes'
Go

Update f
Set Order_No = 5
From UserInterfaceListingField f
	Join UserInterfaceListing l
		On f.User_Interface_Listing_Id = l.User_Interface_Listing_Id
Where l.Internal_Name='Approval_Digblock' and f.Field_Name='GeologyTonnes'
Go

Update f
Set Order_No = 6
From UserInterfaceListingField f
	Join UserInterfaceListing l
		On f.User_Interface_Listing_Id = l.User_Interface_Listing_Id
Where l.Internal_Name='Approval_Digblock' and f.Field_Name='MiningTonnes'
Go

Update f
Set Order_No = 8
From UserInterfaceListingField f
	Join UserInterfaceListing l
		On f.User_Interface_Listing_Id = l.User_Interface_Listing_Id
Where l.Internal_Name='Approval_Digblock' and f.Field_Name='GradeControlTonnes'
Go

Update f
Set Order_No = 9
From UserInterfaceListingField f
	Join UserInterfaceListing l
		On f.User_Interface_Listing_Id = l.User_Interface_Listing_Id
Where l.Internal_Name='Approval_Digblock' and f.Field_Name='BestTonnes'
Go

Update f
Set Display_Name='Monthly<br>Hauled Tonnes'
From UserInterfaceListingField f
	Join UserInterfaceListing l
		On f.User_Interface_Listing_Id = l.User_Interface_Listing_Id
Where l.Internal_Name='Approval_Digblock' and f.Field_Name='BestTonnes'
Go

Update f
Set Order_No = 10
From UserInterfaceListingField f
	Join UserInterfaceListing l
		On f.User_Interface_Listing_Id = l.User_Interface_Listing_Id
Where l.Internal_Name='Approval_Digblock' and f.Field_Name='RemainingTonnes'
Go

Update f
Set Order_No = 11
From UserInterfaceListingField f
	Join UserInterfaceListing l
		On f.User_Interface_Listing_Id = l.User_Interface_Listing_Id
Where l.Internal_Name='Approval_Digblock' and f.Field_Name='ApprovedCheck'
Go

Update f
Set Order_No = 12
From UserInterfaceListingField f
	Join UserInterfaceListing l
		On f.User_Interface_Listing_Id = l.User_Interface_Listing_Id
Where l.Internal_Name='Approval_Digblock' and f.Field_Name='SignoffUser'
Go

Insert Into dbo.UserInterfaceListingField
(
	User_Interface_Listing_Id, Field_Name, Display_Name, Pixel_Width, Is_Visible, Sum_Field, Order_No
)
Select User_Interface_Listing_Id, 'GradeControlInventoryTonnes', 'Initial Grade<br>Control Tonnes', 0, 1, 0, 2 From dbo.UserInterfaceListing Where Internal_Name='Approval_Digblock' Union All
Select User_Interface_Listing_Id, 'TotalMinedPercent', 'Total<br>Survey<br>Depletion', 0, 1, 0, 3 From dbo.UserInterfaceListing Where Internal_Name='Approval_Digblock' Union All
Select User_Interface_Listing_Id, 'MonthlyMinedPercent', 'Monthly<br>Survey<br>Depletion', 0, 1, 0, 4 From dbo.UserInterfaceListing Where Internal_Name='Approval_Digblock' Union All
Select User_Interface_Listing_Id, 'ShortTermGeologyTonnes', 'Monthly Short<br>Term Geology<br>Model', 0, 1, 0, 7 From dbo.UserInterfaceListing Where Internal_Name='Approval_Digblock'
Go

 --changes for Other Movement Approval screen
 Update dbo.UserInterfaceListingField
 Set Order_No = 4
 Where Field_Name = 'Grade Control'
	And User_Interface_Listing_Id = (Select User_Interface_Listing_Id From dbo.UserInterfaceListing Where Internal_Name='Approval_Other')
	
Update dbo.UserInterfaceListingField
 Set Order_No = 5
 Where Field_Name = 'Actual'
	And User_Interface_Listing_Id = (Select User_Interface_Listing_Id From dbo.UserInterfaceListing Where Internal_Name='Approval_Other')

Update dbo.UserInterfaceListingField
 Set Order_No = 6
 Where Field_Name = 'ApprovedCheck'
	And User_Interface_Listing_Id = (Select User_Interface_Listing_Id From dbo.UserInterfaceListing Where Internal_Name='Approval_Other')
	
Update dbo.UserInterfaceListingField
 Set Order_No = 7
 Where Field_Name = 'Signoff'
	And User_Interface_Listing_Id = (Select User_Interface_Listing_Id From dbo.UserInterfaceListing Where Internal_Name='Approval_Other')
Go	
 
Insert Into dbo.UserInterfaceListingField
(
	User_Interface_Listing_Id, Field_Name, Display_Name, Pixel_Width, Is_Visible, Sum_Field, Order_No
)
Select User_Interface_Listing_Id, 'Short Term Geology', 'Short Term Geology<br>Model ktonnes', 0, 1, 0, 3 From dbo.UserInterfaceListing Where Internal_Name='Approval_Other'