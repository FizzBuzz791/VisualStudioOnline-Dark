IF OBJECT_ID('dbo.GetBhpbioBlockImportSyncRowsForLocation') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioBlockImportSyncRowsForLocation
GO

CREATE PROCEDURE dbo.GetBhpbioBlockImportSyncRowsForLocation
(
	@iImportId SMALLINT,
	@iIsCurrent BIT,
	@iSite VARCHAR(31),
	@iPit VARCHAR(31),
	@iBench VARCHAR(31)
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON
    
    SELECT ImportSyncRowId,	ImportId, ImportSyncTableId, IsCurrent,
		SourceRow, DestinationRow,
		IsUpdated, IsDeleted, PreviousImportSyncRowId, RootImportSyncRowId
	FROM dbo.ImportSyncRow
	WHERE ImportId = @iImportId
		AND IsCurrent = @iIsCurrent
		AND (IsNull(@iSite,'') = '' OR SourceRow.value('/BlockModelSource[1]/*[1]/Site[1]','varchar(255)') = @iSite)
		AND (IsNull(@iPit,'') = '' OR SourceRow.value('/BlockModelSource[1]/*[1]/Pit[1]','varchar(255)') = @iPit)
		AND (IsNull(@iBench,'') = '' OR SourceRow.value('/BlockModelSource[1]/*[1]/Bench[1]','varchar(255)') = @iBench)
END
GO
	
GRANT EXECUTE ON dbo.GetBhpbioBlockImportSyncRowsForLocation TO CommonImportManager
GO




