SET NOCOUNT ON

DECLARE @rowId int
DECLARE @errorMessage nvarchar(max)
DECLARE @message nvarchar(max)
DECLARE @processed tinyint

DECLARE @resouceClassification TABLE
(
	[StageBlockModel_BlockModelId] [int] NOT NULL,
	[BlockFullName] [varchar](50) NULL,
	[BlockModelName] [varchar](32) NULL,
	[MaterialTypeId] [int] NULL,
	[ResourceClassification] [varchar](31) NOT NULL,
	[Percentage] [float] NOT NULL
)

DECLARE @modelBlockPartialValue TABLE
(
	[Model_Block_Id] [int] NOT NULL,
	[Sequence_No] [int] NOT NULL,
	[Model_Block_Partial_Field_Id] [varchar](31) NOT NULL,
	[Field_Value] [float] NOT NULL,
	[Test_Model_Block_Partial_Field_Id] [varchar](31) NULL
)

DECLARE @modelBlockLocation TABLE
(
	[Location_Id] [int] NOT NULL
)

WHILE (EXISTS (SELECT 1 FROM [Staging].[ResourceClassificationTempWithMaterialType] WHERE [Processed] = 0))
BEGIN
	SET @rowId = (SELECT MIN([NewRowId]) FROM [Staging].[ResourceClassificationTempWithMaterialType] WHERE [Processed] = 0)

	BEGIN TRANSACTION

	BEGIN TRY
		DELETE FROM @resouceClassification
		DELETE FROM @modelBlockPartialValue

		INSERT INTO @resouceClassification
			SELECT [StageBlockModel_BlockModelId], [BlockFullName], BlockModelName, [MaterialTypeId], 'ResourceClassification1', ResourceClassification1
			FROM [Staging].[ResourceClassificationTempWithMaterialType]
			WHERE [NewRowId] = @rowId
				AND ResourceClassification1 IS NOT NULL
			UNION
			SELECT [StageBlockModel_BlockModelId], [BlockFullName], BlockModelName, [MaterialTypeId], 'ResourceClassification2', ResourceClassification2
			FROM [Staging].[ResourceClassificationTempWithMaterialType]
			WHERE [NewRowId] = @rowId
				AND ResourceClassification2 IS NOT NULL
			UNION
			SELECT [StageBlockModel_BlockModelId], [BlockFullName], BlockModelName, [MaterialTypeId], 'ResourceClassification3', ResourceClassification3
			FROM [Staging].[ResourceClassificationTempWithMaterialType]
			WHERE [NewRowId] = @rowId
				AND ResourceClassification3 IS NOT NULL
			UNION
			SELECT [StageBlockModel_BlockModelId], [BlockFullName], BlockModelName, [MaterialTypeId], 'ResourceClassification4', ResourceClassification4
			FROM [Staging].[ResourceClassificationTempWithMaterialType]
			WHERE [NewRowId] = @rowId
				AND ResourceClassification4 IS NOT NULL
			UNION
			SELECT [StageBlockModel_BlockModelId], [BlockFullName], BlockModelName, [MaterialTypeId], 'ResourceClassification5', ResourceClassification5
			FROM [Staging].[ResourceClassificationTempWithMaterialType]
			WHERE [NewRowId] = @rowId
				AND ResourceClassification5 IS NOT NULL

		-- Only insert missing values
		INSERT INTO [Staging].[StageBlockModelResourceClassification]([BlockModelId], [ResourceClassification], [Percentage])
			SELECT 
				rc.[StageBlockModel_BlockModelId],
				rc.[ResourceClassification], 
				rc.[Percentage]
			FROM @resouceClassification AS rc
				LEFT OUTER JOIN [Staging].[StageBlockModelResourceClassification] AS src
					ON rc.[StageBlockModel_BlockModelId] = src.[BlockModelId]
					AND rc.[ResourceClassification] = src.[ResourceClassification]
			WHERE src.[BlockModelResourceClassificationId] IS NULL

		INSERT INTO @modelBlockPartialValue
			SELECT 
				mbp.[Model_Block_Id],
				mbp.[Sequence_No], 
				t.[ResourceClassification], 
				t.[Percentage], 
				mbpv.[Model_Block_Partial_Field_Id]
			FROM @resouceClassification AS t
				INNER JOIN BlockModel as bm
					ON bm.Name = t.BlockModelName
				INNER JOIN [dbo].[DigblockModelBlock] AS dmb
					ON t.[BlockFullName] = dmb.[Digblock_id]
				INNER JOIN ModelBlock mb
					ON mb.Model_Block_Id = dmb.Model_Block_Id
						AND mb.Block_Model_Id = bm.Block_Model_Id
				INNER JOIN [dbo].[ModelBlockPartial] AS mbp
					ON dmb.[Model_Block_Id] = mbp.[Model_Block_Id]
					AND t.[MaterialTypeId] = mbp.[Material_Type_Id]
				LEFT OUTER JOIN [dbo].[ModelBlockPartialValue] AS mbpv
					ON mbp.[Model_Block_Id] = mbpv.[Model_Block_Id]
					AND mbp.[Sequence_No] = mbpv.[Sequence_No]
					AND t.[ResourceClassification] = mbpv.[Model_Block_Partial_Field_Id]

		IF (NOT EXISTS (SELECT 1 FROM @modelBlockPartialValue WHERE [Test_Model_Block_Partial_Field_Id] IS NULL))
		BEGIN
			SET @processed = 2
			SET @message = 'Skipped - All Model Block Partial data previously loaded'
		END
		ELSE IF (NOT EXISTS (SELECT 1 FROM @modelBlockPartialValue WHERE [Test_Model_Block_Partial_Field_Id] IS NOT NULL))
		BEGIN
			-- no previous data exists
			SET @processed = 1
			SET @message = NULL
		END
		ELSE
		BEGIN
			SET @processed = 3
			SET @message = 'Partial Load - Some Model Block Partial data previously loaded'
		END

		INSERT INTO @modelBlockLocation
			SELECT DISTINCT mbl.[Location_Id]
			FROM @modelBlockPartialValue AS mbpv
				INNER JOIN [ModelBlockLocation] AS mbl
					ON mbpv.[Model_Block_Id] = mbl.[Model_Block_Id]
			WHERE NOT mbl.[Location_Id] IN (SELECT [Location_Id] FROM @modelBlockLocation)

		INSERT INTO [dbo].[ModelBlockPartialValue]([Model_Block_Id], [Sequence_No], [Model_Block_Partial_Field_Id], [Field_Value])
			SELECT [Model_Block_Id], [Sequence_No], [Model_Block_Partial_Field_Id], [Field_Value]
			FROM @modelBlockPartialValue
			WHERE [Test_Model_Block_Partial_Field_Id] IS NULL
		
		-- now we loop through the location ids and update the summary tables. I actually think there
		-- will only every be a single location in this loop, but I'm not 100% sure, so have left this
		-- loop in after refactoring
		WHILE (EXISTS (SELECT 1 FROM @modelBlockLocation))
		BEGIN
			DECLARE @modelBlockLocationId int
			SET @modelBlockLocationId = (SELECT TOP 1 [Location_Id] FROM @modelBlockLocation)

			DELETE FROM @modelBlockLocation
			WHERE [Location_Id] = @modelBlockLocationId

			-- Delete any pre-existing resource classification percentage data
			DELETE bsefv
			FROM dbo.BhpbioSummaryEntry bse
				INNER JOIN BhpbioSummaryEntryField f 
					ON f.[ContextKey] = 'ResourceClassification'
				INNER JOIN dbo.BhpbioSummaryEntryFieldValue bsefv 
					ON bsefv.SummaryEntryId = bse.SummaryEntryId
					AND bsefv.SummaryEntryFieldId = f.SummaryEntryFieldId
			WHERE bse.LocationId = @modelBlockLocationId
	
			-- Insert the resource classification percentage data
			INSERT INTO dbo.BhpbioSummaryEntryFieldValue(SummaryEntryFieldId, SummaryEntryId, Value)
				SELECT
					sf.SummaryEntryFieldId, 
					se.SummaryEntryId, 
					mbpv.Field_Value
				FROM BhpbioSummary s
					inner join BhpbioSummaryEntry se
						on se.SummaryId = s.SummaryId
					inner join bhpbiosummaryentryType st
						on st.SummaryEntryTypeId = se.SummaryEntryTypeId
					inner join BlockModel bm
						on bm.Block_Model_Id = st.AssociatedBlockModelId
					inner join ModelBlockLocation mbl
							on mbl.Location_Id = se.LocationId
					inner join ModelBlock mb
						on mb.Model_Block_Id = mbl.Model_Block_Id
							and mb.Block_Model_Id = bm.Block_Model_Id
					inner join DigblockModelBlock dbm
						on dbm.Model_Block_Id = mb.Model_Block_Id
					inner join dbo.BhpbioSummaryEntryField sf
						on sf.ContextKey = 'ResourceClassification'
					inner join ModelBlockPartial mbp 
						on mbp.Model_Block_Id = mb.Model_Block_Id
							and mbp.Material_Type_Id = se.MaterialTypeId
					inner join ModelBlockPartialValue mbpv
						on mbpv.Model_Block_Partial_Field_Id = sf.Name
							and mbpv.Model_Block_Id = mbp.Model_Block_Id
							and mbpv.Sequence_No = mbp.Sequence_No
					left join BhpbioSummaryEntryFieldValue sfv
						on sfv.SummaryEntryFieldId = sf.SummaryEntryFieldId
							and sfv.SummaryEntryId = se.SummaryEntryId
				WHERE st.Name like '%ModelMovement'
					and mbl.Location_Id = @modelBlockLocationId
					and sfv.Value is null
				ORDER BY s.SummaryMonth, bm.Block_Model_Id, se.MaterialTypeId, sf.Name
		END

		UPDATE [Staging].[ResourceClassificationTempWithMaterialType] SET
			[Processed] = @processed,
			[Message] = @message
		WHERE [NewRowId] = @rowId
		
		print convert(varchar, @rowId) + ' processed'

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		SELECT @errorMessage = ERROR_MESSAGE()

		ROLLBACK TRANSACTION

		UPDATE [Staging].[ResourceClassificationTempWithMaterialType] SET
			[Processed] = 4,
			[Message] = 'An error occurred: ' + @errorMessage
		WHERE [NewRowId] = @rowId
	END CATCH
END





--SELECT *
--FROM [Staging].[ResourceClassificationTemp]
--WHERE [Processed] != 0

--SELECT *
--FROM [Staging].[ResourceClassificationTempWithMaterialType]