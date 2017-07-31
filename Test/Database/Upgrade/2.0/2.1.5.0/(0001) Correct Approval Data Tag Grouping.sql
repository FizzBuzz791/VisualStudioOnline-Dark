--------------------------------------------------------------------------------------
--- OBSOLETE -- THIS CHANGE HAS BEEN REVERTED AS IT DID NOT HAVE THE DESIRED EFFECT
--------------------------------------------------------------------------------------

-- Ensure the F1Geology tags are in there own group to prevent approve / unapprove validation issues
--UPDATE [BhpbioReportDataTags] SET TagGroupId = 'Geology' WHERE TagId like 'F1Geology%'
