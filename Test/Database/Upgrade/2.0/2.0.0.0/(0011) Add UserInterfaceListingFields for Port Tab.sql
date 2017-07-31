--Add additional UserInterfaceListingField for Port Balancing
INSERT INTO UserInterfaceListingField
SELECT 4 As User_Interface_Listing_Id, 'ProductSize' As Field_Name, 'Product Size' As Display_Name, 0 As Pixel_Width, 1 As Is_Visible, 0 As Sum_Field, 3 As Order_No
Union All
SELECT 4 As User_Interface_Listing_Id, 'Fe' As Field_Name, 'Fe' As Display_Name, 0 As Pixel_Width, 1 As Is_Visible, 0 As Sum_Field, 4 As Order_No
Union All
SELECT 4 As User_Interface_Listing_Id, 'P' As Field_Name, 'P' As Display_Name, 0 As Pixel_Width, 1 As Is_Visible, 0 As Sum_Field, 5 As Order_No
Union All
SELECT 4 As User_Interface_Listing_Id, 'SiO2' As Field_Name, 'SiO2' As Display_Name, 0 As Pixel_Width, 1 As Is_Visible, 0 As Sum_Field, 6 As Order_No
Union All
SELECT 4 As User_Interface_Listing_Id, 'Al2O3' As Field_Name, 'Al2O3' As Display_Name, 0 As Pixel_Width, 1 As Is_Visible, 0 As Sum_Field, 7 As Order_No
Union All
SELECT 4 As User_Interface_Listing_Id, 'LOI' As Field_Name, 'LOI' As Display_Name, 0 As Pixel_Width, 1 As Is_Visible, 0 As Sum_Field, 8 As Order_No
Go

--Port Blending
Delete from UserInterfaceListingField
Where User_Interface_Listing_id = 5

Insert Into UserInterfaceListingField
SELECT 5 As User_Interface_Listing_Id, 'Start Date' As Field_Name, 'Start Date' As Display_Name, 0 As Pixel_Width, 1 As Is_Visible, 0 As Sum_Field, 0 As Order_No
Union All
SELECT 5, 'End Date', 'End Date', 0, 1, 0, 1
Union All
SELECT 5, 'Load Site', 'Load Site', 0, 1, 0, 2
Union All
SELECT 5, 'Rake Hub', 'Source Hub', 0, 1, 0, 3
Union All
SELECT 5, 'Destination Hub', 'Destination Hub', 0, 1, 0, 4
Union All
SELECT 5, 'Tonnes', 'Tonnes', 0, 1, 0, 5
Union All
SELECT 5, 'Fe', 'Fe', 0, 1, 0, 6
Union All
SELECT 5, 'P', 'P	', 0, 1, 0, 7
Union All
SELECT 5, 'SiO2', 'SiO2', 0, 1, 0, 8
Union All
SELECT 5, 'Al2O3', 'Al2O3', 0, 1, 0, 9
Union All
SELECT 5, 'LOI', 'LOI', 0, 1, 0, 10
Union All
SELECT 5, 'SourceProductSize', 'SourceProductSize', 0, 0, 0, 11
Union All
SELECT 5, 'DestinationProductSize', 'DestinationProductSize', 0, 0, 0, 12
Union All
SELECT 5, 'SourceProduct', 'SourceProduct', 0, 0, 0, 13
Union All
SELECT 5, 'DestinationProduct', 'DestinationProduct', 0, 0, 0, 14
Go

--Port Shipping
Delete from UserInterfaceListingField
Where User_Interface_Listing_id = 6
Go

--Insert Into UserInterfaceListingField
INSERT INTO UserInterfaceListingField
SELECT 6 As User_Interface_Listing_Id, 'NominationKey' As Field_Name, 'Nomination Key' As Display_Name, 0 As Pixel_Width, 1 As Is_Visible, 0 As Sum_Field, 0 As Order_No
Union All
SELECT 6, 'Nomination', 'Nomination', 0, 1, 0, 1
Union All
SELECT 6, 'OfficialFinishTime', 'Official Finish Time', 0, 1, 0, 2
Union All
SELECT 6, 'COA', 'COA', 0, 1, 0, 3
Union All
SELECT 6, 'VesselName', 'Vessel Name', 0, 1, 0, 4
Union All
SELECT 6, 'CustomerName', 'Customer Name', 0, 1, 0, 5
Union All
SELECT 6, 'ProductCode','Product Code', 0, 1, 0, 6
Union All
SELECT 6, 'Undersize','Undersize', 0, 1, 0, 7
Union All
SELECT 6, 'Oversize','Oversize', 0, 1, 0, 8
Union All
SELECT 6, 'H2O','H2O', 0, 1, 0, 9
Union All
SELECT 6, 'Hub', 'Hub', 0, 1, 0, 10
Union All
SELECT 6, 'Tonnes','Tonnes', 0, 1, 0, 11
Union All
SELECT 6, 'Fe', 'Fe', 0, 1, 0, 12
Union All
SELECT 6, 'P', 'P	', 0, 1, 0, 13
Union All
SELECT 6, 'SiO2', 'SiO2', 0, 1, 0, 14
Union All
SELECT 6, 'Al2O3', 'Al2O3', 0, 1, 0, 15
Union All
SELECT 6, 'LOI', 'LOI', 0, 1, 0, 16
Union All
SELECT 6, 'CustomerNo', 'Customer No', 0, 0, 0, 17
Union All
SELECT 6, 'Density', 'Density', 0, 0, 0, 18
Union All
SELECT 6, 'LastAuthorisedDate', 'Last Authorised Date', 0, 0, 0, 19
Go
