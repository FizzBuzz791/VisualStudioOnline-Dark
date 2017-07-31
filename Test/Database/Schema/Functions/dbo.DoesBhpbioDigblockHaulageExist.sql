IF OBJECT_ID('dbo.DoesBhpbioDigblockHaulageExist') IS NOT NULL 
     DROP FUNCTION dbo.DoesBhpbioDigblockHaulageExist
Go 

Create Function dbo.DoesBhpbioDigblockHaulageExist
(
	@iDigblockId Varchar(31)
)

Returns Bit

With Encryption As

Begin

Declare @RetVal Bit

	Select @RetVal = 0

	If Exists(Select Top 1 1 
				From dbo.Haulage 
				Where Source_Digblock_Id = @iDigblockId
					And Haulage_State_Id in ('A','N')) 
	Begin
		Select @RetVal = 1
	End

	Return (@RetVal)
End
GO

GRANT EXECUTE ON dbo.DoesBhpbioDigblockHaulageExist TO CoreDigblockManager
GO

