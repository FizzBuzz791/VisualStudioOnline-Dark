
--
-- Script to populate the StockpileGroupNotes table to flag 'admin only' groups
--

IF OBJECT_ID('dbo.IsStockpileGroupAdminEditable') IS NOT NULL
     DROP PROCEDURE dbo.IsStockpileGroupAdminEditable  
GO 
  
CREATE PROCEDURE dbo.IsStockpileGroupAdminEditable 
(
	@stockpileGroupId VARCHAR(50),
	@oReturn BIT OUTPUT
)

AS 
BEGIN 
	
	set @oReturn = (
		SELECT CAST(COUNT(*) AS bit) 
		FROM StockpileGroupNotes 
		WHERE Stockpile_Group_Id = @stockpileGroupId
			AND Stockpile_Group_Field_Id = 'ADMIN_EDITABLE_ONLY'
			AND Notes = 'TRUE'
	)
	
END 
GO

GRANT EXECUTE ON dbo.IsStockpileGroupAdminEditable TO BhpbioGenericManager
