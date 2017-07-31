
-- want to change the blastblock approval column name to make it clearer exactly what it does
Update dbo.UserInterfaceListingField
Set Display_Name = 'Depletion<br> Approved'
where Field_Name = 'ApprovedCheck'
	And User_Interface_Listing_Id = (Select User_Interface_Listing_Id From dbo.UserInterfaceListing Where Internal_Name = 'Approval_Digblock')
