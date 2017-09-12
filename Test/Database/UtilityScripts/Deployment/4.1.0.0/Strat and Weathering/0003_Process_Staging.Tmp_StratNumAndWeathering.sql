declare @digblockId varchar(31)
declare @stratNum varchar(7)
declare @weathering int
declare @StratNumFound bit
declare @weatheringFound bit
declare @stratNumFoundInXml bit
declare @weatheringFoundInXml bit
declare @ERROR_MSG varchar(max)
declare @weatheringString varchar(1023)
declare @stratNumNode XML
declare @weatheringNode XML
declare @ImportSyncRowId int
declare @returnedErrorMessage nvarchar(4000)


--No point processing records where the digblock won't resolve - mark it as processed

UPDATE Staging.Tmp_StratWeatheringImport 
	SET [IMPORT_SYNC_ROW_ID] = bmsr.[ImportSyncRowId] 
FROM	Staging.Tmp_StratWeatheringImport inner join Staging.Tmp_BlockModelSyncRow  bmsr on 
			Staging.Tmp_StratWeatheringImport.DIGBLOCK_ID = bmsr.DigBlock_Id  

UPDATE Staging.Tmp_StratWeatheringImport
	SET	[STRATNUM_FOUND_IN_XML] = 1
FROM	[dbo].[ImportSyncRow] isr inner join Staging.Tmp_StratWeatheringImport on Staging.Tmp_StratWeatheringImport.IMPORT_SYNC_ROW_ID = isr.ImportSyncRowId
WHERE	[DIGBLOCK_FOUND] = 1
AND		isr.SourceRow.exist('(/BlockModelSource/BlastModelBlockWithPointAndGrade/StratNum)[1]') = 1

UPDATE Staging.Tmp_StratWeatheringImport
	SET	[WEATHERING_FOUND_IN_XML] = 1
FROM	[dbo].[ImportSyncRow] isr inner join Staging.Tmp_StratWeatheringImport on Staging.Tmp_StratWeatheringImport.IMPORT_SYNC_ROW_ID = isr.ImportSyncRowId
WHERE	[DIGBLOCK_FOUND] = 1
AND		isr.SourceRow.exist('(/BlockModelSource/BlastModelBlockWithPointAndGrade/Weathering)[1]') = 1

UPDATE Staging.Tmp_StratWeatheringImport
	SET	[Processed] = 1,
		[PROCESSED_DATETIME] = GetDate()
WHERE	[DIGBLOCK_FOUND] = 0
AND		PROCESSED = 0

DECLARE  CUR_DIGBLOCKS CURSOR  FOR
SELECT	TOP 1 
		[DIGBLOCK_ID],
		[GEOMET_STRATNUM],
		[GEOMET_WEATHERING],
		[STRATNUM_FOUND],
		[STRATNUM_FOUND_IN_XML],
		[WEATHERING_FOUND],
		[WEATHERING_FOUND_IN_XML],
		[IMPORT_SYNC_ROW_ID]
FROM	Staging.Tmp_StratWeatheringImport
WHERE	[PROCESSED] = 0
ORDER BY [SITE], [DIGBLOCK_ID]

OPEN CUR_DIGBLOCKS;

