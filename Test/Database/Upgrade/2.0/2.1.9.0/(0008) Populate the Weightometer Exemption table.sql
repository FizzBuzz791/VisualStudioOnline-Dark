IF OBJECT_ID('dbo.BhpbioWeightometerDataExceptionExemption') IS NULL
BEGIN

CREATE TABLE dbo.BhpbioWeightometerDataExceptionExemption
(
	Data_Exception_Type_Id INT NOT NULL,
	Weightometer_Id VARCHAR(31) COLLATE DATABASE_DEFAULT NOT NULL,
	[Start_Date] DATETIME NOT NULL,
	End_Date DATETIME NULL

	CONSTRAINT PK_BhpbioWeightometerDataExceptionExemption
		PRIMARY KEY (Data_Exception_Type_Id, Weightometer_Id),
		
	CONSTRAINT FK_PK_BhpbioWeightometerDataExceptionExemption_DataExceptionType
		FOREIGN KEY (Data_Exception_Type_Id)
		REFERENCES dbo.DataExceptionType (Data_Exception_Type_Id),
		
	CONSTRAINT FK_PK_BhpbioWeightometerDataExceptionExemption_Weightometer
		FOREIGN KEY (Weightometer_Id)
		REFERENCES dbo.Weightometer (Weightometer_Id)		
)
END

GO

DECLARE @DataExceptionTypeId_MissingSamples INT

SELECT @DataExceptionTypeId_MissingSamples = Data_Exception_Type_Id
FROM [DataExceptionType]
WHERE [Name] = 'No sample information over a 24-hour period'

IF @DataExceptionTypeId_MissingSamples IS NOT NULL
BEGIN

	-- Add the exemptions (including WB-C2OutFlow, but excluding WB-C2OutFlow-Corrected)
	INSERT INTO [BhpbioWeightometerDataExceptionExemption] (Data_Exception_Type_Id, Weightometer_Id, [Start_Date], End_Date)
	SELECT @DataExceptionTypeId_MissingSamples, w.Weightometer_Id, '2009-04-01', NULL
	FROM Weightometer w
	-- that have never appeared in...
	WHERE (w.Weightometer_Id NOT IN (
		-- the set of weightometers that have ever had a sample with a non-estimate/back-calculated source
		SELECT DISTINCT ws.Weightometer_Id 
		FROM WeightometerSample ws 
		INNER JOIN WeightometerSampleNotes wsn 
			ON wsn.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
				AND wsn.Weightometer_Sample_Field_Id = 'SampleSource'
		WHERE NOT wsn.Notes IN ('ESTIMATE', 'BACK-CALCULATED GRADES')
	)
	OR w.Weightometer_Id = 'WB-C2OutFlow')
	AND NOT w.Weightometer_Id IN ('WB-C2OutFlow-Corrected')
	
END
ELSE
BEGIN

	RAISERROR('Data Exception Type for missing sample information could not be found', 16, 1)	

END