
IF OBJECT_ID('dbo.[SAMEMONTH]') IS NOT NULL 
     DROP FUNCTION dbo.[SAMEMONTH]
Go 


CREATE FUNCTION [dbo].[SAMEMONTH]
(
	@iDate	DATETIME,
	@iMonth	DATETIME
)
RETURNS BIT
BEGIN
	Declare @RetVal Bit
	Select @RetVal = 0

	If MONTH(@iDate)=MONTH(@iMonth) AND YEAR(@iDate) = YEAR(@iMonth)
	Begin
		Select @RetVal = 1
	End

	Return (@RetVal)
END

GO