FETCH NEXT FROM CUR_DIGBLOCKS INTO @digblockId, @stratNum, @weathering, @StratNumFound, @stratNumFoundInXml, @weatheringFound, @weatheringFoundInXml, @ImportSyncRowId
WHILE @@FETCH_STATUS = 0  
BEGIN 
	PRINT @digblockId
	BEGIN TRY
		BEGIN TRANSACTION

		IF @StratNumFound = 1 
		BEGIN
			EXECUTE [dbo].[AddOrUpdateDigblockNotes]  @digblockId, 'StratNum', @stratNum

			IF @stratNumFoundInXml = 1
				UPDATE ImportSyncRow
					SET SourceRow.modify('replace value of (/BlockModelSource/BlastModelBlockWithPointAndGrade/StratNum/text())[1] with sql:variable("@stratNum")')
				WHERE ImportSyncRow.ImportSyncRowId = @ImportSyncRowId
			ELSE
			BEGIN
				SET @stratNumNode = '<StratNum>' + @stratNum + '</StratNum>'

				UPDATE ImportSyncRow
					SET SourceRow.modify('insert sql:variable("@stratNumNode") as last into (/BlockModelSource/BlastModelBlockWithPointAndGrade)[1]')
				WHERE ImportSyncRow.ImportSyncRowId = @ImportSyncRowId
			END
		END

		IF @weatheringFound = 1 
		BEGIN
			SET @weatheringString = cast(@weathering as varchar(1023))
			EXECUTE [dbo].[AddOrUpdateDigblockNotes]  @digblockId, 'Weathering', @weatheringString

			IF @weatheringFoundInXml = 1
				UPDATE ImportSyncRow
					SET SourceRow.modify('replace value of (/BlockModelSource/BlastModelBlockWithPointAndGrade/Weathering/text())[1] with sql:variable("@weatheringString")')
				WHERE ImportSyncRow.ImportSyncRowId = @ImportSyncRowId
			ELSE
			BEGIN
				SET @weatheringNode = '<Weathering>' + @weatheringString + '</Weathering>'

				UPDATE ImportSyncRow
					SET SourceRow.modify('insert sql:variable("@weatheringNode") as last into (/BlockModelSource/BlastModelBlockWithPointAndGrade)[1]')
				WHERE ImportSyncRow.ImportSyncRowId = @ImportSyncRowId
			END
		END
		
		IF (@StratNumFound = 1 or @weatheringFound = 1)	--Only do something if there is a reason to do the update. i.e. Strat and/or Weathering need updating
		BEGIN
			PRINT '[BhpbioSummaryEntry]'
			UPDATE [dbo].[BhpbioSummaryEntry]
				SET [dbo].[BhpbioSummaryEntry].StratNum = CASE WHEN @StratNumFound = 0 THEN NULL ELSE Staging.Tmp_StratWeatheringImport.GEOMET_STRATNUM END,
					[dbo].[BhpbioSummaryEntry].Weathering = CASE WHEN @weatheringFound = 0 THEN NULL ELSE Staging.Tmp_StratWeatheringImport.GEOMET_WEATHERING END
			FROM	Staging.Tmp_StratWeatheringImport inner join [dbo].[DigblockLocation]
						ON [dbo].[DigblockLocation].Digblock_Id = Staging.Tmp_StratWeatheringImport.DIGBLOCK_ID AND Location_Type_Id = 7
					INNER JOIN [dbo].[BhpbioSummaryEntry] on [dbo].[BhpbioSummaryEntry].[LocationId] = [dbo].[DigblockLocation].[Location_Id]
					INNER JOIN [dbo].[BhpbioSummaryEntryType] ON [dbo].[BhpbioSummaryEntry].SummaryEntryTypeId = [dbo].[BhpbioSummaryEntryType].[SummaryEntryTypeId] 
						AND [dbo].[BhpbioSummaryEntryType].[AssociatedBlockModelId] is not null
			WHERE	Staging.Tmp_StratWeatheringImport.DIGBLOCK_ID =  @digblockId
		END

	PRINT 'Set Processed = 1'
	Update	Staging.Tmp_StratWeatheringImport
	Set		[PROCESSED] = 1,
			[PROCESSED_DATETIME] = GetDate()
	Where Digblock_Id = @digblockId
	
	COMMIT TRANSACTION


END TRY
BEGIN CATCH
	SET @returnedErrorMessage = ERROR_MESSAGE()
	WHILE (@@TRANCOUNT > 0)
	BEGIN
		ROLLBACK TRANSACTION
	END

	BEGIN TRANSACTION
	Update Staging.Tmp_StratWeatheringImport
	Set [Processed] = 1,
		[PROCESSED_DATETIME] = GetDate(),
		[ERROR_MESSAGE] = [ERROR_MESSAGE] + ', ' + @returnedErrorMessage
	Where Digblock_Id = @digblockId
	COMMIT TRANSACTION

	print @returnedErrorMessage
END CATCH 
		

FETCH NEXT FROM CUR_DIGBLOCKS INTO @digblockId, @stratNum, @weathering, @StratNumFound, @stratNumFoundInXml, @weatheringFound, @weatheringFoundInXml, @ImportSyncRowId

END
CLOSE CUR_DIGBLOCKS;
DEALLOCATE CUR_DIGBLOCKS;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
select	*
FROM	Staging.Tmp_StratWeatheringImport
WHERE	[PROCESSED] = 1

	SELECT	*
	FROM	BhpbioSummaryEntry
	WHERE	StratNum is not null
	or		Weathering is not null

	*/

/*
UPDATE Staging.Tmp_StratWeatheringImport
	SET [PROCESSED] = 0,
		[PROCESSED_DATETIME] = NULL
WHERE	[PROCESSED] = 1

UPDATE	BhpbioSummaryEntry
	SET StratNum = null,
		Weathering = null

*/