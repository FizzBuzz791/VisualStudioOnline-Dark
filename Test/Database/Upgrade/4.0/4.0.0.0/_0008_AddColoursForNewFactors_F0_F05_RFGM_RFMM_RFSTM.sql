IF NOT EXISTS (SELECT * FROM BhpbioReportColor WHERE TagId = 'RFGM')
BEGIN
	INSERT INTO BhpbioReportColor(TagId,Description,IsVisible,Color, LineStyle, MarkerShape)
	VALUES ('RFGM','RFGM - Mine Production (Expit) / Geology Model',1,'Moccasin','Dashed','None')
END

IF NOT EXISTS (SELECT * FROM BhpbioReportColor WHERE TagId = 'RFMM')
BEGIN
	INSERT INTO BhpbioReportColor(TagId,Description,IsVisible,Color, LineStyle, MarkerShape)
	VALUES ('RFMM','RFMM - Mine Production (Expit) / Mining Model',1,'Tan','Dashed','None')
END

IF NOT EXISTS (SELECT * FROM BhpbioReportColor WHERE TagId = 'RFSTM')
BEGIN
	INSERT INTO BhpbioReportColor(TagId,Description,IsVisible,Color, LineStyle, MarkerShape)
	VALUES ('RFSTM','RFSTM - Mine Production (Expit) / Short Term Model',1,'Brown','Dashed','None')
END

IF NOT EXISTS (SELECT * FROM BhpbioReportColor WHERE TagId = 'F0Factor')
BEGIN
	INSERT INTO BhpbioReportColor(TagId,Description,IsVisible,Color, LineStyle, MarkerShape)
	VALUES ('F0Factor','F0.0 Factor',1,'DarkOrange','Dashed','None')
END

IF NOT EXISTS (SELECT * FROM BhpbioReportColor WHERE TagId = 'F05Factor')
BEGIN
	INSERT INTO BhpbioReportColor(TagId,Description,IsVisible,Color, LineStyle, MarkerShape)
	VALUES ('F05Factor','F0.5 Factor',1,'Purple','Dashed','None')
END

IF NOT EXISTS (SELECT * FROM BhpbioReportColor WHERE TagId = 'Attribute Ultrafines')
BEGIN
	INSERT INTO BhpbioReportColor(TagId,Description,IsVisible,Color, LineStyle, MarkerShape)
	VALUES ('Attribute Ultrafines','Ultrafines',1,'Blue','Solid','None')
END

UPDATE BhpbioReportColor SET Description = 'RFMMD - Total Hauled /  Mining Model' WHERE TagId = 'RecoveryFactorDensity'