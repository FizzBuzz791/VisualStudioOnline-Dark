
Declare @ThresholdTypeId Varchar(64) = 'GeometFactors'

If NOT EXISTS (Select 1 From BhpbioReportThresholdType Where ThresholdTypeId = @ThresholdTypeId)
Begin

	-- New threshold types for new geomet factorss
	Insert Into dbo.BhpbioReportThresholdType (ThresholdTypeId, [Description])
		Select @ThresholdTypeId, 'Geomet Factors' 


	-- create some default values for the new threadhold types
	Insert Into dbo.BhpbioReportThreshold (LocationId, FieldId, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold)
		Select 
		LocationId,
		FieldId, 
		@ThresholdTypeId, 
		5, 
		10,
		0
		From dbo.BhpbioReportThreshold
		Where ThresholdTypeId = 'F1Factor'
		
End
