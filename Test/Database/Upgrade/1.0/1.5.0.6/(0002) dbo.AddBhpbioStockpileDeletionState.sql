If object_id('dbo.AddBhpbioStockpileDeletionState') is Not NULL
	Drop Procedure dbo.AddBhpbioStockpileDeletionState
Go

Create Procedure dbo.AddBhpbioStockpileDeletionState
(
  @iStockpileName VARCHAR(31)
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON 

	BEGIN TRY 
		
		IF NOT EXISTS
				( SELECT 1
				  FROM dbo.BhpbioStockpileDeletion 
				  WHERE Stockpile_Name = @iStockpileName)
		BEGIN
			INSERT INTO dbo.BhpbioStockpileDeletion
			(
				Stockpile_Name
			)
			SELECT @iStockpileName
		END
		
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH	
END 
GO

GRANT EXECUTE ON dbo.AddBhpbioStockpileDeletionState TO CommonImportManager
	
/*
<TAG Name="Data Dictionary" ProcedureName="dbo.AddBhpbioStockpileDeletionState">
 <Procedure>
	Add Deleted Stockpile Name in to the dbo.BhpbioStockpileDeletion Table which can use as a Flag to identify deleted Stockpile
 </Procedure>
</TAG>
*/		
