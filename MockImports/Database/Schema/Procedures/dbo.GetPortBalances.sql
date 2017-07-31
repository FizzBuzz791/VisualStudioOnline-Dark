USE [ReconcilorImportMockWS]
GO

/****** Object:  StoredProcedure [dbo].[GetPortBalances]    Script Date: 07/11/2013 11:34:44 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetPortBalances]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[GetPortBalances]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Alex Barmouta
-- Create date: 2013-08-22
-- Description:	
-- =============================================
CREATE PROCEDURE GetPortBalances 
	@iStartDate DateTime
AS
BEGIN
	SET NOCOUNT ON;

	--Balances
	Select PortBalanceId, BalanceDate, Hub, Tonnes, SourceProduct, TargetProduct, ProductSize
	From dbo.PortBalance
	Where BalanceDate >= @iStartDate

	--Grades
	Select b.PortBalanceId, bg.GradeName, bg.HeadValue
	From dbo.PortBalance b
		Inner Join dbo.PortBalanceGrade bg
			On b.PortBalanceId = bg.PortBalanceId
	Where b.BalanceDate >= @iStartDate

END
GO
