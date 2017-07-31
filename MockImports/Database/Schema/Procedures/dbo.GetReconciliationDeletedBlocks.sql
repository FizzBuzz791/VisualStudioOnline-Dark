USE [ReconcilorImportMockWS]
GO

/****** Object:  StoredProcedure [dbo].[GetReconciliationDeletedBlocks]    Script Date: 07/11/2013 11:34:44 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetReconciliationDeletedBlocks]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GetReconciliationDeletedBlocks]
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
CREATE PROCEDURE GetReconciliationDeletedBlocks 
	@iStartDate Datetime,
	@iEndDate Datetime
AS
BEGIN
	SET NOCOUNT ON;

	-- Blocks
	Select Id, Number, Name
	From dbo.Blocks
	Where 
	IsDelete = 1
	and
	(
	LastModifiedDate Between @iStartDate And @iEndDate
	)

	-- Patterns
	Select b.Id As BlockId, p.[Site], p.Orebody, p.Pit, p.Bench, p.Number
	From dbo.Patterns p
	Inner Join dbo.Blocks b
	On p.Id = b.PatternId
	Where 
	b.IsDelete = 1
	AND
	(
	LastModifiedDate Between @iStartDate And @iEndDate
	)

END
GO
