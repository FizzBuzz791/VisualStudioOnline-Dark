
INSERT INTO [Setting] (Setting_Id, [Description], Data_Type, Is_User_Editable, Value, Acceptable_Values)
SELECT 'WEIGHTOMETER_MINIMUM_TONNES_SIGNIFICANT', 'A minimum movement tonnage, below which movements for a weightometer are not considered significant.', 
	   'INT', 1, '1000', NULL
	   