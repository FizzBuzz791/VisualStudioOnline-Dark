IF Object_Id('dbo.UpdateBhpbioDataExceptionDismissAll') IS NOT NULL
     DROP PROCEDURE dbo.UpdateBhpbioDataExceptionDismissAll
GO 


CREATE PROCEDURE dbo.UpdateBhpbioDataExceptionDismissAll
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
    
    DECLARE @DataExceptions TABLE 
    (
		[Data_Exception_Id] BIGINT NOT NULL,
		[Data_Exception_Type_Id] INT NOT NULL,
		[Data_Exception_Date] DATETIME NOT NULL,
		[Data_Exception_Shift] CHAR(1) NOT NULL,
		[Data_Exception_Status_Id] VARCHAR(5) NOT NULL,
		[Short_Description] VARCHAR(255) NOT NULL,
		[Long_Description] VARCHAR(4096) NOT NULL,
		[Details_XML] XML NULL
		PRIMARY KEY (Data_Exception_Id)
    )
    
    -- we use the filter method to get the list of Ids to dimiss. It is important that this is 
    -- called with exactly the same arguments, otherwise we might dismiss items that are not displayed
    -- on the screen.
    INSERT INTO @DataExceptions
		EXEC dbo.GetBhpbioDataExceptionFilteredList 
			@iIncludeActive,
			@iIncludeDismissed,
			@iIncludeResolved,
			@iDateFrom,
			@iDateTo,
			@iDataExceptionTypeId,
			@iDescriptionContains,
			@iMaxRows,
			@iLocationId
    
    UPDATE dbo.DataException 
    SET Data_Exception_Status_Id = 'D' 
    WHERE Data_Exception_Id IN (SELECT Data_Exception_Id FROM @DataExceptions)
		AND Data_Exception_Status_Id <> 'R'
			
	COMMIT TRANSACTION 		
END 
GO
GRANT EXECUTE ON dbo.UpdateBhpbioDataExceptionDismissAll TO CoreUtilityManager
GRANT EXECUTE ON dbo.UpdateBhpbioDataExceptionDismissAll TO CoreNotificationManager

/*
<TAG Name="Data Dictionary" ProcedureName="GetBhpbioDataExceptionFilteredList">
 <PROCEDURE>
	Returns a list of data exceptions for the type and/or status specified.
 </PROCEDURE>
</TAG>
*/	
