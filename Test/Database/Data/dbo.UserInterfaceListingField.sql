-- Data pop script for UserInterfaceListingField

/*INSERT INTO UserInterfaceListingField
(User_Interface_Listing_Id, Field_Name, Display_Name, Pixel_Width, Is_Visible, Sum_Field, Order_No)
SELECT 49, 'Auto_Activate_Haulage', 'Auto Activate Haulage', 99, 0, 0, 0 UNION ALL
SELECT 50, 'Blast_Block_ID', 'Blast Block ID', 99, 0, 0, 0 UNION ALL
SELECT 51, 'Creation_Datetime', 'Creation Datetime', 99, 0, 0, 0 UNION ALL
SELECT 52, 'Depleted_Blast_Block', 'Depleted<br>Blast<br>Block', 90, 0, 1, 0 UNION ALL
SELECT 53, 'Depleted_Reserve', 'Depleted<br>Mining<br>Model', 90, 0, 1, 0 UNION ALL
SELECT 54, 'Depleted_Resource', 'Depleted<br>Geology<br>Model', 90, 0, 1, 0 UNION ALL
SELECT 55, 'Description', 'Description', 30, 0, 0, 0 UNION ALL
SELECT 56, 'Digblock_ID', 'Blastblock Id', 70, 1, 0, 0 UNION ALL
SELECT 57, 'End_Date', 'End Date', 80, 1, 0, 5 UNION ALL
SELECT 58, 'End_Shift', 'End Shift', 99, 0, 0, 0 UNION ALL
SELECT 59, 'Is_Active', 'Is Active', 99, 0, 0, 0 UNION ALL
SELECT 60, 'Is_Closed', 'Is Closed', 99, 0, 0, 0 UNION ALL
SELECT 61, 'Material_Type_ID', 'Material Type ID', 30, 0, 0, 0 UNION ALL
SELECT 62, 'Material_Type_Name', 'Ore Type', 45, 1, 1, 2 UNION ALL
SELECT 63, 'Notes', 'Notes', 99, 0, 0, 0 UNION ALL
SELECT 64, 'Remaining_Tonnes', 'Remaining<br>Tonnes<br>(Grade Control -<br>Actuals)', 60, 1, 0, 9 UNION ALL
SELECT 65, 'Start_Date', 'Start Date', 80, 1, 0, 3 UNION ALL
SELECT 66, 'Start_Shift', 'Start Shift', 99, 0, 0, 0 UNION ALL
SELECT 67, 'Start_Tonnes', 'Start Tonnes<br> (Grade Control)', 60, 1, 0, 6 UNION ALL
SELECT 68, 'Total_Unapproved_Removed_Tonnes', 'Best Hauled<br>Tonnes', 99, 1, 0, 8 UNION ALL
SELECT 69, 'Unapproved_Removed_Tonnes', '(Reconciled)<br>Tonnes', 70, 1, 0, 7 UNION ALL
SELECT 70, 'X', 'X', 99, 0, 0, 0 UNION ALL
SELECT 71, 'Y', 'Y', 99, 0, 0, 0 UNION ALL
SELECT 72, 'Z', 'Z', 99, 0, 0, 0 UNION ALL
SELECT 73, 'Abbreviation', 'Abbreviation', 99, 0, 0, 0 UNION ALL
SELECT 74, 'Al2O3', 'Al2O3', 0, 1, 0, 99 UNION ALL
SELECT 75, 'Approved_Added_Tonnes_This_Month', 'Approved Added Tonnes<br>This Month', 30, 0, 1, 0 UNION ALL
SELECT 76, 'Current_Tonnes', 'Current Tonnes', 0, 1, 1, 3 UNION ALL
SELECT 77, 'Density', 'Density', 0, 0, 0, 0 UNION ALL
SELECT 78, 'Description', 'Description', 200, 1, 0, 2 UNION ALL
SELECT 79, 'Fe', 'Fe', 0, 1, 0, 9 UNION ALL
SELECT 80, 'Is_Completed', 'Is Completed', 30, 0, 0, 0 UNION ALL
SELECT 81, 'Is_Waste', 'Is Waste', 99, 0, 0, 0 UNION ALL
SELECT 82, 'LOI', 'LOI', 0, 1, 0, 99 UNION ALL
SELECT 83, 'Material_Type_Description', 'Material Type Description', 99, 0, 0, 0 UNION ALL
SELECT 84, 'Material_Type_Id', 'Material Type Id', 30, 0, 0, 0 UNION ALL
SELECT 85, 'Native_Alternative', 'Native Alternative', 99, 0, 0, 0 UNION ALL
SELECT 86, 'Order_No', 'Order No', 99, 0, 0, 0 UNION ALL
SELECT 87, 'P', 'P', 0, 1, 0, 10 UNION ALL
SELECT 88, 'Removed_Tonnes_This_Month', 'Removed Tonnes<br>This Period', 0, 1, 1, 6 UNION ALL
SELECT 89, 'SiO2', 'SiO2', 0, 1, 0, 99 UNION ALL
SELECT 90, 'Stockpile_Added_Tonnes_This_Month', 'Stockpile Added Tonnes<br>This Period', 0, 0, 1, 0 UNION ALL
SELECT 91, 'Stockpile_Group_Id', 'Stockpile Group Id', 0, 1, 0, 0 UNION ALL
SELECT 92, 'Stockpile_Name', 'Stockpile Name', 0, 1, 0, 1 UNION ALL
SELECT 93, 'Unapproved_Added_Tonnes_This_Month', 'Added Tonnes<br>This Period', 0, 1, 1, 5 UNION ALL
SELECT 94, 'Heading', 'Heading', 30, 1, 0, 0 UNION ALL
SELECT 95, 'Order_No', 'Order No', 30, 0, 0, 0 UNION ALL
SELECT 96, 'Sub_Heading', 'Sub Heading', 30, 1, 0, 0 UNION ALL
SELECT 97, 'Tonnes', 'Tonnes', 30, 1, 1, 3 UNION ALL
SELECT 98, 'Transaction_Date', 'Transaction Date', 30, 1, 0, 1 UNION ALL
SELECT 99, 'Transaction_ID', 'Transaction ID', 99, 0, 0, 0 UNION ALL
SELECT 100, 'Transaction_Shift', 'Transaction Shift', 30, 1, 0, 2 UNION ALL
SELECT 101, 'Transaction_Shift_Order_No', 'Transaction Shift Order No', 30, 0, 0, 0 UNION ALL
SELECT 102, 'Balance Date', 'Balance Date', 0, 1, 0, 0 UNION ALL
SELECT 103, 'Hub', 'Hub', 0, 1, 0, 2 UNION ALL
SELECT 104, 'Tonnes', 'Tonnes', 0, 1, 0, 1 UNION ALL
SELECT 105, 'Al2O3', 'Al2O3', 0, 1, 0, 10 UNION ALL
SELECT 106, 'Density', 'Density', 0, 0, 0, 0 UNION ALL
SELECT 107, 'Destination Hub', 'Destination Hub', 0, 1, 0, 5 UNION ALL
SELECT 108, 'End Date', 'End Date', 0, 1, 0, 1 UNION ALL
SELECT 109, 'Fe', 'Fe', 0, 1, 0, 7 UNION ALL
SELECT 110, 'Load Site', 'Load Site', 0, 1, 0, 2 UNION ALL
SELECT 111, 'LOI', 'LOI', 0, 1, 0, 11 UNION ALL
SELECT 112, 'Move Hub', 'Move Hub', 0, 1, 0, 4 UNION ALL
SELECT 113, 'P', 'P', 0, 1, 0, 8 UNION ALL
SELECT 114, 'Rake Hub', 'Load Hub', 0, 1, 0, 3 UNION ALL
SELECT 115, 'SiO2', 'SiO2', 0, 1, 0, 9 UNION ALL
SELECT 116, 'Start Date', 'Start Date', 0, 1, 0, 0 UNION ALL
SELECT 117, 'Tonnes', 'Tonnes', 0, 1, 0, 6 UNION ALL
SELECT 118, 'Al2O3', 'Al2O3', 0, 1, 0, 7 UNION ALL
SELECT 119, 'Customer Name', 'Customer Name', 0, 0, 0, NULL UNION ALL
SELECT 120, 'Customer No', 'Customer No', 0, 0, 0, NULL UNION ALL
SELECT 121, 'Density', 'Density', 0, 0, 0, NULL UNION ALL
SELECT 122, 'Fe', 'Fe', 0, 1, 0, 4 UNION ALL
SELECT 123, 'Hub', 'Hub', 0, 1, 0, 1 UNION ALL
SELECT 124, 'Last Authorised Date', 'Last Authorised Date', 0, 1, 0, 11 UNION ALL
SELECT 125, 'LOI', 'LOI', 0, 1, 0, 8 UNION ALL
SELECT 126, 'Nomination', 'Nomination', 0, 0, 0, NULL UNION ALL
SELECT 127, 'Nomination Key', 'Nomination Key', 0, 0, 0, NULL UNION ALL
SELECT 128, 'Official Finish Time', 'Official Finish Time', 0, 1, 0, 0 UNION ALL
SELECT 129, 'P', 'P', 0, 1, 0, 5 UNION ALL
SELECT 130, 'Product Code', 'Product Code', 0, 1, 0, 2 UNION ALL
SELECT 131, 'SiO2', 'SiO2', 0, 1, 0, 6 UNION ALL
SELECT 132, 'Tonnes', 'Tonnes', 0, 1, 0, 3 UNION ALL
SELECT 133, 'Vessel Name', 'Vessel Name', 0, 0, 0, NULL UNION ALL
SELECT 145, 'Actual', 'Actuals<br>Movements to Stockpiles<br>ktonnes', 0, 1, 0, 5 UNION ALL
SELECT 146, 'ApprovedCheck', 'Approved', 0, 1, 0, 6 UNION ALL
SELECT 147, 'Geology', 'Geology Model<br>ktonnes', 0, 1, 0, 1 UNION ALL
SELECT 148, 'Grade Control', 'Grade Control<br>ktonnes', 0, 1, 0, 4 UNION ALL
SELECT 149, 'MaterialName', '', 200, 1, 0, 0 UNION ALL
SELECT 150, 'Mining', 'Mining Model<br>ktonnes', 0, 1, 0, 2 UNION ALL
SELECT 151, 'Signoff', 'Sign Off', 0, 1, 0, 99 UNION ALL
SELECT 152, 'Al2O3', 'Al2O3', 0, 1, 0, 5 UNION ALL
SELECT 153, 'ApprovedCheck', 'Approved', 0, 1, 0, 8 UNION ALL
SELECT 154, 'Description', 'Description', 310, 1, 0, 0 UNION ALL
SELECT 155, 'Fe', 'Fe', 0, 1, 0, 2 UNION ALL
SELECT 156, 'Investigation', 'Live Data Viewer', 20, 1, 0, NULL UNION ALL
SELECT 157, 'LOI', 'LOI', 0, 1, 0, 7 UNION ALL
SELECT 158, 'P', 'P', 0, 1, 0, 3 UNION ALL
SELECT 159, 'SignOff', 'SignOff', 0, 1, 0, 9 UNION ALL
SELECT 160, 'SiO2', 'SiO2', 0, 1, 0, 6 UNION ALL
SELECT 161, 'Tonnes', 'KTonnes', 0, 1, 0, 1 UNION ALL
SELECT 162, 'ApprovedCheck', 'Approved', 0, 1, 0, 8 UNION ALL
SELECT 163, 'BestTonnes', 'Monthly<br>Best Tonnes', 0, 1, 0, 6 UNION ALL
SELECT 164, 'CorrectedTonnes', 'Corrected', 0, 0, 0, 0 UNION ALL
SELECT 165, 'DigblockLink', 'Blastblock', 0, 1, 0, 0 UNION ALL
SELECT 166, 'GeologyTonnes', 'Monthly<br>Geology<br>Model', 0, 1, 0, 2 UNION ALL
SELECT 167, 'GradeControlTonnes', 'Monthly<br>Grade Control', 0, 1, 0, 4 UNION ALL
SELECT 168, 'HauledTonnes', 'Monthly<br>Hauled', 0, 1, 0, 5 UNION ALL
SELECT 169, 'MaterialTypeDescription', 'Ore Type', 0, 1, 0, 1 UNION ALL
SELECT 170, 'MiningTonnes', 'Monthly<br>Mining<br>Model', 0, 1, 0, 3 UNION ALL
SELECT 171, 'RemainingTonnes', 'Total Remaining<br>Grade Control', 0, 1, 0, 7 UNION ALL
SELECT 172, 'SignoffUser', 'Sign Off', 0, 1, 0, 9 UNION ALL
SELECT 173, 'SurveyedTonnes', 'Surveyed', 0, 0, 0, 0 UNION ALL
SELECT 174, 'Added_Tonnes_This_Month', 'Added Tonnes<br>This Month', 99, 0, 0, 0 UNION ALL
SELECT 175, 'H2O', 'H2O', 0, 1, 0, 9 UNION ALL
SELECT 176, 'COA', 'COA', 0, 1, 0, 12 UNION ALL
SELECT 177, 'Undersize', 'Undersize', 0, 1, 0, 13 UNION ALL
SELECT 178, 'Oversize', 'Oversize', 0, 1, 0, 14*/