USE [ReconcilorImportMockWS]
GO

/****** Object:  StoredProcedure [dbo].[GetReconciliationBlocks]    Script Date: 07/11/2013 11:34:44 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetReconciliationBlocks]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GetReconciliationBlocks]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		John Nickerson
-- Create date: 2013-07-11
-- Description:	
-- =============================================
CREATE PROCEDURE GetReconciliationBlocks 
	@iStartDate Datetime,
	@iEndDate Datetime
AS
BEGIN
	SET NOCOUNT ON;

	-- Blocks
	Select b.Id, b.Number, b.Name, b.BlockedDate, b.BlastedDate, b.PatternId, b.[MQ2PitCode], b.GeoType
	From dbo.Blocks b
	Where (
	b.LastModifiedDate Between @iStartDate And @iEndDate
	)
	And Not b.IsDelete = 1

	-- Patterns
	Select b.Id As BlockId, p.Id, p.[Site], p.Orebody, p.Pit, p.Bench, p.Number
	From dbo.Patterns p
	Inner Join dbo.Blocks b
	On p.Id = b.PatternId
	Where (
	LastModifiedDate Between @iStartDate And @iEndDate
	)
	And Not b.IsDelete = 1

	-- Models
	Select b.Id As BlockId, m.Id, m.Name, m.OreType, m.Volume, m.Tonnes, m.LumpPercent, m.Density, m.LastModifiedUser, m.LastModifiedDate, m.Filename
	From dbo.Models m
	Inner Join dbo.Blocks b
	On m.BlockId = b.Id
	Where (
	b.LastModifiedDate Between @iStartDate And @iEndDate
	)
	And Not b.IsDelete = 1

	-- Grades
	Select b.Id As BlockId, m.Id As ModelId, g.Name as GradeName, g.HeadValue, g.FinesValue, g.LumpValue
	From dbo.Grades g
	Inner Join dbo.ModelGrades mg
	On g.Id = mg.GradeId
	Inner Join dbo.Models m
	On mg.ModelId = m.Id
	Inner Join dbo.Blocks b
	On m.BlockId = b.Id
	Where 
	(
	b.LastModifiedDate Between @iStartDate And @iEndDate
	)
	And Not b.IsDelete = 1

	-- Polygon Points
	Select b.Id As BlockId, pl.Id As PolygonId, p.Number, p.Easting, p.Northing, p.RL
	From dbo.Points p
	Inner Join dbo.Polygons pl
	On p.PolygonId = pl.Id
	Inner Join dbo.Blocks b
	On pl.Id = b.PolygonId
	Where (
	b.LastModifiedDate Between @iStartDate And @iEndDate
	)
	And Not b.IsDelete = 1

	-- Polygon Centroid
	Select b.Id As BlockId, pl.Id, CentroidEasting, CentroidNorthing, CentroidRL
	From dbo.Polygons pl
	Inner Join dbo.Blocks b
	On pl.Id = b.PolygonId
	Where (
	b.LastModifiedDate Between @iStartDate And @iEndDate
	)
	And Not b.IsDelete = 1

END
GO
