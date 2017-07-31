IF OBJECT_ID('dbo.GetBhpbioUngroupedStockpileCount') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioUngroupedStockpileCount  
GO 

CREATE PROCEDURE [dbo].[GetBhpbioUngroupedStockpileCount]
(
  @iLocationId INT,
  @iMonth DATETIME,
  @oCount INT OUTPUT
)
AS
BEGIN
	SELECT @oCount = COUNT(DISTINCT SL.Stockpile_Id)
	FROM dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 0, 'PIT', @iMonth, @iMonth) L
	INNER JOIN StockpileLocation SL ON SL.Location_Id = L.LocationId
	INNER JOIN DataProcessTransaction DPT ON (DPT.Source_Stockpile_Id = SL.Stockpile_Id OR DPT.Destination_Stockpile_Id = SL.Stockpile_Id) 
		AND DATEPART(MONTH, DPT.Data_Process_Transaction_Date) = DATEPART(MONTH, @iMonth) AND DATEPART(YEAR, DPT.Data_Process_Transaction_Date) = DATEPART(YEAR, @iMonth)
	LEFT JOIN StockpileGroupStockpile SGS ON SGS.Stockpile_Id = SL.Stockpile_Id
	WHERE SGS.Stockpile_Id IS NULL AND DPT.Stockpile_Adjustment_Id IS NULL
END
GO

GRANT EXECUTE ON dbo.GetBhpbioUngroupedStockpileCount TO BhpbioGenericManager
Go