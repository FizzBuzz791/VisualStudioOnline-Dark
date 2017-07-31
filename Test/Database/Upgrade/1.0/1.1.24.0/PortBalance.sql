DELETE FROM dbo.BhpbioPortBalance
GO
EXEC dbo.DbaClearImportData 'PortBalance'
GO

-- set the new absolute minimum date
UPDATE p
SET DefaultParameterValue = '31-MAR-2009'
FROM dbo.ImportParameter AS p
	INNER JOIN dbo.Import AS i
		ON (i.ImportId = p.ImportId)
WHERE i.ImportName = 'PortBalance'
	AND p.ParameterName = 'DateFromAbsoluteMinimum'
GO

-- queue a new import, using the defaults but clearing the lookback so it goes all the way back to the start
DECLARE @ImportId SMALLINT
DECLARE @ImportJobId INT
DECLARE @ImportParameterId INT

SET @ImportId = (SELECT ImportId FROM dbo.Import WHERE ImportName = 'PortBalance')
SET @ImportParameterId = (SELECT ImportParameterId FROM dbo.ImportParameter WHERE ImportId = @ImportId AND ParameterName = 'DateFromLookbackDays')

EXEC dbo.AddImportJob
	@iImportID = @ImportId,
	@iPriority = 1,
	@iImportJobStatusId = 1,
    @oImportJobId = @ImportJobId OUTPUT

EXEC dbo.UpdateImportJobParameter
	@iImportJobId = @ImportJobId,
	@iImportParameterId = @ImportParameterId,
	@iParameterValue = ''
GO
