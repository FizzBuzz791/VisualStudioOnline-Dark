If object_id('dbo.GetBhpbioDigblockModelBlockGradeOverPeriod') Is Not Null 
     Drop Procedure dbo.GetBhpbioDigblockModelBlockGradeOverPeriod 
Go 
  
Create Procedure dbo.GetBhpbioDigblockModelBlockGradeOverPeriod
( 
    @iLocationID Int,
	@iBlockModelID Int,
	@iGradeID Int
) 
As
Begin 
    Set NoCount On 
  
    Select DL.Digblock_ID, 
		Case When Sum(MBP.Tonnes * IsNull(DMB.Percentage_In_Digblock, 1)) > 0 Then
				Sum(MBP.Tonnes * IsNull(DMB.Percentage_In_Digblock, 1) * MBPG.Grade_Value) / Sum(MBP.Tonnes * IsNull(DMB.Percentage_In_Digblock, 1)) 
			Else
				Null
			End As Tonnes
	From dbo.ModelBlock As MB
		Inner Join dbo.ModelBlockPartial As MBP
			On (MB.Model_Block_ID = MBP.Model_Block_ID)
		Inner Join dbo.DigblockModelBlock as DMB
			On (MB.Model_Block_ID = DMB.Model_Block_ID)
		Inner Join 
			(
				--Eliminate double counting
				Select DL.Digblock_ID
				From dbo.DigblockLocation As DL
					Inner Join dbo.LocationType As LT
						On (LT.Location_Type_ID = DL.Location_Type_ID)
					Inner Join 
						(
							Select *
							From dbo.GetLocationChildLocationList(@iLocationID) 
							Union 
							Select @iLocationID
						) As L
						On (L.Location_ID = DL.Location_ID)
				Group By DL.Digblock_ID
			) As DL
			On (DMB.Digblock_ID = DL.Digblock_ID)
		Inner Join ModelBlockPartialGrade MBPG
			On (MBPG.Model_Block_ID = MBP.Model_Block_ID
				And MBPG.Sequence_No = MBP.Sequence_No
				And MBPG.Grade_ID = @iGradeID )
	Where MB.Block_Model_ID = @iBlockModelID
	Group By DL.Digblock_ID
  
End 
Go 
GRANT EXECUTE ON dbo.GetBhpbioDigblockModelBlockGradeOverPeriod TO CoreDigblockManager

/*
<TAG Name="Data Dictionary" ProcedureName="GetBhpbioDigblockModelBlockGradeOverPeriod">
 <Procedure>
	Returns a list of digblocks and their total tonnes according to the chosen block model. 
	This is filtered by a parent location that is passed in.
 </Procedure>
</TAG>
*/	
