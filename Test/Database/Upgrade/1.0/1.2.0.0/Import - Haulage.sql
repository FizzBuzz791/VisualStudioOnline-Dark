-- // Migrates the Import Sync Row \\
-- Note that ImportChangedField does not need to be migrated as the only changes were to key-based fields
-- ImportSyncValidate/ImportSyncConflict do not need to be migrated as the latest version will clear out on next run
-- older versions will be out of sync but these are not used and can generally be purged

DECLARE @Result XML
DECLARE @ImportSyncRowId BIGINT
DECLARE @ImportRowCursor CURSOR

-- update the HAULAGE table

SET @ImportRowCursor = CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
	SELECT r.ImportSyncRowId
	FROM dbo.ImportSyncRow AS r
		INNER JOIN dbo.Import AS i
			ON (r.ImportId = i.ImportId)
		INNER JOIN dbo.ImportSyncTable AS t
			ON (r.ImportSyncTableId = t.ImportSyncTableId)
	WHERE i.ImportName = 'Haulage'
		AND t.Name = 'Haulage'	

OPEN @ImportRowCursor
FETCH NEXT FROM @ImportRowCursor INTO @ImportSyncRowId
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @Result =
		(
			SELECT SourceRow.value('(//HaulageSource/Haulage/HaulageDate)[1]', 'VARCHAR(MAX)') AS HaulageDate,
				SourceRow.value('(//HaulageSource/Haulage/HaulageShift)[1]', 'VARCHAR(MAX)') AS HaulageShift,
				SourceRow.value('(//HaulageSource/Haulage/Mine)[1]', 'VARCHAR(MAX)') AS SourceMineSite,
				SourceRow.value('(//HaulageSource/Haulage/Source)[1]', 'VARCHAR(MAX)') AS Source,
				SourceRow.value('(//HaulageSource/Haulage/Mine)[1]', 'VARCHAR(MAX)') AS DestinationMineSite,
				SourceRow.value('(//HaulageSource/Haulage/Destination)[1]', 'VARCHAR(MAX)') AS Destination,
				SourceRow.value('(//HaulageSource/Haulage/Tonnes)[1]', 'VARCHAR(MAX)') AS Tonnes,
				SourceRow.value('(//HaulageSource/Haulage/Loads)[1]', 'VARCHAR(MAX)') AS Loads,
				SourceRow.value('(//HaulageSource/Haulage/Truck)[1]', 'VARCHAR(MAX)') AS Truck,
				SourceRow.value('(//HaulageSource/Haulage/Type)[1]', 'VARCHAR(MAX)') AS Type
			FROM dbo.ImportSyncRow
			WHERE ImportSyncRowId = @ImportSyncRowId
			FOR XML PATH('Haulage'), ROOT('HaulageSource')
		)

	UPDATE dbo.ImportSyncRow
	SET SourceRow = @Result
	WHERE ImportSyncRowId = @ImportSyncRowId

	FETCH NEXT FROM @ImportRowCursor INTO @ImportSyncRowId
END
CLOSE @ImportRowCursor


-- update the HAULAGE GRADE table

SET @ImportRowCursor = CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
	SELECT r.ImportSyncRowId
	FROM dbo.ImportSyncRow AS r
		INNER JOIN dbo.Import AS i
			ON (r.ImportId = i.ImportId)
		INNER JOIN dbo.ImportSyncTable AS t
			ON (r.ImportSyncTableId = t.ImportSyncTableId)
	WHERE i.ImportName = 'Haulage'
		AND t.Name = 'HaulageGrade'	

OPEN @ImportRowCursor
FETCH NEXT FROM @ImportRowCursor INTO @ImportSyncRowId
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @Result =
		(
			SELECT SourceRow.value('(//HaulageSource/HaulageGrade/HaulageDate)[1]', 'DATETIME') AS HaulageDate,
				SourceRow.value('(//HaulageSource/HaulageGrade/HaulageShift)[1]', 'CHAR(1)') AS HaulageShift,
				SourceRow.value('(//HaulageSource/HaulageGrade/Source)[1]', 'VARCHAR(63)') AS Source,
				SourceRow.value('(//HaulageSource/HaulageGrade/Mine)[1]', 'VARCHAR(2)') AS SourceMineSite,
				SourceRow.value('(//HaulageSource/HaulageGrade/Destination)[1]', 'VARCHAR(63)') AS Destination,
				SourceRow.value('(//HaulageSource/HaulageGrade/Mine)[1]', 'VARCHAR(2)') AS DestinationMineSite,
				SourceRow.value('(//HaulageSource/HaulageGrade/Truck)[1]', 'VARCHAR(31)') AS Truck,
				SourceRow.value('(//HaulageSource/HaulageGrade/Type)[1]', 'VARCHAR(255)') AS Type,
				SourceRow.value('(//HaulageSource/HaulageGrade/GradeName)[1]', 'VARCHAR(31)') AS GradeName,
				SourceRow.value('(//HaulageSource/HaulageGrade/Value)[1]', 'VARCHAR(255)') AS Value
			FROM dbo.ImportSyncRow
			WHERE ImportSyncRowId = @ImportSyncRowId
			FOR XML PATH('HaulageGrade'), ROOT('HaulageSource')
		)

	UPDATE dbo.ImportSyncRow
	SET SourceRow = @Result
	WHERE ImportSyncRowId = @ImportSyncRowId

	FETCH NEXT FROM @ImportRowCursor INTO @ImportSyncRowId
