-- New fields for enhancement
INSERT INTO UserInterfaceListingField
(User_Interface_Listing_Id, Field_Name, Display_Name, Pixel_Width, Is_Visible, Sum_Field, Order_No)
SELECT 6, 'H2O', 'H2O', 0, 1, 0, 9
UNION ALL
SELECT 6, 'COA', 'COA', 0, 1, 0, 12
UNION ALL
SELECT 6, 'Undersize', 'Undersize', 0, 1, 0, 13
UNION ALL
SELECT 6, 'Oversize', 'Oversize', 0, 1, 0, 14

GO