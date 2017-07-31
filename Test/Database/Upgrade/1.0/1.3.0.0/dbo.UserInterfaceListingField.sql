
DELETE FROM userinterfacelistingfield
where User_Interface_Listing_Id = (SELECT User_Interface_Listing_Id FROM UserInterfaceListing WHERE  Internal_Name = 'Approval_Digblock')

INSERT INTO userinterfacelistingfield
(User_Interface_Listing_Id, Field_Name, Display_Name, Pixel_Width, Is_Visible, Sum_Field, Order_No)
SELECT User_Interface_Listing_Id,'DigblockLink','Blastblock','0','1','0','0' FROM UserInterfaceListing WHERE  Internal_Name = 'Approval_Digblock'
UNION SELECT User_Interface_Listing_Id,'Ore Type','MaterialTypeDescription','0','1','0','1' FROM UserInterfaceListing WHERE  Internal_Name = 'Approval_Digblock'
UNION SELECT User_Interface_Listing_Id,'MiningTonnes','Monthly<br>Mining<br>Model','0','1','0','3' FROM UserInterfaceListing WHERE  Internal_Name = 'Approval_Digblock'
UNION SELECT User_Interface_Listing_Id,'GeologyTonnes','Monthly<br>Geology<br>Model','0','1','0','2' FROM UserInterfaceListing WHERE  Internal_Name = 'Approval_Digblock'
UNION SELECT User_Interface_Listing_Id,'GradeControlTonnes','Monthly<br>Grade Control','0','1','0','4' FROM UserInterfaceListing WHERE  Internal_Name = 'Approval_Digblock'
UNION SELECT User_Interface_Listing_Id,'HauledTonnes','Monthly<br>Hauled','0','1','0','5' FROM UserInterfaceListing WHERE  Internal_Name = 'Approval_Digblock'
UNION SELECT User_Interface_Listing_Id,'BestTonnes','Monthly<br>Best Tonnes','0','1','0','6' FROM UserInterfaceListing WHERE  Internal_Name = 'Approval_Digblock'
UNION SELECT User_Interface_Listing_Id,'RemainingTonnes','Total Remaining<br>Grade Control','0','1','0','7' FROM UserInterfaceListing WHERE  Internal_Name = 'Approval_Digblock'
UNION SELECT User_Interface_Listing_Id,'ApprovedCheck','Approved','0','1','0','8' FROM UserInterfaceListing WHERE  Internal_Name = 'Approval_Digblock'
UNION SELECT User_Interface_Listing_Id,'SignoffUser','Sign Off','0','1','0','9' FROM UserInterfaceListing WHERE  Internal_Name = 'Approval_Digblock'
UNION SELECT User_Interface_Listing_Id,'CorrectedTonnes','Corrected','0','0','0','' FROM UserInterfaceListing WHERE  Internal_Name = 'Approval_Digblock'
UNION SELECT User_Interface_Listing_Id,'SurveyedTonnes','Surveyed','0','0','0','' FROM UserInterfaceListing WHERE  Internal_Name = 'Approval_Digblock'