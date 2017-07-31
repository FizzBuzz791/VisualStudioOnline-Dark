IF NOT EXISTS(SELECT * FROM Setting WHERE Setting_Id = 'BHPBIO_AUTOMATIC_CONTENT_SELECTION_MAXIMUM_CONTRIBUTORS')
BEGIN
            INSERT INTO Setting(Setting_Id, Description, Data_Type, Is_User_Editable, Value, Acceptable_Values)
            VALUES ('BHPBIO_AUTOMATIC_CONTENT_SELECTION_MAXIMUM_CONTRIBUTORS','The maximum number of contributors to be automatically selected for any analyte and factor combination','INT',0,3,NULL)
END

IF NOT EXISTS(SELECT * FROM Setting WHERE Setting_Id = 'BHPBIO_AUTOMATIC_CONTENT_SELECTION_MINIMUM_ERROR_CONTRIBUTION')
BEGIN
            INSERT INTO Setting(Setting_Id, Description, Data_Type, Is_User_Editable, Value, Acceptable_Values)
            VALUES ('BHPBIO_AUTOMATIC_CONTENT_SELECTION_MINIMUM_ERROR_CONTRIBUTION','The minimum error contribution as a proportion (between 0 and 1) of any contributor included by automatic content selection','REAL',0,0.1,NULL)
END
GO

