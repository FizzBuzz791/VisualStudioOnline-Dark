If (Select top(1) 1 From ModelBlockPartialField Where Model_Block_Partial_Field_Id = 'ResourceClassification5') Is Null
Begin

	Insert Into ModelBlockPartialField (Model_Block_Partial_Field_Id, Description, Order_No, In_Table, Has_Value, Has_Notes, Has_Formula)
		Select 'ResourceClassification5', 'Other', 5, 1, 1, 0, 0
		
	Update ModelBlockPartialField 
		Set [Description] = 'Potential / Very Low'
		Where Model_Block_Partial_Field_Id = 'ResourceClassification4'

End
GO

If (Select top(1) 1 From [BhpbioSummaryEntryField] Where [Name] = 'ResourceClassification5') Is Null
Begin

	-- lets just delete everything from the summary fields - when these scripts are run, the only thing
	-- in these tables will be the RC data
	Delete From dbo.BhpbioSummaryEntryFieldValue
	Delete From dbo.BhpbioSummaryEntryField

	SET IDENTITY_INSERT  dbo.BhpbioSummaryEntryField ON

	INSERT INTO  [dbo].[BhpbioSummaryEntryField]([SummaryEntryFieldId],	[Name],	[ContextKey])
	VALUES (1, 'ResourceClassification1', 'ResourceClassification')

	INSERT INTO  [dbo].[BhpbioSummaryEntryField]([SummaryEntryFieldId],	[Name],	[ContextKey])
	VALUES (2, 'ResourceClassification2', 'ResourceClassification')

	INSERT INTO  [dbo].[BhpbioSummaryEntryField]([SummaryEntryFieldId],	[Name],	[ContextKey])
	VALUES (3, 'ResourceClassification3', 'ResourceClassification')

	INSERT INTO  [dbo].[BhpbioSummaryEntryField]([SummaryEntryFieldId],	[Name],	[ContextKey])
	VALUES (4, 'ResourceClassification4', 'ResourceClassification')

	INSERT INTO  [dbo].[BhpbioSummaryEntryField]([SummaryEntryFieldId],	[Name],	[ContextKey])
	VALUES (5, 'ResourceClassification5', 'ResourceClassification')

	-- this will never be present in the field value table, but it is required in order to make the 
	-- the joins work properly when getting the RC breakdown
	INSERT INTO  [dbo].[BhpbioSummaryEntryField]([SummaryEntryFieldId],	[Name],	[ContextKey])
	VALUES (6, 'ResourceClassificationUnknown', 'ResourceClassification')

	SET IDENTITY_INSERT  dbo.BhpbioSummaryEntryField OFF

End

Go