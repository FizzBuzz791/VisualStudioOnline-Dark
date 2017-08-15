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

GRANT EXECUTE ON dbo.GetReconciliationMovements TO public
GO