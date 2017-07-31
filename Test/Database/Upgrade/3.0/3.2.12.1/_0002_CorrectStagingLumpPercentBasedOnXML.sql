
PRINT 'Extracting Message data'

IF Object_Id('Staging.TmpLumpPercentCorrection') IS NOT NULL
	DROP TABLE Staging.TmpLumpPercentCorrection
GO

CREATE TABLE Staging.TmpLumpPercentCorrection (
	[TimeStamp] DATETIME,
	IsReblockOut BIT,
	Bench VARCHAR(6),
	PitId_MQ2 VARCHAR(50),
	PitId_Log VARCHAR(50),
	PitId_Phy VARCHAR(50),
	PatternNumber VARCHAR(50),
	PatternGUID VARCHAR(50),
	FlitchGUID VARCHAR(50),
	Name VARCHAR(50),
	BlockNumber VARCHAR(6),
	ChangeState VARCHAR(20),
	OreType VARCHAR(10),
	Designation VARCHAR(10),
	GradeSetType VARCHAR(10),
	QualityType VARCHAR(10),
	QualityTypeSplitPercentage FLOAT,
	BlockFullName VARCHAR(50),
	BlockId INTEGER,
	BlockModelId INTEGER,
	IsLatest BIT
)

/*
	ev.value('Timestamp[1]', 'datetime') as [Timestamp],
	  ev.value('IsReblockOut[1]', 'bit') as IsReblockOut,
	  pd.value('Bench[1]', 'varchar(6)') as Bench,
	  pd.value('PitId_MQ2[1]', 'varchar(50)') as PitId_MQ2,
	  pd.value('PitId_Log[1]', 'varchar(50)') as PitId_Log,
	  pd.value('PitId_Phy[1]', 'varchar(50)') as PitId_Phy,
	  pd.value('PatternNumber[1]', 'varchar(6)') as PatternNumber,
	  pd.value('PatternGUID[1]', 'varchar(50)') as PatternGUID,
	  bl.value('FlitchGUID[1]', 'varchar(50)') as FlitchGUID,
	  bl.value('Name[1]', 'varchar(50)') as Name,
	  bl.value('BlockNumber[1]', 'varchar(50)') as BlockNumber,
	  bl.value('ChangeState[1]', 'varchar(50)') as ChangeState,
	  mb.value('OreType[1]', 'varchar(50)') as OreType,
	  mb.value('Designation[1]', 'varchar(50)') as Designation,
	  gs.value('GradeSetType[1]', 'varchar(50)') as GradeSetType,
	  qs.value('QualityType[1]', 'varchar(50)') as QualityType,
	  qs.value('QualityTypeSplitPercentage[1]', 'float') as QualityTypeSplitPercentage
*/

 DECLARE @id INTEGER
 SELECT @id = MIN(Id) FROM Staging.MessageLog
 
 DECLARE @message NVARCHAR(max)

 WHILE NOT @id IS NULL
 BEGIN
	
	SELECT @message = [Message] FROM Staging.MessageLog WHERE Id = @id
	DECLARE @xml XML
	SET @xml = convert(XML,@message)
	
	-- THE XML Structure has this form
		--BlockOutAndBlastedEvent
			--Timestamp
			--IsReblockOut
			--PatternDetails
				--Bench
				--PitId_MQ2
				--PitId_Log
				--PitId_Phy
				--PatternNumber
				--PatternGUID
				--Block
					--FlitchGUID
					--Name
					--BlockNumber
					--ChangeState
					--ModelBlock
						--OreType
						--Designation
						--GradeSet
							--GradeSetType
							--QualitySet
								--QualityType
								--QualityTypeSplitPercentage

	INSERT INTO Staging.TmpLumpPercentCorrection (
		[TimeStamp],
		IsReblockOut,
		Bench,
		PitId_MQ2,
		PitId_Log,
		PitId_Phy,
		PatternNumber,
		PatternGUID,
		FlitchGUID,
		Name,
		BlockNumber,
		ChangeState,
		OreType,
		Designation,
		GradeSetType,
		QualityType,
		QualityTypeSplitPercentage
	)
	select
	  ev.value('Timestamp[1]', 'datetime') as [Timestamp],
	  ev.value('IsReblockOut[1]', 'bit') as IsReblockOut,
	  pd.value('Bench[1]', 'varchar(6)') as Bench,
	  pd.value('PitId_MQ2[1]', 'varchar(50)') as PitId_MQ2,
	  pd.value('PitId_Log[1]', 'varchar(50)') as PitId_Log,
	  pd.value('PitId_Phy[1]', 'varchar(50)') as PitId_Phy,
	  pd.value('PatternNumber[1]', 'varchar(6)') as PatternNumber,
	  pd.value('PatternGUID[1]', 'varchar(50)') as PatternGUID,
	  bl.value('FlitchGUID[1]', 'varchar(50)') as FlitchGUID,
	  bl.value('Name[1]', 'varchar(50)') as Name,
	  bl.value('BlockNumber[1]', 'varchar(50)') as BlockNumber,
	  bl.value('ChangeState[1]', 'varchar(50)') as ChangeState,
	  mb.value('OreType[1]', 'varchar(50)') as OreType,
	  mb.value('Designation[1]', 'varchar(50)') as Designation,
	  gs.value('GradeSetType[1]', 'varchar(50)') as GradeSetType,
	  qs.value('QualityType[1]', 'varchar(50)') as QualityType,
	  qs.value('QualityTypeSplitPercentage[1]', 'float') as QualityTypeSplitPercentage
	from
	  @xml.nodes('/*[local-name()=''BlockOutAndBlastedEvent'']') ev(ev)
	  cross apply ev.nodes('PatternDetails') pd(pd)
	  cross apply pd.nodes('Block') bl(bl)
	  cross apply bl.nodes('ModelBlock') mb(mb)
	  cross apply mb.nodes('GradeSet') gs(gs)
	  cross apply gs.nodes('QualitySet') qs(qs)

	-- get the next id
	SELECT @id = MIN(Id) FROM Staging.MessageLog WHERE Id > @id
 END
 GO

