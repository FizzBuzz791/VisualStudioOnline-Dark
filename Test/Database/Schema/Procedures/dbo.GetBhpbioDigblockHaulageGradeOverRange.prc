If object_id('dbo.GetBhpbioDigblockHaulageGradeOverRange') Is Not Null 
     Drop Procedure dbo.GetBhpbioDigblockHaulageGradeOverRange 
Go 
  
Create Procedure dbo.GetBhpbioDigblockHaulageGradeOverRange
( 
	@iLocationID Int,
    @iStartDate Datetime = Null,
	@iEndDate Datetime = Null,
	@iGradeID Int
) 
As 
Begin 
    Set NoCount On 
  
  
	Select H.Source_Digblock_ID As Digblock_ID, 
		Case When Sum(H.Tonnes) > 0 Then
				Sum(H.Tonnes*HG.Grade_Value) / Sum(H.Tonnes) 
			ELSE
				NULL
			END	As Tonnes
	From dbo.Haulage As H
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
			On (DL.Digblock_ID = H.Source_Digblock_ID)
		Inner Join dbo.HaulageGrade HG
			On (HG.Haulage_ID = H.Haulage_ID
				And HG.Grade_ID = @iGradeID)
	Where H.Haulage_Date >= IsNull(@iStartDate, H.Haulage_Date)
		And H.Haulage_Date <= IsNull(@iEndDate, H.Haulage_Date)
		AND h.Haulage_State_Id IN ('N', 'A')
		AND h.Child_Haulage_Id IS NULL
		And H.Source_Digblock_Id Is Not Null
	Group By H.Source_Digblock_ID

End 
Go 
GRANT EXECUTE ON dbo.GetBhpbioDigblockHaulageGradeOverRange TO CoreDigblockManager

/*
<TAG Name="Data Dictionary" ProcedureName="GetBhpbioDigblockHaulageGradeOverRange">
 <Procedure>
	Returns a list of digblocks and their total survey tonnes for a given period. 
	This is filtered by a parent location that is passed in.
 </Procedure>
</TAG>
*/	