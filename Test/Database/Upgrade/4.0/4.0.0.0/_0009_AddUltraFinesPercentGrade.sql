IF NOT EXISTS (SELECT * FROM Grade WHERE Grade_Name = 'Ultrafines')
BEGIN
	SET IDENTITY_INSERT dbo.Grade ON

	INSERT INTO Grade(Grade_Id, Grade_Name, Description, Order_No, Units, Display_Precision, Display_Format, Grade_Type_Id, Is_Visible)
	VALUES (10,'Ultrafines','Ultrafines',95,'%',2,'DP','Normal',0)

	SET IDENTITY_INSERT dbo.Grade OFF
END
