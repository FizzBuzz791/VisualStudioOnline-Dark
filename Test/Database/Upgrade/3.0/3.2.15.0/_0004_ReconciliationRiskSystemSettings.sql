

IF NOT EXISTS(SELECT * FROM Setting WHERE Setting_Id = 'FORWARD_FACTOR_MINIMUM_NON_DEPLETED_PERCENT')
BEGIN
	INSERT INTO Setting(Setting_Id, Description, Data_Type, Is_User_Editable, Value, Acceptable_Values)
	VALUES ('FORWARD_FACTOR_MINIMUM_NON_DEPLETED_PERCENT','The minumum percentage of non-depleted material within a block for the block to be included in forward factor calculations','REAL',0,5.0,NULL)
END

IF NOT EXISTS(SELECT * FROM Setting WHERE Setting_Id = 'FORWARD_FACTOR_MAX_DAYS_SINCE_BLOCKOUT')
BEGIN
	INSERT INTO Setting(Setting_Id, Description, Data_Type, Is_User_Editable, Value, Acceptable_Values)
	VALUES ('FORWARD_FACTOR_MAX_DAYS_SINCE_BLOCKOUT','The maximum number of days between the block out and reporting date for a block to be included in forward factor calculations','INT',0,365,NULL)
END
GO