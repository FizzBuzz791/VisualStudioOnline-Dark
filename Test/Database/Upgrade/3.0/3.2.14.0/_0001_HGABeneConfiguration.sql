IF NOT EXISTS (SELECT * FROM MaterialType WHERE Abbreviation = 'HGABene')
BEGIN
	-- Add HGABene type
	DECLARE @maxOrderNo INTEGER
	SELECT @maxOrderNo = MAX(Order_No) FROM MaterialType

	DECLARE @hgaId INTEGER

	SELECT @hgaId = mt.Material_Type_Id
	FROM MaterialType mt
	INNER JOIN MaterialTypeLocation mtl ON mtl.Material_Type_Id = mt.Material_Type_Id
	INNER JOIN Location l ON l.Location_Id = mtl.Location_Id
	WHERE mt.Abbreviation = 'HGA'
	AND l.Name = 'Newman'

	BEGIN TRANSACTION

	INSERT INTO MaterialType (Description, Order_No, Abbreviation, Native_Alternative, Is_Waste, Density_Conversion_Factor, Material_Type_Group_Id, Parent_Material_Type_Id, Material_Category_Id)
	VALUES ('HGABene',@maxOrderNo + 1,'HGABene',null,0,1,1,4,'OreType') -- 4 is Bene

	DECLARE @newId INTEGER
	SET @newId = SCOPE_IDENTITY()

	-- Assign HGABene to Newman
	INSERT INTO MaterialTypeLocation(Material_Type_Id, Location_Id)
	SELECT @newId, Location_Id
	FROM Location WHERE Name = 'Newman'

	-- Change HGA to high grade
	UPDATE mt
		SET mt.Parent_Material_Type_Id = 3 -- High Grade
	FROM MaterialType mt
	WHERE mt.Material_Type_Id = @hgaId

	COMMIT TRANSACTION
END