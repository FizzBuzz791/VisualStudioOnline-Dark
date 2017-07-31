-- For testing of 2.0.50.0 (WB-C2 Sample Station Decommissioning)

DECLARE @DataExceptionTypeId INT

-- Grab the exception type
SELECT @DataExceptionTypeId = Data_Exception_Type_Id
FROM dbo.DataExceptionType
WHERE [Name] = 'Insufficient sample information to back-calculate grades'

DELETE FROM dbo.DataException WHERE Data_Exception_Type_Id = @DataExceptionTypeId