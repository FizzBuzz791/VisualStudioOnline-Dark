USE [ReconcilorImportMockWS]
GO

/****** Object:  StoredProcedure [dbo].[GetMETBalancing]    Script Date: 07/11/2013 11:34:44 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetMETBalancing]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GetMETBalancing]
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
