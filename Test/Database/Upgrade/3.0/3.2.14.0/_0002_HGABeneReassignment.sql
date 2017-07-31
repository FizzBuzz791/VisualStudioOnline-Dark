IF EXISTS (SELECT * FROM MaterialType WHERE Abbreviation = 'HGABene')
BEGIN
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

	-- reassign all summary entries for the HGA Newman material type.. to the new HGABene material type.. but only PRIOR TO the cutoff
	UPDATE se
		SET se.MaterialTypeId = @hgaBeneId
	FROM BhpbioSummaryEntry se
		INNER JOIN BhpbioSummary s ON s.SummaryId = se.SummaryId
	WHERE s.SummaryMonth < @cutoff
		AND se.MaterialTypeId = @hgaId

	COMMIT TRANSACTION
END