GO

-- Schedule Recon Movements, Met Balancing, Shipping, Port Balance, Port Blending
INSERT INTO ImportAutoQueueProfile (ImportId, FrequencyHours, TimeOfDay, IsActive, Priority)
	SELECT i.ImportId, null, '2015-01-01 20:00:00', 1, 10
	FROM Import i
	WHERE i.ImportName IN ('Recon Movements', 'Met Balancing', 'Shipping', 'PortBalance', 'PortBlending','ReconBlockInsertUpdate')

-- Now schedule site specific imports
INSERT INTO ImportAutoQueueProfile (ImportId, FrequencyHours, TimeOfDay, IsActive, Priority)
	SELECT i.ImportId, null, '2015-01-01 20:00:00', 1,  sites.offset -- temporarily set priority to sites offset to facilitate later join
	FROM Import i
		CROSS JOIN (
			select 'YR' as code, 1 as offset
				union all select 'NM', 2 as offset
				union all select  'YD', 3 as offset
				union all select  'JB', 4 as offset
				union all select  'WB', 5 as offset
				union all select  '18', 6 as offset
				union all select  '25', 7 as offset
				union all select  'NH', 8 as offset
				union all select  'AC', 9 as offset
		) sites
	WHERE i.ImportName IN ('Haulage', 'Production', 'Stockpile Adjustment', 'Stockpile')
		-- excluding some special combinations... 
		AND NOT (sites.Code = 'NH' AND (i.ImportName IN ('Haualge', 'ReconBlockInsertUpdate') ))
GO

-- Schedule The DateTo parameter for all imports that use DateTo
INSERT INTO ImportAutoQueueProfileParameter (ImportAutoQueueProfileId, ImportParameterId, ParameterValue, UseForExistingJobCheck, InsertParameterValueEvenWhenNull)
	SELECT iaq.ImportAutoQueueProfileId, ip.ImportParameterId, '{TODAY}', 0, 0
	FROM Import i
		INNER JOIN ImportAutoQueueProfile iaq ON iaq.ImportId = i.ImportId
		INNER JOIN ImportParameter ip ON ip.ImportId = i.ImportId AND ip.ParameterName = 'DateTo'
	WHERE i.ImportName NOT IN ('Stockpile')

-- Schedule The lookback days for all imports that use dates
INSERT INTO ImportAutoQueueProfileParameter (ImportAutoQueueProfileId, ImportParameterId, ParameterValue, UseForExistingJobCheck, InsertParameterValueEvenWhenNull)
	SELECT iaq.ImportAutoQueueProfileId, ip.ImportParameterId, 
			CASE WHEN i.ImportName IN ('Haulage', 'Production', 'Stockpile Adjustment') THEN '120'
				WHEN i.ImportName IN ('Met Balancing', 'Shipping', 'PortBalance', 'PortBlending') THEN '31'
				WHEN i.ImportName IN ('Recon Movements','ReconBlockInsertUpdate') THEN '3'
				ELSE '31'
			END, 
			0, 0
	FROM Import i
		INNER JOIN ImportAutoQueueProfile iaq ON iaq.ImportId = i.ImportId
		INNER JOIN ImportParameter ip ON ip.ImportId = i.ImportId AND ip.ParameterName = 'DateFromLookbackDays'
	WHERE i.ImportName NOT IN ('Stockpile')

-- Schedule The Site parameter for the site specific imports
INSERT INTO ImportAutoQueueProfileParameter (ImportAutoQueueProfileId, ImportParameterId, ParameterValue, UseForExistingJobCheck, InsertParameterValueEvenWhenNull)
	SELECT iaq.ImportAutoQueueProfileId, ip.ImportParameterId, sites.code, 1, 0
	FROM Import i
		INNER JOIN ImportAutoQueueProfile iaq ON iaq.ImportId = i.ImportId
		INNER JOIN ImportParameter ip ON ip.ImportId = i.ImportId AND ip.ParameterName = 'Site'
		INNER JOIN (
			select 'YR' as code, 1 as offset
				union all select 'NM', 2 as offset
				union all select  'YD', 3 as offset
				union all select  'JB', 4 as offset
				union all select  'WB', 5 as offset
				union all select  '18', 6 as offset
				union all select  '25', 7 as offset
				union all select  'NH', 8 as offset
				union all select  'AC', 9 as offset
		) sites ON sites.offset = iaq.Priority -- the query above set priority = offset to facilitate this join
	WHERE i.ImportName IN ('Haulage', 'Production', 'Stockpile Adjustment', 'Stockpile', 'ReconBlockInsertUpdate')
GO

-- reset the priority codes
UPDATE ImportAutoQueueProfile
SET Priority = 10
WHERE Priority < 10