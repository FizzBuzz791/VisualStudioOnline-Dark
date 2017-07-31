-- For testing of 2.0.50.0 (WB-C2 Sample Station Decommissioning)

DECLARE @TestDate DATETIME
SET @TestDate = ''

DECLARE @DataExceptionTypeId INT

-- Grab the exception type
SELECT @DataExceptionTypeId = Data_Exception_Type_Id
FROM dbo.DataExceptionType
WHERE [Name] = 'Insufficient sample information to back-calculate grades'

INSERT INTO dbo.DataException (Data_Exception_Type_Id, Data_Exception_Date, Data_Exception_Shift, 
							   Data_Exception_Status_Id, Short_Description, Long_Description, Details_XML)
SELECT @DataExceptionTypeId, @TestDate, 'D', 'A', 
		   'Insufficient sample information to back-calculate grades for WB-C2OutFlow-Corrected on ' + 
				CAST(DATENAME(DAY, @TestDate) AS VARCHAR) + '-' + CAST(DATENAME(MONTH, @TestDate) AS VARCHAR) + '-' + CAST(DATENAME(YEAR, @TestDate) AS VARCHAR), 
		   'Insufficient sample information exists for date ' +
				CAST(DATENAME(DAY, @TestDate) AS VARCHAR) + '-' + CAST(DATENAME(MONTH, @TestDate) AS VARCHAR) + '-' + CAST(DATENAME(YEAR, @TestDate) AS VARCHAR) +
					' to allow for the back-calculation of grade for WB-C2OutFlow-Corrected',
		   '<DocumentElement><Insufficient_Sample_Information><TargetWeightometer_Id>WB-C2OutFlow-Corrected</TargetWeightometer_Id></Insufficient_Sample_Information></DocumentElement>'		
	   
	   
	   
	   
	  