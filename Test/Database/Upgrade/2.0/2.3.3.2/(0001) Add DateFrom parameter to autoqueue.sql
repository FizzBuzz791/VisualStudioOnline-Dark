-------------------------------------------------------------------------------------------------------------------------------------
-- Schedule The DateFrom parameter for all imports that use DateFrom
-- the value is an empty string which mirrors what happens when leaving a parameter blank and scheduling manually
-- all imports with date ranges are queued with a lookback rather than a date from so this parameter can just be blank
INSERT INTO ImportAutoQueueProfileParameter (ImportAutoQueueProfileId, ImportParameterId, ParameterValue, UseForExistingJobCheck, InsertParameterValueEvenWhenNull)
	SELECT iaq.ImportAutoQueueProfileId, ip.ImportParameterId, '', 0, 1		
	FROM Import i
		INNER JOIN ImportAutoQueueProfile iaq ON iaq.ImportId = i.ImportId
		INNER JOIN ImportParameter ip ON ip.ImportId = i.ImportId AND ip.ParameterName = 'DateFrom'
		LEFT JOIN ImportAutoQueueProfileParameter iap ON iap.ImportAutoQueueProfileId  = iaq.ImportAutoQueueProfileId AND iap.ImportParameterId = ip.ImportParameterId
	WHERE iap.ImportAutoQueueProfileId IS NULL -- i.e. where the parameter is not already configured
-------------------------------------------------------------------------------------------------------------------------------------