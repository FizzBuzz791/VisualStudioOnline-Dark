DECLARE @minDateTime DateTime
SET @minDateTime = '2013-07-01'

DECLARE @site VARCHAR(max)
DECLARE @pit VARCHAR(max)
DECLARE @bench VARCHAR(max)
DECLARE @patternnumber VARCHAR(max)

SET @site = 'OB18'
SET @pit = '18SP'
SET @bench = '0599'
SET @patternnumber = '0820'

SELECT 'You need to cross check the data in the following 2 sets manually (for now).'

SELECT 'CountBlocks' as Statistic, COUNT(*) as Value
FROM BhpbioBlastBlockHolding block
WHERE BlockedDate >= @minDateTime
AND block.site = @site
AND block.mq2pitcode = @pit
AND block.bench = @bench
AND block.patternnumber = @patternnumber
Union
SELECT 'MaxBlockId' as Statistic, Max(BlockId) as Value
FROM BhpbioBlastBlockHolding block
WHERE block.site = @site
AND block.mq2pitcode = @pit
AND block.bench = @bench
AND block.patternnumber = @patternnumber
Union
SELECT 'CountModelBlocks' as Statistic, COUNT(*) as Value
FROM BhpbioBlastBlockModelHolding bbmh
INNER JOIN BhpbioBlastBlockHolding block ON block.BlockId = bbmh.BlockId
WHERE block.BlockedDate >= @minDateTime
AND block.site = @site
AND block.mq2pitcode = @pit
--AND block.BlockId BETWEEN @minHoldingBlockId and @maxHoldingBlockId
AND block.bench = @bench
AND block.patternnumber = @patternnumber
Union
SELECT 'ModelTonnes', Sum(bbmh.ModelTonnes)
FROM dbo.BhpbioBlastBlockModelHolding bbmh
INNER JOIN BhpbioBlastBlockHolding block ON block.BlockId = bbmh.BlockId
WHERE block.BlockedDate >= @minDateTime
	AND block.site = @site
	AND block.mq2pitcode = @pit
	AND block.bench = @bench
	AND block.patternnumber = @patternnumber
Union
SELECT 'ModelVolume', Sum(ModelVolume)
FROM dbo.BhpbioBlastBlockModelHolding bbmh
INNER JOIN BhpbioBlastBlockHolding block ON block.BlockId = bbmh.BlockId
WHERE block.BlockedDate >= @minDateTime
	AND block.site = @site
	AND block.mq2pitcode = @pit
	AND block.bench = @bench
	AND block.patternnumber = @patternnumber
Union
SELECT 'ModelCalculatedVolume', Sum(ModelDensity * ModelTonnes)
FROM dbo.BhpbioBlastBlockModelHolding bbmh
INNER JOIN BhpbioBlastBlockHolding block ON block.BlockId = bbmh.BlockId
WHERE block.BlockedDate >= @minDateTime
	AND block.site = @site
	AND block.mq2pitcode = @pit
	AND block.bench = @bench
	AND block.patternnumber = @patternnumber
Union
SELECT 'ModelLumpTonnes', Sum(ModelTonnes * LumpPercent) 
FROM dbo.BhpbioBlastBlockModelHolding bbmh
INNER JOIN BhpbioBlastBlockHolding block ON block.BlockId = bbmh.BlockId
WHERE block.BlockedDate >= @minDateTime
	AND block.site = @site
	AND block.mq2pitcode = @pit
	AND block.bench = @bench
	AND block.patternnumber = @patternnumber
UNION
SELECT 'NumberOfPoints', Count(*)
FROM dbo.BhpbioBlastBlockPointHolding bbph
INNER JOIN BhpbioBlastBlockHolding block ON block.BlockId = bbph.BlockId
WHERE block.BlockedDate >= @minDateTime
AND block.site = @site
AND block.mq2pitcode = @pit
AND block.bench = @bench
AND block.patternnumber = @patternnumber
Union
SELECT 'FeUnits', Sum(bbmh.ModelTonnes * gh.GradeValue)
FROM dbo.BhpbioBlastBlockModelHolding bbmh
INNER JOIN BhpbioBlastBlockHolding block ON block.BlockId = bbmh.BlockId
INNER JOIN BhpbioBlastBlockModelGradeHolding gh 
	ON gh.BlockId = bbmh.BlockId 
	and gh.ModelName = bbmh.ModelName
	and gh.ModelOreType = bbmh.ModelOreType
	and gh.GradeName = 'fe'
WHERE block.BlockedDate >= @minDateTime
	AND block.site = @site
	AND block.mq2pitcode = @pit
	AND block.bench = @bench
	AND block.patternnumber = @patternnumber
