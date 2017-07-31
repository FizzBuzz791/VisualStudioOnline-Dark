IF OBJECT_ID('dbo.GetBhpbioHaulageManagementListFilter') IS NOT NULL
	DROP PROCEDURE dbo.GetBhpbioHaulageManagementListFilter
GO

CREATE PROCEDURE dbo.GetBhpbioHaulageManagementListFilter
(
	@iFilter_Type VARCHAR(31),
	@iLocation_Id INT = NULL
)

WITH ENCRYPTION 
AS
/*-----------------------------------------------------------------------------
--  Name: GetBhpbioHaulageManagementListFilter
--  Purpose: Returns a list of all the Source or Destinations in Haulage.
--  Parameters: @iFilter_Type - Type of filter. 
--					Valid: (Source | Destination | Truck) 
-- 
--  Comments: -
--  
--  Created By:		Murray Hipper
--  Created Date: 	21 October 2006
--
--  Updated By:		Brian Acedo
--					Added Location filter
--					
--  Updated By:     Alex Wong
--					Needs to use Location Subtree
------------------------------------------------------------------------------*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Filter_Table TABLE
	(
		Filter_Display VARCHAR(255) COLLATE Database_Default,
		Filter_Value VARCHAR(255) COLLATE Database_Default,
		Location_Id INT
	)

	IF @iFilter_Type = 'Source'
	BEGIN
		-- Digblock	
		INSERT INTO @Filter_Table (Filter_Display, Filter_Value, Location_Id)
			SELECT distinct ISNULL(d.Description, h.Source_Digblock_Id) AS Description, h.Source_Digblock_Id, IsNull(dl.Location_Id, 0)
			FROM dbo.Haulage AS h
				JOIN dbo.Digblock AS d 
					ON h.Source_Digblock_Id = d.Digblock_Id
				LEFT JOIN dbo.DigblockLocation AS dl
					ON d.Digblock_Id = dl.Digblock_Id
						
		-- Stockpile
		INSERT INTO @Filter_Table (Filter_Display, Filter_Value, Location_Id)
			SELECT distinct ISNULL(s.Stockpile_Name, h.Source_Stockpile_Id) AS Description, h.Source_Stockpile_Id, IsNull(sl.Location_Id, 0)
			FROM dbo.Haulage AS h
				JOIN dbo.Stockpile AS s
					ON h.Source_Stockpile_Id = s.Stockpile_Id
				LEFT JOIN dbo.BhpbioStockpileLocationDate AS sl
					ON s.Stockpile_Id = sl.Stockpile_Id
				AND	(h.Haulage_Date BETWEEN sl.[Start_Date] AND sl.End_Date)
		
		-- Mill
		INSERT INTO @Filter_Table (Filter_Display, Filter_Value, Location_Id)
			SELECT distinct ISNULL(m.Description, h.Source_Mill_Id) AS Description, h.Source_Mill_Id, IsNull(ml.Location_Id, 0)
			FROM dbo.Haulage AS h
				JOIN dbo.Mill AS m
					ON h.Source_Mill_Id = m.Mill_Id
				LEFT JOIN dbo.MillLocation AS ml
					ON m.Mill_Id = ml.Mill_Id
	END
	Else IF @iFilter_Type = 'Destination'
	BEGIN
		-- Crusher	
		INSERT INTO @Filter_Table (Filter_Display, Filter_Value, Location_Id)
			SELECT distinct h.Destination_Crusher_Id AS Description, h.Destination_Crusher_Id, IsNull(cl.Location_Id, 0)
			FROM dbo.Haulage AS h
				JOIN dbo.Crusher AS c 
					ON h.Destination_Crusher_Id = c.Crusher_Id
				LEFT JOIN dbo.CrusherLocation AS cl
					ON c.Crusher_Id = cl.Crusher_Id
						
		-- Stockpile
		INSERT INTO @Filter_Table (Filter_Display, Filter_Value, Location_Id)
			SELECT distinct ISNULL(s.Stockpile_Name, h.Destination_Stockpile_Id) AS Description, h.Destination_Stockpile_Id, IsNull(sl.Location_Id, 0)
			FROM dbo.Haulage AS h
				JOIN dbo.Stockpile AS s
					ON h.Destination_Stockpile_Id = s.Stockpile_Id
				LEFT JOIN dbo.BhpbioStockpileLocationDate AS sl
					ON s.Stockpile_Id = sl.Stockpile_Id
				AND	(h.Haulage_Date BETWEEN sl.[Start_Date] AND sl.End_Date)
		
		-- Mill
		INSERT INTO @Filter_Table (Filter_Display, Filter_Value, Location_Id)
			SELECT distinct ISNULL(m.Description, h.Destination_Mill_Id) AS Description, h.Destination_Mill_Id, IsNull(ml.Location_Id, 0)
			FROM dbo.Haulage AS h
				JOIN dbo.Mill AS m
					ON h.Destination_Mill_Id = m.Mill_Id
				LEFT JOIN dbo.MillLocation AS ml
					ON m.Mill_Id = ml.Mill_Id
					
	END
	Else IF @iFilter_Type = 'Truck'
	BEGIN
		INSERT INTO @Filter_Table (Filter_Display, Filter_Value, Location_Id)
			SELECT H.Truck_Id, H.Truck_Id, Coalesce(@iLocation_Id, 0)
			FROM Haulage AS H
			GROUP BY H.Truck_Id, H.Truck_Id
	END


/*	SELECT *
	FROM @Filter_Table
	WHERE Location_Id = IsNull(@iLocation_Id, Location_Id)
	ORDER BY Filter_Display 
*/

	SELECT *
	FROM @Filter_Table
	WHERE Location_Id IN 
					(	
						SELECT Location_Id
						FROM dbo.GetLocationSubtree(@iLocation_Id)
					)
	ORDER BY Filter_Display 

END
GO
GRANT EXECUTE ON dbo.GetBhpbioHaulageManagementListFilter TO BhpbioGenericManager
GO


/*
<TAG Name="Data Dictionary" ProcedureName="GetHaulageManagementListFilter">
 <Procedure>
	Returns a list of the given filter type to display in the UI.
	Errors are not raised.
 </Procedure>
</TAG>

exec dbo.GetBhpbioHaulageManagementListFilter 'Source',12

*/
