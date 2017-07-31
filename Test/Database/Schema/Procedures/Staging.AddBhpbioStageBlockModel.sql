IF OBJECT_ID('Staging.AddBhpbioStageBlockModel') IS NOT NULL
     DROP PROCEDURE Staging.AddBhpbioStageBlockModel
GO 
  
CREATE PROCEDURE Staging.AddBhpbioStageBlockModel
(
	@iBlockId INTEGER,
	@iModelName VARCHAR(31),
	@iMaterialTypeName VARCHAR(31),
	@iVolume FLOAT,
	@iTonnes FLOAT,
	@iDensity FLOAT,
	@iLastModifiedUsername VARCHAR(50),
	@iLastModifiedDateTime DATETIME,
	@iLumpPercentAsDropped DECIMAL(7,4),
	@iLumpPercentAsShipped DECIMAL(7,4),
	@iModelFilename VARCHAR(200),
	@oModelBlockId INTEGER OUT
)
WITH ENCRYPTION
AS
BEGIN 
	
	SET NOCOUNT ON 

	BEGIN TRY
		-- add the Block Point
		INSERT INTO Staging.StageBlockModel
			(BlockId, BlockModelName, MaterialTypeName, OpeningVolume, OpeningTonnes, OpeningDensity, LastModifiedUser, LastModifiedDate, ModelFilename, LumpPercentAsDropped, LumpPercentAsShipped)
		VALUES(@iBlockId, @iModelName, @iMaterialTypeName, @iVolume, @iTonnes, @iDensity, @iLastModifiedUsername, @iLastModifiedDateTime, @iModelFilename, @iLumpPercentAsDropped, @iLumpPercentAsShipped)
		
		SET @oModelBlockId = Scope_Identity()

		DECLARE @ChangedDataEntryId INTEGER
		
		--Change Logging
		INSERT INTO Staging.ChangedDataEntry
		SELECT GETDATE(), GETDATE(),'StageBlockModel'

		SET @ChangedDataEntryId = Scope_Identity()

		INSERT INTO Staging.ChangedDataEntryRelatedKeyValue
		SELECT @ChangedDataEntryId, 'BlockFullName', BlockFullName
		FROM Staging.StageBlock
		WHERE BlockId = @iBlockId
		UNION ALL
		SELECT @ChangedDataEntryId, 'Site', CASE WHEN m.ContextKey IS NULL THEN b.[Site] ELSE m.[To] END
		FROM Staging.StageBlock b
			LEFT JOIN Staging.StageDataMap m ON m.ContextKey = 'Site' AND m.[From] = b.[Site]
		WHERE b.BlockId = @iBlockId
		UNION ALL
		SELECT @ChangedDataEntryId, 'Pit', IsNull([AlternativePitCode], [Pit])
		FROM Staging.StageBlock
		WHERE BlockId = @iBlockId
		UNION ALL
		SELECT @ChangedDataEntryId, 'Bench', Bench
		FROM Staging.StageBlock
		WHERE BlockId = @iBlockId
		UNION ALL
		SELECT @ChangedDataEntryId, 'BlockModelName', @iModelName

	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON Staging.AddBhpbioStageBlockModel TO BhpbioGenericManager
GO