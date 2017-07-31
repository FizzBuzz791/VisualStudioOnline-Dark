IF OBJECT_ID('dbo.GetBhpbioDataExceptionCount') IS NOT NULL 
     DROP PROCEDURE dbo.GetBhpbioDataExceptionCount 
GO 
  
CREATE PROCEDURE dbo.GetBhpbioDataExceptionCount
( 
    @oNum_Exceptions INT OUTPUT,
	@iLocationId INT = NULL
) 
AS
BEGIN 
    SET NOCOUNT ON 
	
	If @iLocationId Is Null or @iLocationId < 0
	Begin
		Exec dbo.UpdateBhpbioDataExceptionLocations

		SELECT @oNum_Exceptions = count(*)
		FROM dbo.DataException As DE
		WHERE DE.Data_Exception_Status_Id = 'A'

	End
	Else
	Begin
		Declare @CurrentDate datetime = getdate()

		SELECT @oNum_Exceptions = count(*)
		FROM dbo.DataException As DE
			inner join BhpbioDataExceptionLocation el
				on el.DataExceptionId = de.Data_Exception_Id
			inner join dbo.GetBhpbioReportLocationBreakdownWithOverride(@iLocationId, 0, 'BLOCK', @CurrentDate, @CurrentDate) lb
				on lb.LocationId = el.LocationId
		WHERE DE.Data_Exception_Status_Id = 'A'

		-- for backwards compatability we need to include all the exceptions with
		-- no location as well
		SELECT @oNum_Exceptions = @oNum_Exceptions + count(*)
		FROM dbo.DataException As DE
			left join BhpbioDataExceptionLocation el
				on el.DataExceptionId = de.Data_Exception_Id
		WHERE DE.Data_Exception_Status_Id = 'A'
			and el.DataExceptionId is null

	End
END 
GO 
GRANT EXECUTE ON dbo.GetBhpbioDataExceptionCount TO BhpbioGenericManager

/*
<TAG Name="Data Dictionary" ProcedureName="GetDataExceptionCount">
 <Procedure>
	Outputs the number of active data exceptions in the system
 </Procedure>
</TAG>
*/	