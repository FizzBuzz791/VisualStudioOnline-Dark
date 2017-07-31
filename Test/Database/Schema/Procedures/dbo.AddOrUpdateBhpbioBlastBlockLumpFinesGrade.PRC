If Object_Id('dbo.AddOrUpdateBhpbioBlastBlockLumpFinesGrade') Is Not Null
	Drop Procedure dbo.AddOrUpdateBhpbioBlastBlockLumpFinesGrade
GO

Create Procedure dbo.AddOrUpdateBhpbioBlastBlockLumpFinesGrade
(
	@iModelBlockId Int,
	@iGeometType Varchar(15),
	@iSequenceNo Int,
	@iGradeId SmallInt,
	@iLumpValue Real,
	@iFinesValue Real
)

With Encryption
As 

Begin
	Set NoCount On
	
	Set Transaction Isolation Level Repeatable Read
	Begin Transaction

	If @iLumpValue Is Null And @iFinesValue Is Null
	Begin
		-- Delete the grade
		Delete
		From dbo.BhpbioBlastBlockLumpFinesGrade
		Where GradeId = @iGradeId
			And ModelBlockId = @iModelBlockId
			And IsNull(GeometType,'NA') = IsNull(@iGeometType,'NA')
			And SequenceNo = @iSequenceNo
	End
	Else If Exists (Select 1
					From dbo.BhpbioBlastBlockLumpFinesGrade
					Where GradeId = @iGradeId
						And ModelBlockId = @iModelBlockId
						And IsNull(GeometType,'NA') = IsNull(@iGeometType,'NA')
						And SequenceNo = @iSequenceNo)
	Begin
		-- Update the grade
		Update dbo.BhpbioBlastBlockLumpFinesGrade
		Set LumpValue = @iLumpValue,
			FinesValue = @iFinesValue
		Where GradeId = @iGradeId
			And ModelBlockId = @iModelBlockId
			And IsNull(GeometType,'NA') = IsNull(@iGeometType,'NA')
			And SequenceNo = @iSequenceNo
	End
	Else
	Begin
		-- Insert the grade
		Insert Into dbo.BhpbioBlastBlockLumpFinesGrade
			(ModelBlockId, GeometType, SequenceNo, GradeId, LumpValue, FinesValue)
		Values
			(@iModelBlockId, @iGeometType, @iSequenceNo, @iGradeId, @iLumpValue, @iFinesValue)
	End	
	
	Commit Transaction
End
Go
GRANT EXECUTE ON dbo.AddOrUpdateBhpbioBlastBlockLumpFinesGrade TO CoreBlockModelManager

/*
<TAG Name="Data Dictionary" ProcedureName="AddOrUpdateBhpbioBlastBlockLumpFinesGrade">
 <Procedure>
	Adds a new record or updates an existing record in the AddOrUpdateBhpbioBlastBlockLumpFinesGrade table if a 
	@iLumpValue or @iFinesValue is specified.
	If a @iLumpValue or @iFinesValue  is not specified and the record exists in the BhpbioBlastBlockLumpFinesGrade table 
	the record is deleted.
	Errors not raised.
 </Procedure>
</TAG>
*/
