-- Ensure mapping data existing in StageDataMap table
IF NOT EXISTS (SELECT * FROM Staging.StageDataMap WHERE ContextKey = 'Site' AND [From] = 'OB23/25')
BEGIN
	INSERT INTO Staging.StageDataMap(ContextKey,[From],[To]) VALUES ('Site','OB23/25','Eastern Ridge')
END

-- Update Change Data Register Values using the map
UPDATE v
	SET v.TextValue = m.[To]
FROM  Staging.ChangedDataEntryRelatedKeyValue v
	INNER JOIN Staging.StageDataMap m ON m.ContextKey = v.ChangeKey AND m.[From] = v.TextValue

--
-- This script renames Location OB23/25 to Eastern Ridge
--
UPDATE Location 
Set Name = 'Eastern Ridge', Description = 'Eastern Ridge' 
WHERE Name = 'OB23/25'
GO

-- Update Default Import Parameters
UPDATE ImportParameter 
SET DefaultParameterValue = 'Eastern Ridge'
WHERE DefaultParameterValue = 'OB23/25'
GO

UPDATE ImportParameter 
SET DefaultParameterValue = 'ER'
WHERE DefaultParameterValue = '25'
GO

UPDATE ImportAutoQueueProfileParameter 
SET ParameterValue = 'ER'
WHERE ParameterValue = '25'
GO

UPDATE ImportAutoQueueProfileParameter 
SET ParameterValue = 'OB23/25'
WHERE ParameterValue = 'Eastern Ridge'
GO

-- Update Import Job Parameters
UPDATE ImportJobParameter
SET ParameterValue = 'ER' 
WHERE ParameterValue = '25'

UPDATE ImportJobParameter
SET ParameterValue = 'Eastern Ridge' 
WHERE ParameterValue = 'OB23/25'
