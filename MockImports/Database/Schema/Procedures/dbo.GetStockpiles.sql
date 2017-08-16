-- =============================================
-- Author:		John Nickerson
-- Create date: 2013-07-11
-- Description:	
-- =============================================
CREATE PROCEDURE GetStockpiles 
	@iMineSiteCode nvarchar(50)
AS
BEGIN
	SET NOCOUNT ON;

	-- Stockpiles
	Select Mine, s.Name, BusinessId, StockpileType, Description, OreType, Type, Active, StartDate, ProductSize
	From dbo.Stockpiles s
	Inner Join dbo.Locations l
	On s.LocationId = l.Id
	Where l.Mine = @iMineSiteCode

END
GO

GRANT EXECUTE ON dbo.GetStockpiles TO public
GO