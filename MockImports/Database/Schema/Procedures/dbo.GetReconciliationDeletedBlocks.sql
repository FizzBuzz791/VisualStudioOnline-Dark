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

GRANT EXECUTE ON dbo.GetReconciliationDeletedBlocks TO public
GO