DECLARE @processCorrectionDate DATETIME

SELECT @processCorrectionDate = CONVERT(datetime, value) 
FROM Setting s
WHERE Setting_Id = 'BHPBIO_LUMPFINES_IMPORT_CORRECTION_DATE'

IF @processCorrectionDate IS NULL
BEGIN
	SET @processCorrectionDate = GETDATE()
	
	INSERT INTO Setting(Setting_Id, Description,Data_Type, Is_User_Editable, Value)
	VALUES ('BHPBIO_LUMPFINES_IMPORT_CORRECTION_DATE', 'Date that the ReconBlockInsertUpdate lump / fines storage issue was resolved', 'DATETIME', 0, CONVERT(varchar,@processCorrectionDate,20))
END
GO