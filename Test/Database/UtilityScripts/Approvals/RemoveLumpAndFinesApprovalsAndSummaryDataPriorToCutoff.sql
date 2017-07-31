-------------------------------------------------------------------------------------------------------------------------------
-- This script will remove all Lump/Fines summary data and Approval records prior to the LUMP_FINES_CUTOVER_DATE system setting
--
-- IMPORTANT - make sure that the LUMP_FINES_CUTOVER_DATE has been set to something sensible before running this script
-------------------------------------------------------------------------------------------------------------------------------

-- Determine what the Lump/Fines Cutover Date is
DECLARE @lumpFinesCutover DATETIME
SELECT @lumpFinesCutover = Convert(DateTime, s.Value) 
FROM Setting s
WHERE s.Setting_Id = 'LUMP_FINES_CUTOVER_DATE'

PRINT 'Removing lump / fines summary and approval data prior to ' + convert(varchar, @lumpFinesCutover, 103)

BEGIN TRANSACTION

	-- Delete Summary Entry Grades that relate to Lump/Fines summary data prior to the cutover date
	DELETE bseg
	FROM BhpbioSummaryEntryGrade bseg
		INNER JOIN BhpbioSummaryEntry bse ON bse.SummaryEntryId = bseg.SummaryEntryId
		INNER JOIN BhpbioSummary s ON s.SummaryId = bse.SummaryId
	WHERE s.SummaryMonth < @lumpFinesCutover
		AND Not IsNull(bse.ProductSize,'TOTAL') = 'TOTAL'
		

	-- Delete Summary Entries that relate to Lump/Fines summary data prior to the cutover date
	DELETE bse
	FROM BhpbioSummaryEntry bse 
		INNER JOIN BhpbioSummary s ON s.SummaryId = bse.SummaryId
	WHERE s.SummaryMonth < @lumpFinesCutover
		AND Not IsNull(bse.ProductSize,'TOTAL') = 'TOTAL'

	-- Delete Approval records that relate to Lump/Fines tags prior to the Lump/Fines cutover approval date
	DELETE bad
	FROM [dbo].[BhpbioApprovalData] bad
		INNER JOIN (SELECT TagId FROM BhpbioReportDataTags WHERE (TagId like '%Fines%' Or TagId like '%Lump%')) as lfTag
			ON lfTag.TagId = bad.TagId
	WHERE bad.ApprovedMonth < @lumpFinesCutover

COMMIT TRANSACTION
