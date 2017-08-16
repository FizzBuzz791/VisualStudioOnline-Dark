-- =============================================
-- Author:		Alex Barmouta
-- Create date: 2013-08-26
-- Description:	
-- =============================================
CREATE PROCEDURE GetPortBlending 
	@iStartDate Datetime,
	@iEndDate Datetime
AS
BEGIN
	SET NOCOUNT ON;

	-- Port Blending Movements
	Select PortBlendingId, SourceHub, DestinationHub, StartDate, EndDate, LoadSites, SourceProduct, DestinationProduct, SourceProductSize, DestinationProductSize, Tonnes
	From dbo.PortBlending
	Where StartDate Between @iStartDate And @iEndDate
		And EndDate Between @iStartDate And @iEndDate

	-- Port Blending Grades
	Select m.PortBlendingId, g.GradeName, g.HeadValue
	From dbo.PortBlendingGrade g
		Inner Join dbo.PortBlending m
			On g.PortBlendingId = m.PortBlendingId
	Where StartDate Between @iStartDate And @iEndDate
		And EndDate Between @iStartDate And @iEndDate

END
GO

GRANT EXECUTE ON dbo.GetPortBlending TO public
GO