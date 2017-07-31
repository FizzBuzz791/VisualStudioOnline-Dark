-- This script populates Volume information for all ModelMovement summary data
-- It is not neccessry to populate density information as this has historially always been recorded
--
-- This script must be run AFTER the density values in the summary tables are inverted (by another phase 2 upgrade script)
--      i.e. the calculation expects inverted values
--
-- Only ModelMovement summary data need be updated because 
--		this is the only summary type for which Volume is used; and
--		factor calculations for density actually use volume and tonnes information (primarily) rather than density

-- Determine the density grade Id
Declare @densityId INTEGER
SELECT @densityId = Grade_Id FROM Grade WHERE Grade_Name = 'Density'

Update bse
	SET Volume = bse.Tonnes / (1/bseg.GradeValue)
--Select bse.*, bse.Tonnes / (1/bseg.GradeValue) as CalcVolume
From BhpbioSummaryEntry bse 
	Inner Join (
				Select bset.SummaryEntryTypeId 
				FROM BhpbioSummaryEntryType bset 
				WHERE bset.Name like '%ModelMovement'
				) filteredbset
		On filteredbset.SummaryEntryTypeId = bse.SummaryEntryTypeID
	Inner Join BhpbioSummaryEntryGrade bseg ON bseg.SummaryEntryId = bse.SummaryEntryId
		And bseg.GradeId = @densityId
Where bseg.GradeValue IS NOT NULL AND bseg.GradeValue > 0
	AND bse.Volume IS NULL
