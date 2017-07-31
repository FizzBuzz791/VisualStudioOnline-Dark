ALTER TABLE Staging.StageBlockModel
 ADD [LumpPercentAsDropped] [decimal](7, 4) NULL
GO

ALTER TABLE Staging.StageBlockModel
 ADD  [LumpPercentAsShipped] [decimal](7, 4) NULL
GO

UPDATE Staging.StageBlockModel SET [LumpPercentAsShipped] = [LumpPercent]
GO

ALTER TABLE Staging.StageBlockModel
 DROP COLUMN [LumpPercent]
GO
