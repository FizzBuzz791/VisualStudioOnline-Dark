-- =============================================
-- Author:		John Nickerson
-- Create date: 2013-07-11
-- Description:	
-- =============================================
CREATE PROCEDURE GetMETBalancing 
	@iStartDate Datetime,
	@iEndDate Datetime
AS
BEGIN
	SET NOCOUNT ON;

	-- MET Balancing
	Select MetBalancingId, [Site], StartDate, EndDate, PlantName, StreamName, Weightometer, ProductSize, DryTonnes, WetTonnes, SplitCycle, SplitPlant
	From dbo.MetBalancing
	Where StartDate Between @iStartDate And @iEndDate
		And EndDate Between @iStartDate And @iEndDate
	
	-- Grades
	Select m.MetBalancingId, mg.GradeName, mg.HeadValue
	From dbo.MetBalancingGrade mg
		Inner Join dbo.MetBalancing m
			On mg.MetBalancingId = m.MetBalancingId
	Where StartDate Between @iStartDate And @iEndDate
		And EndDate Between @iStartDate And @iEndDate
END
GO

GRANT EXECUTE ON dbo.GetMETBalancing TO public
GO