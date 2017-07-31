/*
IF EXISTS (SELECT * FROM MaterialType WHERE Abbreviation = 'HGABene')
BEGIN
	-- ROLLBACK SCRIPT
	DECLARE @cutoff DATETIME
	SET @cutoff = '2016-01-01'

	DECLARE @hgaId INTEGER

	SELECT @hgaId = mt.Material_Type_Id
	FROM MaterialType mt
	INNER JOIN MaterialTypeLocation mtl ON mtl.Material_Type_Id = mt.Material_Type_Id
	INNER JOIN Location l ON l.Location_Id = mtl.Location_Id
	WHERE mt.Abbreviation = 'HGA'
	AND l.Name = 'Newman'

	DECLARE @hgaBeneId INTEGER

	SELECT @hgaBeneId = mt.Material_Type_Id
	FROM MaterialType mt
	INNER JOIN MaterialTypeLocation mtl ON mtl.Material_Type_Id = mt.Material_Type_Id
	INNER JOIN Location l ON l.Location_Id = mtl.Location_Id
	WHERE mt.Abbreviation = 'HGABene'
	AND l.Name = 'Newman'

	BEGIN TRANSACTION

	-- reassign all summary entries back to the HGA Newman material type..
	UPDATE se
		SET se.MaterialTypeId = @hgaId
	FROM BhpbioSummaryEntry se
		INNER JOIN BhpbioSummary s ON s.SummaryId = se.SummaryId
	WHERE s.SummaryMonth < @cutoff
		AND se.MaterialTypeId = @hgaBeneId

	-- Change HGA back to Bene
	UPDATE mt
		SET mt.Parent_Material_Type_Id = 4 -- High Grade
	FROM MaterialType mt
	WHERE mt.Material_Type_Id = @hgaId

	DELETE FROM MaterialTypeLocation
	WHERE Material_Type_Id = @hgaBeneId

	DELETE FROM MaterialType 
	WHERE Material_Type_Id = @hgaBeneId

	COMMIT TRANSACTION
END
*/