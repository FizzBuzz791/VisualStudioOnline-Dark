USE [ReconcilorImportMockWS]
GO

/****** Object:  StoredProcedure [dbo].[GetStockpileAdjustments]    Script Date: 08/23/2013 13:52:34 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetStockpileAdjustments]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GetStockpileAdjustments]
GO

USE [ReconcilorImportMockWS]
GO

/****** Object:  StoredProcedure [dbo].[GetStockpileAdjustments]    Script Date: 08/23/2013 13:52:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Alex Barmouta
-- Create date: 2013-08-27
-- Description:	
-- =============================================
CREATE PROCEDURE [dbo].[GetStockpileAdjustments] 
	@iMineSiteCode nvarchar(50),
	@iStartDate Datetime,
	@iEndDate Datetime
AS
BEGIN
	SET NOCOUNT ON;
	
	-- Adjustments
	Select a.StockpileAdjustmentId, l.Mine, a.StockpileName, a.AdjustmentType, a.AdjustmentDate, a.Tonnes, a.FinesPercent, a.LumpPercent, a.Bcm, a.LastModifiedTime
	From dbo.StockpileAdjustment a
		Inner Join dbo.Locations l
		On a.LocationId = l.Id
	Where l.Mine = @iMineSiteCode
		And a.AdjustmentDate Between @iStartDate And @iEndDate
	
	-- Grades
	Select a.StockpileAdjustmentId, sg.GradeName, sg.HeadValue
	From dbo.StockpileAdjustmentGrade sg
		Inner Join dbo.StockpileAdjustment a
			On sg.StockpileAdjustmentId = a.StockpileAdjustmentId
		Inner Join dbo.Locations l
			On a.LocationId = l.Id
	Where l.Mine = @iMineSiteCode
		And a.AdjustmentDate Between @iStartDate And @iEndDate
END

GO

