--Need to turn on identity insert
SET IDENTITY_INSERT Staging.StageBlock ON

INSERT INTO Staging.StageBlock
(
	BlockId, BlockExternalSystemId, BlockNumber, BlockName, BlockFullName,
	LithologyTypeName, BlockedDate, BlastedDate,
	[Site],	OreBody, Pit, Bench, PatternNumber,
	AlternativePitCode, CentroidX, CentroidY, CentroidZ, LastMessageTimestamp
)
Select BlockId As BlockId,
	NULL as BlockExternalSystemId,
	BlockNumber As BlockNumber,
	BlockName As BlockName,
	COALESCE(MQ2PitCode,Pit) + '-' + Bench + '-' + PatternNumber + '-' + BlockName As BlockFullName,
	GeoType as LithologyTypeName,
	BlockedDate As BlockedDate,
	BlastedDate as BlastedDate,
	[Site],
	OreBody,
	Pit,
	Bench,
	PatternNumber,
	MQ2PitCode As AlternativePitCode,
	CentroidEasting As CentroidX,
	CentroidNorthing As CentroidY,
	CentroidRL As CentroidZ,
	Null As LastMessageTimestamp
From dbo.BhpbioBlastBlockHolding 
Order by BlockId

SET IDENTITY_INSERT Staging.StageBlock OFF
GO


Insert Into Staging.StageBlockModel
(
	BlockId, BlockModelName, MaterialTypeName,
	OpeningVolume, OpeningTonnes, OpeningDensity,
	LastModifiedUser, LastModifiedDate,
	LumpPercent, ModelFilename
)
Select BlockId As BlockId,
	ModelName AS BlockModelName,
	ModelOreType As MaterialTypeName,
	ModelVolume As OpeningVolume,
	ModelTonnes As OpeningTonnes,
	ModelDensity As OpeningDensity,
	LastModifiedUser As LastModifiedUser,
	LastModifiedDate As LastModifiedDate,
	LumpPercent As LumpPercent,
	ModelFileName As ModelFileName
From dbo.BhpbioBlastBlockModelHolding
Order by BlockId
Go

Insert Into Staging.StageBlockModelGrade
(
	BlockModelId, 
	GradeName, GradeValue, LumpValue, FinesValue
)
Select  
	m.BlockModelId as BlockModelId,
	g.GradeName As GradeName,
	g.GradeValue As GradeValue,
	g.LumpValue As LumpValue,
	g.FinesValue As FinesValue
From dbo.BhpbioBlastBlockModelGradeHolding g
	Inner Join Staging.StageBlockModel m 
		On m.BlockId = g.BlockId 
			And m.BlockModelName = g.ModelName 
			And m.MaterialTypeName = g.ModelOreType
Order by m.BlockModelId 
Go

Insert Into Staging.StageBlockPoint
(
	BlockId,
	Number, X, Y, Z
)
Select BlockId As BlockId,
	Number As Number,
	Easting As X,
	Northing As Y,
	RL As Z
From dbo.BhpbioBlastBlockPointHolding
Order by BlockId
Go
