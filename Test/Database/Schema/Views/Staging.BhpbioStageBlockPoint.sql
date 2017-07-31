IF Object_Id('Staging.BhpbioStageBlockPoint') IS NOT NULL
	DROP VIEW Staging.BhpbioStageBlockPoint
GO

/****** Object:  View [import].[BhpbioStageBlockPoint]    Script Date: 10/03/2014 16:03:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [Staging].[BhpbioStageBlockPoint]
AS
SELECT
	BlockID,
	Number,
	X as [Easting],
	Y as [Northing],
	Z as [RL]
FROM [Staging].[StageBlockPoint]


GO
