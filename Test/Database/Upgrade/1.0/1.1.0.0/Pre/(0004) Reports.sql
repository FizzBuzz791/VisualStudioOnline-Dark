
SET IDENTITY_INSERT ReportGroup ON

Insert Into ReportGroup
(
	Report_Group_Id, Name, Description, Order_No
)
Select '2', 'Bhpbio', 'BHPBIO Reports', 1

SET IDENTITY_INSERT ReportGroup OFF

UPDATE dbo.Report
SET Description = 'Recovery Analysis Report (Line-Chart)'
WHERE Name = 'BhpbioRecoveryAnalysisReport'

UPDATE dbo.Report
SET Description = 'Movement Recovery Report (Histogram)'
WHERE Name = 'BhpbioMovementRecoveryReport'

UPDATE dbo.Report
SET Description = 'Designation Attribute Report (Line-Chart)'
WHERE Name = 'BhpbioModelComparisonReport'

UPDATE dbo.Report
SET Description = 'Designation Attribute Report (Histogram)',
	Name = 'BhpbioDesignationAttributeReport'
WHERE Name = 'BhpbioGradeRecoveryReport'

UPDATE dbo.Report
SET Description = 'F1F2F3 Reconciliation by Attribute Report (Line-Chart)'
WHERE Name = 'BhpbioF1F2F3ReconciliationAttributeReport'

