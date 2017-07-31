DECLARE @minDateTime DateTime
SET @minDateTime = '2014-07-01'

SELECT 'CountBlocks' as Statistic, COUNT(*) as Value
FROM BhpbioBlastBlockHolding
WHERE BlockedDate >= @minDateTime
Union
SELECT 'MaxBlockId' as Statistic, Max(BlockId) as Value
FROM BhpbioBlastBlockHolding bbh
Union
SELECT 'CountModelBlocks' as Statistic, COUNT(*) as Value
FROM BhpbioBlastBlockModelHolding bbmh
INNER JOIN BhpbioBlastBlockHolding block ON block.BlockId = bbmh.BlockId
WHERE block.BlockedDate >= @minDateTime
Union
SELECT 'ModelTonnes', Sum(bbmh.ModelTonnes)
FROM dbo.BhpbioBlastBlockModelHolding bbmh
INNER JOIN BhpbioBlastBlockHolding block ON block.BlockId = bbmh.BlockId
WHERE block.BlockedDate >= @minDateTime
Union
SELECT 'ModelVolume', Sum(ModelVolume)
FROM dbo.BhpbioBlastBlockModelHolding bbmh
INNER JOIN BhpbioBlastBlockHolding block ON block.BlockId = bbmh.BlockId
WHERE block.BlockedDate >= @minDateTime
Union
SELECT 'ModelCalculatedVolume', Sum(ModelDensity * ModelTonnes)
FROM dbo.BhpbioBlastBlockModelHolding bbmh
INNER JOIN BhpbioBlastBlockHolding block ON block.BlockId = bbmh.BlockId
WHERE block.BlockedDate >= @minDateTime
Union
SELECT 'ModelLumpTonnes', Sum(ModelTonnes * LumpPercent) 
FROM dbo.BhpbioBlastBlockModelHolding bbmh
INNER JOIN BhpbioBlastBlockHolding block ON block.BlockId = bbmh.BlockId
WHERE block.BlockedDate >= @minDateTime
UNION
SELECT 'NumberOfPoints', Count(*)
FROM dbo.BhpbioBlastBlockPointHolding bbph
INNER JOIN BhpbioBlastBlockHolding block ON block.BlockId = bbph.BlockId
WHERE block.BlockedDate >= @minDateTime
Union
SELECT 'ModelFeUnits', Sum(bbmh.ModelTonnes * (1 - bbmh.LumpPercent) * gh.FinesValue)
FROM dbo.BhpbioBlastBlockModelHolding bbmh
INNER JOIN BhpbioBlastBlockHolding block ON block.BlockId = bbmh.BlockId
INNER JOIN BhpbioBlastBlockModelGradeHolding gh 
	ON gh.BlockId = bbmh.BlockId 
	and gh.ModelName = bbmh.ModelName
	and gh.ModelOreType = bbmh.ModelOreType
	and gh.GradeName = 'fe'
WHERE block.BlockedDate >= @minDateTime
Union
SELECT 'LumpFeUnits',Sum(bbmh.ModelTonnes * bbmh.LumpPercent * gh.LumpValue)
FROM dbo.BhpbioBlastBlockModelHolding bbmh
INNER JOIN BhpbioBlastBlockHolding block ON block.BlockId = bbmh.BlockId
INNER JOIN BhpbioBlastBlockModelGradeHolding gh 
	ON gh.BlockId = bbmh.BlockId 
	and gh.ModelName = bbmh.ModelName
	and gh.ModelOreType = bbmh.ModelOreType
	and gh.GradeName = 'fe'
WHERE block.BlockedDate >= @minDateTime
Union
SELECT 'FinesFeUnits', Sum(bbmh.ModelTonnes * gh.FinesValue)
FROM dbo.BhpbioBlastBlockModelHolding bbmh
INNER JOIN BhpbioBlastBlockHolding block ON block.BlockId = bbmh.BlockId
INNER JOIN BhpbioBlastBlockModelGradeHolding gh 
	ON gh.BlockId = bbmh.BlockId 
	and gh.ModelName = bbmh.ModelName
	and gh.ModelOreType = bbmh.ModelOreType
	and gh.GradeName = 'fe'
WHERE block.BlockedDate >= @minDateTime