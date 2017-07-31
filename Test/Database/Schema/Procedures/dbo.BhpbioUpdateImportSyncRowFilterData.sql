IF OBJECT_ID('dbo.BhpbioUpdateImportSyncRowFilterData') IS NOT NULL
     DROP PROCEDURE dbo.BhpbioUpdateImportSyncRowFilterData
GO 

CREATE PROCEDURE dbo.BhpbioUpdateImportSyncRowFilterData
(
	@iImportJobId INT
)
AS
BEGIN
	INSERT INTO BhpbioImportSyncRowFilterData
	SELECT ISR.ImportSyncRowId, 
		LHub.Name AS Hub, 
		LSite.Name AS Site,
		ISR.SourceRow.value('(/BlockModelSource/BlastModelBlockWithPointAndGrade/Pit/text())[1]','VARCHAR(31)') AS Pit,
		ISR.SourceRow.value('(/BlockModelSource/BlastModelBlockWithPointAndGrade/Bench/text())[1]','VARCHAR(31)') AS Bench,
		ISR.SourceRow.value('(/BlockModelSource/BlastModelBlockWithPointAndGrade/PatternNumber/text())[1]','VARCHAR(31)') AS PatternNumber,
		ISR.SourceRow.value('(/BlockModelSource/BlastModelBlockWithPointAndGrade/BlockName/text())[1]','VARCHAR(31)') AS BlockName,
		NULL AS TransactionMonth
	FROM ImportSyncQueue ISQ
	INNER JOIN ImportSyncRow ISR ON ISR.ImportSyncRowId = ISQ.ImportSyncQueueId
	LEFT JOIN BhpbioImportSyncRowFilterData FD ON FD.ImportSyncRowId = ISR.ImportSyncRowId
	LEFT JOIN Location LSite ON (LSite.Name = ISR.SourceRow.value('(/BlockModelSource/BlastModelBlockWithPointAndGrade/Site/text())[1]','VARCHAR(31)') AND LSite.Location_Type_Id = 3)
								OR (LSite.Name = 'Eastern Ridge' AND ISR.SourceRow.value('(/BlockModelSource/BlastModelBlockWithPointAndGrade/Site/text())[1]','VARCHAR(31)') = 'OB23/25')
	LEFT JOIN Location LHub ON LHub.Location_Id = LSite.Parent_Location_Id
	WHERE ISQ.LastProcessImportJobId = @iImportJobId
		AND ISR.ImportId = 1
		AND FD.ImportSyncRowId IS NULL -- i.e. haven't processed this row yet.
END
GO

GRANT EXECUTE ON dbo.BhpbioUpdateImportSyncRowFilterData TO CommonImportManager
GO