--
-- The live v approved report has been changed, so we should update the default thresholds so it is
-- still useful.
--
-- Everything should be an absolute threshold, except for Tonnes, and Volume. We change the default thresholds
-- as well, so they are more reasonable.

-- set the tonnes and volume to be relative thresholds, everything else should be absolute
Update BhpbioReportThreshold Set AbsoluteThreshold = 1 Where ThresholdTypeId = 'LiveVsSummaryProportionDiff' And LocationId = 1
Update BhpbioReportThreshold Set AbsoluteThreshold = 0 Where ThresholdTypeId = 'LiveVsSummaryProportionDiff' And LocationId = 1 And FieldId In (-1, 0)

-- set some default values for the absolute and relative thresholds
Update BhpbioReportThreshold 
Set LowThreshold = 0.01, HighThreshold = 0.05 
Where ThresholdTypeId = 'LiveVsSummaryProportionDiff' 
  And LocationId = 1 
  And AbsoluteThreshold = 0

Update BhpbioReportThreshold 
Set LowThreshold = 0.05, HighThreshold = 0.10 
Where ThresholdTypeId = 'LiveVsSummaryProportionDiff' 
  And LocationId = 1 
  And AbsoluteThreshold = 1
