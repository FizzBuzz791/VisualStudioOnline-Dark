
Set Identity_Insert dbo.BlockModelType On

Insert Into dbo.BlockModelType
(
	Block_Model_Type_Id, [Name], Description
)
Select 4, 'Short Term Geology', 'Short Term Geology Model'

Set Identity_Insert dbo.BlockModelType Off

Set Identity_Insert dbo.BlockModel On

Insert Into dbo.BlockModel
(
	Block_Model_Id, Block_Model_Type_Id, [Name], Description, Generated_Date, Creation_Datetime, Is_Default, Is_Displayed, Parent_Location_Id
)
Select 4, 4, 'Short Term Geology', 'Short Term Geology Model', GetDate(), GetDate(), 1, 1, Null

-- we also need a STGM Grade Control entry. This doesn't have any live data associated with it, but it needs to be in
-- the table in order for the stored procs to work properly
Insert Into dbo.BlockModel
(
	Block_Model_Id, Block_Model_Type_Id, [Name], Description, Generated_Date, Creation_Datetime, Is_Default, Is_Displayed, Parent_Location_Id
)
Select 5, 1, 'Grade Control STGM', 'Grade Control with STGM', GetDate(), GetDate(), 1, 0, Null

Set Identity_Insert dbo.BlockModel Off

-- now add the required row to the summary table
Insert Into dbo.BhpbioSummaryEntryType(SummaryEntryTypeId, Name, AssociatedBlockModelId)
	Select 24, 'ShortTermGeologyModelMovement', 4 union all
	Select 25, 'GradeControlSTGMModelMovement', 5
	
-- add the field for recording filename from which model was read: for model versioning purpose
Insert Into dbo.ModelBlockPartialField
(
	Model_Block_Partial_Field_Id, Description, Order_No, In_Table, Has_Value, Has_Notes, Has_Formula
)
Select 'ModelFilename', 'Model filename', 8, 1, 0, 1, 0
