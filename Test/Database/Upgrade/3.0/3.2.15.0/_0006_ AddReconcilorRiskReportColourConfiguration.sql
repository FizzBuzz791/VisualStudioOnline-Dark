IF NOT EXISTS (SELECT * FROM BhpbioReportColor WHERE TagId = 'BlockedOutRemainGC')
BEGIN
	INSERT INTO BhpbioReportColor(TagId,Description,IsVisible,Color, LineStyle, MarkerShape)
	VALUES ('BlockedOutRemainGC','Blocked Out Remaining GC Inventory',1,'Gold','Solid','None')
END

IF NOT EXISTS (SELECT * FROM BhpbioReportColor WHERE TagId = 'AnnualisedMPR')
BEGIN
	INSERT INTO BhpbioReportColor(TagId,Description,IsVisible,Color, LineStyle, MarkerShape)
	VALUES ('AnnualisedMPR','Annualised Monthly Production Rate',1,'Tan','Solid','None')
END