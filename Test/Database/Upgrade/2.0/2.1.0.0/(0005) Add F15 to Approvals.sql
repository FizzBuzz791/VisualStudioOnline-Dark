


Insert Into [dbo].[BhpbioReportThresholdType] (ThresholdTypeId, Description)
	Select 'F15Factor','F1.5 Factor'

Insert Into [dbo].[BhpbioReportThreshold] (LocationId, FieldId, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold)
	Select 1, 0, 'F15Factor', 5, 10, 0 Union
	Select 1, 1, 'F15Factor', 0.3, 0.6, 1 Union
	Select 1, 2, 'F15Factor', 5, 10, 0 Union
	Select 1, 3, 'F15Factor', 5, 10, 0 Union
	Select 1, 4, 'F15Factor', 5, 10, 0 Union
	Select 1, 5, 'F15Factor', 5, 10, 0 Union
	Select 1, 6, 'F15Factor', 5, 10, 0
	
	
-- add appropriate reporting colors for the new factor + model. Based the colors off the existing 
-- measures
Insert Into [dbo].[BhpbioReportColor] (TagId, Description, IsVisible, Color, LineStyle, MarkerShape)
	Select 'F15Factor', 'F1.5 Factor', 1, 'Blue', 'Solid', 'None' Union
	Select 'ShortTermGeologyModel', 'Short Term Geology Model', 1, 'Brown', 'Solid', 'None'

-- In order for the checkboxes to appear next to the values for the F1.5 approvals
-- we have to add the required tags to the ReportDataTags table
Insert Into [dbo].[BhpbioReportDataTags] (TagId, TagGroupId, TagGroupLocationTypeId, OtherMaterialTypeId, ApprovalOrder)
	Select 'F15Factor','F15Factor', 4, Null, 6 Union
	Select 'F15FactorFines', 'F15Factor', 4, Null, 5 Union
	Select 'F15FactorLump', 'F15Factor', 4, Null, 5 Union
	Select 'F15ShortTermGeologyModel', 'F15Factor', 4, Null, 3 Union
	Select 'F15ShortTermGeologyModelFines', 'F15Factor', 4, Null, 2 Union
	Select 'F15ShortTermGeologyModelLump', 'F15Factor', 4, Null, 2 Union
	-- note that the F1Factor Tag group here is not a typo. It needs to be associated with the F1Factor group
	-- in the approval data so that the approval flows work properly
	Select 'F15GradeControlSTGM', 'F1Factor', 4, NULL, 4
