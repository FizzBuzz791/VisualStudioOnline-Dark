 IF Object_Id('dbo.GetBhpbioDataExceptionList') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioDataExceptionList
GO 

CREATE PROCEDURE dbo.GetBhpbioDataExceptionList
( 
    @iDataExceptionTypeId INT = NULL,
	@iDataExceptionStatusId VARCHAR(5) = NULL,
	@iExcludeResolved BIT = 0,
	@iLocationId INT = NULL
) 


AS 

BEGIN 
    SET NOCOUNT ON 
  
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ 
    BEGIN TRANSACTION 
  
    SELECT DE.Data_Exception_Id, DE.Data_Exception_Type_Id, DE.Data_Exception_Date,
		DE.Data_Exception_Shift, DE.Data_Exception_Status_Id, DE.Short_Description,
		DE.Long_Description, DE.Details_Xml
	FROM dbo.DataException DE
		LEFT JOIN dbo.GetBhpbioDataExceptionLocationIgnoreList(@iLocationId) I
			ON I.DataExceptionId = DE.Data_Exception_Id
	WHERE DE.Data_Exception_Type_Id = IsNull(@iDataExceptionTypeId, DE.Data_Exception_Type_Id)
		AND DE.Data_Exception_Status_Id = IsNull(@iDataExceptionStatusId, DE.Data_Exception_Status_Id)
		AND (@iExcludeResolved = 0
			OR DE.Data_Exception_Status_Id <> 'R')
		AND I.DataExceptionId IS NULL
	ORDER BY DE.Data_Exception_Date, DE.Short_Description, DE.Long_Description
			
	COMMIT TRANSACTION 		
END 
GO
GRANT EXECUTE ON dbo.GetBhpbioDataExceptionList TO BhpbioGenericManager

/*
<TAG Name="Data Dictionary" ProcedureName="GetBhpbioDataExceptionList">
 <PROCEDURE>
	Returns a list of data exceptions for the type and/or status specified.
 </PROCEDURE>
</TAG>
*/	
