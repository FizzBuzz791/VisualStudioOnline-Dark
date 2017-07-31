IF OBJECT_ID('dbo.GetBhpbioDataExceptionCount2') IS NOT NULL 
     DROP PROCEDURE dbo.GetBhpbioDataExceptionCount2
GO 

  
CREATE PROCEDURE dbo.GetBhpbioDataExceptionCount2
( 
    @oNum_Exceptions INT OUTPUT,
	@iLocationId INT = NULL,
	@iMonth	DATETIME
) 
AS
BEGIN 
    SET NOCOUNT ON 
		
	Exec dbo.UpdateBhpbioDataExceptionLocations
		
	SELECT @oNum_Exceptions = count(*)
	FROM dbo.DataException As DE
		LEFT JOIN dbo.GetBhpbioDataExceptionLocationIgnoreList(@iLocationId) I
			ON I.DataExceptionId = DE.Data_Exception_Id
	WHERE DE.Data_Exception_Status_Id = 'A'
		AND I.DataExceptionId IS NULL
		AND dbo.SAMEMONTH(DE.Data_Exception_Date,@iMonth)=1
END 
GO 

GRANT EXECUTE ON dbo.GetBhpbioDataExceptionCount2 TO BhpbioGenericManager
Go

/*
<TAG Name="Data Dictionary" ProcedureName="GetDataExceptionCount">
 <Procedure>
	Outputs the number of active data exceptions in the system
 </Procedure>
</TAG>
*/	