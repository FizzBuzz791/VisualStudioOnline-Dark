DECLARE @jobId INT
DECLARE @getJobId CURSOR

SET @getJobId = CURSOR FOR
	SELECT DISTINCT LastProcessImportJobId FROM ImportSyncQueue WHERE ImportId = 1

OPEN @getJobId
FETCH NEXT
FROM @getJobId INTO @jobId
WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC dbo.BhpbioUpdateImportSyncRowFilterData @jobId
	FETCH NEXT
	FROM @getJobId INTO @jobId
END

CLOSE @getJobId
DEALLOCATE @getJobId