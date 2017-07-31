DECLARE @dataExceptionTypeId INTEGER
SELECT @dataExceptionTypeId  = DATA_EXCEPTION_TYPE_ID FROM DataExceptionType WHERE NAme = 'Block changed after haulage imported'

UPDATE de
SET Data_Exception_Status_Id = 'D' 
FROM DataException de 
WHERE de.Data_Exception_Type_Id = @dataExceptionTypeId AND de.Data_Exception_Status_Id = 'A'