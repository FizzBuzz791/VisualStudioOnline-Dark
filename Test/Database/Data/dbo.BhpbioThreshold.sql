DECLARE @locationId INTEGER
SELECT @locationId = Location_Id FROM dbo.Location WHERE Name = 'WAIO'

IF NOT @locationId IS NULL
BEGIN
	INSERT INTO dbo.BhpbioReportThreshold
	(
		LocationId,
		FieldId,
		ThresholdTypeId,
		LowThreshold,
		HighThreshold,
		AbsoluteThreshold
	)
	VALUES (@locationId,0,'LiveVsSummaryProportionDiff',0.01,0.05, 0)

	INSERT INTO dbo.BhpbioReportThreshold
	(
		LocationId,
		FieldId,
		ThresholdTypeId,
		LowThreshold,
		HighThreshold,
		AbsoluteThreshold
	)
	SELECT @locationId,g.Grade_Id,'LiveVsSummaryProportionDiff',0.0001,0.0005, 0
	FROM dbo.Grade g
END
GO