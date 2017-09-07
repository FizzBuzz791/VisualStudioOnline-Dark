declare @digblockId varchar(31)
declare @stratNum varchar(7)
declare @weathering int
declare @digblockFound bit
declare @StratNumFound bit
declare @weatheringFound bit
declare @stratNumFoundInXml bit
declare @weatheringFoundInXml bit
declare @ERROR_MSG varchar(max)


	DECLARE  CUR_DIGBLOCKS CURSOR  FOR
	SELECT	TOP 5 [DIGBLOCK_ID],
			[GEOMET_WEATHERING],
			[GEOMET_STRATNUM],
			[DIGBLOCK_FOUND],
			[STRATNUM_FOUND],
			[WEATHERING_FOUND]
	FROM	Staging.Tmp_StratWeatheringImport
	WHERE	[PROCESSED] = 0

	OPEN CUR_DIGBLOCKS;

	FETCH NEXT FROM CUR_DIGBLOCKS INTO @digblockId, @stratNum, @weathering, @digblockFound, @StratNumFound, @weatheringFound
	WHILE @@FETCH_STATUS = 0  
	BEGIN 
		PRINT @digblockId
		BEGIN TRY
			BEGIN TRANSACTION

			IF (@digblockFound = 1) 
			BEGIN
				

				IF @StratNumFound = 1 
				BEGIN
					PRINT 'Do Stratigraphy'
				END

				IF @weatheringFound = 1 
				BEGIN
					PRINT 'Do Weathering'
				END
			END

--		UPDATE [dbo].[BhpbioSummaryEntry]
--			SET [dbo].[BhpbioSummaryEntry].StratNum = #StratWeatheringImportFile.GEOMET_STRATNUM,
--				[dbo].[BhpbioSummaryEntry].Weathering = #StratWeatheringImportFile.GEOMET_WEATHERING
--		FROM	#StratWeatheringImportFile
--		WHERE	exists (select	1
--						from	[dbo].[BhpbioSummaryEntryType]
--						where	[dbo].[BhpbioSummaryEntryType].[AssociatedBlockModelId] is not null
--						and		[dbo].[BhpbioSummaryEntry].SummaryEntryTypeId = [dbo].[BhpbioSummaryEntryType].[SummaryEntryTypeId])
--		and		exists	(select 1
--						from	[dbo].[DigblockLocation] 
--						WHERE	[dbo].[DigblockLocation].Digblock_Id = #StratWeatheringImportFile.DIGBLOCK_ID
--						AND		Location_Type_Id = 7
--						AND		[dbo].[BhpbioSummaryEntry].[LocationId] = [dbo].[DigblockLocation].[Location_Id] )

		Update	Staging.Tmp_StratWeatheringImport
		Set		[PROCESSED] = 1,
				[PROCESSED_DATETIME] = GetDate()
		Where Digblock_Id = @digblockId
	
		COMMIT TRANSACTION


	END TRY
	BEGIN CATCH
		WHILE (@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK TRANSACTION
		END

		Update Staging.Tmp_StratWeatheringImport
		Set [Processed] = 1,
			[PROCESSED_DATETIME] = GetDate(),
			[ERROR_MESSAGE] = [ERROR_MESSAGE] + ', ' + ERROR_MESSAGE()
		Where Digblock_Id = @digblockId

		print ERROR_MESSAGE()
	END CATCH 
		

		FETCH NEXT FROM CUR_DIGBLOCKS INTO @digblockId, @stratNum, @weathering, @digblockFound, @StratNumFound, @weatheringFound
	END
	CLOSE CUR_DIGBLOCKS;
	DEALLOCATE CUR_DIGBLOCKS;



select	*
FROM	Staging.Tmp_StratWeatheringImport
WHERE	[PROCESSED] = 1

--	SELECT	*
--	FROM	BhpbioSummaryEntry
--	WHERE	StratNum is not null
--	or		Weathering is not null

/*
UPDATE Staging.Tmp_StratWeatheringImport
	SET [PROCESSED] = 0,
		[PROCESSED_DATETIME] = NULL
WHERE	[PROCESSED] = 1
*/