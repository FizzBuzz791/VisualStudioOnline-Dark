

UPDATE H
SET Pit = 'P1'
FROM BhpbioBlastBlockHolding H
Where [Site] IN ('OB23/25')
	AND MQ2PitCode IS NULL
	AND Pit = '23'
	And Orebody = '23'
and not exists (select * from BhpbioBlastBlockHolding Where site = h.site and pit = 'p1' 
				and bench = h.bench and patternnumber = h.patternnumber and blockname = h.blockname)
				
DELETE BBBMGH
--SELECT *
FROM BhpbioBlastBlockHolding BBBH
	INNER JOIN BhpbioBlastBlockModelHolding BBBMH
		ON (BBBH.BlockId = BBBMH.BlockId)
	INNER JOIN BhpbioBlastBlockModelGradeHolding BBBMGH
		ON (BBBMH.BlockId = BBBMGH.BlockId
			AND BBBMH.ModelName = BBBMGH.ModelName
			AND BBBMH.ModelOreType = BBBMGH.ModelOreType)
WHERE BBBH.[Site] IN ('OB23/25')
	AND BBBH.MQ2PitCode IS NULL
	AND BBBH.Pit = '23'
	And BBBH.Orebody = '23'

DELETE BBBMH
--SELECT *
FROM BhpbioBlastBlockHolding BBBH
	INNER JOIN BhpbioBlastBlockModelHolding BBBMH
		ON (BBBH.BlockId = BBBMH.BlockId)
WHERE BBBH.[Site] IN ('OB23/25')
	AND BBBH.MQ2PitCode IS NULL
	AND BBBH.Pit = '23'
	And BBBH.Orebody = '23'

DELETE BBBPH
--SELECT *
FROM BhpbioBlastBlockHolding BBBH
	LEFT JOIN BhpbioBlastBlockModelHolding BBBMH
		ON (BBBH.BlockId = BBBMH.BlockId)
	INNER JOIN BhpbioBlastBlockPointHolding BBBPH
		ON (BBBH.BlockId = BBBPH.BlockId)
WHERE BBBH.[Site] IN ('OB23/25')
	AND BBBH.MQ2PitCode IS NULL
	AND BBBH.Pit = '23'
	And BBBH.Orebody = '23'

DELETE BBBH
--SELECT *
FROM BhpbioBlastBlockHolding BBBH
	LEFT JOIN BhpbioBlastBlockModelHolding BBBMH
		ON (BBBH.BlockId = BBBMH.BlockId)
WHERE BBBH.[Site] IN ('OB23/25')
	AND BBBH.MQ2PitCode IS NULL
	AND BBBH.Pit = '23'
	And BBBH.Orebody = '23'



UPDATE H
SET MQ2PitCode = Orebody + Pit
FROM BhpbioBlastBlockHolding H
Where [Site] IN ('OB23/25', 'OB18', 'JIMBLEBAR')
	AND MQ2PitCode IS NULL
	AND Pit <> 'JB'
and not exists (select * from BhpbioBlastBlockHolding Where site = h.site and pit = h.pit
				and bench = h.bench and patternnumber = h.patternnumber and blockname = h.blockname and blockid <> h.blockid)
				