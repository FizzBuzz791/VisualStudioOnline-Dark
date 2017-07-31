IF OBJECT_ID('dbo.TmpSampleSourceAltered') IS NOT NULL
BEGIN

	UPDATE WeightometerSampleNotes
	SET [Notes] = t.Original_Sample_Source
	FROM (
		SELECT Weightometer_Sample_Id, Original_Sample_Source, Target_Sample_Source
		FROM TmpSampleSourceAltered	
	) t
	WHERE WeightometerSampleNotes.Weightometer_Sample_Id = t.Weightometer_Sample_Id
		AND WeightometerSampleNotes.Weightometer_Sample_Field_Id = 'SampleSource'
		AND WeightometerSampleNotes.[Notes] = t.Target_Sample_Source

	 --If the source is changing from estimate to actual, copy the tonnes to sampletonnes
	UPDATE WeightometerSampleValue
	SET Field_Value = w.OriginalSampleTonnes
	FROM (
		SELECT t.Weightometer_Sample_Id SampleId, t.OriginalSampleTonnes
		FROM TmpSampleSourceAltered t
		WHERE t.OriginalSampleTonnes IS NOT NULL
	) w
	WHERE WeightometerSampleValue.Weightometer_Sample_Id = w.SampleId
		AND WeightometerSampleValue.Weightometer_Sample_Field_Id = 'SampleTonnes'
	
	DROP TABLE dbo.TmpSampleSourceAltered

END
