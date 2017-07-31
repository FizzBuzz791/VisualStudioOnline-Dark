IF OBJECT_ID('dbo.DoesBhpbioDigblockAssociationsExist') IS NOT NULL 
     DROP FUNCTION dbo.DoesBhpbioDigblockAssociationsExist
Go 

Create Function dbo.DoesBhpbioDigblockAssociationsExist
(
	@iDigblockId Varchar(31)
)

Returns Bit

With Encryption As

Begin

Declare @RetVal Bit

	Select @RetVal = 0

	If Exists(Select Top 1 1 
				From dbo.BhpbioApprovalDigblock 
				Where DigblockId = @iDigblockId) 
	Begin
		Select @RetVal = 1
	End
	
	If Exists(Select Top 1 1 
				From BhpbioImportReconciliationMovement m
					Inner Join DigblockLocation d
						on m.BlockLocationId = d.Location_Id
				Where d.Digblock_Id = @iDigblockId) 
	Begin
		Select @RetVal = 1
	End
	Return (@RetVal)
End
GO

GRANT EXECUTE ON dbo.DoesBhpbioDigblockAssociationsExist TO CoreDigblockManager
GO

