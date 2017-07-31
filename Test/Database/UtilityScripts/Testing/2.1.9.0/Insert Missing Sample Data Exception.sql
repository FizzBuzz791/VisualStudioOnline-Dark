-- For testing of 2.0.50.0 (WB-C2 Sample Station Decommissioning)

DECLARE @WeightometerId VARCHAR(31)
DECLARE @SampleDate DATETIME

SET @WeightometerId = ''
SET @SampleDate = ''

DECLARE @DataExceptionTypeId INT

-- Grab the exception type
SELECT @DataExceptionTypeId = Data_Exception_Type_Id
FROM dbo.DataExceptionType
WHERE [Name] = 'No sample information over a 24-hour period'

INSERT INTO dbo.DataException (Data_Exception_Type_Id, Data_Exception_Date, Data_Exception_Shift, 
							   Data_Exception_Status_Id, Short_Description, Long_Description, Details_XML)
SELECT @DataExceptionTypeId, @SampleDate, 'D', 'A', 
	   'Missing sample information for weightometer ' + @WeightometerId + ' on ' + 
			CAST(DATENAME(DAY, @SampleDate) AS VARCHAR) + '-' + CAST(DATENAME(MONTH, @SampleDate) AS VARCHAR) + '-' + CAST(DATENAME(YEAR, @SampleDate) AS VARCHAR), 
	   'There are movements for weightometer ' + @WeightometerId + ' on ' +
			CAST(DATENAME(DAY, @SampleDate) AS VARCHAR) + '-' + CAST(DATENAME(MONTH, @SampleDate) AS VARCHAR) + '-' + CAST(DATENAME(YEAR, @SampleDate) AS VARCHAR) + 
			', however there are no available sample results on that day for that weightometer.',
	   '<DocumentElement><Missing_Samples><Weightometer_Id>' + @WeightometerId + '</Weightometer_Id></Missing_Samples></DocumentElement>'
	   
	   
	   
	   
	  