USE [ReconcilorImportMockWS]
GO

/****** Object:  StoredProcedure [dbo].[GetStockpiles]    Script Date: 07/11/2013 11:34:44 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetStockpiles]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GetStockpiles]
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
CREATE PROCEDURE GetStockpiles 
	@iMineSiteCode nvarchar(50)
AS
BEGIN
	SET NOCOUNT ON;

	-- Stockpiles
	Select Mine, s.Name, BusinessId, StockpileType, Description, OreType, Type, Active, StartDate, ProductSize
	From dbo.Stockpiles s
	Inner Join dbo.Locations l
	On s.LocationId = l.Id
	Where l.Mine = @iMineSiteCode

END
GO
