--
-- Turns out the UI needs all the threshold values filled in to work properly, this will create a record for
-- each missing grade with the default values
--
Declare @ThresholdTypeId Varchar(64)


Set @ThresholdTypeId = 'RecoveryFactorDensity'
Insert Into dbo.BhpbioReportThreshold (LocationId, FieldId, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold)
	Select 
		l.Location_Id As LocationId,
		g.Grade_Id As FieldId,
		@ThresholdTypeId As ThresholdTypeId,
		5 As LowThreshold,
		10 As HighThreshold,
		0 As AbsoluteThreshold
	From Location l
		Inner Join Grade g 
			On l.Name = 'WAIO' 
			And g.Grade_Id Not In (Select FieldId From dbo.BhpbioReportThreshold Where ThresholdTypeId = @ThresholdTypeId)
		
Set @ThresholdTypeId = 'F2DensityFactor'
Insert Into dbo.BhpbioReportThreshold (LocationId, FieldId, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold)
	Select 
		l.Location_Id As LocationId,
		g.Grade_Id As FieldId,
		@ThresholdTypeId As ThresholdTypeId,
		5 As LowThreshold,
		10 As HighThreshold,
		0 As AbsoluteThreshold
	From Location l
		Inner Join Grade g 
			On l.Name = 'WAIO' 
			And g.Grade_Id Not In (Select FieldId From dbo.BhpbioReportThreshold Where ThresholdTypeId = @ThresholdTypeId)

	
Set @ThresholdTypeId = 'RecoveryFactorMoisture'
Insert Into dbo.BhpbioReportThreshold (LocationId, FieldId, ThresholdTypeId, LowThreshold, HighThreshold, AbsoluteThreshold)
	Select 
		l.Location_Id As LocationId,
		g.Grade_Id As FieldId,
		@ThresholdTypeId As ThresholdTypeId,
		5 As LowThreshold,
		10 As HighThreshold,
		0 As AbsoluteThreshold
	From Location l
		Inner Join Grade g 
			On l.Name = 'WAIO' 
			And g.Grade_Id Not In (Select FieldId From dbo.BhpbioReportThreshold Where ThresholdTypeId = @ThresholdTypeId)