IF OBJECT_ID('dbo.TmpSampleSourceAltered') IS NULL
BEGIN
	CREATE TABLE dbo.TmpSampleSourceAltered
	(
		Weightometer_Id VARCHAR(31),
		Weightometer_Sample_Id INT,
		Weightometer_Sample_Date DATETIME,
		Original_Sample_Source VARCHAR(1023),
		Target_Sample_Source VARCHAR(1023),
		OriginalSampleTonnes FLOAT
	) 
END
GO

DECLARE @Month DATETIME
DECLARE @Weightometer VARCHAR(31)

DECLARE @OriginalSampleSource VARCHAR(1023)
DECLARE @TargetSampleSource VARCHAR(1023)
DECLARE @ProportionToAlter DECIMAL(10,1)

--------------------------------------------------

--SET @Month = '2014-01-01'
--SET @Weightometer = 'WB-C2OutFlow'

--SET @OriginalSampleSource = 'CRUSHER ACTUALS'
--SET @TargetSampleSource = 'ESTIMATE'
--SET @ProportionToAlter = 1

SET @Month = '2014-01-01'
SET @Weightometer = '18-PostCrusherToTrainRake'

SET @OriginalSampleSource = 'ESTIMATE'
SET @TargetSampleSource = 'PORT ACTUALS'
SET @ProportionToAlter = 0.8

---------------------------------------------------

IF (@ProportionToAlter < 0 OR @ProportionToAlter > 1)
BEGIN
	RAISERROR('Proportion must be between 0 and 1', 16, 1)
END

INSERT INTO TmpSampleSourceAltered
SELECT @Weightometer, ws.Weightometer_Sample_Id, ws.Weightometer_Sample_Date, 
	   @OriginalSampleSource, @TargetSampleSource, wsv.Field_Value
FROM WeightometerSampleNotes wsn
INNER JOIN WeightometerSample ws
	ON wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
LEFT OUTER JOIN WeightometerSampleValue wsv
	ON wsv.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
		AND wsv.Weightometer_Sample_Field_Id = 'SampleTonnes'	
WHERE wsn.Weightometer_Sample_Field_Id = 'SampleSource'
	AND wsn.[Notes] = @OriginalSampleSource
	AND ws.Weightometer_Id = @Weightometer
	AND dbo.GetDateMonth(ws.Weightometer_Sample_Date) = @Month
	
DECLARE @SampleCount INT

SELECT @SampleCount = COUNT(*)
FROM TmpSampleSourceAltered
WHERE Weightometer_Id = @Weightometer
	AND dbo.GetDateMonth(Weightometer_Sample_Date) = @Month
	AND Original_Sample_Source = @OriginalSampleSource
	AND Target_Sample_Source = @TargetSampleSource

SET @SampleCount = @SampleCount * (1.0 - @ProportionToAlter)

DELETE FROM TmpSampleSourceAltered
WHERE Weightometer_Sample_Id IN (
	SELECT TOP (@SampleCount) Weightometer_Sample_Id
	FROM TmpSampleSourceAltered
	WHERE Weightometer_Id = @Weightometer
		AND dbo.GetDateMonth(Weightometer_Sample_Date) = @Month
		AND Original_Sample_Source = @OriginalSampleSource
		AND Target_Sample_Source = @TargetSampleSource
)

SELECT * FROM TmpSampleSourceAltered

UPDATE WeightometerSampleNotes
SET [Notes] = @TargetSampleSource
WHERE Weightometer_Sample_Id IN (
	SELECT Weightometer_Sample_Id
	FROM TmpSampleSourceAltered
	WHERE Weightometer_Id = @Weightometer
		AND Original_Sample_Source = @OriginalSampleSource
)
AND Weightometer_Sample_Field_Id = 'SampleSource'
AND [Notes] = @OriginalSampleSource


IF @OriginalSampleSource = 'ESTIMATE' 
	AND @TargetSampleSource IN ('CRUSHER ACTUALS', 'PORT ACTUALS')
BEGIN

	 --If the source is changing from estimate to actual, copy the tonnes to sampletonnes
	UPDATE WeightometerSampleValue
	SET Field_Value = w.Tonnes
	FROM (
		SELECT t.Weightometer_Sample_Id SampleId, ws.Tonnes
		FROM TmpSampleSourceAltered t
		INNER JOIN WeightometerSample ws
			ON ws.Weightometer_Sample_Id = t.Weightometer_Sample_Id
	) w
	WHERE WeightometerSampleValue.Weightometer_Sample_Id = w.SampleId
		AND WeightometerSampleValue.Weightometer_Sample_Field_Id = 'SampleTonnes'
		AND WeightometerSampleValue.Field_Value = 0
END

