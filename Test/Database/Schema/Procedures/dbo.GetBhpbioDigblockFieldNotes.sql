IF OBJECT_ID('dbo.GetBhpbioDigblockFieldNotes') IS NOT NULL
     DROP PROCEDURE dbo.GetBhpbioDigblockFieldNotes
GO 

Create Procedure dbo.GetBhpbioDigblockFieldNotes
(
	@iDigblockId Varchar(31),
	@iDigblockFieldId Varchar(31),
	@oNotes Varchar(1023) Output
) As
Begin
	Set Nocount On

	/* Return the value for the given digblock and field name */
	Select @oNotes = Notes
	From DigblockNotes
	Where Digblock_Id = @iDigblockId
	And Digblock_Field_Id = @iDigblockFieldId

End
GO

GRANT EXECUTE ON dbo.GetBhpbioDigblockFieldNotes TO CoreDigblockManager
Go
