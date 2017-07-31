USE [ReconcilorImportMockWS]
GO

/****** Object:  StoredProcedure [dbo].[GetHaulage]    Script Date: 07/11/2013 11:34:44 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetHaulage]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GetHaulage]
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
CREATE PROCEDURE GetHaulage
	@iMineSiteCode nvarchar(50),
	@iStartDate Datetime,
	@iEndDate Datetime
AS
BEGIN
	SET NOCOUNT ON;

	--Haulage
	Select HaulageId As Id, TransactionDate, [Source], SourceMineSite, DestinationMineSite, SourceLocationType, Destination, DestinationType, [Type],
		BestTonnes, HauledTonnes, AerialSurveyTonnes, GroundSurveyTonnes, LumpPercent, LastModifiedTime
	From dbo.Haulage
	Where SourceMineSite = @iMineSiteCode
		And TransactionDate Between @iStartDate And @iEndDate

	-- Location
	Select h.HaulageId As TransactionId, l.Mine
	From dbo.Locations l
		Inner Join dbo.Haulage h
			On h.LocationId = l.Id
	Where h.SourceMineSite = @iMineSiteCode
		And h.TransactionDate Between @iStartDate And @iEndDate

	-- Grades
	Select h.HaulageId As TransactionId, hg.GradeName, hg.HeadValue, hg.FinesValue, hg.LumpValue
	From dbo.HaulageGrade hg
		Inner Join dbo.Haulage h
			On h.HaulageId = hg.HaulageId
	Where h.SourceMineSite = @iMineSiteCode
		And h.TransactionDate Between @iStartDate And @iEndDate

END
GO
