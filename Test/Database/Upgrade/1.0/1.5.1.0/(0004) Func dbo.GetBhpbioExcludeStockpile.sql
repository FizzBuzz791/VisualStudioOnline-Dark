IF Object_Id('dbo.GetBhpbioExcludeStockpileGroup') IS NOT NULL 
     DROP FUNCTION dbo.GetBhpbioExcludeStockpileGroup
GO

CREATE FUNCTION dbo.GetBhpbioExcludeStockpileGroup
(
	@iExclusionType VARCHAR(50)
)
RETURNS @Stockpile TABLE
(
	StockpileId INT
	Primary KEY (StockpileId)
)
BEGIN
	INSERT INTO @Stockpile
		(StockpileId)
	SELECT DISTINCT SGS.Stockpile_Id
	FROM BhpbioFactorExclusionFilter BFEF
	INNER JOIN StockpileGroupStockpile SGS
	  ON SGS.Stockpile_Group_Id = BFEF.StockpileGroupId
	WHERE BFEF.ExclusionType = @iExclusionType
	OR @iExclusionType IS NULL
	
	Return
END
GO