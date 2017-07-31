DELETE FROM dbo.StockpileField Where Stockpile_Field_Id = 'ProductSize'

INSERT INTO dbo.StockpileField (Stockpile_Field_Id, Description, Order_No, In_Table, Has_Value, Has_Notes, Has_Formula) 
VALUES ('ProductSize', 'Used to determine the type of material stored on a given stockpile.', 2, 0, 0, 1, 0)
Go

DELETE FROM dbo.WeightometerSampleField Where Weightometer_Sample_Field_Id = 'ProductSize'

INSERT INTO dbo.WeightometerSampleField (Weightometer_Sample_Field_Id, Description, Order_No, In_Table, Has_Value, Has_Notes, Has_Formula) 
VALUES ('ProductSize', 'Used to determine if a production movement involves Lump, Fines or ROM material.', 5, 0, 0, 1, 0)
Go

-- ProductSize note supercedes the following ones:
Delete From dbo.WeightometerSampleField Where Weightometer_Sample_Field_Id In ('FinesPercent', 'LumpPercent')
Go

DELETE FROM dbo.Setting WHERE Setting_Id IN ('LUMP_FINES_CUTOVER_DATE', 'PORT_BLENDING_CUTOVER_DATE')

INSERT INTO dbo.Setting (Setting_Id, Description, Data_Type, Is_User_Editable, Value, Acceptable_Values) 
VALUES ('LUMP_FINES_CUTOVER_DATE', 'Date from which Reconcilor will report Lump and Fines data.', 'DATETIME', 0, '2013-10-01', Null) 
Go

INSERT INTO dbo.Setting (Setting_Id, Description, Data_Type, Is_User_Editable, Value, Acceptable_Values) 
VALUES ('PORT_BLENDING_CUTOVER_DATE', 'Date from which revised F3 calculation will take effect for port blending.', 'DATETIME', 0, '2013-10-01', Null) 
Go

-- additional Summary Entry Types

DELETE FROM dbo.BhpbioSummaryEntryType WHERE SummaryEntryTypeId IN (22, 23)

INSERT INTO dbo.BhpbioSummaryEntryType (SummaryEntryTypeId, Name, AssociatedBlockModelId) 
VALUES (22, 'OreForRail', Null) 
Go

INSERT INTO dbo.BhpbioSummaryEntryType (SummaryEntryTypeId, Name, AssociatedBlockModelId) 
VALUES (23, 'OreForRailGrades', Null) 
Go

