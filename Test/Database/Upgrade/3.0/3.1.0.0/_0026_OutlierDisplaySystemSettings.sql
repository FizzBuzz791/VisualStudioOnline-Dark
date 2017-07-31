INSERT INTO Setting(Setting_Id, Description, Data_Type, Is_User_Editable, Value, Acceptable_Values)
VALUES ('OUTLIER_DISPLAY_MINIMUM_DATE', 'The minimum date, prior to which outlier results will not be presented on the approval screens', 'DATETIME',1,'2009-04-01', Null)
GO
INSERT INTO Setting(Setting_Id, Description, Data_Type, Is_User_Editable, Value, Acceptable_Values)
VALUES ('OUTLIER_DISPLAY_SUPPRESS_BY_APPROVAL_MAXIMUM_DATE', 'Approvals made prior to this date will cause outlier results for the associated location and month to be hidden.', 'DATETIME',1,'2009-04-01', Null)
GO
INSERT INTO Setting(Setting_Id, Description, Data_Type, Is_User_Editable, Value, Acceptable_Values)
VALUES ('OUTLIER_DISPLAY_SUPPRESS_WHEN_CALCULATING', 'Whether or not to suppress outlier display on the approval screen for months pending calculation', 'BOOLEAN',1,'TRUE', Null)
GO