PRINT 'Finished extracting message data, performing staging update'

BEGIN TRANSACTION
	UPDATE lpc
	SET
		 BlockFullName = IsNull(PitId_MQ2, PitId_Log) + '-' + right('0000' + Bench, 4) + '-' + right('0000' + PatternNumber, 4) + '-' + Name
	FROM Staging.TmpLumpPercentCorrection lpc

	UPDATE lpc
	SET
		 BlockId = b.BlockId
	FROM Staging.TmpLumpPercentCorrection lpc
		INNER JOIN Staging.StageBlock b ON b.BlockFullName = lpc.BlockFullName

	UPDATE lpc
	SET
		 BlockModelId = bm.BlockModelId
	FROM Staging.TmpLumpPercentCorrection lpc
		INNER JOIN Staging.StageBlockModel bm ON bm.BlockId = lpc.BlockId AND bm.BlockModelName like 'Grade Control' AND bm.MaterialTypeName = lpc.OreType

	UPDATE lpc
	SET
		 IsLatest = 1
	FROM Staging.TmpLumpPercentCorrection lpc
		INNER JOIN 
		(
			SELECT lpc2.BlockFullName, lpc2.OreType, lpc2.QualityType, lpc2.GradeSetType,  MAX(lpc2.[Timestamp]) as MaxTimestamp
			FROM Staging.TmpLumpPercentCorrection lpc2
			WHERE lpc2.QualityTypeSplitPercentage IS NOT NULL
			GROUP BY lpc2.BlockFullName, lpc2.OreType, lpc2.QualityType, lpc2.GradeSetType
		) lts ON lts.BlockFullName = lpc.BlockFullName AND lts.OreType = lpc.OreType AND lts.QualityType = lpc.QualityType AND lts.GradeSetType = lpc.GradeSetType AND lts.MaxTimestamp = lpc.[TimeStamp]

	UPDATE bm
		SET bm.LumpPercent = lpc.QualityTypeSplitPercentage
	FROM Staging.StageBlockModel bm
	INNER JOIN Staging.TmpLumpPercentCorrection lpc ON bm.BlockModelId = lpc.BlockModelId
		AND bm.BlockModelName like 'Grade Control'
	WHERE lpc.GradeSetType = 'AS-SHIPPED' AND lpc.QualityType = 'LUMP' AND NOT lpc.QualityTypeSplitPercentage IS NULL
COMMIT TRANSACTION
GO


PRINT 'Completing staging update'
GO