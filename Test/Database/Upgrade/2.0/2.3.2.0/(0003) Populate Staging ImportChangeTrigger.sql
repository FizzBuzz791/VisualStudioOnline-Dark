INSERT INTO staging.ImportChangeTrigger
(
	ImportType, ChangeTypeId, DateFromParameterName, DateToParameterName, LookbackPeriodParameterName, LookbackPeriodUnits, IsActive
)
Select 'Blocks','StageBlockModel',NULL,NULL,NULL,NULL,1
Union All
Select 'Blocks','StageBlock',NULL,NULL,NULL,NULL,1
Go

INSERT INTO Staging.ImportChangeTriggerRelatedKeyValueMapping
(
	ImportChangeTriggerId, ChangeKey, ImportJobParameterName, SpecificMappingOperation
)
Select Id, k.ChangeKey, k.ChangeKey, NULL
From staging.ImportChangeTrigger t, Staging.ChangeKey k
Where ImportType = 'Blocks'
	and k.ChangeKey in ('Site','Pit','Bench')
Go
