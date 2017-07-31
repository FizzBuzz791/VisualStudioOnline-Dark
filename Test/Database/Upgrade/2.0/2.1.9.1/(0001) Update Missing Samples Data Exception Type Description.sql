
UPDATE [DataExceptionType]
SET [Description] = 'Movements exist for a crusher or other source for which there are no sample results in the movement period'
WHERE [Name] = 'No sample information over a 24-hour period'

