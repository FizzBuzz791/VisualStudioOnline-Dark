-- The original name did not match the template... correcting..
-- NOTE: This is not the display name, but the name used to lookup the RDL file
UPDATE Report 
		SET Name = 'BhpbioF1F2F3GeometOverviewReconContributionReport' 
		WHERE Name = 'BhpBioGeometOverviewReconContributionReport'
GO