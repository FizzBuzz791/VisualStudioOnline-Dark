IF Object_Id('dbo.GetBhpbioDataExceptionFilteredList') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioDataExceptionFilteredList
GO 

CREATE PROCEDURE dbo.GetBhpbioDataExceptionFilteredList
( 
    @iIncludeActive BIT = 0,
	@iIncludeDismissed BIT = 0,
	@iIncludeResolved BIT = 0,
	@iDateFrom DateTime = NULL,
	@iDateTo DateTime = NULL,
	@iDataExceptionTypeId INT = NULL,
	@iDescriptionContains VARCHAR(250) = NULL,
	@iMaxRows INT = 100,
	@iLocationId INT = NULL
)
WITH ENCRYPTION
AS 

BEGIN 
    SET NOCOUNT ON 
  
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ 
    BEGIN TRANSACTION 
    
	-- default Location, DateFrom and DateTo if not supplied
	SET @iLocationId = ISNULL(@iLocationId, 1)
	
	SELECT @iDateFrom = ISNULL(@iDateFrom, Convert(DateTime, Value)) 
	FROM Setting 
	WHERE Setting_Id = 'SYSTEM_START_DATE'
	
	SET @iDateTo = IsNull(@iDateTo, GetDate())
  
    SELECT TOP (@iMaxRows) DE.Data_Exception_Id, DE.Data_Exception_Type_Id, DE.Data_Exception_Date,
		Data_Exception_Shift, Data_Exception_Status_Id, Short_Description,
		Long_Description, Details_Xml
	FROM dbo.DataException DE
	LEFT JOIN dbo.GetBhpbioDataExceptionLocationIgnoreList(@iLocationId) L ON L.DataExceptionId = DE.Data_Exception_Id
		AND (DE.Data_Exception_Date >= @iDateFrom OR @iDateFrom IS NULL) 
		AND (DE.Data_Exception_Date <= @iDateTo OR @iDateTo IS NULL)
	WHERE ((DE.Data_Exception_Status_Id = 'A' AND @iIncludeActive = 1)
			OR (DE.Data_Exception_Status_Id = 'D' AND @iIncludeDismissed = 1)
			OR (DE.Data_Exception_Status_Id = 'R' AND @iIncludeResolved = 1))
		AND (DE.Data_Exception_Type_Id = @iDataExceptionTypeId OR @iDataExceptionTypeId IS NULL)
		AND (DE.Data_Exception_Date >= @iDateFrom OR @iDateFrom IS NULL)
		AND (DE.Data_Exception_Date <= @iDateTo OR @iDateTo IS NULL)
		AND (@iDescriptionContains IS NULL 
			OR (DE.Short_Description IS NOT NULL AND CHARINDEX(@iDescriptionContains, DE.Short_Description) > 0) 
			OR (DE.Long_Description IS NOT NULL AND CHARINDEX(@iDescriptionContains, DE.Long_Description) > 0))
		AND (ISNULL(@iLocationId,1) = 1 OR L.LocationId IS NULL)
	ORDER BY DE.Data_Exception_Date, DE.Long_Description
			
	COMMIT TRANSACTION 		
END 
GO

GRANT EXECUTE ON dbo.GetBhpbioDataExceptionFilteredList TO CoreUtilityManager
GO

GRANT EXECUTE ON dbo.GetBhpbioDataExceptionFilteredList TO CoreNotificationManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="GetBhpbioDataExceptionFilteredList">
 <PROCEDURE>
	Returns a list of data exceptions for the type and/or status specified.
 </PROCEDURE>
</TAG>
*/	
