USE [ReconcilorImportMockWS]
GO

/****** Object:  StoredProcedure [dbo].[GetReconciliationMovements]    Script Date: 07/11/2013 11:34:44 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetReconciliationMovements]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GetReconciliationMovements]
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
CREATE PROCEDURE GetReconciliationMovements 
	@iStartDate Datetime,
	@iEndDate Datetime
AS
BEGIN
	SET NOCOUNT ON;

	-- Blocks
	Select Id, Number, Name, LastModifiedDate, LastModifiedUser
	From dbo.Blocks
	Where BlastedDate Between @iStartDate And @iEndDate
	Or BlockedDate Between @iStartDate And @iEndDate

	-- Patterns
	Select b.Id As BlockId, p.[Site], p.Orebody, p.Pit, p.Bench, p.Number
	From dbo.Patterns p
	Inner Join dbo.Blocks b
	On p.Id = b.PatternId
	Where BlastedDate Between @iStartDate And @iEndDate
	Or BlockedDate Between @iStartDate And @iEndDate
	
	-- Movements
	Select b.Id As BlockId, m.DateFrom, m.DateTo, m.LastModifiedDate, m.LastModifiedUser, m.MinedPercentage
	From dbo.Movements m
	Inner Join dbo.Blocks b
	On m.BlockId = b.Id
	Where BlastedDate Between @iStartDate And @iEndDate
	Or BlockedDate Between @iStartDate And @iEndDate
END
GO