Union
SELECT 'LumpFeUnits', Sum(bbmh.ModelTonnes * bbmh.LumpPercent * gh.LumpValue)
FROM dbo.BhpbioBlastBlockModelHolding bbmh
INNER JOIN BhpbioBlastBlockHolding block ON block.BlockId = bbmh.BlockId
INNER JOIN BhpbioBlastBlockModelGradeHolding gh 
	ON gh.BlockId = bbmh.BlockId 
	and gh.ModelName = bbmh.ModelName
	and gh.ModelOreType = bbmh.ModelOreType
	and gh.GradeName = 'fe'
WHERE block.BlockedDate >= @minDateTime
	AND block.site = @site
	AND block.mq2pitcode = @pit
	AND block.bench = @bench
	AND block.patternnumber = @patternnumber
Union
SELECT 'FinesFeUnits', Sum(bbmh.ModelTonnes * (1 - bbmh.LumpPercent) * gh.FinesValue)
FROM dbo.BhpbioBlastBlockModelHolding bbmh
INNER JOIN BhpbioBlastBlockHolding block ON block.BlockId = bbmh.BlockId
INNER JOIN BhpbioBlastBlockModelGradeHolding gh 
	ON gh.BlockId = bbmh.BlockId 
	and gh.ModelName = bbmh.ModelName
	and gh.ModelOreType = bbmh.ModelOreType
	and gh.GradeName = 'fe'
WHERE block.BlockedDate >= @minDateTime
	AND block.site = @site
	AND block.mq2pitcode = @pit
	AND block.bench = @bench
	AND block.patternnumber = @patternnumber

SELECT COUNT(*) as ModelBlockCount, 
		Sum(mbp.Tonnes) as ModelTonnes, 
		Sum(mbp.Tonnes * blp.LumpPercent) as LumpTonnes, 
		Sum(mbp.Tonnes * (1 - blp.LumpPercent)) as FinesTonnes, 
		Sum(mbpg.Grade_Value * mbp.Tonnes) as FeUnits,  
		Sum(bblf.LumpValue * mbp.Tonnes * blp.LumpPercent) as LumpFeUnits,
		Sum(bblf.FinesValue * mbp.Tonnes * (1 - blp.LumpPercent)) as FinesFeUnits
FROM ModelBlock mb
	INNER JOIN ModelBlockPartial mbp 
		ON mbp.Model_Block_Id = mb.Model_Block_Id
	LEFT JOIN dbo.BhpbioBlastBlockLumpPercent blp 
		ON blp.ModelBlockId = mb.Model_Block_Id
	LEFT JOIN ModelBlockPartialGrade mbpg 
		ON mbpg.Model_Block_Id = mbp.Model_Block_Id and mbpg.Sequence_No = mbp.Sequence_No
		AND mbpg.Grade_Id = 1 -- fe only
	LEFT JOIN dbo.BhpbioBlastBlockLumpFinesGrade bblf 
		ON bblf.ModelBlockId = mbp.Model_Block_Id and bblf.SequenceNo = mbp.Sequence_No
		AND bblf.GradeId = 1 -- fe only
	INNER JOIN DigblockModelBlock dmb 
		ON dmb.Model_block_Id = mb.Model_Block_Id
	INNER JOIN Digblock d 
		ON d.Digblock_Id = dmb.Digblock_Id
	INNER JOIN DigblockLocation dl 
		ON dl.Digblock_Id = d.Digblock_Id
	INNER JOIN Location l 
		ON l.Location_Id = dl.Location_Id
	INNER JOIN Location blast 
		ON blast.Location_Id = l.Parent_Location_Id
	INNER JOIN Location bench ON bench.Location_Id = blast.Parent_Location_Id
	INNER JOIN Location pit ON pit.Location_Id = bench.Parent_Location_Id
	INNER JOIN Location site ON site.Location_Id = pit.Parent_Location_Id
WHERE d.Creation_datetime >= @minDateTime
AND site.Name = @site
AND pit.Name = @pit
AND mb.code like @pit + '-' + @bench + '-' + @patternnumber + '%'

--SELECT TOP 100 * FROM ImportSyncRow WHERE ImportId = 1 ORDER BY 1 DESC

--SELECT TOP 10 * FROM ModelBlock ORDER BY 1 DESC
--SELECT TOP 10 * FROM ModelBlockPartial ORDER BY 1 DESC
--SELECT TOP 10 * FROM ModelBlockPartialGrade ORDER BY 1 DESC
--SELECT TOP 10 * FROM dbo.BhpbioBlastBlockLumpPercent ORDER BY 1 DESC
--SELECT TOP 12 * FROM dbo.BhpbioBlastBlockLumpFinesGrade ORDER BY 1 DESC
--SELECT TOP 100 * FROM ImportSyncValidate ORDER BY 1 DESC