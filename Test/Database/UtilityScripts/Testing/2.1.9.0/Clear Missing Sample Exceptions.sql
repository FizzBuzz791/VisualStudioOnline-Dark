-- For testing of 2.0.50.0 (WB-C2 Sample Station Decommissioning)

DECLARE @DataExceptionTypeId INT

-- Grab the exception type
SELECT @DataExceptionTypeId = Data_Exception_Type_Id
FROM dbo.DataExceptionType
WHERE [Name] = 'No sample information over a 24-hour period'

DELETE FROM dbo.DataException WHERE Data_Exception_Type_Id = @DataExceptionTypeId