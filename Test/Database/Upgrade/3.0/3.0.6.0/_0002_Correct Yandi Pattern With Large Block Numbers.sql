
-- CORRECT THE TRUNACTION ISSUE
-- FOR THE YANDI PATTERN WITH LARGE NUMBERS
-- BlockNames ###


-- PATTERN:	 YN W1 0594 0372
	--    BlockNames ###
	UPDATE sb
	SET BlockNumber = CONVERT(int, BlockName)
		FROM Staging.BhpbioStageBlock sb
	WHERE Site = 'YANDI' AND Pit = 'W1' AND PatternNumber  = '0372'
		AND BlockName like '1%' And LEN(BlockName) =3

	--    BlockNames W####
	UPDATE sb
		SET BlockNumber = CONVERT(int, Right(BlockName,3))
	FROM Staging.BhpbioStageBlock sb
	WHERE Site = 'YANDI' AND Pit = 'W1' AND PatternNumber  = '0372'
		AND BlockName like 'W1%' And LEN(BlockName) =4


-- PATTERN:	 YN W5 0558 0014
	UPDATE sb
	SET BlockNumber = CONVERT(int, BlockName)
		FROM Staging.BhpbioStageBlock sb
	WHERE Site = 'YANDI' AND Pit = 'W5' AND PatternNumber  = '0014'
		AND BlockName like '1%' And LEN(BlockName) =3
		
		
-- PATTERN:	 YN W1 0600 0328		
	UPDATE sb
	SET BlockNumber = CONVERT(int, BlockName)
		FROM Staging.BhpbioStageBlock sb
	WHERE Site = 'YANDI' AND Pit = 'W1' AND PatternNumber  = '0328'
		AND BlockName like '1%' And LEN(BlockName) =3
