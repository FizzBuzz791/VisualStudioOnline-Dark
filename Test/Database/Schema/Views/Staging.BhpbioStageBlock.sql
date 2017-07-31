
IF Object_Id('Staging.BhpbioStageBlock') IS NOT NULL
	DROP VIEW Staging.BhpbioStageBlock
GO

/****** Object:  View [import].[BhpbioStageBlock]    Script Date: 10/03/2014 16:02:02 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [Staging].[BhpbioStageBlock]
AS
SELECT
	[BlockId], 
	[BlockExternalSystemId], 
	[BlockNumber], 
	[BlockName], 
	[LithologyTypeName] as GeoType, 
	[BlockedDate], 
	[BlastedDate], 
	
	[Site],
	[Orebody], 
	[Pit],
	[Bench],
	[PatternNumber], 

	[AlternativePitCode] as MQ2PitCode,
	
	[CentroidX] as CentroidEasting, 
	[CentroidY] as CentroidNorthing,
    [CentroidZ] as CentroidRL
FROM [Staging].[StageBlock]


GO
