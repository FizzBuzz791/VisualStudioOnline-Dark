IF NOT EXISTS(SELECT * FROM DigblockField WHERE Digblock_Field_Id = 'BlockExternalSystemId')
BEGIN
	INSERT INTO DigblockField(Digblock_Field_Id, Description, Order_No, In_Table, Has_Value, Has_Notes, Has_Formula)
	VALUES ('BlockExternalSystemId', 'BlockExternalSystemId', 9, 1, 0, 1, 0)
END