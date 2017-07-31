			
DELETE BBBMGH
--SELECT *
FROM BhpbioBlastBlockHolding BBBH
	INNER JOIN BhpbioBlastBlockModelHolding BBBMH
		ON (BBBH.BlockId = BBBMH.BlockId)
	INNER JOIN BhpbioBlastBlockModelGradeHolding BBBMGH
		ON (BBBMH.BlockId = BBBMGH.BlockId
			AND BBBMH.ModelName = BBBMGH.ModelName
			AND BBBMH.ModelOreType = BBBMGH.ModelOreType)
	INNER JOIN BhpbioImportBlockFailure BIBF
		 ON ( BIBF.Site = BBBH.Site
			AND BIBF.Pit = Coalesce(BBBH.MQ2PitCode, BBBH.Pit)
			AND BIBF.Bench = BBBH.Bench
			AND BIBF.PatternNumber = BBBH.PatternNumber
			AND BIBF.BlockName = BBBH.BlockName
			)
WHERE cast(BIBF.blockeddate as datetime) < '01-jan-2008'

DELETE BBBMH
--SELECT *
FROM BhpbioBlastBlockHolding BBBH
	INNER JOIN BhpbioBlastBlockModelHolding BBBMH
		ON (BBBH.BlockId = BBBMH.BlockId)
	INNER JOIN BhpbioImportBlockFailure BIBF
		 ON ( BIBF.Site = BBBH.Site
			AND BIBF.Pit = Coalesce(BBBH.MQ2PitCode, BBBH.Pit)
			AND BIBF.Bench = BBBH.Bench
			AND BIBF.PatternNumber = BBBH.PatternNumber
			AND BIBF.BlockName = BBBH.BlockName
			)
WHERE cast(BIBF.blockeddate as datetime) < '01-jan-2008'

DELETE BBBPH
--SELECT *
FROM BhpbioBlastBlockHolding BBBH
	LEFT JOIN BhpbioBlastBlockModelHolding BBBMH
		ON (BBBH.BlockId = BBBMH.BlockId)
	INNER JOIN BhpbioBlastBlockPointHolding BBBPH
		ON (BBBH.BlockId = BBBPH.BlockId)
	INNER JOIN BhpbioImportBlockFailure BIBF
		 ON ( BIBF.Site = BBBH.Site
			AND BIBF.Pit = Coalesce(BBBH.MQ2PitCode, BBBH.Pit)
			AND BIBF.Bench = BBBH.Bench
			AND BIBF.PatternNumber = BBBH.PatternNumber
			AND BIBF.BlockName = BBBH.BlockName
			)
WHERE cast(BIBF.blockeddate as datetime) < '01-jan-2008'

DELETE BBBH
--SELECT *
FROM BhpbioBlastBlockHolding BBBH
	LEFT JOIN BhpbioBlastBlockModelHolding BBBMH
		ON (BBBH.BlockId = BBBMH.BlockId)
	INNER JOIN BhpbioImportBlockFailure BIBF
		 ON ( BIBF.Site = BBBH.Site
			AND BIBF.Pit = Coalesce(BBBH.MQ2PitCode, BBBH.Pit)
			AND BIBF.Bench = BBBH.Bench
			AND BIBF.PatternNumber = BBBH.PatternNumber
			AND BIBF.BlockName = BBBH.BlockName
			)
WHERE cast(BIBF.blockeddate as datetime) < '01-jan-2008'

