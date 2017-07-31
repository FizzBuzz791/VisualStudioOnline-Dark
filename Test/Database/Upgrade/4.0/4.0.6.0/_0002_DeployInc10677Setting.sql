IF NOT EXISTS(SELECT * FROM Setting WHERE Setting_Id = 'BHPBIO_LOCATION_DATE_REBUILD_MINUTES')
BEGIN
	INSERT INTO Setting(Setting_Id, Description, Data_Type, Is_User_Editable, Value, Acceptable_Values)
	VALUES ('BHPBIO_LOCATION_DATE_REBUILD_MINUTES','The age in minutes for location date data that may be reused rather than rebuilt.','INT',1,30,NULL)
END
GO