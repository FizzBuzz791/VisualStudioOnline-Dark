
INSERT INTO [Setting] (Setting_Id, [Description], Data_Type, Is_User_Editable, Value, Acceptable_Values)
SELECT 'WEIGHTOMETER_MISSING_SAMPLE_IGNORE_MOST_RECENT_DAYS', 'Limits the time range considered when identifying missing sample data exceptions to exclude recent days', 
	   'INT', 1, '5', NULL  