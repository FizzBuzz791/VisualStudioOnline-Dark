-- Sets the import validation lookback date in the Exception Bar

INSERT INTO dbo.Setting
           (Setting_Id
           ,[Description]
           ,Data_Type
           ,Is_User_Editable
           ,Value
           ,Acceptable_Values)
     VALUES
           ('IMPORT_VALIDATION_LOOKBACK_DATE'
           ,'Sets the import validation lookback date in the Exception Bar'
           ,'STRING'
           ,1
           ,'01-JAN-2015'
           ,NULL)
GO
