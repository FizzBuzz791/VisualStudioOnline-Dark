
--
-- Script to populate the StockpileGroupNotes table to flag 'admin only' groups
--
IF NOT EXISTS (SELECT 1 FROM StockpileGroupField WHERE Stockpile_Group_Field_Id = 'ADMIN_EDITABLE_ONLY')
BEGIN
	
	INSERT INTO StockpileGroupField
			(Stockpile_Group_Field_Id,Description,Order_No,In_Table,Has_Value,Has_Notes,Has_Formula)
		VALUES
			('ADMIN_EDITABLE_ONLY', 'The membership of this stockpile group can only be changed by admins', 1, 1, 0, 1, 0)


		
	INSERT INTO dbo.StockpileGroupNotes
			   (Stockpile_Group_Id, Stockpile_Group_Field_Id, Notes)
		 VALUES
			   ('Post Crusher', 'ADMIN_EDITABLE_ONLY', 'TRUE')
			   
END

Go




