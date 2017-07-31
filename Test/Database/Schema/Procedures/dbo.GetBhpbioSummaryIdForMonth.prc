IF OBJECT_ID('dbo.GetBhpbioSummaryIdForMonth') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioSummaryIdForMonth 
GO 
    
CREATE PROCEDURE dbo.GetBhpbioSummaryIdForMonth
(
	@iSummaryMonth DATETIME,
	@oSummaryId INT OUTPUT
)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	-- Get a version of datetime that is gauranteed to be the start of the month
	DECLARE @sanitisedMonth DATETIME
	SELECT @sanitisedMonth = dbo.GetDateMonth(@iSummaryMonth)
			
	BEGIN TRY
		-- First make attempt to find an existing summary for the month
		SELECT @oSummaryId = SummaryId
		FROM dbo.BhpbioSummary 
		WHERE SummaryMonth = @sanitisedMonth

		IF (@oSummaryId IS NULL)
		BEGIN
			-- if no existing summary exists for the month then need to start a new one
			INSERT INTO dbo.BhpbioSummary(SummaryMonth) 
			VALUES (@sanitisedMonth)
	
			SELECT @oSummaryId = @@IDENTITY
		END
	END TRY
	BEGIN CATCH
		EXEC dbo.StandardCatchBlock
	END CATCH
END
GO

GRANT EXECUTE ON dbo.GetBhpbioSummaryIdForMonth TO BhpbioGenericManager
GO

/*
DECLARE @testDateTime DATETIME
DECLARE @summaryId INTEGER

SET @testDateTime = '2010-11-23'

EXEC dbo.GetBhpbioSummaryIdForMonth @iSummaryMonth = @testDateTime,
									@oSummaryId = @summaryId OUTPUT
									
SELECT @summaryId								
*/

/*
<TAG Name="Data Dictionary" ProcedureName="dbo.GetBhpbioSummaryIdForMonth">
 <Procedure>
	Finds the Id of the Summary for a month (if one exists) or creates and outputs a new one if none already exists
	
	Pass: 
			@iSummaryMonth: The month to get a Summary Id for
			@oSummaryId: Outputs the found or created SummaryId
 </Procedure>
</TAG>
*/