IF Object_Id('dbo.UpdateBhpbioStockpileLocationDate') IS NOT NULL 
     DROP PROCEDURE dbo.UpdateBhpbioStockpileLocationDate
GO

CREATE PROCEDURE dbo.UpdateBhpbioStockpileLocationDate
AS
BEGIN

	Declare @GlobalStartDate DateTime
	Declare @GlobalEndDate DateTime
	Declare @CreateDate DateTime
		
	SET NOCOUNT ON

	SET @GlobalStartDate = '1900-01-01'
	SET @GlobalEndDate = '2050-12-31'   
	SET @CreateDate = GETDATE()

	DELETE FROM BhpbioStockpileLocationDate
	
	INSERT INTO BhpbioStockpileLocationDate
	(
		Period_Order,Stockpile_Id, Location_Id,[Start_Date],End_Date,Is_Override, Date_Created
	)

	SELECT	0 AS Period_Order, Stockpile_Id, Location_Id
	,		@GlobalStartDate AS [Start_Date]
	,		@GlobalEndDate AS End_Date
	,		0 AS Is_Override
	,		@CreateDate AS Date_Created
	FROM	StockpileLocation
	UNION ALL
	SELECT	DISTINCT ROW_NUMBER() OVER (PARTITION BY Stockpile_Id, Location_Id ORDER BY FromMonth) AS Period_Order
	,		Stockpile_Id, Location_Id, FromMonth AS [Start_Date], ToMonth AS [End_Date], 1 AS Is_Override
	,		@CreateDate AS Date_Created
	FROM	BhpbioStockpileLocationOverride

	INSERT INTO BhpbioStockpileLocationDate
	(
	  Period_Order,Stockpile_Id,Location_Id,[Start_Date],End_Date,Is_Override, Date_Created
	)
	SELECT	CLH.Period_Order + 1, CLH.Stockpile_Id, CLH3.Location_Id
	,		DATEADD(DAY, 1, FD.End_Date) AS [Start_Date], @GlobalEndDate AS End_Date, 1 AS Is_Override
	,		@CreateDate AS Date_Created
	FROM	BhpbioStockpileLocationDate CLH
	INNER JOIN BhpbioStockpileLocationDate CLH3 
		ON	CLH.Stockpile_Id = CLH3.Stockpile_Id
		AND CLH3.Period_Order = 0
	CROSS APPLY 
	(
		SELECT	TOP 1 End_Date
		FROM	BhpbioStockpileLocationDate CLH2
		WHERE	CLH.Period_Order = CLH2.Period_Order
		AND		CLH.Stockpile_Id = CLH2.Stockpile_Id
		ORDER BY Period_Order DESC  
	) FD
	WHERE CLH.Period_Order > 0
	AND FD.End_Date <  @GlobalEndDate

	DELETE	CLH1
	FROM	BhpbioStockpileLocationDate CLH1
	INNER JOIN BhpbioStockpileLocationDate CLH2 
		ON	CLH2.Stockpile_Id = CLH1.Stockpile_Id
		AND	CLH2.Period_Order = CLH1.Period_Order + 1
		AND	CLH2.[Start_Date] = CLH1.[Start_Date]

	UPDATE	CLH1 SET End_Date = DATEADD(DAY, -1, CLH2.[Start_Date])
	FROM	BhpbioStockpileLocationDate CLH1
	INNER JOIN BhpbioStockpileLocationDate CLH2 
		ON	CLH2.Stockpile_Id = CLH1.Stockpile_Id
		AND	CLH2.Period_Order = CLH1.Period_Order + 1
END
GO

GRANT EXECUTE ON dbo.UpdateBhpbioStockpileLocationDate TO CommonImportManager
GO

/*
EXEC dbo.UpdateBhpbioStockpileLocationDate
select * from BhpbioStockpileLocationDate
*/