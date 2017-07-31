If Object_Id('dbo.AddOrUpdateBhpbioBlastBlockLumpPercent') Is Not Null
	Drop Procedure dbo.AddOrUpdateBhpbioBlastBlockLumpPercent
GO

Create Procedure dbo.AddOrUpdateBhpbioBlastBlockLumpPercent
(
	@iModelBlockId Int,
	@iGeometType Varchar(15),
	@iSequenceNo Int,
	@iLumpPercent Decimal(7,6)
)

With Encryption
As 

Begin
	Set NoCount On
	
	Set Transaction Isolation Level Repeatable Read
	Begin Transaction

	If @iLumpPercent Is Null 
	Begin
		-- Delete the lump percent
		Delete
		From dbo.BhpbioBlastBlockLumpPercent
		Where ModelBlockId = @iModelBlockId
			AND IsNull(GeometType,'NA') = IsNull(@iGeometType,'NA')
			AND SequenceNo = @iSequenceNo
			 
		-- And associated grades
		Delete
		From dbo.BhpbioBlastBlockLumpFinesGrade
		Where ModelBlockId = @iModelBlockId
			AND IsNull(GeometType,'NA') = IsNull(@iGeometType,'NA')
			AND SequenceNo = @iSequenceNo
	End
	Else If Exists (Select 1
					From dbo.BhpbioBlastBlockLumpPercent
					Where ModelBlockId = @iModelBlockId
					AND IsNull(GeometType,'NA') = IsNull(@iGeometType,'NA')
					AND SequenceNo = @iSequenceNo
					)
	Begin
		-- Update the lump percentage
		Update dbo.BhpbioBlastBlockLumpPercent
		Set LumpPercent = @iLumpPercent
		Where ModelBlockId = @iModelBlockId
			AND IsNull(GeometType,'NA') = IsNull(@iGeometType,'NA')
			AND SequenceNo = @iSequenceNo
	End
	Else
	Begin
		-- Insert the lump percent
		Insert Into dbo.BhpbioBlastBlockLumpPercent
			(ModelBlockId, GeometType, SequenceNo, LumpPercent)
		Values
			(@iModelBlockId, @iGeometType, @iSequenceNo, @iLumpPercent)
	End	
	
	Commit Transaction
End
Go
GRANT EXECUTE ON dbo.AddOrUpdateBhpbioBlastBlockLumpPercent TO CoreBlockModelManager

/*
<TAG Name="Data Dictionary" ProcedureName="AddOrUpdateBhpbioBlastBlockLumpPercent">
 <Procedure>
	Adds a new record or updates an existing record in the BhpbioBlastBlockLumpPercent table if a 
	@iLumpPercent value is specified.
	If a @iLumpPercent value is not specified and the record exists in the BhpbioBlastBlockLumpPercent table 
	the record is deleted.  Associated records in the BhpbioBlastBlockLumpinesGrade are also removed to ensure data 
	consistency.
	Errors not raised.
 </Procedure>
</TAG>
*/