END
CLOSE @ImportRowCursor


-- update the HAULAGE NOTES table

SET @ImportRowCursor = CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
	SELECT r.ImportSyncRowId
	FROM dbo.ImportSyncRow AS r
		INNER JOIN dbo.Import AS i
			ON (r.ImportId = i.ImportId)
		INNER JOIN dbo.ImportSyncTable AS t
			ON (r.ImportSyncTableId = t.ImportSyncTableId)
	WHERE i.ImportName = 'Haulage'
		AND t.Name = 'HaulageNotes'	

OPEN @ImportRowCursor
FETCH NEXT FROM @ImportRowCursor INTO @ImportSyncRowId
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @Result =
		(
			SELECT SourceRow.value('(//HaulageSource/HaulageNotes/HaulageDate)[1]', 'VARCHAR(MAX)') AS HaulageDate,
				SourceRow.value('(//HaulageSource/HaulageNotes/HaulageShift)[1]', 'VARCHAR(MAX)') AS HaulageShift,
				SourceRow.value('(//HaulageSource/HaulageNotes/Source)[1]', 'VARCHAR(MAX)') AS Source,
				SourceRow.value('(//HaulageSource/HaulageNotes/Mine)[1]', 'VARCHAR(MAX)') AS SourceMineSite,
				SourceRow.value('(//HaulageSource/HaulageNotes/Destination)[1]', 'VARCHAR(MAX)') AS Destination,
				SourceRow.value('(//HaulageSource/HaulageNotes/Mine)[1]', 'VARCHAR(MAX)') AS DestinationMineSite,
				SourceRow.value('(//HaulageSource/HaulageNotes/Truck)[1]', 'VARCHAR(MAX)') AS Truck,
				SourceRow.value('(//HaulageSource/HaulageNotes/Type)[1]', 'VARCHAR(MAX)') AS Type,
				SourceRow.value('(//HaulageSource/HaulageNotes/FieldId)[1]', 'VARCHAR(MAX)') AS FieldId,
				SourceRow.value('(//HaulageSource/HaulageNotes/Notes)[1]', 'VARCHAR(MAX)') AS Notes
			FROM dbo.ImportSyncRow
			WHERE ImportSyncRowId = @ImportSyncRowId
			FOR XML PATH('HaulageNotes'), ROOT('HaulageSource')
		)

	UPDATE dbo.ImportSyncRow
	SET SourceRow = @Result
	WHERE ImportSyncRowId = @ImportSyncRowId

	FETCH NEXT FROM @ImportRowCursor INTO @ImportSyncRowId
END
CLOSE @ImportRowCursor


-- update the HAULAGE VALUE table

SET @ImportRowCursor = CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
	SELECT r.ImportSyncRowId
	FROM dbo.ImportSyncRow AS r
		INNER JOIN dbo.Import AS i
			ON (r.ImportId = i.ImportId)
		INNER JOIN dbo.ImportSyncTable AS t
			ON (r.ImportSyncTableId = t.ImportSyncTableId)
	WHERE i.ImportName = 'Haulage'
		AND t.Name = 'HaulageValue'	

