If Exists (Select * From dbo.sysobjects Where id = object_id(N'dbo.GetBhpbioDefaultLumpFinesRecord') And OBJECTPROPERTY(id, N'IsProcedure') = 1)
	Drop Procedure dbo.GetBhpbioDefaultLumpFinesRecord
Go

Create Procedure dbo.GetBhpbioDefaultLumpFinesRecord
(
	@iBhpbioDefaultLumpFinesId Int
)
As
Begin
	Set Nocount On
	
	Select b.BhpbioDefaultLumpFinesId,
		b.LocationId,
		l.Name As LocationName,
		b.StartDate,
		Convert(Float, (b.LumpPercent * 100)) As LumpPercentage,
		b.IsNonDeletable
	From dbo.BhpbioDefaultLumpFines b
		Inner Join dbo.Location l
			On b.LocationId = l.Location_Id
	Where b.BhpbioDefaultLumpFinesId = @iBhpbioDefaultLumpFinesId
End
Go

Grant Execute On dbo.GetBhpbioDefaultLumpFinesRecord To BhpbioGenericManager
Go
/*
<TAG Name="Data Dictionary" ProcedureName="dbo.GetBhpbioDefaultLumpFinesRecord">
 <Procedure>
 </Procedure>
</TAG>
*/

