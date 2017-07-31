IF OBJECT_ID('dbo.UpdateBhpbioPortBalance') IS NOT NULL
     DROP PROCEDURE dbo.UpdateBhpbioPortBalance  
GO 
  
CREATE PROCEDURE dbo.UpdateBhpbioPortBalance
(
    @iBhpbioPortBalanceId INT,
    @iTonnes FLOAT,
    @iProduct VARCHAR(30) = NULL,
    @iProductSize VARCHAR(5) = NULL
)
AS
BEGIN
	SET NOCOUNT ON 

	BEGIN TRY
		-- update the nomination record
		UPDATE dbo.BhpbioPortBalance
		SET	Tonnes = @iTonnes,
			Product = @iProduct,
			ProductSize = @iProductSize
		WHERE BhpbioPortBalanceId = @iBhpbioPortBalanceId
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON dbo.UpdateBhpbioPortBalance TO BhpbioGenericManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.UpdateBhpbioPortBalance">
 <Procedure>
	Updates port Balance records as required.
 </Procedure>
</TAG>
*/	
