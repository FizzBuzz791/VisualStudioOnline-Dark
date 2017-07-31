If Exists (Select * From dbo.sysobjects Where id = object_id(N'dbo.DeleteBhpbioModelBlockLumpFinesInformation') And OBJECTPROPERTY(id, N'IsProcedure') = 1)
	Drop Procedure dbo.DeleteBhpbioModelBlockLumpFinesInformation
Go

Create Procedure dbo.DeleteBhpbioModelBlockLumpFinesInformation
(
	@iModelBlockId Int
)
As
Begin
	Set Nocount On
	
	Declare @TransactionCount Int
	Declare @TransactionName Varchar(32)
	
	Select @TransactionName = 'DeleteBhpbioModelBlockLumpFinesInformation',
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
	
		Delete From dbo.BhpbioBlastBlockLumpFinesGrade
		Where ModelBlockId = @iModelBlockId
		
		Delete From dbo.BhpbioBlastBlockLumpPercent
		Where ModelBlockId = @iModelBlockId
		
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

Grant Execute On dbo.DeleteBhpbioModelBlockLumpFinesInformation To CoreBlockModelManager
Go
/*
<TAG Name="Data Dictionary" ProcedureName="dbo.DeleteBhpbioModelBlockLumpFinesInformation">
 <Procedure>
 </Procedure>
</TAG>
*/

