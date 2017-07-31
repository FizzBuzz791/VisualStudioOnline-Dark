IF Object_Id('Staging.BhpbioStageBlockModelGrade') IS NOT NULL
	DROP VIEW Staging.BhpbioStageBlockModelGrade
GO

/****** Object:  View [import].[BhpbioStageBlockModelGrade]    Script Date: 10/03/2014 16:02:23 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [Staging].[BhpbioStageBlockModelGrade]
AS
SELECT
	m.[BlockId],
	m.[BlockModelName] as ModelName,
	m.[MaterialTypeName] as ModelOreType,
	g.[GradeName],
	g.[GradeValue],
	g.[LumpValue],
	g.[FinesValue],
	g.GeometType
FROM [Staging].[StageBlockModelGrade] g
	INNER JOIN [Staging].[StageBlockModel] m ON m.BlockModelId = g.BlockModelId

GO


