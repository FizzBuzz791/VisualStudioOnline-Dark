If (Select top(1) 1 From ModelBlockPartialField Where Model_Block_Partial_Field_Id like 'ResourceClassification%') Is Null
Begin

	Insert Into ModelBlockPartialField (Model_Block_Partial_Field_Id, Description, Order_No, In_Table, Has_Value, Has_Notes, Has_Formula)
		Select 'ResourceClassification1', 'Measured / High', 1, 1, 1, 0, 0 Union
		Select 'ResourceClassification2', 'Indicated / Medium', 2, 1, 1, 0, 0 Union
		Select 'ResourceClassification3', 'Inferred / Low', 3, 1, 1, 0, 0 Union
		Select 'ResourceClassification4', 'Unclassified', 4, 1, 1, 0, 0

End
GO