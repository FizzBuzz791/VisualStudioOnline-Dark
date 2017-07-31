If object_id('dbo.ClearBhpbioStockpileDeletionState') is Not NULL
	DROP PROCEDURE dbo.ClearBhpbioStockpileDeletionState
Go

CREATE PROCEDURE dbo.ClearBhpbioStockpileDeletionState
(
  @iStockpileName VARCHAR(31),
  @oPreviousDeletionState BIT OUTPUT,
  @oMatchingStockpileId INT OUTPUT
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON 
    BEGIN TRY
		SET @oPreviousDeletionState = 0
		SET @oMatchingStockpileId = NULL
		
		--Get the Stockpile_Id 
	   SELECT @oMatchingStockpileId = Stockpile_Id 
	   FROM Stockpile
	   WHERE Stockpile_Name = @iStockpileName
			   
		IF EXISTS
				( SELECT 1
				  FROM dbo.BhpbioStockpileDeletion 
				  WHERE Stockpile_Name = @iStockpileName)
		BEGIN
		   SET @oPreviousDeletionState = 1
		   
		   --Delete the Stockpile Deletion Flag
		   DELETE 
		   FROM dbo.BhpbioStockpileDeletion
		   WHERE Stockpile_Name = @iStockpileName
		END  
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH	
END 
GO

GRANT EXECUTE ON dbo.ClearBhpbioStockpileDeletionState TO CommonImportManager

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.ClearBhpbioStockpileDeletionState">
 <Procedure>
	Check Whether Stockpile exists then delete the record, return the matching stockpile id for the given stockpile name
	and the previous state	
 </Procedure>
</TAG>
*/		