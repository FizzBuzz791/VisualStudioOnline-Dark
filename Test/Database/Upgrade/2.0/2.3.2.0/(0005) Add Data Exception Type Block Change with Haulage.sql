DECLARE @newDataExceptionTypeId INTEGER
DECLARE @order INTEGER

SELECT @newDataExceptionTypeId = MAX([Data_Exception_Type_Id]) + 1
FROM [DataExceptionType]

SELECT @order = MAX([Order_No]) + 1
FROM [DataExceptionType] WHERE [Name] != 'Other'


INSERT INTO [DataExceptionType] ([Data_Exception_Type_Id], [Name], [Description], [Order_No])
VALUES (@newDataExceptionTypeId, 'Block changed after haulage imported', 'The details of a Block have been changed after haulage for the Block has already been imported', @order)


INSERT INTO DataExceptionResolution(Data_Exception_Type_Id,  Name, [Description])
VALUES (@newDataExceptionTypeId, 'Review and update Haulage', 'Review the haulage transactions from the associated Block and update if required.')
GO
