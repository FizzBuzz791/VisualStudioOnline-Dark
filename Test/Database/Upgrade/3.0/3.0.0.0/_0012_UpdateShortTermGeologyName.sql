
UPDATE BlockModel 
SET Description = 'Short Term Model' WHERE Description = 'Short Term Geology Model'

UPDATE BlockModel 
SET Description = 'Grade Control with STM' WHERE Description = 'Grade Control with STGM'

UPDATE BhpbioReportColor 
SET [Description] = REPLACE([Description],'STGM', 'STM') 
WHERE Description like '%STGM%'

UPDATE BhpbioReportColor 
SET [Description] = REPLACE([Description],'Short Term Geology Model', 'Short Term Model') 
WHERE Description like '%Short Term Geology Model%'