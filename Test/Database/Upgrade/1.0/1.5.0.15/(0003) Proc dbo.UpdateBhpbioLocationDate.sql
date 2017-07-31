IF Object_Id('dbo.UpdateBhpbioLocationDate') IS NOT NULL 
     DROP PROCEDURE dbo.UpdateBhpbioLocationDate
GO

CREATE PROCEDURE dbo.UpdateBhpbioLocationDate
AS
BEGIN

	Declare @GlobalStartDate DateTime
	Declare @GlobalEndDate DateTime
	Declare @CreateDate DateTime
		
	SET NOCOUNT ON

	SET @GlobalStartDate = '1900-01-01'
	SET @GlobalEndDate = '2050-12-31'   --GETDATE()
	SET @CreateDate = GETDATE()

	DELETE FROM BhpbioLocationDate
	
	INSERT INTO BhpbioLocationDate
	(
		Period_Order,Location_Id,Location_Type_Id,Parent_Location_Id,[Start_Date],End_Date,Is_Override, Date_Created
	)

	SELECT	0 AS Period_Order, Location_Id, Location_Type_Id, Parent_Location_Id
	,		@GlobalStartDate AS [Start_Date], @GlobalEndDate AS End_Date, 0 AS Is_Override
	,		@CreateDate AS Date_Created
	FROM	Location
	UNION ALL
	SELECT	DISTINCT ROW_NUMBER() OVER (PARTITION BY Location_Id ORDER BY FromMonth) AS Period_Order
	,		Location_Id, Location_Type_Id, Parent_Location_Id, FromMonth AS [Start_Date], ToMonth AS [End_Date], 1 AS Is_Override
	,		@CreateDate AS Date_Created
	FROM	BhpbioLocationOverride

	INSERT INTO BhpbioLocationDate
	(
	  Period_Order,Location_Id,Location_Type_Id,Parent_Location_Id,[Start_Date],End_Date,Is_Override, Date_Created
	)
	SELECT	CLH.Period_Order + 1 , CLH.Location_Id, CLH.Location_Type_Id, CLH3.Parent_Location_Id
	,		DATEADD(DAY, 1, FD.End_Date) AS [Start_Date], @GlobalEndDate AS End_Date, 1 AS Is_Override
	,		@CreateDate AS Date_Created
	FROM	BhpbioLocationDate CLH
	INNER JOIN BhpbioLocationDate CLH3 
		ON	CLH.Location_Id = CLH3.Location_Id
		AND CLH3.Period_Order = 0
	CROSS APPLY 
	(
		SELECT	TOP 1 End_Date
		FROM	BhpbioLocationDate CLH2
		WHERE	CLH.Period_Order = CLH2.Period_Order
		AND		CLH.Location_Id = CLH2.Location_Id
		ORDER BY Period_Order DESC  
	) FD
	WHERE CLH.Period_Order > 0

	DELETE	CLH1
	FROM	BhpbioLocationDate CLH1
	INNER JOIN BhpbioLocationDate CLH2 
		ON	CLH2.Location_Id = CLH1.Location_Id
		AND	CLH2.Period_Order = CLH1.Period_Order + 1
		AND	CLH2.[Start_Date] = CLH1.[Start_Date]

	UPDATE	CLH1 SET End_Date = DATEADD(DAY, -1, CLH2.[Start_Date])
	FROM	BhpbioLocationDate CLH1
	INNER JOIN BhpbioLocationDate CLH2 
		ON	CLH2.Location_Id = CLH1.Location_Id
		AND	CLH2.Period_Order = CLH1.Period_Order + 1
END
GO


/*
EXEC dbo.UpdateBhpbioLocationDate
select * from BhpbioLocationDate
*/