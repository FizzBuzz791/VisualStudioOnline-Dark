if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DoesBhpbioDigblockNotesExist]') and xtype in (N'FN', N'IF', N'TF'))
	drop function [dbo].[DoesBhpbioDigblockNotesExist]
GO

Create Function dbo.DoesBhpbioDigblockNotesExist
(
	@iDigblockNotesField Varchar(31),
	@iDigblockNotes Varchar(1023)
)

Returns Bit

With Encryption As

Begin

Declare @RetVal Bit

	Select @RetVal = 0

	If Exists(Select Top 1 1 
				From dbo.DigblockNotes 
				Where  Digblock_Field_Id = @iDigblockNotesField
					and Notes = @iDigblockNotes)
	Begin
		Select @RetVal = 1
	End

	Return (@RetVal)
End
GO

GRANT EXECUTE ON dbo.DoesBhpbioDigblockNotesExist TO CoreDigblockManager
GO

