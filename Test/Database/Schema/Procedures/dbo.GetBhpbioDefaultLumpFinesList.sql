If Exists (Select * From dbo.sysobjects Where id = object_id(N'dbo.GetBhpbioDefaultLumpFinesList') And OBJECTPROPERTY(id, N'IsProcedure') = 1)
	Drop Procedure dbo.GetBhpbioDefaultLumpFinesList
Go

Create Procedure dbo.GetBhpbioDefaultLumpFinesList
(
	@iLocationId Int = Null,
	@iLocationTypeId Int = Null,
	@iNoOfRecords Int = Null
)
As
Begin
	Set Nocount On
	
	Select D.BhpbioDefaultLumpFinesId,
		L.Name As LocationName,
		T.Description As LocationType,
		D.StartDate,
		Convert(Float, (D.LumpPercent * 100)) As LumpPercentage, --convert to float so that it can be re-formatted on UI
		D.IsNonDeletable
	From dbo.BhpbioDefaultLumpFines As D
		Inner Join dbo.Location As L
			On D.LocationId = L.Location_Id
		Inner Join dbo.LocationType As T
			On L.Location_Type_Id = T.Location_Type_Id
	Where (@iLocationId Is Null Or D.LocationId In
			(
				Select @iLocationId
				Union
				Select LocationId
				From dbo.GetBhpbioReportLocationBreakdown(@iLocationId, 1, 'Pit')
			)
		)
		And (@iLocationTypeId Is Null Or T.Location_Type_Id = @iLocationTypeId)
	Order By L.Name, D.StartDate
End
Go

Grant Execute On dbo.GetBhpbioDefaultLumpFinesList To BhpbioGenericManager
Go
/*
<TAG Name="Data Dictionary" ProcedureName="dbo.GetBhpbioDefaultLumpFinesList">
 <Procedure>
 </Procedure>
</TAG>
*/

