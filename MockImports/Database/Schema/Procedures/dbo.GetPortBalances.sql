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

GRANT EXECUTE ON dbo.GetPortBalances TO public
GO