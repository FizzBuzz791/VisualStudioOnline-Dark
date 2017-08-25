
IF Object_Id('Staging.BhpbioStageBlockModel') IS NOT NULL
	DROP VIEW Staging.BhpbioStageBlockModel
GO


/****** Object:  View [import].[BhpbioStageBlockModel]    Script Date: 10/03/2014 16:02:39 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [Staging].[BhpbioStageBlockModel]
AS
SELECT
	m.[BlockId],
	b.[BlockExternalSystemId],
	m.[BlockModelName] as ModelName,
	m.[MaterialTypeName] as ModelOreType,
	m.[OpeningVolume] as ModelVolume,
	m.[OpeningTonnes] as ModelTonnes,
	m.[OpeningDensity] as ModelDensity,
	m.[LastModifiedUser],
	m.[LastModifiedDate],
	m.[ModelFilename],
	m.LumpPercentAsDropped,
	m.LumpPercentAsShipped,
	m.StratNum
FROM [Staging].[StageBlockModel] m
	INNER JOIN Staging.StageBlock b ON b.BlockId = m.BlockId


GO