OPEN @ImportRowCursor
FETCH NEXT FROM @ImportRowCursor INTO @ImportSyncRowId
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @Result =
		(
			SELECT SourceRow.value('(//HaulageSource/HaulageValue/HaulageDate)[1]', 'VARCHAR(MAX)') AS HaulageDate,
				SourceRow.value('(//HaulageSource/HaulageValue/HaulageShift)[1]', 'VARCHAR(MAX)') AS HaulageShift,
				SourceRow.value('(//HaulageSource/HaulageValue/Source)[1]', 'VARCHAR(MAX)') AS Source,
				SourceRow.value('(//HaulageSource/HaulageValue/Mine)[1]', 'VARCHAR(MAX)') AS SourceMineSite,
				SourceRow.value('(//HaulageSource/HaulageValue/Destination)[1]', 'VARCHAR(MAX)') AS Destination,
				SourceRow.value('(//HaulageSource/HaulageValue/Mine)[1]', 'VARCHAR(MAX)') AS DestinationMineSite,
				SourceRow.value('(//HaulageSource/HaulageValue/Truck)[1]', 'VARCHAR(MAX)') AS Truck,
				SourceRow.value('(//HaulageSource/HaulageValue/Type)[1]', 'VARCHAR(MAX)') AS Type,
				SourceRow.value('(//HaulageSource/HaulageValue/FieldId)[1]', 'VARCHAR(MAX)') AS FieldId,
				SourceRow.value('(//HaulageSource/HaulageValue/Value)[1]', 'VARCHAR(MAX)') AS Value
			FROM dbo.ImportSyncRow
			WHERE ImportSyncRowId = @ImportSyncRowId
			FOR XML PATH('HaulageValue'), ROOT('HaulageSource')
		)

	UPDATE dbo.ImportSyncRow
	SET SourceRow = @Result
	WHERE ImportSyncRowId = @ImportSyncRowId

	FETCH NEXT FROM @ImportRowCursor INTO @ImportSyncRowId
END
CLOSE @ImportRowCursor

/* testing
SELECT * FROM dbo.BhpbioImportHaulage
SELECT * FROM dbo.BhpbioImportHaulageGrade
SELECT * FROM dbo.BhpbioImportHaulageNotes
SELECT * FROM dbo.BhpbioImportHaulageValue
*/
GO

-- clear existing haulage prior to re-resolution
EXEC dbo.DeleteHaulageAll

-- create copies of the HaulageRawField
INSERT INTO dbo.HaulageRawField
(
	Haulage_Raw_Field_Id, Description, Order_No, In_Table, Has_Value, Has_Notes, Has_Formula
)
SELECT 'SourceMineSite', Description, Order_No, In_Table, Has_Value, Has_Notes, Has_Formula
FROM dbo.HaulageRawField
WHERE Haulage_Raw_Field_Id = 'Site'
UNION ALL
SELECT 'DestinationMineSite', Description, Order_No, In_Table, Has_Value, Has_Notes, Has_Formula
FROM dbo.HaulageRawField
WHERE Haulage_Raw_Field_Id = 'Site'

-- create copies of HaulageField
INSERT INTO dbo.HaulageField
(
	Haulage_Field_Id, Description, Order_No, In_Table, Has_Value, Has_Notes, Has_Formula
)
SELECT 'SourceMineSite', Description, Order_No, In_Table, Has_Value, Has_Notes, Has_Formula
FROM dbo.HaulageField
WHERE Haulage_Field_Id = 'Site'
UNION ALL
SELECT 'DestinationMineSite', Description, Order_No, In_Table, Has_Value, Has_Notes, Has_Formula
FROM dbo.HaulageField
WHERE Haulage_Field_Id = 'Site'

-- migrate haulage raw notes
INSERT INTO dbo.HaulageRawNotes
(
	Haulage_Raw_Id, Haulage_Raw_Field_Id, Notes
)
SELECT Haulage_Raw_Id, 'SourceMineSite', Notes
FROM dbo.HaulageRawNotes
WHERE Haulage_Raw_Field_Id = 'Site'
UNION ALL
SELECT Haulage_Raw_Id, 'DestinationMineSite', Notes
FROM dbo.HaulageRawNotes
WHERE Haulage_Raw_Field_Id = 'Site'

-- clean up
DELETE
FROM dbo.HaulageRawNotes
WHERE Haulage_Raw_Field_Id = 'Site'

DELETE
FROM dbo.HaulageRawField
WHERE Haulage_Raw_Field_Id = 'Site'

DELETE
FROM dbo.HaulageField
WHERE Haulage_Field_Id = 'Site'

EXEC dbo.HaulageRawResolveAll
GO

/* testing
DECLARE @HaulageRawId INT
DECLARE @Resolved BIT
DECLARE @HaulageRawCursor CURSOR

SET @HaulageRawCursor = CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
	SELECT Haulage_Raw_Id
	FROM dbo.HaulageRaw
	WHERE Haulage_Raw_State_Id = 'A'

OPEN @HaulageRawCursor

FETCH NEXT FROM @HaulageRawCursor INTO @HaulageRawId
WHILE @@Fetch_Status = 0
BEGIN
	EXEC dbo.HaulageRawResolve
		@iHaulageRawId = @HaulageRawId,
		@oIsResolved = @Resolved OUTPUT

	PRINT @Resolved

	FETCH NEXT FROM @HaulageRawCursor INTO @HaulageRawId
END
GO
*/
