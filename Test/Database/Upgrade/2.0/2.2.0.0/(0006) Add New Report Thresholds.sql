
-- COPY THE LOI Threshold to H2O, H2O-As-Dropped, H2O-As-Shipped and Density WHERE not already exists
INSERT INTO dbo.BhpbioReportThreshold (LocationId, FieldId, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold)
SELECT brt.LocationId, g.Grade_Id, brt.ThresholdTypeId, brt.LowThreshold, brt.HighThreshold, brt.AbsoluteThreshold
FROM  BhpbioReportThreshold brt
	INNER JOIN (SELECT Grade_Id FROM Grade WHERE Grade_Name IN ('Density','H2O', 'H2O-As-Dropped', 'H2O-As-Shipped')) as g ON brt.FieldId = 5
WHERE NOT EXISTS ( 
		SELECT 1 FROM BhpbioReportThreshold  brtex 
		WHERE brtex.LocationId = brt.LocationId AND brtex.FieldId = g.Grade_Id and brtex.ThresholdTypeId = brt.ThresholdTypeId)
Go
		
-- COPY THE Tonnes Threshold to Volume WHERE not already exists
INSERT INTO dbo.BhpbioReportThreshold (LocationId, FieldId, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold)
SELECT brt.LocationId, -1, brt.ThresholdTypeId, brt.LowThreshold, brt.HighThreshold, brt.AbsoluteThreshold
FROM  BhpbioReportThreshold brt
WHERE brt.FieldId = 0 AND NOT EXISTS ( 
		SELECT 1 FROM BhpbioReportThreshold  brtex 
		WHERE brtex.LocationId = brt.LocationId AND brtex.FieldId = -1 and brtex.ThresholdTypeId = brt.ThresholdTypeId)
Go


-- New threshold types for new factors
Insert Into dbo.BhpbioReportThresholdType (ThresholdTypeId, [Description])
Select 'RecoveryFactorDensity', 'Recovery Factor (Density)' Union All
Select 'F2DensityFactor', 'F2 Density Factor' Union All
Select 'RecoveryFactorMoisture', 'Recovery Factor (H2O)'
Go

-- create some default values for the new threadhold types
Insert Into dbo.BhpbioReportThreshold (LocationId, FieldId, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold)
	Select l.Location_Id, g.Grade_Id, 'RecoveryFactorDensity', 5, 10, 0
	From Location l
	Inner Join Grade g
		On l.Name = 'WAIO' And g.Grade_Name = 'Density'
Union All
	Select l.Location_Id, g.Grade_Id, 'F2DensityFactor', 5, 10, 0
	From Location l
	Inner Join Grade g
		On l.Name = 'WAIO' And g.Grade_Name = 'Density'
Union All
Select l.Location_Id, g.Grade_Id, 'RecoveryFactorMoisture', 5, 10, 0
	From Location l
	Inner Join Grade g
		On l.Name = 'WAIO' And g.Grade_Name = 'H2O'
		
-- we also need thresholds for tonnes and volume on these
Declare @WAIO Int
Declare @TonnesGradeId Int
Declare @VolumeGradeId Int

Select @WAIO = Location_Id from Location where Name = 'WAIO'
Set @TonnesGradeId = 0
Set @VolumeGradeId = -1

Insert Into dbo.BhpbioReportThreshold (LocationId, FieldId, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold)
	Select @WAIO, @TonnesGradeId, 'F2DensityFactor', 5, 10, 0 Union
	Select @WAIO, @VolumeGradeId, 'F2DensityFactor', 5, 10, 0 Union
	Select @WAIO, @TonnesGradeId, 'RecoveryFactorDensity', 5, 10, 0 Union
	Select @WAIO, @VolumeGradeId, 'RecoveryFactorDensity', 5, 10, 0 Union
	Select @WAIO, @TonnesGradeId, 'RecoveryFactorMoisture', 5, 10, 0 Union
	Select @WAIO, @VolumeGradeId, 'RecoveryFactorMoisture', 5, 10, 0
Go