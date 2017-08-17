-- =============================================
-- Author:		John Nickerson
-- Create date: 2013-07-11
-- Description:	
-- =============================================
CREATE PROCEDURE GetProductionMovements
	@iMineSiteCode nvarchar(50),
	@iStartDate Datetime,
	@iEndDate Datetime
AS
BEGIN
	SET NOCOUNT ON;

	-- Transactions (i.e. weightometer based measure points)
	Select t.Id,
		l.Mine,
		t.TransactionDate,
		t.Source,
		t.SourceType,
		t.Destination,
		t.DestinationType,
		t.Type,
		t.SourceMineSite,
		t.DestinationMineSite,
		t.Tonnes,
		t.ProductSize,
		t.SampleSource,
		t.SampleTonnes,
		t.SampleCount
	From dbo.Transactions t Inner Join dbo.Locations l On t.LocationId = l.Id
	Where t.TransactionDate Between @iStartDate And @iEndDate
	And (t.SourceMineSite = @iMineSiteCode Or t.DestinationMineSite = @iMineSiteCode)

	-- Grades
	Select t.Id As TransactionId, tg.GradeName, tg.HeadValue
	From	dbo.TransactionGrades tg Inner Join dbo.Transactions t On tg.TransactionId = t.Id
	
	Where	t.TransactionDate Between @iStartDate And @iEndDate
	And		(t.SourceMineSite = @iMineSiteCode Or t.DestinationMineSite = @iMineSiteCode)
END
GO

GRANT EXECUTE ON dbo.GetProductionMovements TO public
GO