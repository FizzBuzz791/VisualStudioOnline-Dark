If Object_Id('dbo.GetBhpbioDataExceptionTypeFilteredList') Is Not Null 
     Drop Procedure dbo.GetBhpbioDataExceptionTypeFilteredList 
Go 
  
Create Procedure dbo.GetBhpbioDataExceptionTypeFilteredList 
(
	@iIncludeActive BIT = 0,
	@iIncludeDismissed BIT = 0,
	@iIncludeResolved BIT = 0,
	@iDateFrom DateTime = NULL,
	@iDateTo DateTime = NULL,
	@iDataExceptionTypeId INT = NULL,
	@iDescriptionContains VARCHAR(250) = NULL,
	@iLocationId INT = NULL
)

With Encryption 
As 

Begin 
    Set NoCount On 
  
    Set Transaction Isolation Level Repeatable Read 
    Begin Transaction 
    
    -- default Location, DateFrom and DateTo if not supplied
	SET @iLocationId = ISNULL(@iLocationId, 1)

	SELECT @iDateFrom = ISNULL(@iDateFrom, CONVERT(DATETIME, Value)) 
		FROM Setting 
		WHERE Setting_Id = 'SYSTEM_START_DATE'

	SET @iDateTo = IsNull(@iDateTo, GetDate())
 
	SELECT DISTINCT DET.Data_Exception_Type_Id, DET.Name, DET.Description, DET.Order_No
	FROM DataExceptionType AS DET	
	INNER JOIN DataException AS DE ON DE.Data_Exception_Type_Id = DET.Data_Exception_Type_Id
	LEFT JOIN dbo.GetBhpbioDataExceptionLocationIgnoreList(@iLocationId) L ON L.DataExceptionId = DE.Data_Exception_Id 
		AND (DE.Data_Exception_Date >= @iDateFrom OR @iDateFrom IS NULL) AND (DE.Data_Exception_Date <= @iDateTo OR @iDateTo IS NULL)
	WHERE ((DE.Data_Exception_Status_Id = 'A' AND @iIncludeActive = 1)
			OR (DE.Data_Exception_Status_Id = 'D' AND @iIncludeDismissed = 1)
			OR (DE.Data_Exception_Status_Id = 'R' AND @iIncludeResolved = 1))
		AND (DET.Data_Exception_Type_Id = @iDataExceptionTypeId OR @iDataExceptionTypeId IS NULL)
		AND (DE.Data_Exception_Date >= @iDateFrom OR @iDateFrom IS NULL)
		AND (DE.Data_Exception_Date <= @iDateTo OR @iDateTo IS NULL)
		AND (@iDescriptionContains IS NULL 
			OR (DE.Short_Description IS NOT NULL AND CHARINDEX(@iDescriptionContains, DE.Short_Description) > 0) 
			OR (DE.Long_Description IS NOT NULL AND CHARINDEX(@iDescriptionContains, DE.Long_Description) > 0))
		AND (ISNULL(@iLocationId,1) = 1	OR l.LocationId IS NULL)
	ORDER BY Order_No ASC
	
    Commit Transaction 
End 
GO

GRANT EXECUTE ON dbo.GetBhpbioDataExceptionTypeFilteredList TO CoreUtilityManager
GO

GRANT EXECUTE ON dbo.GetBhpbioDataExceptionTypeFilteredList TO CoreNotificationManager
GO

/*
<TAG Name="Data Dictionary" ProcedureName="GetBhpbioDataExceptionTypeFilteredList">
 <Procedure>
	Retrieves a list of data exception types for which exceptions actually exist that match the specified filter criteria
 </Procedure>
</TAG>
*/