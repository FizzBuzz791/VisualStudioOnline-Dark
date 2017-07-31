--Update order of fields on PortShipping Page

Update uilf
Set Order_No = Order_No + 1
From dbo.UserInterfaceListing uil
	Inner join dbo.UserInterfaceListingField uilf
		on uil.User_Interface_Listing_Id = uilf.User_Interface_Listing_Id
where uil.Internal_Name = 'Port_Shipping'
	And uilf.Order_No >= 17
	
Update uilf
Set Order_No = 17
From dbo.UserInterfaceListing uil
	Inner join dbo.UserInterfaceListingField uilf
		on uil.User_Interface_Listing_Id = uilf.User_Interface_Listing_Id
where uil.Internal_Name = 'Port_Shipping'
	And uilf.Order_No = 9	

Update uilf
Set Order_No = Order_No - 1
From dbo.UserInterfaceListing uil
	Inner join dbo.UserInterfaceListingField uilf
		on uil.User_Interface_Listing_Id = uilf.User_Interface_Listing_Id
where uil.Internal_Name = 'Port_Shipping'
	And uilf.Order_No >= 10
	
--Update order of fields on 'Port_Blending Page
--Move SourceProductSize to position 4
Update uilf
Set Order_No = Order_No + 1
From dbo.UserInterfaceListing uil
	Inner join dbo.UserInterfaceListingField uilf
		on uil.User_Interface_Listing_Id = uilf.User_Interface_Listing_Id
where uil.Internal_Name = 'Port_Blending'
	And uilf.Order_No >= 4
	
Update uilf
Set Order_No = 4,
	Is_Visible = 1,
	Display_Name = 'Source Product Size'
From dbo.UserInterfaceListing uil
	Inner join dbo.UserInterfaceListingField uilf
		on uil.User_Interface_Listing_Id = uilf.User_Interface_Listing_Id
where uil.Internal_Name = 'Port_Blending'
	And uilf.Order_No = 12

--Move DestinationProductSize to position 6
Update uilf
Set Order_No = Order_No + 1
From dbo.UserInterfaceListing uil
	Inner join dbo.UserInterfaceListingField uilf
		on uil.User_Interface_Listing_Id = uilf.User_Interface_Listing_Id
where uil.Internal_Name = 'Port_Blending'
	And uilf.Order_No >= 6

Update uilf
Set Order_No = 6,
	Is_Visible = 1,
	Display_Name = 'Destination Product Size'
From dbo.UserInterfaceListing uil
	Inner join dbo.UserInterfaceListingField uilf
		on uil.User_Interface_Listing_Id = uilf.User_Interface_Listing_Id
where uil.Internal_Name = 'Port_Blending'
	And uilf.Order_No = 14

--Add H2O
INSERT INTO UserInterfaceListingField
Select uil.User_Interface_Listing_Id, 'H2O','H2O',0,1,0,13
From dbo.UserInterfaceListing uil
where uil.Internal_Name = 'Port_Blending'

--Add H2O for Port Balances
INSERT INTO UserInterfaceListingField
Select uil.User_Interface_Listing_Id, 'H2O','H2O',0,1,0,9
From dbo.UserInterfaceListing uil
where uil.Internal_Name = 'Port_Balances'
	