-- caters for the renaming of Yandi OHP1 and OHP2 crushers within MQ2 for RGP5

INSERT INTO [ReconcilorBHPBIO].[dbo].[BhpbioProductionResolveBasic]
           ([Code]
           ,[Resolve_From_Date]
           ,[Resolve_From_Shift]
           ,[Resolve_To_Date]
           ,[Resolve_To_Shift]
           ,[Stockpile_Id]
           ,[Build_Id]
           ,[Component_Id]
           ,[Digblock_Id]
           ,[Crusher_Id]
           ,[Mill_Id]
           ,[Description]
           ,[Production_Direction])
     VALUES
           ('YD-YD1',
           '2009-04-01 00:00:00.000',
           'D',
           NULL,
           NULL,
           NULL,
           NULL,
           NULL,
           NULL,
           'YD-OHP1',
           NULL,
           'Yandi OHP Crusher Rename for RGP5',
           'B')

INSERT INTO [ReconcilorBHPBIO].[dbo].[BhpbioProductionResolveBasic]
           ([Code]
           ,[Resolve_From_Date]
           ,[Resolve_From_Shift]
           ,[Resolve_To_Date]
           ,[Resolve_To_Shift]
           ,[Stockpile_Id]
           ,[Build_Id]
           ,[Component_Id]
           ,[Digblock_Id]
           ,[Crusher_Id]
           ,[Mill_Id]
           ,[Description]
           ,[Production_Direction])
     VALUES
           ('YD-YD2',
           '2009-04-01 00:00:00.000',
           'D',
           NULL,
           NULL,
           NULL,
           NULL,
           NULL,
           NULL,
           'YD-OHP2',
           NULL,
           'Yandi OHP Crusher Rename for RGP5',
           'B')
