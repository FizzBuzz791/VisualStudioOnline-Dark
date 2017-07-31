
INSERT INTO [Setting] (Setting_Id, [Description], Data_Type, Is_User_Editable, Value, Acceptable_Values)
SELECT 'WB_C2_BACK_CALCULATION_START_DATE', 'Start date from which the WB-C2 Back Calculation is allowed to apply', 
	   'DATETIME', 1, '1-Jan-2014', NULL  