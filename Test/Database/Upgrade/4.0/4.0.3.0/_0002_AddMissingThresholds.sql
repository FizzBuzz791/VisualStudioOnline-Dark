IF NOT EXISTS (SELECT TOP(1) * FROM BhpbioReportThreshold WHERE FieldId = 10 AND ThresholdTypeId = 'F0Factor') 
    INSERT INTO BhpbioReportThreshold (LocationId, FieldId, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold) 
		VALUES (1,10,'F0Factor',5,10,0)

IF NOT EXISTS (SELECT TOP(1) * FROM BhpbioReportThreshold WHERE FieldId = 10 AND ThresholdTypeId = 'F05Factor') 
    INSERT INTO BhpbioReportThreshold (LocationId, FieldId, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold) 
		VALUES (1,10,'F05Factor',1,3,0)

IF NOT EXISTS (SELECT TOP(1) * FROM BhpbioReportThreshold WHERE FieldId = 10 AND ThresholdTypeId = 'F1Factor') 
    INSERT INTO BhpbioReportThreshold (LocationId, FieldId, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold) 
		VALUES (1,10,'F1Factor',5,10,0)

IF NOT EXISTS (SELECT TOP(1) * FROM BhpbioReportThreshold WHERE FieldId = 10 AND ThresholdTypeId = 'F15Factor') 
    INSERT INTO BhpbioReportThreshold (LocationId, FieldId, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold) 
		VALUES (1,10,'F15Factor',5,10,0)

IF NOT EXISTS (SELECT TOP(1) * FROM BhpbioReportThreshold WHERE FieldId = 10 AND ThresholdTypeId = 'F2Factor') 
    INSERT INTO BhpbioReportThreshold (LocationId, FieldId, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold) 
		VALUES (1,10,'F2Factor',5,10,0)

IF NOT EXISTS (SELECT TOP(1) * FROM BhpbioReportThreshold WHERE FieldId = 10 AND ThresholdTypeId = 'F2DensityFactor') 
    INSERT INTO BhpbioReportThreshold (LocationId, FieldId, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold) 
		VALUES (1,10,'F2DensityFactor',5,10,0)

IF NOT EXISTS (SELECT TOP(1) * FROM BhpbioReportThreshold WHERE FieldId = 10 AND ThresholdTypeId = 'F25Factor') 
    INSERT INTO BhpbioReportThreshold (LocationId, FieldId, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold) 
		VALUES (1,10,'F25Factor',5,10,0)

IF NOT EXISTS (SELECT TOP(1) * FROM BhpbioReportThreshold WHERE FieldId = 10 AND ThresholdTypeId = 'F3Factor') 
    INSERT INTO BhpbioReportThreshold (LocationId, FieldId, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold) 
		VALUES (1,10,'F3Factor',5,10,0)

IF NOT EXISTS (SELECT TOP(1) * FROM BhpbioReportThreshold WHERE FieldId = 10 AND ThresholdTypeId = 'GeometFactors') 
    INSERT INTO BhpbioReportThreshold (LocationId, FieldId, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold) 
		VALUES (1,10,'GeometFactors',5,10,0)

IF NOT EXISTS (SELECT TOP(1) * FROM BhpbioReportThreshold WHERE FieldId = 10 AND ThresholdTypeId = 'GraphThreshold') 
    INSERT INTO BhpbioReportThreshold (LocationId, FieldId, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold) 
		VALUES (1,10,'GraphThreshold',0.9,1.1,0)

IF NOT EXISTS (SELECT TOP(1) * FROM BhpbioReportThreshold WHERE FieldId = 10 AND ThresholdTypeId = 'LiveVsSummaryProportionDiff') 
    INSERT INTO BhpbioReportThreshold (LocationId, FieldId, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold) 
		VALUES (1,10,'LiveVsSummaryProportionDiff',0.05,0.1,0)

IF NOT EXISTS (SELECT TOP(1) * FROM BhpbioReportThreshold WHERE FieldId = 10 AND ThresholdTypeId = 'RecoveryFactorDensity') 
    INSERT INTO BhpbioReportThreshold (LocationId, FieldId, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold) 
		VALUES (1,10,'RecoveryFactorDensity',5,10,0)

IF NOT EXISTS (SELECT TOP(1) * FROM BhpbioReportThreshold WHERE FieldId = 10 AND ThresholdTypeId = 'RecoveryFactorMoisture') 
    INSERT INTO BhpbioReportThreshold (LocationId, FieldId, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold) 
		VALUES (1,10,'RecoveryFactorMoisture',5,10,0)

IF NOT EXISTS (SELECT TOP(1) * FROM BhpbioReportThreshold WHERE FieldId = 10 AND ThresholdTypeId = 'RFGM') 
    INSERT INTO BhpbioReportThreshold (LocationId, FieldId, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold) 
		VALUES (1,10,'RFGM',5,10,0)

IF NOT EXISTS (SELECT TOP(1) * FROM BhpbioReportThreshold WHERE FieldId = 10 AND ThresholdTypeId = 'RFMM') 
    INSERT INTO BhpbioReportThreshold (LocationId, FieldId, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold) 
		VALUES (1,10,'RFMM',5,10,0)

IF NOT EXISTS (SELECT TOP(1) * FROM BhpbioReportThreshold WHERE FieldId = 10 AND ThresholdTypeId = 'RFSTM') 
    INSERT INTO BhpbioReportThreshold (LocationId, FieldId, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold) 
		VALUES (1,10,'RFSTM',5,10,0)