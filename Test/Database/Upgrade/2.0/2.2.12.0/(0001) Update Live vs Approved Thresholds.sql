
--
-- These proportions should be between 0 and 100 if they are relative thresholds, but currently they
-- are in the 0-1 range, causing a 'red-cross' to always be shown.
--

Update BhpbioReportThreshold 
Set LowThreshold = 1, HighThreshold = 5
Where ThresholdTypeId = 'LiveVsSummaryProportionDiff'
	And FieldId in (-1, 0)
	And AbsoluteThreshold = 0
	