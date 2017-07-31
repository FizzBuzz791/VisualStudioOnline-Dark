
-- Make sure Other isn't ignored when determining the id. Only when determining the order
INSERT INTO [DataExceptionType] ([Data_Exception_Type_Id], [Name], [Description], [Order_No])
SELECT MAX([Data_Exception_Type_Id]) + 1, 
	  'Insufficient sample information to back-calculate grades', 'A grade back-calculation is required however there is insufficient sample information for other weightometers to support the back-calculation',
	  (SELECT MAX([Order_No]) + 1 FROM [DataExceptionType] WHERE [Name] != 'Other')
FROM [DataExceptionType]
