 IF OBJECT_ID('dbo.GetBhpbioImportsRunningQueuedCount') IS NOT NULL 
     DROP PROCEDURE dbo.GetBhpbioImportsRunningQueuedCount 
GO 
  
CREATE PROCEDURE dbo.GetBhpbioImportsRunningQueuedCount 
( 
    @oNumImportsRunning INT OUTPUT
) 
WITH ENCRYPTION 
AS
BEGIN 
    SET NOCOUNT ON 
  
    SELECT @oNumImportsRunning = Count(*)
	FROM dbo.ImportJob AS J
		INNER JOIN dbo.ImportJobStatus AS S
			ON (J.ImportJobStatusId = S.ImportJobStatusId)
	WHERE S.ImportJobStatusName In ('RUNNING', 'QUEUED')
END 
GO 
GRANT EXECUTE ON dbo.GetBhpbioImportsRunningQueuedCount TO CommonImportManager

/*
<TAG Name="Data Dictionary" ProcedureName="GetBhpbioImportsRunningQueuedCount">
 <Procedure>
	Outputs the number of imports running against the system
 </Procedure>
</TAG>
*/	
