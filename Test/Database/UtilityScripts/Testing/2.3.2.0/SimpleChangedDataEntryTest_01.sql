DELETE FROM staging.ChangedDataEntryRelatedKeyValue
DELETE FROM staging.ChangedDataEntry
GO

-- A Simple test...
-- the summarised latest changes are
--  OB18 SP 0599	2015-08-18
--  OB18 SP 0613	2015-08-19
--  OB18 NP 0613	2015-08-20


INSERT INTO staging.ChangedDataEntry
(
	ChangeAppliedDateTime, MessageTimestamp, ChangeTypeId
)
Select '2015-01-16',GetDate(), 'StageBlockModel' Union All
Select '2015-01-17',GetDate(), 'StageBlock' Union All
Select '2015-01-18',GetDate(), 'StageBlock' Union All
Select '2015-01-19',GetDate(), 'StageBlock' Union All
Select '2015-01-20',GetDate(), 'StageBlock'


INSERT INTO staging.ChangedDataEntryRelatedKeyValue
(
	ChangedDataEntryId, ChangeKey, TextValue	
)
Select Id, 'Site','OB18' From staging.ChangedDataEntry where ChangeTypeId = 'StageBlockModel' and ChangeAppliedDateTime = '2015-01-16' union ALL
Select Id,'Pit', 'SP' From staging.ChangedDataEntry where ChangeTypeId = 'StageBlockModel' and ChangeAppliedDateTime = '2015-01-16' union ALL
Select Id , 'Bench','0599' From staging.ChangedDataEntry where ChangeTypeId = 'StageBlockModel' and ChangeAppliedDateTime = '2015-01-16' union ALL

Select Id, 'Site','OB18' From staging.ChangedDataEntry where ChangeTypeId = 'StageBlock' and ChangeAppliedDateTime = '2015-01-17' union ALL
Select Id,'Pit', 'SP' From staging.ChangedDataEntry where ChangeTypeId = 'StageBlock' and ChangeAppliedDateTime = '2015-01-17' union ALL
Select Id , 'Bench','0599' From staging.ChangedDataEntry where ChangeTypeId = 'StageBlock' and ChangeAppliedDateTime = '2015-01-17' union ALL

Select Id, 'Site','OB18' From staging.ChangedDataEntry where ChangeTypeId = 'StageBlock' and ChangeAppliedDateTime = '2015-01-18' union ALL
Select Id,'Pit', 'SP' From staging.ChangedDataEntry where ChangeTypeId = 'StageBlock' and ChangeAppliedDateTime = '2015-01-18' union ALL
Select Id , 'Bench','0599' From staging.ChangedDataEntry where ChangeTypeId = 'StageBlock' and ChangeAppliedDateTime = '2015-01-18' union ALL

Select Id, 'Site','OB18' From staging.ChangedDataEntry where ChangeTypeId = 'StageBlock' and ChangeAppliedDateTime = '2015-01-19' union ALL
Select Id,'Pit', 'SP' From staging.ChangedDataEntry where ChangeTypeId = 'StageBlock' and ChangeAppliedDateTime = '2015-01-19' union ALL
Select Id , 'Bench','0613' From staging.ChangedDataEntry where ChangeTypeId = 'StageBlock' and ChangeAppliedDateTime = '2015-01-19' union ALL

Select Id, 'Site','OB18' From staging.ChangedDataEntry where ChangeTypeId = 'StageBlock' and ChangeAppliedDateTime = '2015-01-20' union ALL
Select Id,'Pit', 'NP' From staging.ChangedDataEntry where ChangeTypeId = 'StageBlock' and ChangeAppliedDateTime = '2015-01-20' union ALL
Select Id , 'Bench','0613' From staging.ChangedDataEntry where ChangeTypeId = 'StageBlock' and ChangeAppliedDateTime = '2015-01-20'

GO