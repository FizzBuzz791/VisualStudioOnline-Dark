
Update dbo.HaulageRawField
Set Has_Value = 0,
	Has_Notes = 1
Where Haulage_Raw_Field_Id In ('DestinationMineSite', 'SourceMineSite')
Go

Update dbo.HaulageField
Set Has_Value = 0,
	Has_Notes = 1
Where Haulage_Field_Id In ('DestinationMineSite', 'SourceMineSite')
Go