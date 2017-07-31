
-- calc virtual flow for 2013 onwards to perform back calculation with corrected M232 grades

DECLARE @DateFrom DATETIME
DECLARE @DateTo DATETIME
DECLARE @CurrentProcessingDate DATETIME

SET @DateFrom = '2013-01-01'
SET @DateTo = DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())) 

SET @CurrentProcessingDate = @DateFrom

WHILE @CurrentProcessingDate <= @DateTo
BEGIN
	
	PRINT CAST(@CurrentProcessingDate AS VARCHAR)
	
	EXEC CalcVirtualFlowRaise @CurrentProcessingDate
	
	SET @CurrentProcessingDate = DATEADD(DAY, 1, @CurrentProcessingDate)

END

EXEC CalcVirtualflow

-- Run the C2 back calculation for all dates that werent calculated in the previous query

SET @DateFrom = '2009-04-01'
SET @DateTo = '2012-12-31'

SET @CurrentProcessingDate = @DateFrom

WHILE @CurrentProcessingDate <= @DateTo
BEGIN

	EXEC CalcWhalebackVirtualFlowC2 @iCalcDate = @CurrentProcessingDate
	
	SET @CurrentProcessingDate = DATEADD(DAY, 1, @CurrentProcessingDate)

END

-- Check if there are any duplicates on the fields that we are using to match Weightometer Samples for the Data Transaction Tonnes Flow update
IF EXISTS (
	SELECT *
	FROM dbo.WeightometerSample ws 
	INNER JOIN dbo.WeightometerSample ws2 
		ON ws2.Weightometer_Id = ws.Weightometer_ID 
			AND ws2.Weightometer_Sample_Date = ws.Weightometer_Sample_Date 
			AND (NOT ws.Weightometer_Sample_Id = ws2.Weightometer_Sample_ID) 
			AND ws2.Destination_Stockpile_Id = ws.Destination_Stockpile_Id
	WHERE ws.Weightometer_Id = 'WB-C2OutFlow'
) 
BEGIN
	PRINT 'DON''T DO IT THERE ARE DUPLICATES'
END
ELSE
BEGIN

	PRINT 'OK'
	
	-- ok to match on Weightometer_Id, Weightometer_Sample_Date, Destination_Stockpile_Id
	
	UPDATE dbo.DataTransactionTonnesFlow
	SET Weightometer_Sample_Id = d.NewSampleId
	FROM (
		SELECT DISTINCT ws.Weightometer_Sample_Id OriginalSampleId, ws2.Weightometer_Sample_Id NewSampleId
		FROM dbo.DataTransactionTonnesFlow dttf
		INNER JOIN dbo.WeightometerSample ws
			ON dttf.Weightometer_Sample_Id = ws.Weightometer_Sample_Id
		INNER JOIN dbo.WeightometerSample ws2
			ON ws2.Weightometer_Id = 'WB-C2OutFlow-Corrected'
				AND ws.Weightometer_Sample_Date = ws2.Weightometer_Sample_Date
				AND ws.Destination_Stockpile_Id = ws2.Destination_Stockpile_Id
		WHERE ws.Weightometer_Id = 'WB-C2OutFlow'
			AND ws.Weightometer_Sample_Date >= @DateFrom
	) d
	WHERE Weightometer_Sample_Id = d.OriginalSampleId

END
