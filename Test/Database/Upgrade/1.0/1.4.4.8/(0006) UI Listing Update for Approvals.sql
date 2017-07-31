
UPDATE uilf
SET uilf.Display_Name = 'Live Data Viewer'
FROM UserInterfaceListingField uilf
	INNER JOIN UserInterfaceListing uil
		ON uil.User_Interface_Listing_Id = uilf.User_Interface_Listing_Id
WHERE uilf.Field_Name = 'Investigation'
	AND uil.Internal_Name = 'Approval_Data'

GO