If object_id('dbo.GetBhpbioDigblockReconciledGradeOverPeriod') Is Not Null 
     Drop Procedure dbo.GetBhpbioDigblockReconciledGradeOverPeriod 
Go 
  
Create Procedure dbo.GetBhpbioDigblockReconciledGradeOverPeriod 
( 
    @iLocationId Int,
	@iStartDate DateTime = Null,
	@iEndDate DateTime = Null,
	@iGradeID Int
) 
With Encryption 
As
Begin 
    Set NoCount On 
  
    Set Transaction Isolation Level Repeatable Read 
    Begin Transaction 
  
    Select DPT.Source_Digblock_Id As Digblock_Id, 
		Case When Sum(DPT.Tonnes) > 0 Then
				Sum(DPT.Tonnes*DPTG.Grade_Value) / Sum(DPT.Tonnes)
			Else
				Null
			End As Tonnes
	From dbo.DataProcessTransaction As DPT
		Inner Join 
			(	
				--Eliminate double counting
				Select DL.Digblock_Id
				From dbo.DigblockLocation As DL
					Inner Join dbo.LocationType As LT
						On (LT.Location_Type_Id = DL.Location_Type_Id)
					Inner Join 
						(	
							Select Location_Id 
							From dbo.GetLocationChildLocationList(@iLocationId)
							Union All
							Select @iLocationId As Location_Id
						)  As L
						On (L.Location_Id = DL.Location_Id)
				Group By DL.Digblock_Id
			) As DL
			On (DL.Digblock_Id = DPT.Source_Digblock_Id)
		Inner Join dbo.DataProcessTransactionGrade As DPTG
			On (DPTG.Data_Process_Transaction_ID = DPTG.Data_Process_Transaction_ID
				And DPTG.Grade_ID = @iGradeID)
	Where DPT.Source_Digblock_Id Is Not Null
		And DPT.Data_Process_Transaction_Date >= IsNull(@iStartDate, DPT.Data_Process_Transaction_Date)
		And DPT.Data_Process_Transaction_Date <= IsNull(@iEndDate, DPT.Data_Process_Transaction_Date)
	Group By DPT.Source_Digblock_Id

    Commit Transaction 
End 
Go 
GRANT EXECUTE ON dbo.GetBhpbioDigblockReconciledGradeOverPeriod TO CoreDigblockManager

/*
<TAG Name="Data Dictionary" ProcedureName="GetBhpbioDigblockReconciledGradeOverPeriod">
 <Procedure>
	Returns a list of digblocks and their total reconciled tonnes for a given period. 
	This is filtered by a parent location that is passed in.	
 </Procedure>
</TAG>
*/	
