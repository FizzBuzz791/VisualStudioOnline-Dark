If Object_Id('dbo.AddOrUpdateBhpbioHaulageLumpFinesGrade') Is Not Null 
     Drop Procedure dbo.AddOrUpdateBhpbioHaulageLumpFinesGrade 
Go 

Create Procedure dbo.AddOrUpdateBhpbioHaulageLumpFinesGrade
(
	@iHaulageRawId Int,
	@iGradeId Int = Null,
	@iLumpValue Real= Null,
	@iFinesValue Real = Null
)

With Encryption
As

Begin
	Declare @CurrentHaulageRawId Int
	Declare @NextHaulageRawId Int
	
	Set NoCount On

	Set Transaction Isolation Level Repeatable Read
	Begin Transaction

		-- do not allow the changing of a record that is not at the end of a chain
		If (Select Child_Haulage_Raw_Id
			From HaulageRaw
			Where Haulage_Raw_Id = @iHaulageRawId) Is Not Null
		Begin
			RaisError('AddOrUpdateBhpbioHaulageLumpFinesGrade: HaulageRaw has been modified and cannot be updated.', 16, 1)
		End
		Else
		Begin
			If @iHaulageRawId Is Not Null And @iGradeId Is Null And @iLumpValue Is Null And @iFinesValue Is Null
			Begin
				--Delete all records in the chain
				Set @CurrentHaulageRawId = dbo.GetFirstHaulageRawId(@iHaulageRawId)
				
				While @CurrentHaulageRawId Is Not Null
				Begin
					Select @NextHaulageRawId = Child_Haulage_Raw_Id
					From dbo.HaulageRaw
					Where Haulage_Raw_Id = @CurrentHaulageRawId
					
					Delete
					From dbo.BhpbioHaulageLumpFinesGrade
					Where HaulageRawId = @CurrentHaulageRawId
					
					Set @CurrentHaulageRawId = @NextHaulageRawId
				End
			End
			Else If Exists (
				Select 1
				From dbo.BhpbioHaulageLumpFinesGrade
				Where HaulageRawId = @iHaulageRawId
					And GradeId = @iGradeId
			)
			Begin
				If @iLumpValue Is Null And @iFinesValue Is Null
				Begin
					Delete
					From dbo.BhpbioHaulageLumpFinesGrade
					Where HaulageRawId = @iHaulageRawId
						And GradeId = @iGradeId
				End
				Else
				Begin
					Update BhpbioHaulageLumpFinesGrade
					Set LumpValue = @iLumpValue,
						FinesValue = @iFinesValue
					Where HaulageRawId = @iHaulageRawId
						And GradeId = @iGradeId
				End
			End
			Else
			Begin
				If @iLumpValue Is Not Null Or @iFinesValue Is Not Null
				Begin
					Insert Into dbo.BhpbioHaulageLumpFinesGrade
					(
						HaulageRawId, GradeId, LumpValue, FinesValue
					)
					Select @iHaulageRawId, @iGradeId, @iLumpValue, @iFinesValue
				End
			End
		End


	Commit Transaction
End
Go
Grant Execute On dbo.AddOrUpdateBhpbioHaulageLumpFinesGrade To CoreHaulageManager

/*
<TAG Name="Data Dictionary" ProcedureName="AddOrUpdateBhpbioHaulageLumpFinesGrade">
 <Procedure>
	Adds a new record or updates an existing record in the AddOrUpdateBhpbioHaulageLumpFinesGrade table if the @iGrade_Value 
	value is specified.  If no lump or fines grade values are specified and the record exists in the AddOrUpdateBhpbioHaulageLumpFinesGrade table the record is deleted.
 </Procedure>
</TAG>
*/
