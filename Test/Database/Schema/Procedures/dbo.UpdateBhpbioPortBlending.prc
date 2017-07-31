IF OBJECT_ID('dbo.UpdateBhpbioPortBlending') IS NOT NULL
     DROP PROCEDURE dbo.UpdateBhpbioPortBlending  
GO 
  
CREATE PROCEDURE dbo.UpdateBhpbioPortBlending
(
    @iBhpbioPortBlendingId INT,
    @iSourceProductSize VARCHAR(5),
    @iDestinationProductSize VARCHAR(5),
    @iTonnes FLOAT
)
AS
BEGIN
	SET NOCOUNT ON 

	BEGIN TRY
		-- update the blending record
		UPDATE dbo.BhpbioPortBlending
		SET SourceProductSize = @iSourceProductSize,
			DestinationProductSize = @iDestinationProductSize,
			Tonnes = @iTonnes
		WHERE BhpbioPortBlendingId = @iBhpbioPortBlendingId
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END 
GO

GRANT EXECUTE ON dbo.UpdateBhpbioPortBlending TO BhpbioGenericManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.UpdateBhpbioPortBlending">
 <Procedure>
	Updates port blending records as required.
 </Procedure>
</TAG>
*/	
 