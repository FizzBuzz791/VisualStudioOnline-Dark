Update Import
Set IsActive = 0
Where ImportName = 'BlockInsertUpdate'

Update Import
Set IsActive = 0
Where ImportName = 'BlockDelete'

UPDATE ij
	SET ImportJobStatusId = (SELECT ijs2.ImportJobStatusId FROM ImportJobStatus ijs2 WHERE ijs2.ImportJobStatusName = 'KILLED')
FROM ImportJob ij
WHERE ij.ImportId IN (SELECT i.ImportId FROM Import i WHERE i.ImportName IN ('BlockInsertUpdate', 'BlockDelete'))
	AND ij.ImportJobStatusId IN (SELECT ijs.ImportJobStatusId FROM ImportJobStatus ijs WHERE ijs.ImportJobStatusName IN ('QUEUED', 'PENDING'))
