If Exists (Select * From dbo.sysobjects Where id = object_id(N'dbo.AddOrUpdateBhpbioLumpFinesRecord') And OBJECTPROPERTY(id, N'IsProcedure') = 1)
	Drop Procedure dbo.AddOrUpdateBhpbioLumpFinesRecord
Go

Create Procedure dbo.AddOrUpdateBhpbioLumpFinesRecord
(
	@iBhpbioDefaultLumpFinesId Int = Null,
	@iLocationId Int,
	@iStartDate DateTime,
	@iLumpPercent Decimal(5,4),
	@iValidateOnly Bit = 0
)
As
Begin
	Set Nocount On
	
	Declare @TransactionCount Int
	Declare @TransactionName Varchar(32)
	
	Declare @IsValid Bit
	Declare @Error Varchar(300)
	Declare @BenchLocTypeId Int
	Declare @BlastLocTypeId Int
	Declare @BlockLocTypeId Int
	Declare @CurrentLocationId Int
	Declare @CurrentStartDate DateTime
	Declare @IsNonDeletable Bit
	
	Select @TransactionName = 'AddOrUpdateBhpbioLumpFinesRecord',
			@TransactionCount = @@TranCount 

	-- if there are no transactions available then start a new one
	-- if there is already a transaction then only mark a savepoint
	If @TransactionCount = 0
	Begin
		Set Transaction Isolation Level Repeatable Read
		Begin Transaction
	End
	Else
	Begin
		Save Transaction @TransactionName
	End
  
	Begin Try
	
		Select @BenchLocTypeId = Location_Type_Id
		From dbo.LocationType
		Where [Description] = 'Bench'
		
		Select @BlastLocTypeId = Location_Type_Id
		From dbo.LocationType
		Where [Description] = 'Blast'
		
		Select @BlockLocTypeId = Location_Type_Id
		From dbo.LocationType
		Where [Description] = 'Block'
		
		Select @IsValid = 1, @Error = ''
		
		Set @IsNonDeletable = 0 -- if new record, then it is deletable
		If @iBhpbioDefaultLumpFinesId Is Not Null -- if an existing record, then check the flag
		Begin
			Select @IsNonDeletable = IsNonDeletable
			From dbo.BhpbioDefaultLumpFines
			Where BhpbioDefaultLumpFinesId = @iBhpbioDefaultLumpFinesId
		End
		
		-- Non-deletable implies that neither location nor start date can be changed
		If @IsNonDeletable = 0 And Exists
		(
			Select 1
			From dbo.Location l
				Inner Join dbo.LocationType lt
					On l.Location_Type_Id = lt.Location_Type_Id
			Where l.Location_Id = @iLocationId
				And lt.Location_Type_Id In (@BenchLocTypeId, @BlastLocTypeId, @BlockLocTypeId)
		)
		Begin
			Select @IsValid = 0, @Error = 'Bench, Blast or Block location types are not allowed.'
		End
	
		If @IsNonDeletable = 0 And Exists -- look for record with the same location and start date
		(
			Select 1
			From dbo.BhpbioDefaultLumpFines
			Where LocationId = @iLocationId
				And StartDate = @iStartDate
		)
		Begin
			If @iBhpbioDefaultLumpFinesId Is Null -- if this is a new record, then return error
			Begin
				Select @IsValid = 0, @Error = 'Record with the same location and start date already exists.'
			End
			Else
			Begin
				Select @CurrentLocationId = LocationId, @CurrentStartDate = StartDate
				From dbo.BhpbioDefaultLumpFines
				Where BhpbioDefaultLumpFinesId = @iBhpbioDefaultLumpFinesId
					
				If @CurrentLocationId <> @iLocationId Or @CurrentStartDate <> @iStartDate -- if location or start date has changed and match to another record (see IF statement above) 
				Begin
					Select @IsValid = 0, @Error = 'Record with the same location and start date already exists.'
				End
			End
		End
	
		If @iValidateOnly = 0 And @IsValid = 1
		Begin
			If @iBhpbioDefaultLumpFinesId Is Null
			Begin
				Insert Into dbo.BhpbioDefaultLumpFines
				(
					LocationId, StartDate, LumpPercent
				)
				Select @iLocationId, @iStartDate, @iLumpPercent
			End
			Else
			Begin
				If @IsNonDeletable = 1 -- Non-deletable implies that neither location nor start date can be changed: only the percentage
				Begin
					Update dbo.BhpbioDefaultLumpFines
					Set LumpPercent = @iLumpPercent
					Where BhpbioDefaultLumpFinesId = @iBhpbioDefaultLumpFinesId
				End
				Else
				Begin
					Update dbo.BhpbioDefaultLumpFines
					Set LocationId = @iLocationId,
						StartDate = @iStartDate,
						LumpPercent = @iLumpPercent
					Where BhpbioDefaultLumpFinesId = @iBhpbioDefaultLumpFinesId
				End
			End
		End
		
		-- return the result
		Select @IsValid As Success, @Error As ErrorMessage
		
		-- if we started a new transaction that is still valid then commit the changes
		If (@TransactionCount = 0) And (XAct_State() = 1)
		Begin
			Commit Transaction
		End
	End Try
	Begin Catch
		-- if we started a transaction then roll it back
		If (@TransactionCount = 0)
		Begin
			Rollback Transaction
		End
		-- if we are part of an existing transaction and 
		Else If (XAct_State() = 1) And (@TransactionCount > 0)
		Begin
			Rollback Transaction @TransactionName
		End

		Exec dbo.StandardCatchBlock
	End Catch
End
Go

Grant Execute On dbo.AddOrUpdateBhpbioLumpFinesRecord To BhpbioGenericManager
Go
/*
<TAG Name="Data Dictionary" ProcedureName="dbo.AddOrUpdateBhpbioLumpFinesRecord">
 <Procedure>
 </Procedure>
</TAG>
*/

