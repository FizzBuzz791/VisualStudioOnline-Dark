IF NOT EXISTS(SELECT * FROM Setting WHERE Setting_Id = 'BHPBIO_REPORT_CACHE_TIMEOUT_PERIOD')
BEGIN
            INSERT INTO Setting(Setting_Id, Description, Data_Type, Is_User_Editable, Value, Acceptable_Values)
            VALUES ('BHPBIO_REPORT_CACHE_TIMEOUT_PERIOD','The number of minutes a file should be cached for before it is considered stale. Setting to -1 will turn caching off.','INT',1,30,NULL)
END
GO