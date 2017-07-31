
DELETE BBBMGH
--SELECT *
FROM BhpbioBlastBlockHolding BBBH
	INNER JOIN BhpbioBlastBlockModelHolding BBBMH
		ON (BBBH.BlockId = BBBMH.BlockId)
	INNER JOIN BhpbioBlastBlockModelGradeHolding BBBMGH
		ON (BBBMH.BlockId = BBBMGH.BlockId
			AND BBBMH.ModelName = BBBMGH.ModelName
			AND BBBMH.ModelOreType = BBBMGH.ModelOreType)
WHERE BBBH.BlockedDate < '01-Jan-2008'
	AND BBBMH.ModelTonnes <= 0

DELETE BBBMH
--SELECT *
FROM BhpbioBlastBlockHolding BBBH
	INNER JOIN BhpbioBlastBlockModelHolding BBBMH
		ON (BBBH.BlockId = BBBMH.BlockId)
WHERE BBBH.BlockedDate < '01-Jan-2008'
	AND BBBMH.ModelTonnes <= 0

DELETE BBBPH
--SELECT *
FROM BhpbioBlastBlockHolding BBBH
	LEFT JOIN BhpbioBlastBlockModelHolding BBBMH
		ON (BBBH.BlockId = BBBMH.BlockId)
	INNER JOIN BhpbioBlastBlockPointHolding BBBPH
		ON (BBBH.BlockId = BBBPH.BlockId)
WHERE BBBH.BlockedDate < '01-Jan-2008'
	AND BBBMH.BlockId IS NULL

DELETE BBBH
--SELECT *
FROM BhpbioBlastBlockHolding BBBH
	LEFT JOIN BhpbioBlastBlockModelHolding BBBMH
		ON (BBBH.BlockId = BBBMH.BlockId)
WHERE BBBH.BlockedDate < '01-Jan-2008'
	AND BBBMH.BlockId IS NULL

