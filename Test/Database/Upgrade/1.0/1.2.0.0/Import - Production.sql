-- // Migrates the Import Sync Row \\
-- Note that ImportChangedField does not need to be migrated as the only changes were to key-based fields
-- ImportSyncValidate/ImportSyncConflict do not need to be migrated as the latest version will clear out on next run
-- older versions will be out of sync but these are not used and can generally be purged

DECLARE @Result XML
DECLARE @ImportSyncRowId BIGINT
DECLARE @ImportRowCursor CURSOR

SET @ImportRowCursor = CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
	SELECT r.ImportSyncRowId
	FROM dbo.ImportSyncRow AS r
		INNER JOIN dbo.Import AS i
			ON (r.ImportId = i.ImportId)
		INNER JOIN dbo.ImportSyncTable AS t
			ON (r.ImportSyncTableId = t.ImportSyncTableId)
	WHERE i.ImportName = 'Production'
		AND t.Name = 'Transaction'	

OPEN @ImportRowCursor
FETCH NEXT FROM @ImportRowCursor INTO @ImportSyncRowId
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @Result =
		(
			SELECT
				SourceRow.value('(//ProductionSource/Transaction/TransactionDate)[1]', 'VARCHAR(MAX)') AS TransactionDate,
				SourceRow.value('(//ProductionSource/Transaction/Source)[1]', 'VARCHAR(MAX)') AS Source,
				SourceRow.value('(//ProductionSource/Transaction/Site)[1]', 'VARCHAR(MAX)') AS SourceMineSite,
				SourceRow.value('(//ProductionSource/Transaction/SourceLocationType)[1]', 'VARCHAR(MAX)') AS SourceLocationType,
				SourceRow.value('(//ProductionSource/Transaction/Destination)[1]', 'VARCHAR(MAX)') AS Destination,
				SourceRow.value('(//ProductionSource/Transaction/Site)[1]', 'VARCHAR(MAX)') AS DestinationMineSite,
				SourceRow.value('(//ProductionSource/Transaction/DestinationType)[1]', 'VARCHAR(MAX)') AS DestinationType,
				SourceRow.value('(//ProductionSource/Transaction/Type)[1]', 'VARCHAR(MAX)') AS Type,
				SourceRow.value('(//ProductionSource/Transaction/SampleSource)[1]', 'VARCHAR(MAX)') AS SampleSource,
				SourceRow.value('(//ProductionSource/Transaction/SampleTonnes)[1]', 'VARCHAR(MAX)') AS SampleTonnes,
				SourceRow.value('(//ProductionSource/Transaction/Tonnes)[1]', 'VARCHAR(MAX)') AS Tonnes,
				SourceRow.value('(//ProductionSource/Transaction/FinesPercent)[1]', 'VARCHAR(MAX)') AS FinesPercent,
				SourceRow.value('(//ProductionSource/Transaction/LumpPercent)[1]', 'VARCHAR(MAX)') AS LumpPercent,
				SourceRow.value('(//ProductionSource/Transaction/Grades)[1]', 'VARCHAR(MAX)') AS Grades
			FROM dbo.ImportSyncRow
			WHERE ImportSyncRowId = @ImportSyncRowId
			FOR XML PATH('Transaction'), ROOT('ProductionSource')
		)

	UPDATE dbo.ImportSyncRow
	SET SourceRow = @Result
	WHERE ImportSyncRowId = @ImportSyncRowId

	FETCH NEXT FROM @ImportRowCursor INTO @ImportSyncRowId
END
CLOSE @ImportRowCursor
GO
