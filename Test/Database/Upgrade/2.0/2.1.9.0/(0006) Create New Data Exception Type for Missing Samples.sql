
-- Make sure Other isn't ignored when determining the id. Only when determining the order
INSERT INTO [DataExceptionType] ([Data_Exception_Type_Id], [Name], [Description], [Order_No])
SELECT MAX([Data_Exception_Type_Id]) + 1, 
	  'No sample information over a 24-hour period', 'Movements exist from a crusher or other source for which there are no sample results in the movement period',
	  (SELECT MAX([Order_No]) + 1 FROM [DataExceptionType] WHERE [Name] != 'Other')
FROM [DataExceptionType]
